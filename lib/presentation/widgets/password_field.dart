import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.validator,
    this.focusNode,
    this.enabled = true,
    this.onSubmitted,
    this.label = 'Senha',
    this.newPassword = false,
    this.textInputAction = TextInputAction.done,
    super.key,
  });
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final String label;
  final bool newPassword;
  final TextInputAction textInputAction;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    focusNode: widget.focusNode,
    enabled: widget.enabled,
    validator: widget.validator,
    obscureText: _obscure,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: widget.textInputAction,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
        onPressed: widget.enabled
            ? () => setState(() => _obscure = !_obscure)
            : null,
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
