import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/user_profile.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/submit_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.session,
    required this.profile,
    super.key,
  });
  final SessionController session;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      if (!session.isReady || session.user?.uid != profile.userId) {
        return const SizedBox.shrink();
      }
      return AuthFormLayout(
        title: 'Perfil',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: AppSpacing.xl,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        profile.displayName.characters.first.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      profile.displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(session.user!.email, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Minha conta',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session.authFailure != null)
              AuthFeedback(session.authFailure!.message),
            SubmitButton(
              key: const ValueKey('logout-submit'),
              label: 'Sair',
              busy: session.isSigningOut,
              enabled: !session.isBusy,
              onPressed: session.signOut,
            ),
          ],
        ),
      );
    },
  );
}
