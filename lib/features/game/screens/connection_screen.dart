import 'dart:async';
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
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/game/logic/multiplayer_game.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/features/game/blocs/game_connection_bloc.dart';
import 'package:tic_tac_toe/features/game/models/game_model.dart';
import 'package:tic_tac_toe/features/game/models/game_round_model.dart';
import 'package:tic_tac_toe/features/game/models/game_setting_model.dart';
import 'package:tic_tac_toe/features/game/models/matrix_size_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/connection_entry_info.dart';
import 'package:tic_tac_toe/features/game/widgets/connection_players_row.dart';
import 'package:tic_tac_toe/features/game/widgets/connection_timer.dart';

/// Waiting-room screen shown while matchmaking for a random online opponent;
/// hosts (or joins) a game via [GameConnectionBloc] and navigates to
/// [MazeScreen] once an opponent connects.
class ConnectionScreen extends StatefulWidget {
  final MatrixSize size;
  final int fee;
  final GameRound round;

  const ConnectionScreen({
    super.key,
    required this.size,
    required this.fee,
    required this.round,
  });

  static Route route(RouteSettings settings) {
    Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
    return GradientRouter(
        builder: (context) => BlocProvider(
              create: (context) => GameConnectionBloc(),
              child: ConnectionScreen(
                size: args['size'] as MatrixSize,
                fee: args['fee'] as int,
                round: args['round'] as GameRound,
              ),
            ));
  }

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  Timer? timer; // periodic 1s ticker counting down the matchmaking search

  /// Key of the game we created and are hosting. Stays null when we joined an
  /// existing game (in which case there is nothing for us to close on timeout).
  String? hostedGameKey;

  // Remaining search seconds; drives the countdown display without a full rebuild.
  final ValueNotifier<int> time = ValueNotifier(
    AppSettings.multiplayerConnectionSearchTime,
  );

  /// True once the search has timed out without finding an opponent; the
  /// waiting screen then swaps its status text for a retry button instead of
  /// popping, so the player can search again without re-navigating.
  bool connectionFailed = false;

  @override
  void initState() {
    startConnection();
    super.initState();
  }

  void startConnection() {
    hostedGameKey = null;
    connectionFailed = false;
    time.value = AppSettings.multiplayerConnectionSearchTime;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (time.value == 0) {
        timer.cancel();

        // Timer expired without an opponent: ask the bloc to close the game we
        // are hosting. The retry button is shown once it confirms via
        // GameConnectionClosed.
        if (mounted && hostedGameKey != null) {
          context.read<GameConnectionBloc>().add(CloseGame(hostedGameKey!));
        }

        return;
      }
      time.value--;
    });
    context.read<GameConnectionBloc>().add(ConnectGame(
        player1: Player(
          playerId: context.read<AuthenticationBloc>().user!.userId,
          skinX: DatabaseService.instance.activeSkin.skinX,
          skinO: DatabaseService.instance.activeSkin.skinO,
          name: context.read<AuthenticationBloc>().user!.username,
          playerProfile: context.read<AuthenticationBloc>().user!.profilePic,
        ),
        size: widget.size,
        fee: widget.fee,
        round: widget.round));
  }

  void retryConnection() {
    timer?.cancel();
    setState(startConnection);
  }

  @override
  void dispose() {
    timer?.cancel();
    // Leaving the waiting screen (manual back, etc.): close the game we are
    // hosting so it can't be joined as a "ghost" after we're gone. closeGame is
    // a no-op when an opponent already joined or it was already closed (e.g. by
    // the connection timer), so this is safe to fire on every exit path.
    if (hostedGameKey != null) {
      DatabaseService.instance.closeGame(hostedGameKey!);
    }
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<GameConnectionBloc, GameConnectionState>(
        listener: (context, state) async {
          if (state is GameConnectionWaiting) {
            // Remember the game we are hosting so the timer can close it.
            hostedGameKey = state.gameKey;
          }
          if (state is GameConnectionSuccess) {
            GameModel gameModel =
                await DatabaseService.instance.getGame(state.gameKey);
            if (!context.mounted) return;

            Navigator.popAndPushNamed(context, AppRoutes.mazeScreen,
                arguments: MultiplayerGame(
                    settings: MultiplayerGameSetting(gameModel,
                        boardSize: gameModel.matrixSize)));
          }
          if (state is GameConnectionClosed) {
            setState(() {
              connectionFailed = true;
            });
          }
          if (state is GameConnectionInsufficientCoins) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(context.tr('notEnoughCoinsToPlay',
                      params: {'amount': '${state.required}'}))),
            );
            Navigator.pop(context);
          }
        },
        child: SizedBox(
          width: context.screenWidth,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: context.sizes.md)
                .copyWith(top: Platform.isIOS ? 30.r(context) : 0),
            child: Column(
              children: [
                SizedBox(
                  height: 30.r(context),
                ),
                Column(
                  children: [
                    CustomText(
                      context.tr('playWithRandom').toUpperCase(),
                      fontSize: context.font.xL,
                    ),
                    SizedBox(
                      height: 10.r(context),
                    ),
                    CustomText(
                      context.tr('onlineMultiplayer'),
                      fontSize: context.font.medium,
                    ),
                    SizedBox(
                      height: 30.r(context),
                    ),
                    CustomImage(
                      AppIcons.dora4,
                      width: 138.rs(context),
                      height: 153.rs(context),
                      fit: BoxFit.none,
                    ),
                  ],
                ),
                SizedBox(
                  height: 30.r(context),
                ),
                ConnectionEntryInfo(fee: widget.fee, size: widget.size),
                SizedBox(
                  height: 30.r(context),
                ),
                const ConnectionPlayersRow(),
                SizedBox(
                  height: 30.r(context),
                ),
                ConnectionTimer(time: time),
                SizedBox(
                  height: 30.r(context),
                ),
                if (connectionFailed) ...[
                  CustomText(context.tr('failedToConnectTryAgain'),
                      fontSize: context.font.normal),
                  SizedBox(
                    height: 15.r(context),
                  ),
                  CustomButton(
                    title: context.tr('reload'),
                    type: ButtonType.primary,
                    onTap: retryConnection,
                  ),
                ] else
                  CustomText(context.tr('connectingWithOpponents'),
                      fontSize: context.font.normal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
