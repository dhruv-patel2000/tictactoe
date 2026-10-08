import 'dart:ui';

// Adjusts a Color's lightness by shifting each RGB channel, used for
// hover/pressed states and shading UI elements.
extension ColorExt on Color {
  // Shifts each channel up toward white by value (0.0-1.0).
  Color brighten(double value) {
    double red = (r + value).clamp(0.0, 1.0);
    double green = (g + value).clamp(0.0, 1.0);
    double blue = (b + value).clamp(0.0, 1.0);

    return Color.fromARGB(
      255,
      (red * 255).toInt(),
      (green * 255).toInt(),
      (blue * 255).toInt(),
    );
  }

  // Shifts each channel down toward black by value (0.0-1.0).
  Color darken(double value) {
    double red = (r - value).clamp(0.0, 1.0);
    double green = (g - value).clamp(0.0, 1.0);
    double blue = (b - value).clamp(0.0, 1.0);

    return Color.fromARGB(
      255,
      (red * 255).toInt(),
      (green * 255).toInt(),
      (blue * 255).toInt(),
    );
  }
}
