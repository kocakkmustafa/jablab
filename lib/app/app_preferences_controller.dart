import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show BuildContext, InheritedNotifier;

import 'app_preferences.dart';

enum PreferencesReadPhase {
  notStarted,
  loading,
  loaded,
  missing,
  recovered,
  invalid,
  unavailable,
  timedOut,
  ignoredAfterEdit,
}

enum PreferencesSavePhase { idle, saving, saved, failed, uncertain }

/// Lives above MotionIdentityGate. It is device state, independent of account
/// admission/owner epochs. Construct once and await load() before runApp().
/// Reads have a UI deadline; they never mutate storage. A timed-out underlying
/// read may finish later but cannot update this controller or the first root.
class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({
    required this.store,
    required this.codec,
    this.readDeadline = const Duration(seconds: 2),
    AppPreferences initial = const AppPreferences(),
  }) : _value = initial {
    codec.validate(initial);
    if (readDeadline <= Duration.zero) {
      throw ArgumentError('A positive read deadline is required');
    }
  }

  /// Harness-only fallback. The production launcher injects the file store;
  /// mounting JabLabApp in a widget test never starts path_provider I/O.
  factory AppPreferencesController.transient(AppPreferencesCodec codec) =>
      AppPreferencesController(
        store: _TransientPreferencesStore(),
        codec: codec,
      );

  final AppPreferencesStore store;
  final AppPreferencesCodec codec;
  final Duration readDeadline;
  AppPreferences _value;
  AppPreferences get value => _value;
  PreferencesReadPhase _readPhase = PreferencesReadPhase.notStarted;
  PreferencesReadPhase get readPhase => _readPhase;
  PreferencesSavePhase _savePhase = PreferencesSavePhase.idle;
  PreferencesSavePhase get savePhase => _savePhase;
  int _revision = 0;
  int _savedRevision = 0;
  int _readRequest = 0;
  int _saveAttempt = 0;
  bool _disposed = false;
  bool get dirty => _revision > _savedRevision;
  bool get persistent => store.persistent;

  Future<void> load() async {
    if (_disposed) return;
    final request = ++_readRequest;
    final revisionAtStart = _revision;
    final mayApply = _revision == 0;
    _readPhase = PreferencesReadPhase.loading;
    notifyListeners();
    PreferencesReadResult result;
    try {
      result = await store.read().timeout(
        readDeadline,
        onTimeout: () =>
            const PreferencesReadResult(PreferencesReadKind.timedOut),
      );
    } on Object {
      result = const PreferencesReadResult(PreferencesReadKind.unavailable);
    }
    if (_disposed || request != _readRequest) return;
    // A retry/read begun before or after an edit must not replace user intent.
    if (!mayApply || _revision != revisionAtStart) {
      _readPhase = PreferencesReadPhase.ignoredAfterEdit;
      notifyListeners();
      return;
    }
    final loaded = result.value;
    if (loaded == null &&
        (result.kind == PreferencesReadKind.loaded ||
            result.kind == PreferencesReadKind.recovered)) {
      result = const PreferencesReadResult(PreferencesReadKind.invalid);
    }
    if (loaded != null) {
      try {
        codec.validate(loaded);
        _value = loaded;
      } on Object {
        result = const PreferencesReadResult(PreferencesReadKind.invalid);
      }
    }
    _readPhase = switch (result.kind) {
      PreferencesReadKind.loaded => PreferencesReadPhase.loaded,
      PreferencesReadKind.missing => PreferencesReadPhase.missing,
      PreferencesReadKind.recovered => PreferencesReadPhase.recovered,
      PreferencesReadKind.invalid => PreferencesReadPhase.invalid,
      PreferencesReadKind.unavailable => PreferencesReadPhase.unavailable,
      PreferencesReadKind.timedOut => PreferencesReadPhase.timedOut,
    };
    notifyListeners();
  }

  void selectTheme(AppThemePreference theme) =>
      _select(_value.withTheme(theme));
  void selectLocale(String? localeTag) => _select(_value.withLocale(localeTag));

  void _select(AppPreferences next) {
    if (_disposed) return;
    // The call is explicit user intent, including selecting the current
    // fallback after a failed read. Untouched retrySave remains a no-op.
    codec.validate(next);
    _value = next;
    _revision++;
    unawaited(_persistLatest());
  }

  /// No untouched/default Save after a failed read. Only a real user edit can
  /// create a save attempt. Retry preserves the current draft, not a readback.
  Future<void> retrySave() {
    if (_disposed || _revision == 0) return Future<void>.value();
    return _persistLatest();
  }

  Future<void> _persistLatest() async {
    final snapshot = _value;
    final revision = _revision;
    final attempt = ++_saveAttempt;
    _savePhase = PreferencesSavePhase.saving;
    notifyListeners();
    PreferencesWriteResult result;
    try {
      result = await store.write(snapshot);
    } on Object {
      result = const PreferencesWriteResult(PreferencesWriteKind.failed);
    }
    if (_disposed) return;
    if (result.kind == PreferencesWriteKind.committed &&
        revision > _savedRevision) {
      _savedRevision = revision;
    }
    // An older Save completion may not replace the newer draft's status.
    if (attempt != _saveAttempt) return;
    _savePhase = switch (result.kind) {
      PreferencesWriteKind.committed => PreferencesSavePhase.saved,
      PreferencesWriteKind.failed => PreferencesSavePhase.failed,
      PreferencesWriteKind.uncertain => PreferencesSavePhase.uncertain,
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _readRequest++;
    // Already queued device preference writes may finish. They cannot notify
    // a disposed UI and contain no user/account data requiring an owner drain.
    super.dispose();
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    super.key,
    required AppPreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppPreferencesController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppPreferencesScope>()
      ?.notifier;
}

class _TransientPreferencesStore implements AppPreferencesStore {
  AppPreferences? _value;
  @override
  bool get persistent => false;
  @override
  Future<PreferencesReadResult> read() async => PreferencesReadResult(
    _value == null ? PreferencesReadKind.missing : PreferencesReadKind.loaded,
    _value,
  );
  @override
  Future<PreferencesWriteResult> write(AppPreferences value) async {
    _value = value;
    return const PreferencesWriteResult(PreferencesWriteKind.committed);
  }
}
