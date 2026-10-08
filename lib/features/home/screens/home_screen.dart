import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/banner_ad_widget.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/game/logic/offline_game.dart';
import 'package:tic_tac_toe/features/game/logic/pass_n_play.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/features/game/models/game_setting_model.dart';
import 'package:tic_tac_toe/features/game/models/matrix_size_model.dart';
import 'package:tic_tac_toe/features/home/widgets/difficulty_selection_dialog.dart';
import 'package:tic_tac_toe/features/home/widgets/entryfee_selection_dialog.dart';
import 'package:tic_tac_toe/features/home/widgets/home_card.dart';
import 'package:tic_tac_toe/features/home/widgets/home_top_bar.dart';
import 'package:tic_tac_toe/features/home/widgets/matrixsize_selection_dialog.dart';

// Landing screen after auth: lets the player pick offline, random online,
// or pass-n-play, walking each through its own setup dialogs before
// navigating to the matching game screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static Route route(RouteSettings settings) {
    return GradientRouter(
        builder: (BuildContext context) => const HomeScreen());
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const BannerAdWidget(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(HomeTopBar.preferredHeightOf(context)),
        child: const HomeTopBar(),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.sizes.md),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            spacing: 12.r(context),
            children: [
              HomeCard(
                reverse: false,
                image: AppIcons.dora1,
                title: context.tr('offlinePlay'),
                subTitle: context.tr('playWithTheCleverFoxDora'),
                onTap: () async {
                  // Dialogs return null when dismissed (e.g. back button);
                  // bail out of the setup flow rather than proceeding with
                  // no selection.
                  Difficulty? difficulty = await UiUtils.showDialog(context,
                      child: DifficultySelectionDialog());
                  if (difficulty == null) return;
                  if (!context.mounted) return;
                  MatrixSize? size = await UiUtils.showDialog(context,
                      child: MatrixSizeSelectionDialog());
                  if (size == null) return;
                  // Defer to the next frame: the dialog's pop is still
                  // animating/closing this frame, so pushing immediately can
                  // race with it.
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    Navigator.pushNamed(context, AppRoutes.mazeScreen,
                        arguments: OfflineGame(
                            settings: GameSettings(boardSize: size.size),
                            difficulty: difficulty));
                  });
                },
              ),
              HomeCard(
                reverse: true,
                image: AppIcons.dora2,
                title: context.tr('randomPlay'),
                subTitle: context.tr('findYourMatchAroundTheWorld'),
                onTap: () async {
                  int? entryFee = await UiUtils.showDialog(context,
                      child: EntryFeeSelectionDialog());
                  if (entryFee == null) return;
                  if (!context.mounted) return;
                  MatrixSize? size = await UiUtils.showDialog(context,
                      child: MatrixSizeSelectionDialog());
                  if (size == null) return;
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    Navigator.pushNamed(context, AppRoutes.connectionScreen,
                        arguments: {
                          'size': size,
                          'fee': entryFee,
                          'round': AppSettings.rounds.first,
                        });
                  });
                },
              ),
              HomeCard(
                reverse: false,
                image: AppIcons.dora3,
                subTitle: context.tr('passNPlayWithYourFriend'),
                title: context.tr('passNPlay'),
                onTap: () async {
                  MatrixSize? size = await UiUtils.showDialog(context,
                      child: MatrixSizeSelectionDialog());
                  if (size == null) return;
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    Navigator.pushNamed(context, AppRoutes.mazeScreen,
                        arguments: PassNPlayGame(
                            settings: GameSettings(boardSize: size.size)));
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
