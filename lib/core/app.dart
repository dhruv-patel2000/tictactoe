import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:tic_tac_toe/core/localization/app_language.dart';
import 'package:tic_tac_toe/core/localization/app_localization.dart';
import 'package:tic_tac_toe/core/routes/route_observer.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/screen_width_tester.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/commons/blocs/locale_cubit.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthenticationBloc()),
        BlocProvider(create: (context) => LocaleCubit()),
      ],
      child: ScreenWidthTester(
        enabled: false,
        showControls: true,
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              onGenerateRoute: AppRoutes.onGeneratedRoutes,
              navigatorObservers: [appRouteObserver],
              locale: locale,
              supportedLocales: AppLanguages.supported
                  .map((language) => Locale(language.code)),
              localizationsDelegates: const [
                AppLocalization.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                colorScheme: ColorScheme.dark(
                  primary: AppColors.primaryColor,
                  secondary: AppColors.secondaryColor,
                  tertiary: AppColors.tertiaryColor,
                  outline: AppColors.outlineColor,
                  surfaceContainer: AppColors.surfaceColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
