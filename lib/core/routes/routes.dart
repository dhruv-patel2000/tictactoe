import 'package:flutter/material.dart';

import 'package:tic_tac_toe/features/auth/screens/auth_options_screen.dart';
import 'package:tic_tac_toe/features/auth/screens/email_login_screen.dart';
import 'package:tic_tac_toe/features/auth/screens/email_signup_screen.dart';
import 'package:tic_tac_toe/features/game/screens/connection_screen.dart';
import 'package:tic_tac_toe/features/game/screens/maze_screen.dart';
import 'package:tic_tac_toe/features/history/screens/history_screen.dart';
import 'package:tic_tac_toe/features/home/screens/home_screen.dart';
import 'package:tic_tac_toe/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:tic_tac_toe/features/more_games/screens/game_webview_screen.dart';
import 'package:tic_tac_toe/features/more_games/screens/more_games_screen.dart';
import 'package:tic_tac_toe/features/settings/screens/how_to_play_screen.dart';
import 'package:tic_tac_toe/features/settings/screens/legal_info_screen.dart';
import 'package:tic_tac_toe/features/settings/screens/settings_screen.dart';
import 'package:tic_tac_toe/features/shop/screens/shop_screen.dart';
import 'package:tic_tac_toe/features/skins/screens/skins_screen.dart';
import 'package:tic_tac_toe/features/splash/screens/splash_screen.dart';

// Central route table: named route strings plus the generator that maps a
// route name to the screen's own `route()` factory (each screen owns its
// PageRoute/transition). Wired into MaterialApp.onGenerateRoute in core/app.dart.
abstract class AppRoutes {
  static const String splashScreen = '/';
  static const String authOptionsScreen = '/auth-options';
  static const String emailLoginScreen = '/email-login';
  static const String emailSignupScreen = '/email-signup';
  static const String connectionScreen = '/multiplayer-connection';
  static const String mazeScreen = '/game-maze';
  static const String homeScreen = '/home';
  static const String skinsScreen = '/skins';
  static const String settingsScreen = '/settings';
  static const String historyScreen = '/history';
  static const String leaderboardScreen = '/leaderboard';
  static const String shopScreen = '/shop';
  static const String moreGamesScreen = '/more-games';
  static const String gameWebViewScreen = '/game-webview';
  static const String legalInfoScreen = '/legal-info';
  static const String howToPlayScreen = '/how-to-play';

  static Route onGeneratedRoutes(RouteSettings settings) {
    if (settings.name == splashScreen) {
      return SplashScreen.route(settings);
    }
    if (settings.name == authOptionsScreen) {
      return AuthOptionsScreen.route(settings);
    }
    if (settings.name == emailLoginScreen) {
      return EmailLoginScreen.route(settings);
    }
    if (settings.name == emailSignupScreen) {
      return EmailSignupScreen.route(settings);
    }
    if (settings.name == homeScreen) {
      return HomeScreen.route(settings);
    }
    if (settings.name == connectionScreen) {
      return ConnectionScreen.route(settings);
    }
    if (settings.name == mazeScreen) {
      return MazeScreen.route(settings);
    }
    if (settings.name == skinsScreen) {
      return SkinsScreen.route(settings);
    }
    if (settings.name == settingsScreen) {
      return SettingsScreen.route(settings);
    }
    if (settings.name == historyScreen) {
      return HistoryScreen.route(settings);
    }
    if (settings.name == leaderboardScreen) {
      return LeaderboardScreen.route(settings);
    }
    if (settings.name == shopScreen) {
      return ShopScreen.route(settings);
    }
    if (settings.name == moreGamesScreen) {
      return MoreGamesScreen.route(settings);
    }
    if (settings.name == gameWebViewScreen) {
      return GameWebViewScreen.route(settings);
    }
    if (settings.name == legalInfoScreen) {
      return LegalInfoScreen.route(settings);
    }
    if (settings.name == howToPlayScreen) {
      return HowToPlayScreen.route(settings);
    }
    // Unknown route: assert in debug, but still return a visible fallback
    // screen in release instead of crashing.
    assert(false, 'No route defined for ${settings.name}');
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }
}
