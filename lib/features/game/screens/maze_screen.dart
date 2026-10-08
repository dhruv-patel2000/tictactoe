import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/countdown.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/utils/ui_utils.dart';
import 'package:tic_tac_toe/commons/widgets/banner_ad_widget.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/game/logic/board_offsets.dart';
import 'package:tic_tac_toe/features/game/logic/game.dart';
import 'package:tic_tac_toe/features/game/logic/multiplayer_game.dart';
import 'package:tic_tac_toe/core/services/sound_service.dart';
import 'package:tic_tac_toe/features/game/blocs/game_bloc.dart';
import 'package:tic_tac_toe/features/game/models/game_position_model.dart';
import 'package:tic_tac_toe/features/game/models/game_setting_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/draw_dialog.dart';
import 'package:tic_tac_toe/features/game/widgets/game_information_header.dart';
import 'package:tic_tac_toe/features/game/widgets/game_over_dialog.dart';
import 'package:tic_tac_toe/features/game/widgets/line_animation.dart';
import 'package:tic_tac_toe/features/game/widgets/next_round_dialog.dart';
import 'package:tic_tac_toe/features/game/widgets/players_profile_widget.dart';
import 'package:tic_tac_toe/features/game/widgets/tile_box_widget.dart';

/// Main gameplay screen: renders the board for any [Game] variant (offline,
/// pass-n-play, or multiplayer) and reacts to [GameBloc] state to animate
/// wins, advance rounds, and show game-over/draw dialogs.
class MazeScreen extends StatefulWidget {
  final Game game;

  const MazeScreen({super.key, required this.game});

  static Route route(RouteSettings settings) {
    final Game game = settings.arguments as Game;
    return GradientRouter(
        builder: (context) => BlocProvider(
              create: (context) => GameBloc(GameState(game)),
              child: MazeScreen(game: game),
            ));
  }

  @override
  State<MazeScreen> createState() => _MazeScreenState();
}

