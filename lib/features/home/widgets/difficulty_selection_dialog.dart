import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/sliver_heighted_deliget.dart';
import 'package:tic_tac_toe/commons/widgets/borderd_container.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';

extension _DifficultyLabel on Difficulty {
  /// Translation key for this level's label (see `assets/languages/*.json`).
  String get labelKey => switch (this) {
        Difficulty.easy => 'easy',
        Difficulty.medium => 'medium',
        Difficulty.hard => 'hard',
      };
}

// Lets the player pick AI difficulty before starting offline play; pops
// with the chosen [Difficulty] (or null if dismissed).
class DifficultySelectionDialog extends StatefulWidget {
  const DifficultySelectionDialog({super.key});

  @override
  State<DifficultySelectionDialog> createState() =>
      _DifficultySelectionDialogState();
}

class _DifficultySelectionDialogState extends State<DifficultySelectionDialog> {
  Difficulty selectedDifficulty = Difficulty
      .medium; // current pick, defaults to medium; returned via Navigator.pop on "next"

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('selectDifficulty'),
      buttons: [
        DialogButton(
          title: context.tr('next'),
          icon: AppIcons.next,
          onTap: () {
            Navigator.pop(context, selectedDifficulty);
          },
        ),
      ],
      child: GridView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.xxxl, vertical: context.sizes.xl),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
            crossAxisSpacing: 24.r(context),
            mainAxisSpacing: 24.r(context),
            crossAxisCount: 1,
            height: 42.r(context)),
        children: List.generate(
          Difficulty.values.length,
          (index) {
            final Difficulty difficulty = Difficulty.values[index];
            final bool isSelected = selectedDifficulty == difficulty;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDifficulty = difficulty;
                });
              },
              child: BorderContainer(
                color: isSelected ? context.color.secondary : null,
                borderColor: isSelected ? context.color.secondary : null,
                child: CustomText(
                  context.tr(difficulty.labelKey),
                  fontSize: context.font.medium,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
