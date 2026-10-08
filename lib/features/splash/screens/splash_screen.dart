import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const SplashScreen(),
        disableMazeBackground: true,
      );

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    context.read<AuthenticationBloc>().add(CheckAuthenticationEvent());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        // Nothing may stay under the first real screen — back from it should
        // exit the app rather than land on the splash.
        if (state is UnAuthorizedState) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.authOptionsScreen, (route) => false);
        } else if (state is AuthenticatedAsGuestState ||
            state is AuthenticatedState) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.homeScreen, (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomImage(AppIcons.appLogo),
              CustomText(
                context.tr('calculateEveryMove'),
                textAlign: TextAlign.center,
                fontSize: 44.rf(context),
                family: 'tangerine',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
