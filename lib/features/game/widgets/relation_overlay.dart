import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/models/game_object.dart';
import '../../../core/utils/format.dart';

/// Dashed guides drawn over the scene:
/// - a line between an island object and its partner, labelled with the
///   distance ("2 m");
/// - a ring around every camp group.
///
/// With [usePlaced] the guides follow where the player put the objects
/// instead of the real positions.
class RelationOverlay extends StatelessWidget {
  const RelationOverlay({
    super.key,
    required this.objects,
    this.usePlaced = false,
    this.showLabels = true,
    this.color = Colors.white,
    this.ringPadding = GameConstants.objectSize * 0.8,
  });

  final List<GameObject> objects;
  final bool usePlaced;
  final bool showLabels;
  final Color color;

  /// How far the ring around a group reaches past its outermost object (px).
  final double ringPadding;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RelationPainter(
          objects: objects,
          usePlaced: usePlaced,
          showLabels: showLabels,
          color: color,
          ringPadding: ringPadding,
        ),
      ),
    );
  }
}

class _RelationPainter extends CustomPainter {
  const _RelationPainter({
    required this.objects,
    required this.usePlaced,
    required this.showLabels,
    required this.color,
    required this.ringPadding,
  });

  final List<GameObject> objects;
  final bool usePlaced;
  final bool showLabels;
  final Color color;
  final double ringPadding;

  static const double _dash = 7;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Offset? pointOf(GameObject object) {
      final x = usePlaced ? object.placedX : object.targetX;
      final y = usePlaced ? object.placedY : object.targetY;
      if (x == null || y == null) return null;
      return Offset(x * size.width, y * size.height);
    }

    // Island: anchor -> partner.
    final byId = {for (final o in objects) o.id: o};
    for (final child in objects) {
      final anchorId = child.anchorId;
      if (anchorId == null) continue;
      final anchor = byId[anchorId];
      if (anchor == null) continue;
      final from = pointOf(anchor);
      final to = pointOf(child);
      if (from == null || to == null) continue;

      _drawDashed(
        canvas,
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy),
        paint,
      );
      if (showLabels) {
        _drawLabel(
          canvas,
          (from + to) / 2,
          formatMeters((to - from).distance / size.width),
        );
      }
    }

    // Camp: a ring around every group.
    final groups = <int, List<GameObject>>{};
    for (final object in objects) {
      final clusterId = object.clusterId;
      if (clusterId != null) (groups[clusterId] ??= []).add(object);
    }
    for (final members in groups.values) {
      final points = [
        for (final member in members) pointOf(member),
      ].whereType<Offset>().toList();
      if (points.length < members.length) continue;

      final center =
          points.fold<Offset>(Offset.zero, (sum, p) => sum + p) /
              points.length.toDouble();
      final radius =
          points.map((p) => (p - center).distance).reduce(max) + ringPadding;
      _drawDashed(
        canvas,
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
        paint,
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = min(start + _dash, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += _dash + _gap;
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: ' $text ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RelationPainter oldDelegate) => true;
}
