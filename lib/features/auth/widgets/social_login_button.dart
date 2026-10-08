import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';

// Round icon button used for Google/Apple/guest sign-in on the login screen;
// shows a spinner in place of the icon while its provider is signing in.
class SocialLoginButton extends StatelessWidget {
  final String icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool inProgress;

  const SocialLoginButton({
    super.key,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.inProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InnerShadowContainer(
        width: 40.r(context),
        height: 40.r(context),
        child: inProgress
            ? SizedBox(
                width: context.sizes.lg,
                height: context.sizes.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.color.onSurface,
                ),
              )
            : CustomImage(icon, color: iconColor),
      ),
    );
  }
}
