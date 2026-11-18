import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens semânticos interpoláveis; widgets não escolhem paletas individualmente.
final class AppPalette extends ThemeExtension<AppPalette> {
  AppPalette(Map<String, Color> values) : _values = Map.unmodifiable(values);
  final Map<String, Color> _values;

  static final light = AppPalette({
    'primary': AppColors.primary,
    'secondary': AppColors.secondary,
    'mint': AppColors.mint,
    'mintSurface': AppColors.mintSurface,
    'background': AppColors.background,
    'surface': AppColors.surface,
    'surfaceMuted': AppColors.surfaceMuted,
    'textPrimary': AppColors.textPrimary,
    'textSecondary': AppColors.textSecondary,
    'border': AppColors.border,
    'success': AppColors.success,
    'warning': AppColors.warning,
    'error': AppColors.error,
    'onPrimary': Colors.white,
    'onError': AppColors.textPrimary,
    'expenseText': const Color(0xFFD91032),
    'expenseControlText': const Color(0xFFC4102D),
    'expenseSurface': const Color(0xFFFEE1E3),
    'shadow': AppColors.textPrimary,
    'brandSurface': Colors.transparent,
  });
  static final dark = AppPalette({
    'primary': const Color(0xFF6DE2BA),
    'secondary': const Color(0xFF34D399),
    'mint': const Color(0xFF2A7257),
    'mintSurface': const Color(0xFF203D32),
    'background': const Color(0xFF101715),
    'surface': const Color(0xFF1B2622),
    'surfaceMuted': const Color(0xFF25332D),
    'textPrimary': const Color(0xFFF3F7F5),
    'textSecondary': const Color(0xFFADBDB5),
    'border': const Color(0xFF3E5148),
    'success': const Color(0xFF5BDE92),
    'warning': const Color(0xFFFFC36B),
    'error': const Color(0xFFFF98A5),
    'onPrimary': const Color(0xFF052E23),
    'onError': AppColors.textPrimary,
    'expenseText': const Color(0xFFFFA0AD),
    'expenseControlText': const Color(0xFFFFA0AD),
    'expenseSurface': const Color(0xFF4B252E),
    'shadow': Colors.black,
    'brandSurface': AppColors.mintSurface,
  });

  Color get primary => _values['primary']!;
  Color get secondary => _values['secondary']!;
  Color get mint => _values['mint']!;
  Color get mintSurface => _values['mintSurface']!;
  Color get background => _values['background']!;
  Color get surface => _values['surface']!;
  Color get surfaceMuted => _values['surfaceMuted']!;
  Color get textPrimary => _values['textPrimary']!;
  Color get textSecondary => _values['textSecondary']!;
  Color get border => _values['border']!;
  Color get success => _values['success']!;
  Color get warning => _values['warning']!;
  Color get error => _values['error']!;
  Color get onPrimary => _values['onPrimary']!;
  Color get onError => _values['onError']!;
  Color get expenseText => _values['expenseText']!;
  Color get expenseControlText => _values['expenseControlText']!;
  Color get expenseSurface => _values['expenseSurface']!;
  Color get shadow => _values['shadow']!;
  Color get brandSurface => _values['brandSurface']!;

  @override
  AppPalette copyWith({Map<String, Color>? values}) =>
      AppPalette({..._values, ...?values});
  @override
  AppPalette lerp(covariant AppPalette? other, double t) => other == null
      ? this
      : AppPalette({
          for (final entry in _values.entries)
            entry.key: Color.lerp(entry.value, other._values[entry.key], t)!,
        });
}

extension AppColorContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
