/// App-wide light/dark theme selector.
enum AppTheme { light, dark }

/// Visual style variants for the shared custom button widget.
enum ButtonType {
  shadow,
  primary,
  gradient,
}

/// Sign-in methods offered on the auth screens.
enum AuthenticationType {
  apple,
  google,
  email,
  guest,
}

/// Distinguishes the email auth form's sign-in vs sign-up mode.
enum EmailLoginType { signin, signup }

/// Marks which side initiated an online multiplayer game connection.
enum GameConnection { created, joined }

/// How sharp Dora plays in offline games. Chosen by the player before an
/// offline match (see `DifficultySelectionDialog`) and consumed by
/// [TicTacToeAI.getBestMove] to decide how many heuristics she applies.
enum Difficulty { easy, medium, hard }
