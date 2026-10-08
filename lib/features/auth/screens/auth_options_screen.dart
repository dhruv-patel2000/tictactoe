import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/login/apple_login.dart';
import 'package:tic_tac_toe/core/services/login/google_login.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/features/auth/screens/auth_state_listener.dart';

// Entry screen for auth flow: offers Google/Apple/guest/email sign-in and
// reacts to AuthenticationBloc state via onAuthenticationStateChanged.
class AuthOptionsScreen extends StatefulWidget {
  final bool hideGuestOption;

  const AuthOptionsScreen({super.key, this.hideGuestOption = false});
  static Route route(RouteSettings settings) {
    final hideGuestOption = settings.arguments ==
        true; // route arg controls whether guest button is shown
    return GradientRouter(
        builder: (context) =>
            AuthOptionsScreen(hideGuestOption: hideGuestOption));
  }

  @override
  State<AuthOptionsScreen> createState() => _AuthOptionsScreenState();
}

class _AuthOptionsScreenState extends State<AuthOptionsScreen> {
  Widget buildButton(
    BuildContext context, {
    String? title,
    String? icon,
    Color? iconColor,
    VoidCallback? onTap,
    bool inProgress = false,
  }) {
    return CustomButton(
      width: context.screenWidth,
      height: 52.r(context),
      inProgress: inProgress,
      // Always built: CustomButton keeps it in the layout (invisible) while
      // loading so the button doesn't change shape.
      customWidget: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImage(
            icon ?? "",
            width: 40.r(context),
            height: 40.r(context),
            color: iconColor,
          ),
          SizedBox(
            width: context.sizes.md,
          ),
          Flexible(
            child: CustomText(
              title ?? '',
              fontSize: context.font.medium,
              color: AppColors.white,
              maxLines: 1,
              ellipsis: true,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: onAuthenticationStateChanged,
        child: SizedBox(
          width: double.maxFinite,
          child: Padding(
            padding: EdgeInsets.all(context.sizes.md),
            child: Column(
              children: [
                const Spacer(
                  flex: 3,
                ),
                CustomImage(
                  AppIcons.doraIcon,
                  width: context.screenWidth,
                  height: 250.r(context),
                  fit: BoxFit.fitHeight,
                ),
                const Spacer(
                  flex: 2,
                ),
                BlocBuilder<AuthenticationBloc, AuthenticationState>(
                  builder: (context, state) {
                    // Track which provider (if any) is mid sign-in so only
                    // that button shows a spinner while all others disable.
                    final AuthenticationType? signinProvider =
                        state is SigninInProgressState ? state.provider : null;
                    final guestInProgress = state is GuestLoginInProgressState;
                    // True if any sign-in method is running, used to disable all other buttons.
                    final anyInProgress =
                        signinProvider != null || guestInProgress;
                    return Column(
                      spacing: context.sizes.md,
                      children: [
                        buildButton(context,
                            icon: AppIcons.google,
                            inProgress:
                                signinProvider == AuthenticationType.google,
                            onTap: anyInProgress
                                ? null
                                : () {
                                    context.read<AuthenticationBloc>().add(
                                        SigninEvent(
                                            authProvider: GoogleLogin()));
                                  },
                            title: context.tr('signInWithGoogle')),
                        // Apple only: Sign in with Google without an Apple
                        // equivalent fails App Store review (Guideline 4.8).
                        if (Platform.isIOS)
                          buildButton(context,
                              icon: AppIcons.apple,
                              iconColor: AppColors.white,
                              inProgress:
                                  signinProvider == AuthenticationType.apple,
                              onTap: anyInProgress
                                  ? null
                                  : () {
                                      context.read<AuthenticationBloc>().add(
                                          SigninEvent(
                                              authProvider: AppleLogin()));
                                    },
                              title: context.tr('signInWithApple')),
                        if (!widget.hideGuestOption)
                          buildButton(context,
                              icon: AppIcons.guestLogin,
                              inProgress: guestInProgress,
                              onTap: anyInProgress
                                  ? null
                                  : () {
                                      context
                                          .read<AuthenticationBloc>()
                                          .add(GuestLoginEvent());
                                    },
                              title: context.tr('playAsAGuest')),
                        buildButton(context,
                            icon: AppIcons.emailLogin,
                            onTap: anyInProgress
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, AppRoutes.emailLoginScreen);
                                  },
                            title: context.tr('signInWithEmail')),
                      ],
                    );
                  },
                ),
                const Spacer(
                  flex: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
