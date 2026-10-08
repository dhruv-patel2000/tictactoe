import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/more_games/models/more_game_model.dart';

/// Opens a [MoreGame] inside an in-app WebView.
class GameWebViewScreen extends StatefulWidget {
  final MoreGame game;

  const GameWebViewScreen({super.key, required this.game});

  static Route route(RouteSettings settings) {
    final game = settings.arguments as MoreGame;
    return GradientRouter(
      builder: (context) => GameWebViewScreen(game: game),
    );
  }

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  // Drives navigation/reload for the embedded game page.
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      // Toggle the loading spinner around each page navigation (including reloads).
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.game.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(
          widget.game.name,
          fontSize: context.font.large,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
        actions: [
          IconButton(
            tooltip: context.tr('reload'),
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: context.color.secondary),
            ),
        ],
      ),
    );
  }
}
