import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../presentation/screens/welcome/welcome_screen.dart';

class BolsoZenApp extends StatelessWidget {
  const BolsoZenApp({this.home = const WelcomeScreen(), super.key});
  final Widget home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BolsoZen',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );
}
