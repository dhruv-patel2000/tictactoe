import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/utils/validator.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/custom_textfield.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/login/apple_login.dart';
import 'package:tic_tac_toe/core/services/login/email_login.dart';
import 'package:tic_tac_toe/core/services/login/google_login.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/features/auth/screens/auth_state_listener.dart';
import 'package:tic_tac_toe/features/auth/widgets/forgot_password_dialog.dart';
import 'package:tic_tac_toe/features/auth/widgets/social_login_button.dart';

// Email/password sign-in screen; also offers Google/Apple/guest as
// alternate providers and links out to signup and forgot-password.
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});
  static Route route(RouteSettings settings) {
    return GradientRouter(builder: (context) => const EmailLoginScreen());
  }

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //--------------------------------------------------
  // Lifecycle
  //--------------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  //--------------------------------------------------
  // Auth Handlers
  //--------------------------------------------------

  Future<void> _onTapSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    context.read<AuthenticationBloc>().add(SigninEvent(
        authProvider: EmailLogin()
          ..setData(EmailLoginParameters(
              email: _emailController.text,
              password: _passwordController.text.trim(),
              type: EmailLoginType.signin))));
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    await UiUtils.showDialog(context, child: ForgotPasswordDialog());
  }

  void _onTapGoogleLogin() {
    context
        .read<AuthenticationBloc>()
        .add(SigninEvent(authProvider: GoogleLogin()));
  }

  void _onTapAppleLogin() {
    context
        .read<AuthenticationBloc>()
        .add(SigninEvent(authProvider: AppleLogin()));
  }

  void _onTapGuestLogin() {
    context.read<AuthenticationBloc>().add(GuestLoginEvent());
  }

  //--------------------------------------------------
  // Widget Builders
  //--------------------------------------------------

  Widget buildCreateAccountLink({bool enabled = true}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: context.tr('dontHaveAnAccount'),
            style: TextStyle(
              fontSize: context.font.normal,
              fontWeight: FontWeight.w500,
              color: context.color.onSurface.withAlpha(150),
            ),
          ),
          TextSpan(
            text: context.tr('register'),
            style: TextStyle(
                fontSize: context.font.normal,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = enabled
                  ? () {
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.emailSignupScreen);
                    }
                  : null,
          ),
        ],
      ),
      style: TextStyle(
        fontSize: context.font.medium,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget buildDivider() {
    final divider = Container(
      height: 1.5.r(context),
      color: context.color.outline,
    );
    return Row(
      spacing: 10.r(context),
      children: [
        Expanded(
          child: divider,
        ),
        CustomText(context.tr('or'), fontSize: context.font.normal),
        Expanded(
          child: divider,
        ),
      ],
    );
  }

  //--------------------------------------------------
  // Build
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: onAuthenticationStateChanged,
        child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
          builder: (context, state) {
            // Track which provider (if any) is mid sign-in so only that
            // button shows a spinner while every other button disables.
            final AuthenticationType? signinProvider =
                state is SigninInProgressState ? state.provider : null;
            final bool guestInProgress = state is GuestLoginInProgressState;
            // True if any sign-in method is running, used to disable all other buttons/links.
            final bool anyInProgress =
                signinProvider != null || guestInProgress;

            return Form(
              key: _formKey,
              child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(context.sizes.md),
                    child: Column(
                      children: [
                        SizedBox(
                          height: context.screenHeight * 0.05,
                        ),
                        CustomImage(
                          AppIcons.doraIcon,
                          width: context.screenWidth,
                          fit: BoxFit.fitHeight,
                          height: 250.r(context),
                        ),
                        Column(
                          children: [
                            CustomText(
                              context.tr('signIn'),
                              fontSize: context.font.xXL,
                              color: AppColors.white,
                            ),
                            SizedBox(
                              height: 25.r(context),
                            ),
                            CustomTextField(
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              hintText: context.tr('email'),
                              validator: (value) =>
                                  Validator.validateEmail(context, value),
                            ),
                            SizedBox(
                              height: context.sizes.xl,
                            ),
                            CustomTextField(
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              hintText: context.tr('password'),
                              obscureText: true,
                              validator: (value) =>
                                  Validator.validatePassword(context, value),
                            ),
                            SizedBox(
                              height: context.sizes.xs,
                            ),
                            Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: GestureDetector(
                                  onTap: anyInProgress
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          _showForgotPasswordDialog(context);
                                        },
                                  child: CustomText(
                                    context.tr('forgotPasswordQuestion'),
                                    fontSize: context.font.normal,
                                    color: AppColors.white,
                                  ),
                                )),
                            SizedBox(
                              height: context.sizes.xl,
                            ),
                            CustomButton(
                              onTap: anyInProgress ? null : _onTapSignIn,
                              title: context.tr('signIn'),
                              type: ButtonType.primary,
                              inProgress:
                                  signinProvider == AuthenticationType.email,
                            ),
                            SizedBox(
                              height: 15.r(context),
                            ),
                            buildDivider(),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 25.r(context)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 25.r(context),
                                children: [
                                  SocialLoginButton(
                                    icon: AppIcons.google,
                                    onTap: anyInProgress
                                        ? null
                                        : _onTapGoogleLogin,
                                    inProgress: signinProvider ==
                                        AuthenticationType.google,
                                  ),
                                  // Apple only: Sign in with Google without an
                                  // Apple equivalent fails App Store review
                                  // (Guideline 4.8).
                                  if (Platform.isIOS)
                                    SocialLoginButton(
                                      icon: AppIcons.apple,
                                      iconColor: AppColors.white,
                                      onTap: anyInProgress
                                          ? null
                                          : _onTapAppleLogin,
                                      inProgress: signinProvider ==
                                          AuthenticationType.apple,
                                    ),
                                  SocialLoginButton(
                                    icon: AppIcons.guestLogin,
                                    onTap:
                                        anyInProgress ? null : _onTapGuestLogin,
                                    inProgress: guestInProgress,
                                  ),
                                ],
                              ),
                            ),
                            buildCreateAccountLink(enabled: !anyInProgress)
                          ],
                        ),
                      ],
                    ),
                  )),
            );
          },
        ),
      ),
    );
  }
}
