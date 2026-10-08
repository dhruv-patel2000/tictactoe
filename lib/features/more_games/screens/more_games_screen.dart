import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/color_extension.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/interstitial_ad_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/more_games/models/more_game_model.dart';

/// Lists the WebView games registered in [AppSettings.moreGames].
/// Tapping a game opens it inside [GameWebViewScreen].
class MoreGamesScreen extends StatefulWidget {
  const MoreGamesScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const MoreGamesScreen(),
      );

  @override
  State<MoreGamesScreen> createState() => _MoreGamesScreenState();
}

class _MoreGamesScreenState extends State<MoreGamesScreen> {
  @override
  void initState() {
    // Clear any orientation lock so embedded games can use landscape if needed.
    SystemChrome.setPreferredOrientations([]);
    super.initState();
    InterstitialAdService.loadAd();
  }

  Widget _gameCard(BuildContext context, MoreGame game) {
    return IntrinsicHeight(
      child: Row(
        spacing: 12.r(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InnerShadowContainer(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.sizes.sm, vertical: context.sizes.xs),
                child: Row(
                  spacing: 12.r(context),
                  children: [
                    CustomImage(
                      game.image.isEmpty ? AppIcons.moreGame : game.image,
                      fit: BoxFit.cover,
                      width: context.sizes.xxxl,
                      height: context.sizes.xxxl,
                      radius: 10.r(context),
                    ),
                    Expanded(
                      child: CustomText(
                        game.name,
                        fontSize: context.font.xL,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.gameWebViewScreen,
              arguments: game,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.sizes.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.sizes.radiusXs),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.color.primary.brighten(0.55),
                    context.color.primary.brighten(0.15),
                    context.color.primary.darken(0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomText(
                context.tr('playNow'),
                fontSize: context.font.normal,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configured list of WebView games to promote.
    final games = AppSettings.moreGames;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(
          context.tr('playMoreGames'),
          fontSize: context.font.xL,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
      ),
      body: games.isEmpty
          ? Center(
              child: CustomText(context.tr('noGamesAvailableYet'),
                  fontSize: context.font.medium))
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.sizes.md,
                  right: context.sizes.md,
                  top: context.sizes.md,
                  bottom:
                      context.sizes.md + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  spacing: 16.r(context),
                  children: [
                    for (final game in games) _gameCard(context, game),
                  ],
                ),
              ),
            ),
    );
  }
}
