import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/avatar_card.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/marquee.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/features/game/models/player_model.dart';
import 'package:tic_tac_toe/features/game/widgets/neon_border_widget.dart';

// Row of both players' avatars/names below the board; highlights whichever
// player's turn it currently is with a neon border.
class PlayersProfileWidget extends StatefulWidget {
  final Player? player1;
  final Player? player2;
  final Player?
      currentPlayer; // whose turn it is; used to pick which avatar gets the neon border

  const PlayersProfileWidget(
      {super.key,
      required this.player1,
      required this.player2,
      this.currentPlayer});

  @override
  State<PlayersProfileWidget> createState() => _PlayersProfileWidgetState();
}

class _PlayersProfileWidgetState extends State<PlayersProfileWidget> {
  Widget buildPlayerProfile(
    BuildContext context, {
    required String id,
    required String image,
    required String skin,
    required String name,
    required bool
        contentAlignLeft, // mirrors the avatar/text layout so player2's profile faces player1's
  }) {
    Widget content() {
      return Column(
        crossAxisAlignment: contentAlignLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child: CustomText(
                context.tr('sign'),
                fontSize: context.font.small,
                maxLines: 2,
                ellipsis: true,
              )),
              Transform.translate(
                offset: const Offset(4, 0),
                child: CustomImage(
                  skin,
                  width: 16.r(context),
                  height: 16.r(context),
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
          MarqueeWidget(
            child: CustomText(
              name,
              fontSize: context.font.small,
              maxLines: 1,
              ellipsis: true,
            ),
          )
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (contentAlignLeft) ...[
          Expanded(child: content()),
          SizedBox(
            width: 7.r(context),
          )
        ],
        Container(
            decoration: BoxDecoration(
              border: widget.currentPlayer?.playerId == id
                  ? const NeonBorderContainer(Colors.pink)
                  : null,
            ),
            child: AvatarCard(
              width: 52.r(context),
              height: 52.r(context),
              image: image,
              disableShadow: widget.currentPlayer?.playerId == id,
            )),
        if (!contentAlignLeft) ...[
          SizedBox(
            width: 7.r(context),
          ),
          Expanded(child: content())
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 35.r(context),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: buildPlayerProfile(context,
              image: widget.player1?.playerProfile ?? AppIcons.guest,
              skin: widget.player1!.getSkin(),
              contentAlignLeft: false,
              name: (widget.player1!.isYou &&
                      context.read<AuthenticationBloc>().isGuest)
                  ? context.tr('you')
                  : widget.player1!.name,
              id: widget.player1!.playerId),
        ),
        CustomImage(
          AppIcons.versus,
          width: 30.r(context),
          height: 60.r(context),
        ),
        Expanded(
          child: buildPlayerProfile(context,
              id: widget.player2!.playerId,
              image: widget.player2?.playerProfile ?? AppIcons.guest,
              skin: widget.player2!.getSkin(),
              contentAlignLeft: true,
              name: (widget.player2!.isYou &&
                      context.read<AuthenticationBloc>().isGuest)
                  ? context.tr('you')
                  : widget.player2!.name),
        ),
      ],
    );
  }
}
