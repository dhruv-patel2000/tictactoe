import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';

// ConnectionScreen's remaining-search-time pill.
class ConnectionTimer extends StatelessWidget {
  final ValueNotifier<int> time;

  const ConnectionTimer({super.key, required this.time});

  static String _formatTime(int time) {
    final minutes = (time ~/ 60).toString().padLeft(2, '0');
    final seconds = (time % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144.r(context),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.color.onSurface.withAlpha(150),
        ),
        borderRadius: BorderRadius.circular(6.r(context)),
      ),
      padding: EdgeInsets.all(10.r(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImage(
            AppIcons.clock,
            width: 20.r(context),
            height: 20.r(context),
          ),
          SizedBox(
            width: 6.r(context),
          ),
          ValueListenableBuilder(
              valueListenable: time,
              builder: (context, value, child) {
                return CustomText(
                  _formatTime(value),
                  fontSize: context.font.xL,
                  fontWeight: FontWeight.w600,
                );
              }),
        ],
      ),
    );
  }
}
