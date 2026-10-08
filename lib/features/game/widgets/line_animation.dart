import 'package:flutter/material.dart';

import 'package:tic_tac_toe/core/theme/colors.dart';

// Drives the winning-line overlay: holds its current start/end/color and
// notifies AnimatedLine's state via onChange rather than a ChangeNotifier.
class LineAnimationController {
  Offset? start;
  Offset? end;
  Color color = const Color(0xFFFF2D95);
  void Function()? onChange;

  void setAnimation(Offset start, Offset end, {Color? color}) {
    this.start = start;
    this.end = end;
    if (color != null) this.color = color;
    onChange?.call();
  }

  /// Removes the line (e.g. when a new round starts) so a finished round's
  /// winning line never lingers on the next round's empty board.
  void clear() {
    start = null;
    end = null;
    onChange?.call();
  }
}

// Animates a glowing line across the board to mark the winning row/column/
// diagonal; reads its endpoints from [LineAnimationController].
class AnimatedLine extends StatefulWidget {
  final LineAnimationController controller;

  const AnimatedLine({super.key, required this.controller});

  @override
  State<AnimatedLine> createState() => _AnimatedLineState();
}

class _AnimatedLineState extends State<AnimatedLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset>?
      _animation; // null when there's no line to draw (e.g. before a win or after clear())

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    widget.controller.onChange = () {
      if (!mounted) return;
      if (widget.controller.start == null || widget.controller.end == null) {
        _controller.reset();
        setState(() => _animation = null);
        return;
      }
      _animation = Tween<Offset>(
              begin: widget.controller.start, end: widget.controller.end)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          if (widget.controller.start != null) {
            return CustomPaint(
              size: Size.infinite,
              painter: LinePainter(
                widget.controller.color,
                start: widget.controller.start!,
                end: _animation!.value,
              ),
            );
          }
          return const SizedBox.shrink();
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Paints the neon-glow winning line (layered blurred strokes).
class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  LinePainter(this.color, {required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    // Neon look = a soft coloured halo built from blurred strokes, brightest at
    // the core, finished with a near-white hot centre. Drawn widest-first so the
    // brighter layers sit on top.
    final outerGlow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);

    final innerGlow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final core = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;

    final hotCenter = Paint()
      ..color = AppColors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas.drawLine(start, end, outerGlow);
    canvas.drawLine(start, end, innerGlow);
    canvas.drawLine(start, end, core);
    canvas.drawLine(start, end, hotCenter);
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}
