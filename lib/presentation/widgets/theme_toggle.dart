import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key});
  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  double _drag = 0;
  Future<void> _select(ThemeController? controller, bool dark) async {
    if (controller == null) return;
    await controller.setDark(dark);
    if (mounted && controller.failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.failure!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.maybeOf(context);
    final dark =
        controller?.isDark ?? Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onHorizontalDragStart: (_) => _drag = 0,
      onHorizontalDragUpdate: (event) => _drag += event.delta.dx,
      onHorizontalDragEnd: (_) {
        if (_drag.abs() >= 12) _select(controller, _drag > 0);
      },
      child: Container(
        width: 96,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.mintSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Semantics(
                  selected: !dark,
                  child: IconButton(
                    tooltip: 'Ativar tema claro',
                    onPressed: controller == null || controller.isSaving
                        ? null
                        : () => _select(controller, false),
                    icon: Icon(
                      Icons.light_mode_outlined,
                      color: !dark
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                Semantics(
                  selected: dark,
                  child: IconButton(
                    tooltip: 'Ativar tema escuro',
                    onPressed: controller == null || controller.isSaving
                        ? null
                        : () => _select(controller, true),
                    icon: Icon(
                      Icons.dark_mode_outlined,
                      color: dark
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
