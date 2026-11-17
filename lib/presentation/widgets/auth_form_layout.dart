import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Composição TEL-02/TEL-10: fundo do tema, alinhamento à esquerda e rolagem.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    required this.title,
    required this.child,
    this.description,
    this.onBack,
    super.key,
  });
  final String title;
  final String? description;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    child: Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(height: AppSpacing.base),
                  ] else
                    const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthFeedback extends StatelessWidget {
  const AuthFeedback(this.message, {this.success = false, super.key});
  final String message;
  final bool success;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: success
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}
