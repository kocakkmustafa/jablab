import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'owner_resource_lifetime.dart';

/// Host ownership boundary around the shared account UI.
class OwnerBoundAccountPage extends StatefulWidget {
  const OwnerBoundAccountPage({
    super.key,
    required this.account,
    this.lifetime,
    this.ownerRegistry,
    this.initialPasswordRecovery = false,
    this.onRetryIdentity,
    this.clearLocalData,
    this.canInitiate,
  });

  final MotionAccountClient account;
  final bool Function()? canInitiate;
  final OwnerResourceLifetime? lifetime;
  final OwnerResourceRegistry? ownerRegistry;
  final bool initialPasswordRecovery;
  final Future<void> Function()? onRetryIdentity;
  final Future<void> Function(String userId)? clearLocalData;

  @override
  State<OwnerBoundAccountPage> createState() => _OwnerBoundAccountPageState();
}

class _OwnerBoundAccountPageState extends State<OwnerBoundAccountPage> {
  _OwnerBoundAccountClient? _bound;
  late MotionAccountClient _account;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    // Every binding owns the error-filtered stream, including recovery, guest,
    // and unverified identity. Only an admitted account ticket permits deletion.
    _account = _bound = _OwnerBoundAccountClient(
      delegate: widget.account,
      canInitiate: widget.canInitiate,
      lifetime: widget.lifetime,
      registry: widget.ownerRegistry ?? defaultOwnerResourceRegistry,
    );
  }

  @override
  void didUpdateWidget(covariant OwnerBoundAccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.account, widget.account) ||
        !identical(oldWidget.lifetime, widget.lifetime) ||
        !identical(oldWidget.ownerRegistry, widget.ownerRegistry)) {
      _bound?.dispose();
      _bind();
    }
  }

  @override
  void dispose() {
    _bound?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MotionAccountPage(
    // A mounted old dialog cannot resume through a replacement client/ticket.
    key: ObjectKey(_account),
    account: _account,
    initialPasswordRecovery: widget.initialPasswordRecovery,
    onRetryIdentity: widget.onRetryIdentity,
    clearLocalData: _bound?.destructiveEnabled == true
        ? widget.clearLocalData
        : null,
  );
}

/// Only this page's authorization retires. Local IO lifetime activation and
/// retirement remain the verified host's responsibility.
class _OwnerBoundAccountClient extends MotionAccountClient {
  _OwnerBoundAccountClient({
    required MotionAccountClient delegate,
    required this.lifetime,
    required this.registry,
    this.canInitiate,
  }) : _openingSession = delegate.supabase.auth.currentSession,
       _openingToken = delegate.supabase.auth.currentSession?.accessToken,
       super(
         supabase: delegate.supabase,
         app: delegate.app,
         emailRedirectTo: delegate.emailRedirectTo,
       ) {
    destructiveEnabled = _currentTicket;
    _subscription = delegate.authChanges.listen(
      _onAuthState,
      onError: (Object _, StackTrace __) => _retire(),
      onDone: _retire,
    );
  }

  final OwnerResourceLifetime? lifetime;
  final OwnerResourceRegistry registry;
  final bool Function()? canInitiate;
  late final bool destructiveEnabled;
  final Session? _openingSession;
  final String? _openingToken;
  final _changes = StreamController<AuthState>.broadcast(sync: true);
  late final StreamSubscription<AuthState> _subscription;
  bool _awaitingReplay = true;
  bool _ready = false;
  bool _disposed = false;
  int _authGeneration = 0;
  Session? _admittedSession;
  String? _admittedToken;

  /// Observe source errors to close this host binding. Core V4 also observes
  /// raw auth errors; this filtered stream preserves the separate host policy.
  @override
  Stream<AuthState> get authChanges => _changes.stream;

  void _retire() {
    _authGeneration++;
  }

  bool get _currentTicket {
    final ticket = lifetime;
    return ticket != null &&
        ticket.accountUserId != null &&
        registry.isCurrent(ticket) &&
        ticket.isActive &&
        ticket.journalWrites.isActive &&
        _matchesOwner(currentUser?.id);
  }

