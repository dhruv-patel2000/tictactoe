import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/sliver_heighted_deliget.dart';
import 'package:tic_tac_toe/commons/widgets/coin_cointainer.dart';
import 'package:tic_tac_toe/commons/widgets/custom_dialog_box.dart';
import 'package:tic_tac_toe/core/constants/settings.dart';

// Lets the player pick a coin stake before matchmaking; pops with the
// chosen fee (or null if dismissed).
class EntryFeeSelectionDialog extends StatefulWidget {
  const EntryFeeSelectionDialog({super.key});

  @override
  State<EntryFeeSelectionDialog> createState() =>
      _EntryFeeSelectionDialogState();
}

class _EntryFeeSelectionDialogState extends State<EntryFeeSelectionDialog> {
  int selectedEntryFee = AppSettings.multiplayerFees
      .first; // current pick, defaults to lowest fee; returned via Navigator.pop on "next"

  @override
  Widget build(BuildContext context) {
    return CustomDialogBox(
      title: context.tr('playWithRandomMatch'),
      buttons: [
        DialogButton(
          title: context.tr('next'),
          icon: AppIcons.next,
          onTap: () {
            Navigator.pop(context, selectedEntryFee);
          },
        ),
      ],
      child: GridView(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
            horizontal: context.sizes.lg, vertical: context.sizes.xl),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
            crossAxisSpacing: 24.r(context),
            mainAxisSpacing: 24.r(context),
            crossAxisCount: 2,
            height: 42.r(context)),
        children: List.generate(
          AppSettings.multiplayerFees.length,
          (index) {
            final int fee = AppSettings.multiplayerFees[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedEntryFee = fee;
                });
              },
              child: CoinContainer(
                selected: selectedEntryFee == fee,
                coins: fee,
              ),
            );
          },
        ),
      ),
    );
  }
}
