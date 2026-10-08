import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/core/services/interstitial_ad_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/leaderboard/models/leaderboard_model.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_repository.dart';
import 'package:tic_tac_toe/features/settings/widgets/profile_card.dart';

// Shows the ranked player list, paginated and infinite-scrolled from the repository.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const LeaderboardScreen(),
      );

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  /// All leaderboard/rank logic lives in the repository; the screen only
  /// renders whatever ranked page it fetches.
  final LeaderboardRepository _repository = LeaderboardRepository();

  /// Used only to highlight the signed-in player's own row.
  final String? _currentUserId = DatabaseService.instance.userId;

  // Accumulated ranked players loaded so far across all fetched pages.
  final List<LeaderboardModel> _players = [];
  final ScrollController _scrollController = ScrollController();
  // Pagination cursor for the next page; null once there's nothing left to fetch.
  LeaderboardCursor? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    InterstitialAdService.loadAd();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Prefetches the next page 300px before the bottom so scrolling feels continuous.
  void _onScroll() {
    if (_nextCursor == null || _loadingMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    final page = await _repository.fetchLeaderboardPage();
    if (!mounted) return;
    setState(() {
      _players
        ..clear()
        ..addAll(page.players);
      _nextCursor = page.nextCursor;
      _loading = false;
    });
  }

  Future<void> _loadNextPage() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    // startRank continues numbering from where the current list left off.
    final page = await _repository.fetchLeaderboardPage(
      cursor: _nextCursor,
      startRank: _players.length + 1,
    );
    if (!mounted) return;
    setState(() {
      _players.addAll(page.players);
      _nextCursor = page.nextCursor;
      _loadingMore = false;
    });
  }

  //--------------------------------------------------
  // Widget builders
  //--------------------------------------------------
  Widget _buildPlayerCard(BuildContext context, LeaderboardModel player) {
    final rank = player.rank ??
        0; // fallback to 0 (unranked) if the repository didn't assign one
    final isCurrentUser =
        _currentUserId != null && player.userId == _currentUserId;
    return InnerShadowContainer(
      backgroundColor:
          isCurrentUser ? context.color.tertiary.withAlpha(60) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.md, vertical: 10.r(context)),
        child: Row(
          spacing: context.sizes.md,
          children: [
            SizedBox(
                width: 26.r(context),
                child: Center(child: _buildRank(context, rank))),
            _buildAvatar(context, player),
            Expanded(
              child: CustomText(
                player.name,
                fontSize: context.font.normal,
                color: context.color.onSurface,
                fontWeight: FontWeight.w600,
                ellipsis: true,
                maxLines: 2,
              ),
            ),
            CustomText(
              '${player.score}',
              fontSize: context.font.medium,
              fontWeight: FontWeight.w700,
              color: context.color.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  // Top 3 ranks get medal icons instead of a plain number.
  Widget _buildRank(BuildContext context, int rank) {
    if (rank >= 1 && rank <= 3) {
      final rankIcons = [AppIcons.rank1, AppIcons.rank2, AppIcons.rank3];
      return CustomImage(
        rankIcons[rank - 1],
        width: 26.r(context),
        height: 40.r(context),
        fit: BoxFit.contain,
      );
    }
    return CustomText(
      '$rank',
      fontSize: context.font.medium,
      fontWeight: FontWeight.w700,
      color: context.color.onSurface,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: true,
    );
  }

  Widget _buildAvatar(BuildContext context, LeaderboardModel player) {
    final pic = player.profilePic;
    if (pic != null && pic.isNotEmpty) {
      return Container(
        width: 40.r(context),
        height: 40.r(context),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: CustomImage(pic, fit: BoxFit.cover),
      );
    }
    // No avatar asset — fall back to an initial on a tinted circle.
    return Container(
      width: 40.r(context),
      height: 40.r(context),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.color.tertiary.withAlpha(100),
      ),
      child: CustomText(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        fontSize: context.font.large,
        fontWeight: FontWeight.w700,
        color: context.color.onSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(context.tr('leaderboard'),
            fontSize: context.font.xL,
            fontWeight: FontWeight.w700,
            color: AppColors.white),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.all(context.sizes.md),
          child: Column(
            spacing: 16.r(context),
            children: [
              const ProfileCard(showCoin: false),
              if (_loading)
                Padding(
                  padding: EdgeInsets.only(top: context.sizes.xxl),
                  child: CircularProgressIndicator(
                    color: context.color.secondary,
                  ),
                )
              else if (_players.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.sizes.xxl),
                  child: CustomText(
                    context.tr('noPlayersYet'),
                    fontSize: context.font.medium,
                    color: context.color.onSurface,
                  ),
                )
              else ...[
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _players.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: context.sizes.md),
                  itemBuilder: (context, index) =>
                      _buildPlayerCard(context, _players[index]),
                ),
                if (_loadingMore)
                  Padding(
                    padding: EdgeInsets.only(top: context.sizes.xs),
                    child: CircularProgressIndicator(
                      color: context.color.secondary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