  bool _matchesOwner(String? id) {
    final owner = lifetime?.accountUserId;
    if (owner == null) return false;
    try {
      return canonicalOwnerId(id) == owner;
    } on ArgumentError {
      return false;
    }
  }

  void _onAuthState(AuthState state) {
    if (_disposed) return;
    if (_awaitingReplay) {
      _awaitingReplay = false;
      // gotrue 2.27.2's subject replays its latest value/error. The first value
      // is a baseline only if the exact opening session still owns this ticket.
      if (!identical(state.session, _openingSession) ||
          !identical(supabase.auth.currentSession, _openingSession) ||
          supabase.auth.currentSession?.accessToken != _openingToken ||
          _openingToken == null ||
          _openingToken.isEmpty ||
          state.event == AuthChangeEvent.passwordRecovery ||
          // Handle the retained SDK enum fail-closed even while deprecated.
          // ignore: deprecated_member_use
          state.event == AuthChangeEvent.userDeleted ||
          state.event == AuthChangeEvent.signedOut ||
          !_currentTicket) {
        _retire();
      } else {
        _ready = true;
        _admittedSession = state.session;
        _admittedToken = state.session?.accessToken;
      }
    } else {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.passwordRecovery:
        // ignore: deprecated_member_use
        case AuthChangeEvent.userDeleted:
        case AuthChangeEvent.initialSession:
          // A new auth epoch can reuse UUID, token, and even Session object.
          _retire();
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          if (!_currentTicket ||
              !_matchesOwner(state.session?.user.id) ||
              !identical(state.session, supabase.auth.currentSession) ||
              state.session?.accessToken.isNotEmpty != true) {
            _retire();
          } else {
            _admittedSession = state.session;
            _admittedToken = state.session?.accessToken;
          }
        default:
          if (!_currentTicket ||
              !identical(state.session, _admittedSession) ||
              state.session?.accessToken != _admittedToken) {
            _retire();
          }
      }
    }
    _changes.add(state);
  }

  void _checkCurrent() {
    if (_disposed ||
        !(canInitiate?.call() ?? true) ||
        _authGeneration != 0 ||
        !_ready ||
        !_currentTicket ||
        !identical(supabase.auth.currentSession, _admittedSession) ||
        supabase.auth.currentSession?.accessToken != _admittedToken ||
        supabase.auth.currentSession?.accessToken.isNotEmpty != true) {
      throw OwnerResourceRetiredException();
    }
  }

  @override
  Future<void> deleteCommonAccount({
    Future<void> Function(String userId)? afterRemoteDelete,
  }) async {
    // Public GoTrue auth events are asynchronous. Complete their queued delivery
    // before admission, including signedIn events reusing the same Session.
    await Future<void>.delayed(Duration.zero);
    // No await separates this final check from Core capturing UUID/token.
    _checkCurrent();
    final initiatingUser = currentUser!.id;
    final initiatingLifetime = lifetime!;
    return super.deleteCommonAccount(
      afterRemoteDelete: (confirmedId) async {
        if (confirmedId != initiatingUser) {
          throw OwnerResourceStaleCleanupException();
        }
        // Core has verified this exact UUID's deletion receipt. Start both the
        // captured handle retirement and the authoritative UUID fence before
        // the first await. Auth and replacement media are not selected here.
        final capturedDrain = initiatingLifetime.retireAndDrain();
        Future<void> cleanup;
        try {
          cleanup =
              afterRemoteDelete?.call(confirmedId) ?? Future<void>.value();
        } catch (error, stack) {
          cleanup = Future<void>.error(error, stack);
        }
        // Even a synchronous host callback failure must leave the captured
        // retirement observed and settled before Core completes this operation.
        await Future.wait<void>([capturedDrain, cleanup]);
      },
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _retire();
    unawaited(
      Future.wait<void>([_subscription.cancel(), _changes.close()])
          .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
    );
  }
}
