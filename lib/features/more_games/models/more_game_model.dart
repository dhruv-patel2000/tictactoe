/// A game that opens inside an in-app WebView from the "Play More Games" menu.
///
/// Register new games in [AppSettings.moreGames] (see `lib/settings.dart`).
class MoreGame {
  /// Display name shown in the games list and on the WebView app bar.
  final String name;

  /// The URL of the web game that gets loaded inside the WebView.
  final String url;

  /// Optional thumbnail. Accepts an asset path (png/svg) or a network URL;
  /// [CustomImage] resolves either. Falls back to the app logo when empty.
  final String image;

  const MoreGame({
    required this.name,
    required this.url,
    this.image = '',
  });
}