class _MazeScreenState extends State<MazeScreen>
    with SingleTickerProviderStateMixin {
  late final int _boardSize = widget.game.settings.boardSize;
  // Drives the win-line draw animation rendered over the board.
  late final LineAnimationController _controller = LineAnimationController();
  // Caches each tile's pixel offset so the win line can be positioned over it.
  late BoardOffsets boardOffsets = BoardOffsets(boardSize: _boardSize);

  /// The Stack that holds both the board and the winning-line overlay. Tile
  /// centres are converted into this box's local space so the line aligns.
  final GlobalKey _boardAreaKey = GlobalKey();
  int?
      currentRound; // 1-based round number shown in the UI; null outside multiplayer

  /// The winner of the round that just ended, captured from GameOverState
  /// before the NextRoundState transition (which carries no winner data of
  /// its own) so NextRoundDialog can announce the right player. Null means
  /// the round was tied.
  Player? _lastRoundWinner;
  bool _lastRoundWasTie = false;
  bool _soundOn = SoundService.isEnabled;
  // Token identifying this screen's music session, passed to start/stop calls.
  final Object _soundSession = Object();

  /// Turn timer scales with the board: bigger boards give players more time to
  /// read the grid and plan a move (see [AppSettings.turnDurationFor]).
  late final int _turnDuration = AppSettings.turnDurationFor(_boardSize);
  late final Countdown countdown = Countdown(_turnDuration);

  @override
  void initState() {
    widget.game.setContext(context);
    widget.game.countdown = countdown;

    SoundService.playBackgroundMusic(_soundSession);

    countdown.current.addListener(() {
      if (countdown.current.value == 0 && isYourTurn(widget.game)) {
        // Route through the same GameOverEvent -> GameOverState path as a
        // real board win so the timeout also gets the win animation +
        // GameOverDialog (with its replay button) instead of being silently
        // swallowed by Game.onGameOver's no-op default.
        widget.game.addEvent(GameOverEvent(
          winner: widget.game.opponent,
          gameOverRow: null,
          gameOverColumn: null,
        ));
      }
    });
    // Intentionally empty: timeout is already handled by the listener above
    // (which fires the GameOverEvent); this hook is only needed to satisfy
    // Countdown's API.
    countdown.onTimerEnd(
      () {},
    );

    if (!widget.game.initialized) {
      widget.game.onGameStart();
    }

    setState(() {});

    assert(
        widget.game.player1 != null &&
            widget.game.player2 != null &&
            widget.game.currentPlayer != null,
        'Please set player 1 and player2 and current player');

    if (widget.game is MultiplayerGame) {
      currentRound = (widget.game.settings as MultiplayerGameSetting)
              .gameModel
              .currentRound +
          1;
      setState(() {});
    }

    countdown.start();

    super.initState();
  }

  bool isYourTurn(Game game) {
    if (!game.restrictedMoves) {
      return true;
    }

    return game.selfPlayerId != null &&
        game.selfPlayerId == game.currentPlayer?.playerId;
  }

  /// Matches the default skin colours: X is pink, O is blue.
  static const Color _xSignColor = Color(0xFFFF2D95);
  static const Color _oSignColor = Color(0xFF00A0FF);

  void _startGameOverAnimation(GameOverState state) {
    // Offsets are filled lazily once the grid has laid out; if they aren't ready
    // yet, skip rather than risk a range error indexing into them.
    if (boardOffsets.offsets.length < _boardSize * _boardSize) return;

    final Color lineColor =
        state.winner.activeSkinType == 'O' ? _oSignColor : _xSignColor;

    if (state.gameOverColumn != null) {
      _controller.setAnimation(
        boardOffsets.getColumnStartOffset(state.gameOverColumn!),
        boardOffsets.getColumnEndOffset(state.gameOverColumn!),
        color: lineColor,
      );
    } else if (state.gameOverRow != null) {
      _controller.setAnimation(
        boardOffsets.getRowStartOffset(state.gameOverRow!),
        boardOffsets.getRowEndOffset(state.gameOverRow!),
        color: lineColor,
      );
    } else if (state.diagonal == WinDiagonal.main) {
      _controller.setAnimation(
        boardOffsets.getMainDiagonalStart(),
        boardOffsets.getMainDiagonalEnd(),
        color: lineColor,
      );
    } else if (state.diagonal == WinDiagonal.anti) {
      _controller.setAnimation(
        boardOffsets.getAntiDiagonalStart(),
        boardOffsets.getAntiDiagonalEnd(),
        color: lineColor,
      );
    }
  }

  bool hasNextRound() {
    if (widget.game is MultiplayerGame) {
      MultiplayerGameSetting setting =
          (widget.game.settings as MultiplayerGameSetting);
      return (setting.gameModel.rounds - 1) > setting.gameModel.currentRound;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    countdown.dispose();
    widget.game.onDispose();
    SoundService.stopBackgroundMusic(_soundSession);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    widget.game.setContext(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _boardAreaKey,
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: const BannerAdWidget(),
          body: BlocConsumer<GameBloc, GameState>(
            listener: (context, state) async {
              if (state is NextRoundState) {
                // Drop the previous round's winning line before the fresh
                // board appears under the dialog.
                _controller.clear();
                UiUtils.showDialog(
                  context,
                  child: NextRoundDialog(
                    player1: widget.game.player1!,
                    player2: widget.game.player2!,
                    round: state.round,
                    winner: _lastRoundWasTie ? null : _lastRoundWinner,
                  ),
                );
                currentRound = state.round + 1;
                setState(() {});
              }
              if (state is GameOverState) {
                _lastRoundWinner = state.winner;
                _lastRoundWasTie = false;
                _startGameOverAnimation(state);
                SoundService.playWin();

                // Capture the final-round decision BEFORE onGameOver runs:
                // onGameOver advances gameModel.currentRound, so checking
                // hasNextRound() after it would read the wrong round.
                final bool isFinalRound = !hasNextRound();

                try {
                  await widget.game.onGameOver(
                      state.winner, state.gameOverRow, state.gameOverColumn,
                      diagonal: state.diagonal);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(context.tr('somethingWentWrongTryAgain'))));
                  }
                }

                // Hold on the board so the win-line animation and win sound
                // finish playing before the round/game-over dialog covers it.
                await Future.delayed(const Duration(seconds: 3));

                if (!context.mounted) return;
                if (isFinalRound) {
                  UiUtils.showDialog(context,
                      child: GameOverDialog(
                        game: widget.game,
                        isMultiplayer: widget.game is MultiplayerGame,
                        entryFee: widget.game.settings.fee,
                        winner: state.winner,
                      ),
                      dismissible: false);
                }
              }
              if (state is GameDrawState) {
                _lastRoundWasTie = true;
                // Capture the final-round decision BEFORE onGameDraw advances
                // the round (same race as the GameOverState branch above).
                final bool isFinalRound = !hasNextRound();

                try {
                  await widget.game.onGameDraw();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(context.tr('somethingWentWrongTryAgain'))));
                  }
                }

                await Future.delayed(const Duration(seconds: 3));

                if (!context.mounted) return;
                if (isFinalRound) {
                  UiUtils.showDialog(context,
                      child: DrawDialog(
                        game: widget.game,
                        player1: widget.game.player1!,
                        player2: widget.game.player2!,
                        isMultiplayer: widget.game is MultiplayerGame,
                        entryFee: widget.game.settings.fee,
                      ),
                      dismissible: false);
                }
              }
              if (state is PlayerMoveState) {
                widget.game.onUpdate(state.row, state.column, state.player);
              }
            },
            builder: (context, state) {
              return Padding(
                padding: EdgeInsets.all(context.sizes.md)
                    .copyWith(top: 30.r(context)),
                child: Column(
                  children: [
                    SizedBox(
                      height: 14.r(context),
                    ),
                    GameInformationHeader(
                      game: widget.game,
                      countdown: countdown,
                      turnDuration: _turnDuration,
                      isYourMove: state.game.currentPlayer?.playerId ==
                          state.game.selfPlayerId,
                      soundOn: _soundOn,
                      onToggleSound: () {
                        final bool next = !_soundOn;
                        SoundService.setEnabled(next);
                        setState(() => _soundOn = next);
                      },
                    ),
                    SizedBox(
                      height: context.sizes.lg,
                    ),
                    if (currentRound != null) ...[
                      CustomText(
                          context.tr('currentRound',
                              params: {'round': '${currentRound!}'}),
                          fontSize: context.font.xXL),
                    ],
                    Expanded(
                      child: Center(
                        // On most devices the board already fits the space
                        // Expanded gives it, so scaleDown is a no-op here —
                        // same rendering as before. It only kicks in for a
                        // wide/short viewport (e.g. multiplayer's extra
                        // "Current Round" line eating into a landscape
                        // tablet's height budget), shrinking the whole board
                        // uniformly instead of letting the bottom row clip.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: context.screenWidth - context.sizes.md * 2,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _boardSize * _boardSize,
                              shrinkWrap: true,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                childAspectRatio: 1,
                                mainAxisSpacing: 20.r(context),
                                crossAxisSpacing: 20.r(context),
                                crossAxisCount: _boardSize,
                              ),
                              itemBuilder: (context, index) {
                                final int row = index ~/ _boardSize;
                                final int column = index % _boardSize;

                                final GamePosition currentPosition =
                                    state.game.board[row][column];

                                // Re-armed on every tile build (cheap: fillOffsetIfEmpty
                                // no-ops once populated). The 900ms delay gives the grid
                                // time to finish laying out before offsets are read, since
                                // there's no direct post-frame hook for GridView tiles here.
                                Future.delayed(
                                    const Duration(milliseconds: 900), () {
                                  if (!context.mounted) return;
                                  final referenceBox = _boardAreaKey
                                      .currentContext
                                      ?.findRenderObject() as RenderBox?;
                                  boardOffsets.fillOffsetIfEmpty(
                                      context, referenceBox);
                                });
                                return GestureDetector(
                                  onTap: () {
                                    if (!currentPosition.isBlank) {
                                      return;
                                    }
                                    if (!isYourTurn(state.game)) {
                                      return;
                                    }

                                    SoundService.playClick();
                                    context
                                        .read<GameBloc>()
                                        .add(Move(row: row, column: column));
                                  },
                                  child: TileBoxWidget(
                                    child: currentPosition.skin != null
                                        ? CustomImage(
                                            UiUtils.getSkin(
                                                currentPosition.skin!),
                                            width: 50.r(context),
                                            height: 50.r(context),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: context.sizes.lg,
                    ),
                    PlayersProfileWidget(
                        player1: widget.game.player1,
                        currentPlayer: widget.game.currentPlayer,
                        player2: widget.game.player2),
                    if (widget.game.showNote) ...[
                      SizedBox(
                        height: 35.r(context),
                      ),
                      CustomText(
                        widget.game.note,
                        fontSize: context.font.normal,
                        color: context.color.onSurface.withAlpha(100),
                        fontWeight: FontWeight.w400,
                      )
                    ]
                  ],
                ),
              );
            },
          ),
        ),
        // Winning-line overlay. IgnorePointer so it never eats board taps;
        // the tile offsets are corrected for the SafeArea inset so the line
        // lands on the tiles.
        IgnorePointer(child: AnimatedLine(controller: _controller)),
      ],
    );
  }
}
