import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/navigation_routers/gradient_router.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/commons/widgets/inner_shadow.dart';
import 'package:tic_tac_toe/core/constants/legal_content.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// Generic screen for legal/contact pages (About, Terms, Privacy, Contact Us);
// which page to render is chosen by the [LegalInfoPage] passed as route argument.
class LegalInfoScreen extends StatelessWidget {
  final LegalInfoPage page;

  const LegalInfoScreen({super.key, required this.page});

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments;
    // Falls back to Contact Us if the route was pushed without a page argument.
    final page =
        arguments is LegalInfoPage ? arguments : LegalContent.contactUs;

    return GradientRouter(
      builder: (context) => LegalInfoScreen(page: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: CustomText(
          context.tr(page.titleKey),
          fontSize: context.font.large,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        backgroundColor: context.color.surfaceContainer,
        surfaceTintColor: context.color.surfaceContainer,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: context.sizes.md,
          right: context.sizes.md,
          top: context.sizes.md,
          bottom: context.sizes.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: InnerShadowContainer(
          child: Padding(
            padding: EdgeInsets.all(18.r(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 18.r(context),
              children: [
                CustomText(
                  context.tr(page.titleKey),
                  fontSize: context.font.xL,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface,
                ),
                CustomText(
                  page.body.trim(),
                  fontSize: context.font.normal,
                  color: context.color.onSurface.withAlpha(210),
                ),
                if (page.contactItems.isNotEmpty) ...[
                  SizedBox(height: 2.r(context)),
                  ...page.contactItems
                      .map((item) => _contactTile(context, item)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTile(BuildContext context, LegalContactItem item) {
    return Container(
      padding: EdgeInsets.all(14.r(context)),
      decoration: BoxDecoration(
        color: context.color.surfaceContainer,
        borderRadius: BorderRadius.circular(context.sizes.radiusSm),
        border: Border.all(color: context.color.outline),
      ),
      child: Row(
        spacing: 12.r(context),
        children: [
          Icon(_iconFor(item.type), color: context.color.primary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.r(context),
              children: [
                CustomText(
                  item.label,
                  fontSize: context.font.small,
                  color: context.color.onSurface.withAlpha(170),
                ),
                CustomText(
                  item.value,
                  fontSize: context.font.normal,
                  fontWeight: FontWeight.w700,
                  color: context.color.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LegalContactType type) {
    switch (type) {
      case LegalContactType.email:
        return Icons.mail_outline;
      case LegalContactType.phone:
        return Icons.call_outlined;
      case LegalContactType.responseTime:
        return Icons.schedule_outlined;
    }
  }
}
