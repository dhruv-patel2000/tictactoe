// Model: state of a single board cell - which player occupies it (if any)
// and the skin to render there.
class GamePosition {
  final String? playerId;
  final String? skin;

  const GamePosition({
    this.playerId,
    this.skin,
  });

  bool get isBlank => playerId == null;

  @override
  String toString() {
    return 'Player($playerId)';
  }
}
