import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/models/game_object.dart';

/// Visual for one object (placeholder icon on a light tile).
///
/// Directional objects pass an [angle]: the icon turns and a small arrow on
/// the edge of the tile shows where the object points.
class ObjectBadge extends StatelessWidget {
  const ObjectBadge({
    super.key,
    required this.definition,
    this.size = GameConstants.objectSize,
    this.angle,
  });

  final ObjectDefinition definition;
  final double size;

  /// Heading in radians, clockwise from up. Null = the heading does not matter.
  final double? angle;

  @override
  Widget build(BuildContext context) {
    final tint = definition.tint;
    final angle = this.angle;

    Widget icon = Icon(
      definition.icon,
      size: size * 0.55,
      color: tint ?? const Color(0xFF1B2440),
    );
    if (angle != null) icon = Transform.rotate(angle: angle, child: icon);

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        // Colored objects get a matching border so the color is easy to read.
        border: tint == null ? null : Border.all(color: tint, width: 3),
      ),
      child: Center(child: icon),
    );

    if (angle == null) return tile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tile,
        Positioned.fill(child: DirectionArrow(angle: angle, size: size)),
      ],
    );
  }
}

/// A small arrow that sits on the edge of a [size] x [size] box and points
/// where [angle] says. It paints slightly outside the box.
class DirectionArrow extends StatelessWidget {
  const DirectionArrow({
    super.key,
    required this.angle,
    required this.size,
    this.color = const Color(0xFFFFC107),
    this.length = GameConstants.directionArrowLength,
  });

  final double angle;
  final double size;
  final Color color;
  final double length;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          size: Size.square(size),
          painter: _ArrowPainter(color: color, length: length),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.length});

  final Color color;
  final double length;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final halfBase = length * 0.8;
    final arrow = Path()
      ..moveTo(centerX, -length)
      ..lineTo(centerX - halfBase, 1)
      ..lineTo(centerX + halfBase, 1)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.length != length;
}

/// An [ObjectBadge] that can be dragged. The drag payload is the object id.
/// With [onTap] set (placed directional objects) a tap turns the object.
class DraggableObject extends StatelessWidget {
  const DraggableObject({
    super.key,
    required this.definition,
    this.angle,
    this.onTap,
  });

  final ObjectDefinition definition;
  final double? angle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = ObjectBadge(definition: definition, angle: angle);
    final draggable = Draggable<String>(
      data: definition.id,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(scale: 1.15, child: badge),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: badge),
      child: badge,
    );
    if (onTap == null) return draggable;
    return GestureDetector(onTap: onTap, child: draggable);
  }
}
