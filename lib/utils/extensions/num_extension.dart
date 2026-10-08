import 'package:flutter/widgets.dart';
import 'package:tic_tac_toe/core/theme/responsive.dart';

/// Number formatting and device-responsive scaling helpers (coins, currency
/// display, spacing/size/font scaling by device type).
extension NumExtension on num {
  // Inserts a thousands-separator comma (only handles up to 4-digit numbers).
  String get toStringWithCommas {
    final String number = toString();
    if (number.length >= 4) {
      return number.replaceRange(3, 4, ',');
    }
    return number;
  }

  double minMaxNormalize(double min, double max) {
    if (min == max) return 0.0; // Avoid division by zero
    return (this - min) / (max - min);
  }

  /// General-purpose responsive scale for spacing, sizing, radii.
  double r(BuildContext context) {
    return this *
        switch (ResponsiveHelper.deviceTypeOf(context)) {
          DeviceType.smallPhone => 0.9,
          DeviceType.largePhone => 1,
          DeviceType.tablet => 1.3,
          DeviceType.largeTablet => 1.5,
        };
  }

  /// Wider-range scale for values that need to grow more aggressively on
  /// tablets (large gaps, illustration widths, etc).
  double rs(BuildContext context) {
    return this *
        switch (ResponsiveHelper.deviceTypeOf(context)) {
          DeviceType.smallPhone => 0.9,
          DeviceType.largePhone => 1,
          DeviceType.tablet => 1.5,
          DeviceType.largeTablet => 2.5,
        };
  }

  /// Font-size scale.
  double rf(BuildContext context) {
    return this *
        switch (ResponsiveHelper.deviceTypeOf(context)) {
          DeviceType.smallPhone => 0.75,
          DeviceType.largePhone => 1,
          DeviceType.tablet => 1.2,
          DeviceType.largeTablet => 1.3,
        };
  }
}
