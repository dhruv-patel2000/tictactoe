import 'dart:math';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';

/// Computes the CPU opponent's ("Dora") move for offline games, from random
/// play up to a full minimax search depending on the chosen [Difficulty].
class TicTacToeAI {
  final String player = 'X'; // Dora's own mark, maximized by the minimax search
  final String opponent =
      'O'; // the human's mark, minimized by the minimax search
  final Random _random =
      Random(); // picks random moves and breaks ties between equally good ones

  /// Picks Dora's move for [board], and she gets sharper as [difficulty] rises:
  ///
  /// * [Difficulty.easy]   — plays a random empty cell; easy to beat.
  /// * [Difficulty.medium] — heuristic play: takes an immediate win, blocks an
  ///   immediate loss, then grabs the centre / strategic corners, otherwise
  ///   plays randomly. Sensible, but can be out-planned (e.g. forks).
  /// * [Difficulty.hard]   — full look-ahead via [_bestMinimaxMove]: she reads
  ///   the game out to the search horizon, sees and sets up forks, and plays
  ///   optimally on the 3x3 board (she never loses there).
  int getBestMove(List<List<String>> board, int boardSize,
      {Difficulty difficulty = Difficulty.hard}) {
    final Map<String, int> toBeReturned = () {
      // chosen move as {'x': row, 'y': col}, before flattening to a single index
      switch (difficulty) {
        case Difficulty.easy:
          return getRandomMove(board, boardSize);
        case Difficulty.medium:
          Map<String, int> move = checkImmediateMoves(board, boardSize);
          if (move.isNotEmpty) return move;

          move = takeCenter(board, boardSize);
          if (move.isNotEmpty) return move;

          move = takeStrategicPositions(board, boardSize);
          return move.isNotEmpty ? move : getRandomMove(board, boardSize);
        case Difficulty.hard:
          return _bestMinimaxMove(board, boardSize);
      }
    }();

    return (toBeReturned["x"] as int) * boardSize + (toBeReturned["y"] as int);
  }

  Map<String, int> checkImmediateMoves(
      List<List<String>> board, int boardSize) {
    Map<String, int>? winningMove = findLineMove(board, boardSize, player);
    if (winningMove != null) return winningMove;

    Map<String, int>? blockingMove = findLineMove(board, boardSize, opponent);
    return blockingMove ?? {};
  }

  Map<String, int>? findLineMove(
      List<List<String>> board, int boardSize, String mark) {
    for (int i = 0; i < boardSize; i++) {
      Map<String, int>? rowMove =
          findLineMoveInDirection(board, i, 0, 0, 1, boardSize, mark);
      if (rowMove != null) return rowMove;

      Map<String, int>? colMove =
          findLineMoveInDirection(board, 0, i, 1, 0, boardSize, mark);
      if (colMove != null) return colMove;
    }

    Map<String, int>? diag1Move =
        findLineMoveInDirection(board, 0, 0, 1, 1, boardSize, mark);
    if (diag1Move != null) return diag1Move;

    return findLineMoveInDirection(
        board, 0, boardSize - 1, 1, -1, boardSize, mark);
  }

  Map<String, int>? findLineMoveInDirection(List<List<String>> board,
      int startX, int startY, int dirX, int dirY, int boardSize, String mark) {
    int markCount = 0;
    Map<String, int> emptyCell =
        {}; // the line's one empty cell, if any — the candidate move
    for (int i = 0; i < boardSize; i++) {
      int x = startX + i * dirX;
      int y = startY + i * dirY;
      if (board[x][y] == mark) {
        markCount++;
      } else if (board[x][y] == '') {
        emptyCell = {'x': x, 'y': y};
      }
    }

    if (markCount == boardSize - 1 && emptyCell.isNotEmpty) {
      return emptyCell;
    }

    return null;
  }

  Map<String, int> takeCenter(List<List<String>> board, int boardSize) {
    if (boardSize % 2 == 1 && board[boardSize ~/ 2][boardSize ~/ 2] == '') {
      return {'x': boardSize ~/ 2, 'y': boardSize ~/ 2};
    }
    return {};
  }

  Map<String, int> takeStrategicPositions(
      List<List<String>> board, int boardSize) {
    List<Map<String, int>> strategicPositions = [
      {'x': 0, 'y': 0},
      {'x': 0, 'y': boardSize - 1},
      {'x': boardSize - 1, 'y': 0},
      {'x': boardSize - 1, 'y': boardSize - 1},
      {'x': 0, 'y': boardSize ~/ 2},
      {'x': boardSize - 1, 'y': boardSize ~/ 2},
      {'x': boardSize ~/ 2, 'y': 0},
      {'x': boardSize ~/ 2, 'y': boardSize - 1}
    ];

    for (var position in strategicPositions) {
      if (board[position['x']!][position['y']!] == '') {
        return position;
      }
    }

    return {};
  }

