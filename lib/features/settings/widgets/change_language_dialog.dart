import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_bottom_sheet.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/localization/app_language.dart';
import 'package:tic_tac_toe/commons/blocs/locale_cubit.dart';

// Bottom sheet letting the user pick the app's display language.
class ChangeLanguageDialog {
  ChangeLanguageDialog._();

  static Future<void> show(BuildContext context) {
    return showCustomBottomSheet(
      context,
      title: context.tr('changeLanguage'),
      child: const _LanguageList(),
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
              context.sizes.md, 0, context.sizes.md, context.sizes.lg),
          itemCount: AppLanguages.supported.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: context.sizes.xxs),
          itemBuilder: (context, index) {
            final language = AppLanguages.supported[index];
            final isSelected = language.code == locale.languageCode;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Update locale first so the sheet closes with the new language already applied.
                context.read<LocaleCubit>().changeLocale(language.code);
                Navigator.pop(context);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.sizes.xs),
                child: Row(
                  spacing: 14.r(context),
                  children: [
                    Container(
                      width: 22.r(context),
                      height: 22.r(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? context.color.secondary
                              : context.color.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 11.r(context),
                                height: 11.r(context),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.color.secondary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: CustomText(
                        language.nativeName,
                        fontSize: context.font.normal,
                        color: isSelected
                            ? context.color.secondary
                            : context.color.onSurface.withAlpha(200),
                        maxLines: 1,
                        ellipsis: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
