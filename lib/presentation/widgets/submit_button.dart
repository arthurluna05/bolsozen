import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final bool busy, enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Semantics(
      value: busy ? 'Em andamento, aguarde' : null,
      liveRegion: busy,
      child: FilledButton(
        onPressed: enabled && !busy ? onPressed : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              ExcludeSemantics(
                child: SizedBox(
                  width: AppSpacing.lg,
                  height: AppSpacing.lg,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    ),
  );
}
