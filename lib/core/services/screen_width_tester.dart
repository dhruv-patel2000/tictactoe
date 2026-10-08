import 'package:flutter/material.dart';

import 'package:tic_tac_toe/core/theme/colors.dart';

/// A utility widget for testing the app at different screen widths.
/// This helps identify UI issues on smaller devices.
///
/// Usage: Wrap your app with this widget and enable it in debug mode.
class ScreenWidthTester extends StatefulWidget {
  const ScreenWidthTester({
    super.key,
    required this.child,
    this.enabled = false,
    this.initialWidth,
    this.showControls = true,
  });

  final Widget child;

  final bool enabled;

  final double? initialWidth;

  final bool showControls;

  @override
  State<ScreenWidthTester> createState() => _ScreenWidthTesterState();
}

class _ScreenWidthTesterState extends State<ScreenWidthTester> {
  double?
      _customWidth; // simulated width override; null means use the real device width
  bool _isControlsExpanded = false;

  static const Map<String, double> presetWidths = {
    // device name -> width shortcuts shown in the control panel
    'iPhone SE': 320,
    'iPhone 8': 375,
    'iPhone 12': 390,
    'iPhone 14 Pro Max': 430,
    'Pixel 5': 393,
    'Galaxy S21': 360,
    'Small Tablet': 600,
    'iPad Mini': 768,
  };

  @override
  void initState() {
    super.initState();
    _customWidth = widget.initialWidth;
  }

  //--------------------------------------------------
  // UI Builder Methods
  //--------------------------------------------------

  Widget _buildConstrainedApp({
    required double deviceWidth,
    required double deviceHeight,
    required double effectiveWidth,
    required double scale,
  }) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(size: Size(effectiveWidth, deviceHeight)),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: effectiveWidth > deviceWidth ? deviceWidth : effectiveWidth,
          decoration: _customWidth != null
              ? BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                )
              : null,
          child: effectiveWidth > deviceWidth
              ? FittedBox(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: effectiveWidth,
                    height: deviceHeight / scale,
                    child: widget.child,
                  ),
                )
              : widget.child,
        ),
      ),
    );
  }

  Widget _buildControlPanel(double deviceWidth) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.black87,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: () =>
                  setState(() => _isControlsExpanded = !_isControlsExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.width_normal,
                      color: AppColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _customWidth != null
                          ? '${_customWidth!.toInt()}px'
                          : 'Device',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isControlsExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_isControlsExpanded) ...[
              const SizedBox(height: 8),
              _buildPresetButton(
                'Reset',
                null,
                isSelected: _customWidth == null,
              ),
              const SizedBox(height: 4),
              ...presetWidths.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildPresetButton(
                    '${entry.key} (${entry.value.toInt()})',
                    entry.value,
                    isSelected: _customWidth == entry.value,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomWidthSlider(deviceWidth),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(
    String label,
    double? width, {
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () => setState(() => _customWidth = width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomWidthSlider(double deviceWidth) {
    final currentWidth = _customWidth ?? deviceWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Width:',
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepButton(
              icon: Icons.remove,
              onTap: () {
                final newWidth = (currentWidth - 50).clamp(200.0, 900.0);
                setState(() => _customWidth = newWidth);
              },
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${currentWidth.toInt()}px',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStepButton(
              icon: Icons.add,
              onTap: () {
                final newWidth = (currentWidth + 50).clamp(200.0, 900.0);
                setState(() => _customWidth = newWidth);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [250, 300, 350, 400, 500].map((w) {
            final isSelected = currentWidth.toInt() == w;
            return GestureDetector(
              onTap: () => setState(() => _customWidth = w.toDouble()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$w',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final deviceWidth = constraints.maxWidth;
          final deviceHeight = constraints.maxHeight;
          final effectiveWidth = _customWidth ?? deviceWidth;

          // Shrink factor to fit a simulated width wider than the real device
          // into the available screen; 1.0 (no shrink) when it already fits.
          final scale =
              effectiveWidth > deviceWidth ? deviceWidth / effectiveWidth : 1.0;

          return Stack(
            children: [
              Positioned.fill(
                child: _buildConstrainedApp(
                  deviceWidth: deviceWidth,
                  deviceHeight: deviceHeight,
                  effectiveWidth: effectiveWidth,
                  scale: scale,
                ),
              ),
              if (widget.showControls)
                Positioned(
                  right: 8,
                  bottom: 100,
                  child: _buildControlPanel(deviceWidth),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A simpler version that just constrains width without controls
/// Useful for automated testing or quick checks
class ConstrainedWidthWrapper extends StatelessWidget {
  const ConstrainedWidthWrapper({
    super.key,
    required this.child,
    required this.width,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(size: Size(width, MediaQuery.of(context).size.height)),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    );
  }
}
