import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/submit_button.dart';

/// Estados reais de carregamento/erro. Ausência confirmada tem formulário próprio.
class SessionStatusScreen extends StatelessWidget {
  const SessionStatusScreen({required this.session, super.key});
  final SessionController session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final missing = session.phase == SessionPhase.missingProfile;
      final loading =
          session.phase == SessionPhase.checking ||
          session.phase == SessionPhase.authenticating ||
          session.phase == SessionPhase.loadingProfile;
      if (loading) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      semanticsLabel: 'Verificando sua sessão',
                    ),
                    if (session.user != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      SubmitButton(
                        key: const ValueKey('status-logout'),
                        label: 'Sair',
                        busy: session.isSigningOut,
                        enabled: session.canSignOut,
                        onPressed: session.signOut,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return AuthFormLayout(
        title: missing
            ? 'Perfil não encontrado'
            : 'Não foi possível carregar sua conta',
        description: missing
            ? 'Seu perfil ainda não está disponível. Saia da conta e tente entrar novamente.'
            : 'Tente novamente ou saia da sua conta para continuar com segurança.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!missing) ...[
              if (session.hasPendingProfileCreation)
                const AuthFeedback(
                  'Sua conta já está conectada. Falta confirmar o perfil; tente salvar novamente, sem criar outra conta.',
                ),
              AuthFeedback(
                session.profileFailure?.message ??
                    session.authFailure?.message ??
                    'Não foi possível confirmar sua sessão.',
              ),
              SubmitButton(
                label: session.hasPendingProfileCreation
                    ? 'Tentar salvar perfil novamente'
                    : 'Tentar novamente',
                enabled: !session.isBusy,
                onPressed: session.phase == SessionPhase.sessionError
                    ? session.retrySession
                    : session.retryProfile,
              ),
              const SizedBox(height: AppSpacing.base),
            ] else if (session.authFailure != null)
              AuthFeedback(session.authFailure!.message),
            SubmitButton(
              key: const ValueKey('status-logout'),
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
