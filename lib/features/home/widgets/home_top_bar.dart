import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/convert_number.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/avatar_card.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/routes/routes.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';

/// Avatar / coin balance / leaderboard row shared by [HomeScreen] and any
/// other screen (e.g. HowToPlayScreen) that reuses the home app bar.
class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({super.key});

  /// The row's content (top padding + avatar) scales with [NumExtension.r],
  /// so the reserved app bar height must scale the same way — otherwise the
  /// avatar/coin/leaderboard pills get squeezed into whatever's left once a
  /// fixed height stops covering the scaled-up padding on tablets. Callers
  /// must size their `appBar:` slot with this instead of a bare
  /// `PreferredSize`/`HomeTopBar.preferredSize`.
  ///
  /// 70 = 15 (breathing room below the status bar) + 55 (avatar + shadow
  /// pad) + a few px slack. Scaffold's default `primary: true` already
  /// reserves `MediaQuery.padding.top` (status bar/notch) above this
  /// widget, so this only needs a small extra gap — not the status bar's
  /// own height again.
  static double preferredHeightOf(BuildContext context) => 70.r(context);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  //--------------------------------------------------
  // Widget Builders
  //--------------------------------------------------

  Widget _buildCoinsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.shopScreen),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        // Don't clip the pill/icon that overflow the stack bounds.
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.center,
        children: [
          // Bound to the slot (start..end) instead of sizing to content, so a
          // long formatted number can't push the pill past the card edge.
          PositionedDirectional(
            start: 7.r(context),
            end: 0,
            child: InnerShadowContainer(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    3.r(context), 4.r(context), 4.r(context), 4.r(context)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 30.r(context)),
                    Flexible(
                      child: CustomText(
                        ConvertNumber.formatCompact(
                            context.watch<AuthenticationBloc>().user?.coin ??
                                0),
                        fontSize: context.font.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        maxLines: 1,
                        ellipsis: true,
                      ),
                    ),
                    SizedBox(width: 10.r(context)),
                    CustomImage(
                      AppIcons.incrementCoin,
                      width: 18.r(context),
                      height: 18.r(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            child: CustomImage(
              AppIcons.coin,
              width: 37.r(context),
              height: 37.r(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboardScreen),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.centerEnd,
        children: [
          // Bound to the slot (start..end) and ellipsize the label instead of
          // sizing to content — a long translation must not spill off the card.
          PositionedDirectional(
            start: 0,
            end: 7.r(context),
            child: InnerShadowContainer(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    3.r(context), 4.r(context), 4.r(context), 4.r(context)),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.r(context)),
                        child: CustomText(
                          context.tr('leaderboard'),
                          fontSize: context.font.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          maxLines: 1,
                          ellipsis: true,
                        ),
                      ),
                    ),
                    SizedBox(width: context.sizes.lg),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            child: Container(
              width: 38.r(context),
              height: 38.r(context),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: context.color.secondary),
              child: CustomImage(
                AppIcons.leaderBoardIcon,
                fit: BoxFit.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // Build
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthenticationBloc>();
    final isGuest = auth
        .isGuest; // guests have no coin balance, so the coins pill is hidden below
    // Scaffold's `primary: true` reserves the real status bar/notch height
    // above this widget's own preferredSize, but that combined height isn't
    // known until layout — bottom-pin the row instead of centering it, so
    // all of that slack collects above (behind the status bar) and none of
    // it shows up as dead space between the row and the body below.
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.sizes.md)
            .copyWith(top: 15.r(context)),
        child: ConstrainedBox(
          // Cap the bar so the coin/leaderboard pills don't stretch to
          // absurd widths on tablets — they'd otherwise split whatever
          // space is left on the row, however large that is.
          constraints:
              BoxConstraints(maxWidth: context.sizes.maxTabletContentWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.settingsScreen);
                },
                child: AvatarCard(
                  image: auth.user?.profilePic ?? AppIcons.guest,
                  width: 45.r(context),
                  height: 45.r(context),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: context.sizes.lg),
              if (!isGuest) Flexible(child: _buildCoinsCard(context)),
              SizedBox(width: context.sizes.lg),
              Flexible(child: _buildLeaderboardCard(context)),
            ],
          ),
        ),
      ),
    );
  }
}
