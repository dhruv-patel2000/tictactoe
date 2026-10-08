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
import 'package:tic_tac_toe/commons/models/user_model.dart';

// ConnectionScreen's "you" vs "opponent joining soon" avatar row.
class ConnectionPlayersRow extends StatelessWidget {
  const ConnectionPlayersRow({super.key});

  @override
  Widget build(BuildContext context) {
    UserModel? user = context.read<AuthenticationBloc>().user;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
            child: FittedBox(
                fit: BoxFit.none,
                child: Column(
                  spacing: 5.r(context),
                  children: [
                    AvatarCard(
                      image: user?.profilePic ?? AppIcons.guest,
                      height: 90.r(context),
                      width: 90.r(context),
                    ),
                    SizedBox(
                      width: 90.r(context),
                      child: MarqueeWidget(
                        child: CustomText(
                          user!.username,
                          fontSize: context.font.small,
                          maxLines: 1,
                          ellipsis: true,
                        ),
                      ),
                    )
                  ],
                ))),
        CustomImage(
          AppIcons.versus,
        ),
        Expanded(
            child: FittedBox(
                fit: BoxFit.none,
                child: Column(
                  spacing: 5.r(context),
                  children: [
                    AvatarCard(
                      image: '',
                      height: 90.r(context),
                      width: 90.r(context),
                    ),
                    SizedBox(
                      width: 90.r(context),
                      child: CustomText(
                        context.tr('joiningSoon'),
                        fontSize: context.font.small,
                        maxLines: 1,
                        ellipsis: true,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ))),
      ],
    );
  }
}
