import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/sliver_heighted_deliget.dart';
import 'package:tic_tac_toe/commons/widgets/borderd_container.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';
import 'package:tic_tac_toe/features/game/models/matrix_size_model.dart';

// Lets the player pick the board size (3x3, 4x4, ...) before starting a
// game; pops with the chosen [MatrixSize] (or null if dismissed).
class MatrixSizeSelectionDialog extends StatefulWidget {
  const MatrixSizeSelectionDialog({super.key});

  @override
  State<MatrixSizeSelectionDialog> createState() =>
      _MatrixSizeSelectionDialogState();
}

class _MatrixSizeSelectionDialogState extends State<MatrixSizeSelectionDialog> {
  MatrixSize? selectedMatrixSize = AppSettings.matrixSizes
      .first; // current pick, defaults to first size; returned via Navigator.pop on "start"

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('chooseYourGameMode'),
      buttons: [
        DialogButton(
          title: context.tr('start'),
          onTap: () {
            Navigator.pop(context, selectedMatrixSize);
          },
        ),
      ],
      child: GridView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.xxxl, vertical: context.sizes.xl),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
            crossAxisSpacing: 20.r(context),
            mainAxisSpacing: 20.r(context),
            crossAxisCount: 1,
            height: 42.r(context)),
        children: List.generate(
          AppSettings.matrixSizes.length,
          (index) {
            final MatrixSize matrixSize = AppSettings.matrixSizes[index];
            final bool isSelected = selectedMatrixSize == matrixSize;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedMatrixSize = matrixSize;
                });
              },
              child: BorderContainer(
                color: isSelected ? context.color.secondary : null,
                borderColor: isSelected ? context.color.secondary : null,
                child: CustomText(
                  matrixSize.title.toString(),
                  fontSize: context.font.large,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
