import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final p = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final colors =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: p.mintSurface,
          onPrimaryContainer: p.primary,
          secondary: p.secondary,
          onSecondary: p.textPrimary,
          surface: p.surface,
          onSurface: p.textPrimary,
          onSurfaceVariant: p.textSecondary,
          outline: p.border,
          error: p.error,
          onError: p.onError,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.button),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, 48)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [p],
      fontFamily: 'Roboto',
      colorScheme: colors,
      scaffoldBackgroundColor: p.background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.mintSurface,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
      ),
      textTheme:
          TextTheme(
            displayLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
            displaySmall: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
            headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0,
            ),
            headlineSmall: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0,
            ),
            titleSmall: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0,
            ),
            bodyLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: 0,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: 0,
            ),
            labelSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: 0,
            ),
          ).apply(
            fontFamily: 'Roboto',
            bodyColor: p.textPrimary,
            displayColor: p.textPrimary,
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(p.primary),
          foregroundColor: WidgetStatePropertyAll(p.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(p.mintSurface),
          foregroundColor: WidgetStatePropertyAll(p.primary),
          side: WidgetStatePropertyAll(BorderSide(color: p.secondary)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorStyle: TextStyle(color: p.textPrimary, fontSize: 12),
        errorMaxLines: 3,
        filled: true,
        fillColor: p.surfaceMuted,
        contentPadding: EdgeInsets.all(AppSpacing.base),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: p.border),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}
