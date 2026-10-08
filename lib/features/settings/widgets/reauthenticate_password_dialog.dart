import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/validator.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_textfield.dart';

/// Prompts for the account password so a sensitive Firebase operation
/// (account deletion) can pass `reauthenticateWithCredential` after
/// Firebase rejects it with `requires-recent-login`.
class ReauthenticatePasswordDialog extends StatefulWidget {
  const ReauthenticatePasswordDialog({super.key});

  @override
  State<ReauthenticatePasswordDialog> createState() =>
      _ReauthenticatePasswordDialogState();
}

class _ReauthenticatePasswordDialogState
    extends State<ReauthenticatePasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: CustomDialogBox(
        title: context.tr('password'),
        buttons: [
          DialogButton(
            color: Colors.transparent,
            title: context.tr('cancel'),
            onTap: () => Navigator.pop(context, null),
          ),
          DialogButton(
            title: context.tr('confirm'),
            onTap: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, _passwordController.text.trim());
            },
          ),
        ],
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: context.sizes.md, vertical: context.sizes.xxs),
          child: CustomTextField(
            hintText: context.tr('password'),
            controller: _passwordController,
            obscureText: true,
            validator: (value) => Validator.validatePassword(context, value),
          ),
        ),
      ),
    );
  }
}
