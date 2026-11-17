import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  void _showAvailability(BuildContext context, String resource) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource),
        content: Text('$resource estará disponível em uma etapa posterior.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Image.asset(
                        'assets/branding/bolsozen_logo.png',
                        width: 280,
                        height: 280,
                        fit: BoxFit.contain,
                        semanticLabel: 'BolsoZen, finanças com tranquilidade',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Controle suas finanças, alcance seus objetivos e tenha mais tranquilidade no dia a dia.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      const _IllustrationCarousel(),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _showAvailability(context, 'Entrar'),
                          child: const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              _showAvailability(context, 'Criar conta'),
                          child: const Text('Criar conta'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _IllustrationCarousel extends StatefulWidget {
  const _IllustrationCarousel();

  @override
  State<_IllustrationCarousel> createState() => _IllustrationCarouselState();
}

class _IllustrationCarouselState extends State<_IllustrationCarousel> {
  static const _assets = [
    'assets/illustrations/onboarding01.png',
    'assets/illustrations/onboarding02.png',
    'assets/illustrations/onboarding03.png',
  ];
  int _page = 0;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AspectRatio(
        aspectRatio: 1.6,
        child: PageView.builder(
          itemCount: _assets.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) => Image.asset(
            _assets[index],
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Semantics(
        label: 'Ilustração ${_page + 1} de ${_assets.length}',
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _assets.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Container(
                key: ValueKey('onboarding-dot-$index'),
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _page
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
