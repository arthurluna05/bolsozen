import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/services/auth_validation.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/password_field.dart';
import '../../widgets/submit_button.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.session, this.onRegister, super.key});
  final SessionController session;
  final VoidCallback? onRegister;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final _emailFocus = FocusNode(), _passwordFocus = FocusNode();
  bool _submitting = false, _attempted = false;

  Future<void> _submit() async {
    if (_submitting || widget.session.isBusy) return;
    if (!_form.currentState!.validate()) {
      (AuthValidation.email(_email.text) != null ? _emailFocus : _passwordFocus)
          .requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _attempted = true;
    });
    FocusScope.of(context).unfocus();
    try {
      await widget.session.signIn(email: _email.text, password: _password.text);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final busy = _submitting || widget.session.isBusy;
      final failure = _attempted ? widget.session.authFailure : null;
      final error = failure == null
          ? null
          : (failure.kind == AuthFailureKind.userDisabled ||
                failure.kind == AuthFailureKind.unauthenticated)
          ? const AuthFailure(AuthFailureKind.invalidCredentials).message
          : failure.message;
      return AuthFormLayout(
        title: 'Entrar no BolsoZen',
        description: 'Acesse sua conta e continue cuidando das suas finanças.',
        onBack: () => Navigator.of(context).maybePop(),
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              children: [
                if (error != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AuthFeedback(error),
                  ),
                TextFormField(
                  key: const ValueKey('login-email'),
                  controller: _email,
                  focusNode: _emailFocus,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) =>
                      AuthValidation.email(value ?? '')?.message,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                PasswordField(
                  key: const ValueKey('login-password'),
                  controller: _password,
                  focusNode: _passwordFocus,
                  enabled: !busy,
                  validator: (value) =>
                      AuthValidation.loginPassword(value ?? '')?.message,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PasswordResetScreen(session: widget.session),
                            ),
                          ),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SubmitButton(
                  key: const ValueKey('login-submit'),
                  label: 'Entrar',
                  busy: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: Text(
                        'ou',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: busy ? null : widget.onRegister,
                    child: const Text('Criar conta'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autenticação segura',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'Login com Firebase',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
