import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/local_storage.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/login/google_login.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Confirmation dialog that signs the user out and returns them to auth options.
class LogoutConfirmDialog {
  LogoutConfirmDialog._();

  static Future<void> show(BuildContext context) {
    return UiUtils.showDialog(context, child: const _LogoutConfirmDialog());
  }
}

class _LogoutConfirmDialog extends StatefulWidget {
  const _LogoutConfirmDialog();

  @override
  State<_LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<_LogoutConfirmDialog> {
  bool _inProgress = false;

  Future<void> _logout() async {
    setState(() => _inProgress = true);
    await FirebaseAuth.instance.signOut();
    try {
      // Also clear the native Google session; ignored if the user never signed in with Google.
      await GoogleLogin.ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await LocalStorage.logoutUser();
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.authOptionsScreen, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('logoutAccount'),
      hideCloseButton: true,
      buttons: [
        DialogButton(
          title: context.tr('no'),
          color: context.color.secondary,
          textColor: AppColors.black,
          onTap: _inProgress ? null : () => Navigator.pop(context),
        ),
        DialogButton(
          title: context.tr('yesLogout'),
          color: AppColors.white,
          textColor: AppColors.black,
          inProgress: _inProgress,
          onTap: _inProgress ? null : _logout,
        ),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.md, vertical: context.sizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImage(
              AppIcons.logoutAccountIllustration,
              width: 114.r(context),
              height: 96.r(context),
              fit: BoxFit.contain,
            ),
            SizedBox(height: context.sizes.md),
            CustomText(
              context.tr('areYouSureLogout'),
              textAlign: TextAlign.center,
              fontSize: context.font.medium,
              color: context.color.onSurface.withAlpha(200),
            ),
          ],
        ),
      ),
    );
  }
}
