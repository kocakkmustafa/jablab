import 'dart:convert';

/// Device UI preferences only: no account, training, billing or owner IDs.
enum AppThemePreference { system, light, dark }

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    this.localeTag,
  });

  final AppThemePreference theme;

  /// Null means follow the device's preferred languages.
  final String? localeTag;

  AppPreferences withTheme(AppThemePreference value) =>
      AppPreferences(theme: value, localeTag: localeTag);
  AppPreferences withLocale(String? value) =>
      AppPreferences(theme: theme, localeTag: value);

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.theme == theme &&
      other.localeTag == localeTag;
  @override
  int get hashCode => Object.hash(theme, localeTag);
}

/// The caller supplies the actually shipped locale set, not planned locales.
/// This automatically accepts the extra six only when their runtime catalog
/// is deliberately enabled by its owner. Exact canonical BCP47 tags are used.
class AppPreferencesCodec {
  AppPreferencesCodec({required Iterable<String> supportedLocaleTags})
    : supportedLocaleTags = Set<String>.unmodifiable(supportedLocaleTags) {
    if (this.supportedLocaleTags.isEmpty) {
      throw ArgumentError('A shipped locale set is required');
    }
  }

  static const int schemaVersion = 1;
  static const int maxBytes = 4096;
  final Set<String> supportedLocaleTags;

  void validate(AppPreferences value) {
    final tag = value.localeTag;
    if (tag != null && !supportedLocaleTags.contains(tag)) {
      throw const FormatException('Unsupported preferences locale');
    }
  }

  List<int> encode(AppPreferences value) {
    validate(value);
    return utf8.encode(
      jsonEncode(<String, Object?>{
        'schemaVersion': schemaVersion,
        'theme': value.theme.name,
        'locale': value.localeTag,
      }),
    );
  }

  AppPreferences decode(List<int> bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Preferences exceed byte limit');
    }
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map<String, dynamic> ||
        raw.length != 3 ||
        raw['schemaVersion'] is! int ||
        raw['schemaVersion'] != schemaVersion ||
        !raw.containsKey('locale') ||
        !raw.containsKey('theme')) {
      throw const FormatException('Unsupported preferences schema');
    }
    final theme = switch (raw['theme']) {
      'system' => AppThemePreference.system,
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => throw const FormatException('Unsupported theme preference'),
    };
    final locale = raw['locale'];
    if (locale != null && locale is! String) {
      throw const FormatException('Invalid preferences locale');
    }
    final value = AppPreferences(theme: theme, localeTag: locale as String?);
    validate(value);
    return value;
  }
}

enum PreferencesReadKind {
  loaded,
  missing,
  recovered,
  invalid,
  unavailable,
  timedOut,
}

class PreferencesReadResult {
  const PreferencesReadResult(this.kind, [this.value]);
  final PreferencesReadKind kind;
  final AppPreferences? value;
}

enum PreferencesWriteKind { committed, failed, uncertain }

class PreferencesWriteResult {
  const PreferencesWriteResult(this.kind);
  final PreferencesWriteKind kind;
}

abstract interface class AppPreferencesStore {
  bool get persistent;
  Future<PreferencesReadResult> read();
  Future<PreferencesWriteResult> write(AppPreferences value);
}
