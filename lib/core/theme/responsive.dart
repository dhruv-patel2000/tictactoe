import 'package:flutter/widgets.dart';

enum DeviceType {
  smallPhone,
  largePhone,
  tablet,
  largeTablet,
}

// Classifies the current device by shortest screen side so layouts/sizes
// can adapt between phones and tablets.
abstract final class ResponsiveHelper {
  static bool isSmallPhone(BuildContext context) {
    return deviceTypeOf(context) == DeviceType.smallPhone;
  }

  static bool isTablet(BuildContext context) {
    return deviceTypeOf(context) == DeviceType.tablet ||
        deviceTypeOf(context) == DeviceType.largeTablet;
  }

  static bool isLargeTablet(BuildContext context) {
    return deviceTypeOf(context) == DeviceType.largeTablet;
  }

  static DeviceType deviceTypeOf(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;

    // Breakpoints ordered largest-first so each threshold short-circuits.
    return switch (shortestSide) {
      >= 900 => DeviceType.largeTablet,
      >= 600 => DeviceType.tablet,
      >= 360 => DeviceType.largePhone,
      _ => DeviceType.smallPhone,
    };
  }
}
