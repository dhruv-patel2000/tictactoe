import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/num_extension.dart';

// Type scale, resolved per-screen via `.rf(context)` so text scales with
// device size (see ResponsiveHelper / num_extension.dart).
class FontSizes {
  FontSizes(this._context);

  final BuildContext _context;

  double get extraSmall => 10.0.rf(_context);
  double get small => 12.0.rf(_context);
  double get normal => 14.0.rf(_context);
  double get medium => 16.0.rf(_context);
  double get large => 18.0.rf(_context);
  double get xL => 20.0.rf(_context);
  double get xXL => 24.0.rf(_context);
}
