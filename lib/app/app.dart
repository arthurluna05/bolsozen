import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../presentation/screens/welcome/welcome_screen.dart';

class BolsoZenApp extends StatefulWidget {
  const BolsoZenApp({
    this.home = const WelcomeScreen(),
    this.themeController,
    super.key,
  });
  final Widget home;
  final ThemeController? themeController;
  @override
  State<BolsoZenApp> createState() => _BolsoZenAppState();
}

class _BolsoZenAppState extends State<BolsoZenApp> {
  late final ThemeController _theme =
      widget.themeController ?? ThemeController();
  @override
  void dispose() {
    if (widget.themeController == null) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ThemeScope(
    controller: _theme,
    child: ListenableBuilder(
      listenable: _theme,
      builder: (context, _) => MaterialApp(
        title: 'BolsoZen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.mode,
        themeAnimationDuration:
            WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 300),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget.home,
      ),
    ),
  );
}
