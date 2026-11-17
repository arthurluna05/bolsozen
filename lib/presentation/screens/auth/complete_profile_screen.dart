import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/services/auth_validation.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/auth_form_layout.dart';
import '../../widgets/submit_button.dart';

/// Somente ausência confirmada; erro/permissão não autoriza sobrescrever perfil.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({required this.session, super.key});
  final SessionController session;
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _focus = FocusNode();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting || widget.session.isBusy) return;
    if (!_form.currentState!.validate()) {
      _focus.requestFocus();
      return;
    }
    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();
    try {
      await widget.session.completeProfile(displayName: _name.text);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      if (session.user == null ||
          session.phase != SessionPhase.missingProfile) {
        return const SizedBox.shrink();
      }
      return AuthFormLayout(
        title: 'Completar perfil',
        description: 'Sua conta está conectada. Informe seu nome para concluir seu perfil.',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (session.authFailure != null)
                AuthFeedback(session.authFailure!.message),
              TextFormField(
                key: ValueKey('complete-email-${session.user!.uid}'),
                initialValue: session.user!.email,
                readOnly: true,
                enableInteractiveSelection: true,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              TextFormField(
                key: const ValueKey('complete-name'),
                controller: _name,
                focusNode: _focus,
                enabled: !session.isBusy && !_submitting,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.done,
                validator: (value) => AuthValidation.name(value ?? '')?.message,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SubmitButton(
                key: const ValueKey('complete-submit'),
                label: 'Salvar perfil',
                busy: _submitting,
                enabled: !session.isBusy,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.base),
              SubmitButton(
                key: const ValueKey('status-logout'),
                label: 'Sair',
                busy: session.isSigningOut,
                enabled: session.canSignOut,
                onPressed: session.signOut,
              ),
            ],
          ),
        ),
      );
    },
  );
}
