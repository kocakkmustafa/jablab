import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:motion_core/motion_core.dart';

final RegExp _ownerUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? canonicalOwnerId(String? owner) {
  if (owner == null) return null;
  if (!_ownerUuid.hasMatch(owner)) {
    throw ArgumentError.value(owner, 'accountUserId', 'Expected UUID');
  }
  return owner.toLowerCase();
}

final class OwnerResourceRetiredException extends StateError {
  OwnerResourceRetiredException() : super('Owner resource lifetime is closed');
}

/// A stale account page cannot erase a successor's local lifetime. The confirmed
/// remote deletion remains pending for the independent receipt reconciliation.
final class OwnerResourceStaleCleanupException extends StateError {
  OwnerResourceStaleCleanupException()
    : super('Local cleanup requires current initiating owner lifetime');
}

/// One admitted account/guest epoch. Core journals and host course IO share its
/// retirement boundary, while their independent drain barriers are both awaited.
final class OwnerResourceLifetime {
  OwnerResourceLifetime._(this.accountUserId, this.epoch);

  final String? accountUserId;
  final int epoch;
  final SessionStoreWriteLease journalWrites = SessionStoreWriteLease();
  final ValueNotifier<bool> _active = ValueNotifier<bool>(true);
  final Set<Future<void>> _pendingCourseIo = <Future<void>>{};
  bool _courseAdmission = true;
  bool _drained = false;
  Future<void>? _retirement;

  bool get isActive => _active.value;
  ValueListenable<bool> get active => _active;

  void checkActive() {
    if (!_courseAdmission || !journalWrites.isActive) {
      throw OwnerResourceRetiredException();
    }
  }

  /// Host course operations register before invoking filesystem/queue code.
  /// Core's private lease runner cannot account for these operations.
  Future<T> runCourseIo<T>(Future<T> Function() operation) async {
    checkActive();
    final Completer<void> settled = Completer<void>();
    _pendingCourseIo.add(settled.future);
    try {
      final T value = await operation();
      checkActive();
      return value;
    } finally {
      _pendingCourseIo.remove(settled.future);
      settled.complete();
    }
  }

  /// Admission closes synchronously, including before the active notification.
  /// Retirement never erases persisted data.
  Future<void> retireAndDrain() {
    final Future<void>? retirement = _retirement;
    if (retirement != null) return retirement;
    _courseAdmission = false;
    final Future<void> journals = journalWrites.retireAndDrain();
    // Set the future before notifying a reentrant host listener.
    _retirement =
        Future.wait<void>(<Future<void>>[
          journals,
          ..._pendingCourseIo,
        ]).then<void>((_) {
          _drained = true;
        });
    _active.value = false;
    return _retirement!;
  }
}

/// One instance represents one app storage namespace. Tests with separate roots
/// inject separate registries instead of sharing the production singleton.
final class OwnerResourceRegistry {
  OwnerResourceRegistry({bool admitGuest = true}) {
    if (admitGuest) activate(null);
  }

  final Map<String?, OwnerResourceLifetime> _owners =
      <String?, OwnerResourceLifetime>{};
  final Map<String, Future<void>> _deletions = <String, Future<void>>{};
  int _nextEpoch = 0;

  /// Only a verified host transition may create a new account epoch. Calling
  /// capture/open never reactivates a closed epoch. Wait for the old drain first.
  OwnerResourceLifetime activate(String? owner) {
    final String? id = canonicalOwnerId(owner);
    if (id != null && _deletions.containsKey(id)) {
      throw OwnerResourceRetiredException();
    }
    final OwnerResourceLifetime? previous = _owners[id];
    if (previous?.isActive == true) return previous!;
    if (previous != null && !previous._drained) {
      throw OwnerResourceRetiredException();
    }
    return _owners[id] = OwnerResourceLifetime._(id, ++_nextEpoch);
  }

  OwnerResourceLifetime capture(String? owner) {
    final String? id = canonicalOwnerId(owner);
    final OwnerResourceLifetime? lifetime = _owners[id];
    if (lifetime == null || (id != null && _deletions.containsKey(id))) {
      throw OwnerResourceRetiredException();
    }
    lifetime.checkActive();
    return lifetime;
  }

  /// Identity comparison, including retired tickets, without creating an epoch.
  bool isCurrent(OwnerResourceLifetime lifetime) =>
      identical(_owners[lifetime.accountUserId], lifetime);

  Future<void> retire(String? owner) {
    final String? id = canonicalOwnerId(owner);
    return _owners[id]?.retireAndDrain() ?? Future<void>.value();
  }

  Future<void> retireAll() => Future.wait<void>(<Future<void>>[
    for (final OwnerResourceLifetime lifetime in _owners.values.toList())
      lifetime.retireAndDrain(),
  ]).then((_) {});

  /// Admission and duplicate-callback coalescing happen before the first await.
  /// The host erase closure runs only after journal AND host course IO settles.
  Future<void> eraseConfirmed(
    String confirmedAccountUserId,
    Future<void> Function() erase, {
    OwnerResourceLifetime? expectedLifetime,
  }) {
    final String id = canonicalOwnerId(confirmedAccountUserId)!;
    if (expectedLifetime != null &&
        (expectedLifetime.accountUserId != id ||
            !isCurrent(expectedLifetime) ||
            !expectedLifetime.isActive ||
            !expectedLifetime.journalWrites.isActive ||
            _deletions.containsKey(id))) {
      throw OwnerResourceStaleCleanupException();
    }
    final Future<void>? pending = _deletions[id];
    if (pending != null) return pending;
    final Completer<void> completion = Completer<void>();
    _deletions[id] = completion.future;
    final Future<void> drained = retire(id);
    unawaited(() async {
      try {
        await drained;
        await erase();
        completion.complete();
      } catch (error, stack) {
        completion.completeError(error, stack);
      } finally {
        if (identical(_deletions[id], completion.future)) {
          _deletions.remove(id);
        }
      }
    }());
    return completion.future;
  }
}

final OwnerResourceRegistry defaultOwnerResourceRegistry =
    OwnerResourceRegistry();
