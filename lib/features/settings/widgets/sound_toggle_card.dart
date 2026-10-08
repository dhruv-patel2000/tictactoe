import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/commons/widgets/custom_text.dart';
import 'package:tic_tac_toe/core/services/sound_service.dart';
import 'package:tic_tac_toe/core/theme/colors.dart';

// On/off toggle pair for app sound effects, backed by SoundService.
class SoundToggleCard extends StatefulWidget {
  const SoundToggleCard({super.key});

  @override
  State<SoundToggleCard> createState() => _SoundToggleCardState();
}

class _SoundToggleCardState extends State<SoundToggleCard> {
  bool _soundOn = SoundService.isEnabled;

  // Skip redundant writes/rebuilds when tapping the already-active pill.
  void _set(bool value) {
    if (value == _soundOn) return;
    SoundService.setEnabled(value);
    setState(() => _soundOn = value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.sizes.sm, vertical: context.sizes.sm),
      child: Row(
        spacing: 12.r(context),
        children: [
          Expanded(
            child: _pill(
              context,
              active: _soundOn,
              icon: Icons.volume_up,
              label: context.tr('soundOn'),
              onTap: () => _set(true),
            ),
          ),
          Expanded(
            child: _pill(
              context,
              active: !_soundOn,
              icon: Icons.volume_off,
              label: context.tr('soundOff'),
              onTap: () => _set(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final Color background =
        active ? context.color.secondary : context.color.surface;
    final Color foreground = active ? AppColors.white : context.color.secondary;
    return InkWell(
      borderRadius: BorderRadius.circular(context.sizes.radiusLg),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 10.r(context), vertical: context.sizes.xs),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.sizes.radiusLg),
          border: Border.all(color: context.color.secondary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6.r(context),
          children: [
            Icon(icon, color: foreground, size: context.sizes.md),
            Flexible(
              child: CustomText(
                label,
                color: foreground,
                fontSize: context.font.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
