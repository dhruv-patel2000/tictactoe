import 'package:flutter/material.dart';

import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';
import 'package:tic_tac_toe/features/home/widgets/home_card_shape.dart';

// Large tappable card on the home screen advertising one game mode (image +
// title/subtitle + play button); `reverse` mirrors layout/text alignment so
// alternating cards face each other.
class HomeCard extends StatefulWidget {
  final bool reverse;
  final String? title;
  final String subTitle;
  final String image;
  final VoidCallback? onTap;

  const HomeCard(
      {super.key,
      required this.reverse,
      required this.image,
      this.title,
      required this.subTitle,
      this.onTap});

  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  @override
  Widget build(BuildContext context) {
    // `reverse` is a logical flip; under RTL it must invert again so the
    // card still reads left-to-right visually the same as in LTR.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final visualFlip = isRtl ? !widget.reverse : widget.reverse;
    return Transform.flip(
      flipX: visualFlip,
      child: Container(
        width: context.screenWidth,
        decoration: ShapeDecoration(
          shape: HomeCardShapeBorder(borderColor: context.color.outline),
          shadows: [
            BoxShadow(
              color: Color(0xffFFFFFF).withValues(alpha: 0.07),
            ),
            BoxShadow(
              color: context.color.surface.withValues(alpha: 0.2),
              offset: Offset(visualFlip ? -5 : 5, 5),
              spreadRadius: 0,
              blurRadius: 0,
            ),
            BoxShadow(
                color: context.color.surface.withValues(alpha: 0.23),
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(visualFlip ? -3 : 3, 3)),
          ],
        ),
        child: Transform.flip(
          flipX: visualFlip,
          child: Row(
            children: [
              if (widget.reverse) buildContent(),
              CustomImage(
                widget.image,
                fit: BoxFit.contain,
                // dora_1/2/3.svg are all 137x149 intrinsic — this matches
                // that exactly on phones (r() is a no-op there) and grows
                // moderately on tablets so the card isn't left mostly empty
                // next to the text column.
                height: 149.r(context),
              ),
              if (!widget.reverse) buildContent()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildContent() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24.r(context), 64.r(context), 24.r(context), 14.r(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2.r(context),
          crossAxisAlignment: widget.reverse
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            CustomText(
              (widget.title ?? '').toUpperCase(),
              fontSize: context.font.xL,
              fontWeight: FontWeight.w700,
              maxLines: 2,
              ellipsis: true,
              color: AppColors.white,
              textAlign: widget.reverse ? TextAlign.start : TextAlign.end,
            ),
            CustomText(
              widget.subTitle,
              fontSize: context.font.normal,
              maxLines: 2,
              ellipsis: true,
              textAlign: widget.reverse ? TextAlign.start : TextAlign.end,
            ),
            CustomButton(
              onTap: widget.onTap,
              height: 32.r(context),
              title: context.tr('playNow'),
              type: ButtonType.primary,
            )
          ],
        ),
      ),
    );
  }
}
