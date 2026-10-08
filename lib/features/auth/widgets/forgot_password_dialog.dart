import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/validator.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/custom_textfield.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';

// Dialog for requesting a password-reset email; closes itself on success or
// shows an inline error from the bloc on failure.
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String?
      _errorText; // set from bloc failure state, cleared on each new send attempt

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        // Reset email sent: close the dialog rather than showing a success
        // message here.
        if (state is SendForgotPasswordEmailSuccessState) {
          Navigator.pop(context);
        }
        if (state is SendForgotPasswordEmailFailState) {
          setState(() => _errorText = state.error);
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: CustomDialogBox(
              title: context.tr('forgotPassword'),
              buttons: [
                DialogButton(
                    color: Colors.transparent,
                    title: context.tr('cancel'),
                    onTap: state is SendForgotPasswordEmailInProgressState
                        ? null
                        : () => Navigator.pop(context)),
                DialogButton(
                    title: context.tr('sendEmail'),
                    inProgress: state is SendForgotPasswordEmailInProgressState,
                    onTap: state is SendForgotPasswordEmailInProgressState
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            setState(() => _errorText = null);
                            context.read<AuthenticationBloc>().add(
                                SendForgotPasswordEmailEvent(
                                    email: _emailController.text.trim()));
                          })
              ],
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.sizes.md, vertical: context.sizes.xxs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      hintText: context.tr('enterYourEmail'),
                      validator: (value) =>
                          Validator.validateEmail(context, value),
                      controller: _emailController,
                    ),
                    if (_errorText != null)
                      Padding(
                        padding: EdgeInsets.only(top: context.sizes.xs),
                        child: CustomText(
                          _errorText!,
                          fontSize: context.font.normal,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              )),
        );
      },
    );
  }
}
