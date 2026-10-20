// Device appearance adapter for the published Core appearance/locale API.
// Host runtime acceptance and physical-device acceptance remain separate.
import 'package:flutter/material.dart';
import 'package:motion_account/motion_account.dart';

import 'app_preferences.dart';
import 'app_preferences_controller.dart';
import 'design_tokens.dart';
import 'ui_language.dart';

/// Top-level runApp adapter: device presentation never owns identity or storage.
class JabLabIdentityAppearanceGate extends StatefulWidget {
  const JabLabIdentityAppearanceGate({
    super.key,
    required this.runtime,
    required this.preferences,
    required this.child,
  });

  final MotionAccountRuntime runtime;
  final AppPreferencesController preferences;
  final Widget child;

  @override
  State<JabLabIdentityAppearanceGate> createState() =>
      _JabLabIdentityAppearanceGateState();
}

class _JabLabIdentityAppearanceGateState
    extends State<JabLabIdentityAppearanceGate>
    with WidgetsBindingObserver {
  late List<Locale> _preferredLocales;

  @override
  void initState() {
    super.initState();
    _preferredLocales = List<Locale>.unmodifiable(
      WidgetsBinding.instance.platformDispatcher.locales,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (!mounted) {
      return;
    }
    setState(() {
      _preferredLocales = List<Locale>.unmodifiable(
        locales ?? const <Locale>[],
      );
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.preferences,
    // Same Widget instance: appearance rebuilds do not create owner tickets.
    child: widget.child,
    builder: (context, child) {
      final value = widget.preferences.value;
      final selected = value.localeTag;
      final locale = selected == null
          ? null
          : AppLocalizations.supportedLocales.firstWhere(
              (candidate) => candidate.toLanguageTag() == selected,
            );
      return MotionIdentityGate(
        runtime: widget.runtime,
        theme: jablabTheme(Brightness.light),
        darkTheme: jablabTheme(Brightness.dark),
        themeMode: switch (value.theme) {
          AppThemePreference.system => ThemeMode.system,
          AppThemePreference.light => ThemeMode.light,
          AppThemePreference.dark => ThemeMode.dark,
        },
        locale: locale,
        preferredLocales: _preferredLocales,
        child: child!,
      );
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // The launcher keeps ownership of runtime and device preferences.
    super.dispose();
  }
}
