import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';

/// Faint lines that split the play area into equal cells. They help the player
/// compare positions ("the antenna is in the top-left cell") and never block
/// touches.
class GuideGrid extends StatelessWidget {
  const GuideGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GuideGridPainter(GameConstants.guideGridDivisions),
      ),
    );
  }
}

class _GuideGridPainter extends CustomPainter {
  const _GuideGridPainter(this.divisions);

  final int divisions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideGridPainter oldDelegate) =>
      oldDelegate.divisions != divisions;
}
