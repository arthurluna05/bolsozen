import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/services/auth_validation.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/password_field.dart';
import '../../widgets/submit_button.dart';

/// TEL-03. Credenciais somente na memória do formulário até seu descarte.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.session,
    required this.onLogin,
    super.key,
  });
  final SessionController session;
  final VoidCallback onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  final _nameFocus = FocusNode(), _emailFocus = FocusNode();
  final _passwordFocus = FocusNode(), _confirmationFocus = FocusNode();
  bool _submitting = false, _attempted = false;

  Future<void> _submit() async {
    if (_submitting || widget.session.isBusy) return;
    if (!_form.currentState!.validate()) {
      final focus = AuthValidation.name(_name.text) != null
          ? _nameFocus
          : AuthValidation.email(_email.text) != null
          ? _emailFocus
          : AuthValidation.registrationPassword(_password.text) != null
          ? _passwordFocus
          : _confirmationFocus;
      focus.requestFocus();
      return;
    }
    setState(() {
      _submitting = true;
      _attempted = true;
    });
    FocusScope.of(context).unfocus();
    try {
      await widget.session.signUp(
        displayName: _name.text,
        email: _email.text,
        password: _password.text,
        confirmation: _confirmation.text,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirmation]) {
      controller.dispose();
    }
    for (final focus in [
      _nameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmationFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final busy = _submitting || widget.session.isBusy;
      return AuthFormLayout(
        title: 'Criar sua conta',
        description: 'É rápido e gratuito. Comece hoje a organizar suas finanças com o BolsoZen.',
        onBack: () => Navigator.of(context).maybePop(),
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              children: [
                if (_attempted && widget.session.authFailure != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AuthFeedback(widget.session.authFailure!.message),
                  ),
                TextFormField(
                  key: const ValueKey('register-name'),
                  controller: _name,
                  focusNode: _nameFocus,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      AuthValidation.name(value ?? '')?.message,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                TextFormField(
                  key: const ValueKey('register-email'),
                  controller: _email,
                  focusNode: _emailFocus,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
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
                  key: const ValueKey('register-password'),
                  controller: _password,
                  focusNode: _passwordFocus,
                  enabled: !busy,
                  newPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      AuthValidation.registrationPassword(value ?? '')?.message,
                  onSubmitted: (_) => _confirmationFocus.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.base),
                PasswordField(
                  key: const ValueKey('register-confirmation'),
                  label: 'Confirmar senha',
                  controller: _confirmation,
                  focusNode: _confirmationFocus,
                  enabled: !busy,
                  newPassword: true,
                  validator: (value) => AuthValidation.passwordConfirmation(
                    _password.text,
                    value ?? '',
                  )?.message,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                SubmitButton(
                  key: const ValueKey('register-submit'),
                  label: 'Criar conta',
                  busy: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: busy ? null : widget.onLogin,
                  child: const Text(
                    'Já tenho conta',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
