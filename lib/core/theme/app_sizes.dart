import 'package:flutter/material.dart';

import 'package:tic_tac_toe/utils/extensions/num_extension.dart';

// Spacing/radius scale, resolved per-screen via `.r(context)` so values scale
// with device size (see ResponsiveHelper / num_extension.dart).
class AppSizes {
  AppSizes(this._context);

  final BuildContext _context;

  double get xxs => 4.r(_context);
  double get xs => 8.r(_context);
  double get sm => 12.r(_context);
  double get md => 16.r(_context);
  double get lg => 20.r(_context);
  double get xl => 24.r(_context);
  double get xxl => 32.r(_context);
  double get xxxl => 40.r(_context);
  double get xxxxl => 48.r(_context);
  double get xxxxxl => 64.r(_context);

  double get radiusXxs => 4.r(_context);
  double get radiusXs => 8.r(_context);
  double get radiusSm => 12.r(_context);
  double get radiusMd => 16.r(_context);
  double get radiusLg => 20.r(_context);
  double get radiusXl => 24.r(_context);
  double get radiusPill =>
      9999; // large enough to force fully rounded (pill) corners on any widget

  // Cap on how wide dialogs/top-bar content are allowed to grow on tablets;
  // shared so every call site tracks the same Figma-driven cap instead of
  // re-typing the literal.
  double get maxTabletContentWidth => 560.rs(_context);
}
