import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/features/home/widgets/home_top_bar.dart';

// Static rules/help screen shown from Settings.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static Route route(RouteSettings settings) => GradientRouter(
        builder: (context) => const HowToPlayScreen(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(HomeTopBar.preferredHeightOf(context)),
        child: const HomeTopBar(),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(context.sizes.md, 58.r(context),
            context.sizes.md, context.sizes.md),
        child: Column(
          children: [
            _buildCard(context),
            Expanded(
              child: Center(
                child: CustomImage(
                  AppIcons.dora4,
                  width: 168.rs(context),
                  height: 188.rs(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.sizes.xl),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: context.color.outline,
          strokeWidth: 1,
          radius: Radius.circular(10.r(context)),
          dashPattern: const [4, 4],
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.color.surface,
            borderRadius: BorderRadius.circular(10.r(context)),
          ),
          padding: EdgeInsets.all(context.sizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                context.tr('howToPlay'),
                fontWeight: FontWeight.w700,
                fontSize: context.font.large,
                color: context.color.onSurface.withAlpha(200),
              ),
              Divider(
                endIndent: 14,
                indent: 14,
                thickness: 0.5,
                color: context.color.outline,
              ),
              SizedBox(height: context.sizes.xs),
              CustomText(
                context.tr('howToPlayDescription'),
                textAlign: TextAlign.center,
                fontSize: context.font.large,
                color: context.color.onSurface.withAlpha(200),
              ),
              SizedBox(height: context.sizes.lg),
              CustomButton(
                title: context.tr('ok'),
                type: ButtonType.primary,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
