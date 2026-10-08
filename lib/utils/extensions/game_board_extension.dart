import 'package:tic_tac_toe/features/game/models/game_position_model.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';

// Game-logic helpers on the 2D board grid: placing moves and reading
// diagonal cells for win-checking.
extension GameBoardExtension on List<List<GamePosition>> {
  // Places player's mark at (x, y) if that cell is empty; returns whether
  // the move was applied.
  bool move({required int x, required int y, required Player player}) {
    if (!this[x][y].isBlank) {
      return false;
    }
    this[x][y] = GamePosition(
      playerId: player.playerId,
      skin: player.activeSkinType == 'X' ? player.skinX : player.skinO,
    );
    return true;
  }

  // Returns the cross-diagonal element of the board: index i gives row i,
  // column i.
  GamePosition diagonal(int index) {
    return this[index][index];
  }

  GamePosition diagonalFromEnd(int index) {
    return this[(length - 1) - index][index];
  }
}
