import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/coin_cointainer.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/commons/models/user_model.dart';
import 'package:tic_tac_toe/features/leaderboard/repositories/leaderboard_repository.dart';
import 'package:tic_tac_toe/features/settings/widgets/edit_profile_sheet.dart';

// Shared header card (avatar, name, coins, stats) reused across History,
// Leaderboard and Settings screens; content adapts via constructor flags.
class ProfileCard extends StatefulWidget {
  // Optional custom bottom section (e.g. History's day filter); falls back to _defaultBottom when null.
  final Widget Function(BuildContext context, UserModel? user)? bottomBuilder;

  final bool showCoin;

  /// When true (and the user isn't a guest), the avatar becomes tappable and
  /// shows an edit badge that opens [EditProfileSheet]. Off by default so the
  /// card stays read-only on the leaderboard/history screens.
  final bool editable;

  const ProfileCard(
      {super.key,
      this.bottomBuilder,
      this.showCoin = true,
      this.editable = false});

  @override
  State<ProfileCard> createState() => _ProfileCardState();

  static Widget buildInsight(
      BuildContext context, ({String title, int value}) insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10.r(context),
      children: [
        CustomText(
          insight.title,
          fontSize: context.font.small,
          textAlign: TextAlign.center,
        ),
        CustomText(
          insight.value.toString(),
          fontSize: context.font.large,
          fontWeight: FontWeight.w700,
        )
      ],
    );
  }

  static Widget buildVerticalDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.sizes.sm),
      child: DottedBorder(
          options: RectDottedBorderOptions(
            dashPattern: [2, 5],
            color: context.color.outline,
            strokeWidth: 1,
            padding: EdgeInsets.zero,
          ),
          child: SizedBox(
            width: 0,
            height: 45.r(context),
          )),
    );
  }
}

class _ProfileCardState extends State<ProfileCard> {
  final LeaderboardRepository _leaderboardRepository =
      LeaderboardRepository(); // source for the rank stream below

  // Cached per user id so the underlying Firebase listener survives rebuilds.
  // `AuthenticationBloc` re-emits its state on every change to the user's own
  // node (score, coin, ...), which rebuilds this widget far more often than
  // the rank itself changes. Building the stream straight from
  // `LeaderboardRepository().streamUserRank(id)` inside `build()` created a
  // brand new listener on every one of those rebuilds — for a full, unindexed
  // `users` read, that's slow enough that the listener kept getting cancelled
  // before its first snapshot arrived, so the rank stayed stuck on "-".
  String? _rankUserId;
  Stream<UserRank?>? _rankStream;

  //--------------------------------------------------
  // Helper Methods
  //--------------------------------------------------

  Stream<UserRank?> _rankStreamFor(String userId) {
    if (_rankUserId != userId) {
      _rankUserId = userId;
      _rankStream = _leaderboardRepository.streamUserRank(userId);
    }
    return _rankStream!;
  }

  //--------------------------------------------------
  // UI Builder Methods
  //--------------------------------------------------

  Widget _defaultBottom(BuildContext context, UserModel? user) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildRankInsight(context, user)),
        ProfileCard.buildVerticalDivider(context),
        Expanded(
            flex: 2,
            child: ProfileCard.buildInsight(context,
                (title: context.tr('score'), value: user?.score ?? 0))),
        ProfileCard.buildVerticalDivider(context),
        Expanded(
            flex: 2,
            child: ProfileCard.buildInsight(context,
                (title: context.tr('played'), value: user?.matchPlayed ?? 0))),
        ProfileCard.buildVerticalDivider(context),
        Expanded(
            flex: 2,
            child: ProfileCard.buildInsight(context,
                (title: context.tr('wins'), value: user?.matchWon ?? 0)))
      ],
    );
  }

  Widget _buildRankInsight(BuildContext context, UserModel? user) {
    final id = user?.userId ?? '';
    // A user with score == 0 has never finished a match and is excluded
    // from ranking entirely (see rankUsers in leaderboard_ranking.dart), so
    // skip the rank stream and show '-' instead of a misleading capped
    // rank like "#1000+".
    if (id.isEmpty || (user?.score ?? 0) == 0) {
      return _rankColumn(context, '-');
    }
    return StreamBuilder<UserRank?>(
      stream: _rankStreamFor(id),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return _rankColumn(
          context,
          data == null ? '-' : '#${data.rank}${data.isCapped ? '+' : ''}',
        );
      },
    );
  }

  Widget _rankColumn(BuildContext context, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10.r(context),
      children: [
        CustomText(
          context.tr('rank'),
          fontSize: context.font.small,
          textAlign: TextAlign.center,
        ),
        CustomText(
          value,
          fontSize: context.font.large,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  static Widget buildHorizontalDivider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.sizes.sm),
      child: DottedBorder(
          options: RectDottedBorderOptions(
            padding: EdgeInsets.zero,
            dashPattern: [4, 4],
            color: context.color.outline,
          ),
          child: Container(
            height: 0,
          )),
    );
  }

  Widget buildNameAndEmail(UserModel? user, BuildContext context) {
    return Expanded(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              user?.username ?? '',
              color: context.color.onSurface,
              ellipsis: true,
              maxLines: 1,
              fontSize: context.font.normal,
            ),
            if (user?.email?.isNotEmpty ?? false)
              CustomText(user?.email ?? '', fontSize: context.font.normal),
          ]),
    );
  }

  Widget buildProfileImage(UserModel? user) {
    final Widget avatar = Container(
        width: 50.r(context),
        height: 50.r(context),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.color.tertiary.withAlpha(100)),
        child: ClipOval(
          child: CustomImage(
            user?.profilePic ?? AppIcons.guest,
            fit: BoxFit.cover,
          ),
        ));

    final bool canEdit =
        widget.editable && !context.read<AuthenticationBloc>().isGuest;
    if (!canEdit) return avatar;

    return GestureDetector(
      onTap: () => EditProfileSheet.show(context),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          avatar,
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              padding: EdgeInsets.all(3.r(context)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.secondary,
                border: Border.all(
                    color: context.color.surfaceContainer, width: 1.5),
              ),
              child: Icon(
                Icons.edit,
                size: 11.r(context),
                color: context.color.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // build()
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        UserModel? user;
        if (state is AuthenticatedState) {
          user = state.user;
        } else if (state is AuthenticatedAsGuestState) {
          user = state.user;
        }
        return InnerShadowContainer(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.sizes.md, vertical: context.sizes.sm),
            child: Column(
              children: [
                Row(
                  spacing: 10.r(context),
                  children: [
                    buildProfileImage(user),
                    buildNameAndEmail(user, context),
                    if (widget.showCoin) CoinContainer(coins: user?.coin ?? 0)
                  ],
                ),
                buildHorizontalDivider(context),
                widget.bottomBuilder?.call(context, user) ??
                    _defaultBottom(context, user),
              ],
            ),
          ),
        );
      },
    );
  }
}
