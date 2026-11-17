import 'package:flutter/material.dart';

import '../presentation/controllers/session_controller.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/complete_profile_screen.dart';
import '../presentation/screens/auth/session_status_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/welcome/welcome_screen.dart';
import 'session_gate.dart';

/// Mesma árvore para produção e testes; somente os contratos são injetados.
class AuthExperience extends StatelessWidget {
  const AuthExperience({required this.createController, super.key});
  final SessionController Function() createController;

  @override
  Widget build(BuildContext context) => SessionGate(
    createController: createController,
    publicBuilder: (context, session) => WelcomeScreen(
      onSignIn: session.isBusy
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _PublicAuthFlow(session: session),
              ),
            ),
      onRegister: session.isBusy
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    _PublicAuthFlow(session: session, registration: true),
              ),
            ),
    ),
    loadingBuilder: (_, session) => SessionStatusScreen(session: session),
    readyBuilder: (_, session, profile) =>
        ProfileScreen(session: session, profile: profile),
    missingProfileBuilder: (_, session) =>
        CompleteProfileScreen(session: session),
    errorBuilder: (_, session) => SessionStatusScreen(session: session),
  );
}

/// Uma única rota acima das boas-vindas: alternar formulário não empilha rotas.
class _PublicAuthFlow extends StatefulWidget {
  const _PublicAuthFlow({required this.session, this.registration = false});
  final SessionController session;
  final bool registration;
  @override
  State<_PublicAuthFlow> createState() => _PublicAuthFlowState();
}

class _PublicAuthFlowState extends State<_PublicAuthFlow> {
  late bool _registration = widget.registration;
  @override
  Widget build(BuildContext context) => _registration
      ? RegisterScreen(
          session: widget.session,
          onLogin: () => setState(() => _registration = false),
        )
      : LoginScreen(
          session: widget.session,
          onRegister: () => setState(() => _registration = true),
        );
}