  Map<String, int> getRandomMove(List<List<String>> board, int boardSize) {
    List<Map<String, int>> availableMoves = [];
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board[i][j] == '') {
          availableMoves.add({'x': i, 'y': j});
        }
      }
    }
    if (availableMoves.isNotEmpty) {
      return availableMoves[_random.nextInt(availableMoves.length)];
    }
    return {};
  }

  // ---------------------------------------------------------------------------
  // Hard mode: minimax with alpha-beta pruning.
  //
  // A win requires filling a whole row, column, or one of the two main
  // diagonals (the same rule `Game.checkWin` enforces). The search mutates the
  // passed-in board in place while exploring — safe because the offline game
  // hands us a throwaway `List<List<String>>` copy, not its live board.
  // ---------------------------------------------------------------------------

  /// Score of a decisive line. Kept far larger than any heuristic total so a
  /// real win/loss always outranks positional preferences.
  static const int _winScore = 1000000;

  /// Returns Dora's optimal move (to the search horizon) as `{'x':row,'y':col}`,
  /// breaking ties randomly so she isn't perfectly predictable.
  Map<String, int> _bestMinimaxMove(List<List<String>> board, int n) {
    final int depth = _searchDepth(n);
    int bestScore = -_winScore *
        2; // starts below any real minimax score so the first candidate always wins
    final List<Map<String, int>> bestMoves =
        []; // every move tied for bestScore, so the choice can be randomized

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (board[i][j] != '') continue;
        board[i][j] = player;
        final int score =
            _minimax(board, n, depth - 1, false, -_winScore * 2, _winScore * 2);
        board[i][j] = '';

        if (score > bestScore) {
          bestScore = score;
          bestMoves
            ..clear()
            ..add({'x': i, 'y': j});
        } else if (score == bestScore) {
          bestMoves.add({'x': i, 'y': j});
        }
      }
    }

    if (bestMoves.isEmpty) return getRandomMove(board, n);
    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  /// Standard minimax with alpha-beta pruning. [isMax] is true on Dora's plies.
  /// Terminal scores fold in [depth] so she prefers the quickest win and the
  /// slowest loss; at the depth cut-off she falls back to [_evaluate].
  int _minimax(List<List<String>> board, int n, int depth, bool isMax,
      int alpha, int beta) {
    final String? winner = _winner(board, n);
    if (winner == player) return _winScore + depth;
    if (winner == opponent) return -_winScore - depth;
    if (_isFull(board, n)) return 0;
    if (depth == 0) return _evaluate(board, n);

    if (isMax) {
      int best = -_winScore * 2;
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (board[i][j] != '') continue;
          board[i][j] = player;
          best = max(best, _minimax(board, n, depth - 1, false, alpha, beta));
          board[i][j] = '';
          alpha = max(alpha, best);
          if (beta <= alpha) return best;
        }
      }
      return best;
    } else {
      int best = _winScore * 2;
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (board[i][j] != '') continue;
          board[i][j] = opponent;
          best = min(best, _minimax(board, n, depth - 1, true, alpha, beta));
          board[i][j] = '';
          beta = min(beta, best);
          if (beta <= alpha) return best;
        }
      }
      return best;
    }
  }

  /// How far hard mode looks ahead. The 3x3 board is searched to the end (so
  /// play is perfect); larger boards are capped to keep each move snappy, since
  /// the branching factor explodes and the AI runs on the UI isolate.
  int _searchDepth(int n) {
    switch (n) {
      case 3:
        return 9; // whole game
      case 4:
        return 4;
      default:
        return 3; // 5x5 and any larger board
    }
  }

  /// The mark ('X'/'O') occupying a full row, column, or diagonal, else `null`.
  String? _winner(List<List<String>> board, int n) {
    // Rows.
    for (int i = 0; i < n; i++) {
      final String c = board[i][0];
      if (c.isNotEmpty && _allEqual(board, n, i, 0, 0, 1, c)) return c;
    }
    // Columns.
    for (int j = 0; j < n; j++) {
      final String c = board[0][j];
      if (c.isNotEmpty && _allEqual(board, n, 0, j, 1, 0, c)) return c;
    }
    // Main diagonal.
    final String d1 = board[0][0];
    if (d1.isNotEmpty && _allEqual(board, n, 0, 0, 1, 1, d1)) return d1;
    // Anti-diagonal.
    final String d2 = board[0][n - 1];
    if (d2.isNotEmpty && _allEqual(board, n, 0, n - 1, 1, -1, d2)) return d2;

    return null;
  }

  /// Whether every cell of the length-[n] line from (sx,sy) stepping (dx,dy)
  /// holds [mark].
  bool _allEqual(List<List<String>> board, int n, int sx, int sy, int dx,
      int dy, String mark) {
    for (int k = 0; k < n; k++) {
      if (board[sx + k * dx][sy + k * dy] != mark) return false;
    }
    return true;
  }

  bool _isFull(List<List<String>> board, int n) {
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (board[i][j] == '') return false;
      }
    }
    return true;
  }

  /// Heuristic value of a non-terminal board from Dora's perspective. Each line
  /// still winnable by exactly one side scores for that side, weighted so a line
  /// one mark short dominates weaker ones; contested (mixed) lines are dead.
  int _evaluate(List<List<String>> board, int n) {
    int score = 0;
    for (int i = 0; i < n; i++) {
      score += _lineScore(board, n, i, 0, 0, 1); // row i
      score += _lineScore(board, n, 0, i, 1, 0); // column i
    }
    score += _lineScore(board, n, 0, 0, 1, 1); // main diagonal
    score += _lineScore(board, n, 0, n - 1, 1, -1); // anti-diagonal
    return score;
  }

  int _lineScore(
      List<List<String>> board, int n, int sx, int sy, int dx, int dy) {
    int mine = 0, theirs = 0;
    for (int k = 0; k < n; k++) {
      final String c = board[sx + k * dx][sy + k * dy];
      if (c == player) {
        mine++;
      } else if (c == opponent) {
        theirs++;
      }
    }
    if (mine > 0 && theirs > 0) return 0; // blocked line, no potential
    if (mine > 0) return _potential(mine);
    if (theirs > 0) return -_potential(theirs);
    return 0;
  }

  /// Grows by an order of magnitude per mark (1, 10, 100, …) so a nearly
  /// complete line outweighs any number of weaker ones.
  int _potential(int count) {
    int weight = 1;
    for (int i = 1; i < count; i++) {
      weight *= 10;
    }
    return weight;
  }
}
