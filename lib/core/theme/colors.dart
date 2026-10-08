import 'package:flutter/material.dart';

// App-wide color palette; screens should reference these instead of raw hex.
class AppColors {
  static const Color primaryColor = Color(0xFF00A0FF);
  static const Color secondaryColor = Color(0xFFF0842A);
  static const Color tertiaryColor = Color(0xFF00A8CA);
  static const Color surfaceColor = Color(0xff242424);

  static const Color outlineColor = Color.fromARGB(255, 90, 90, 90);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Gradient stops for the app's screen background; `.last` is also used to
  // color the system navigation bar so it matches (see main.dart).
  static const List<Color> screenBackgroundGradient = [
    Color(0xff262C30),
    Color(0xff161719),
  ];
}
