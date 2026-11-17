import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/auth_failure.dart';
import '../../../domain/services/auth_validation.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/submit_button.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({required this.session, super.key});
  final SessionController session;
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false, _submitting = false, _attempted = false;

  Future<void> _submit() async {
    if (_sent ||
        _submitting ||
        widget.session.isBusy ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _attempted = true;
    });
    FocusScope.of(context).unfocus();
    final sent = await widget.session.sendPasswordReset(email: _email.text);
    if (mounted) {
      setState(() {
        _submitting = false;
        _sent = sent;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) => AuthFormLayout(
      title: 'Recuperar senha',
      description: 'Informe seu e-mail para solicitar as instruções de recuperação da sua senha.',
      onBack: () => Navigator.of(context).maybePop(),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent)
              const AuthFeedback(
                AuthFailure.passwordResetConfirmation,
                success: true,
              ),
            if (_attempted && widget.session.passwordResetFailure != null)
              AuthFeedback(widget.session.passwordResetFailure!.message),
            TextFormField(
              key: const ValueKey('reset-email'),
              controller: _email,
              enabled: !_sent && !_submitting && !widget.session.isBusy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              validator: (value) => AuthValidation.email(value ?? '')?.message,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'E-mail',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SubmitButton(
              key: const ValueKey('reset-submit'),
              label: 'Enviar link de recuperação',
              busy: _submitting || widget.session.isResettingPassword,
              enabled: !_sent && !widget.session.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Voltar para entrar',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
