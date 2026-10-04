import '../constants/game_constants.dart';

String formatSeconds(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Island distance label, e.g. 0.2 of the play area -> "2 m" (rounded to 0.5).
String formatMeters(double normalizedDistance) {
  final halfMeters =
      (normalizedDistance * GameConstants.islandSideMeters * 2).round();
  return halfMeters.isEven
      ? '${halfMeters ~/ 2} m'
      : '${(halfMeters / 2).toStringAsFixed(1)} m';
}

/// Which side [dx], [dy] points to (screen coordinates: y grows downwards).
enum OffsetSide { right, left, below, above }

OffsetSide offsetSide(double dx, double dy) {
  if (dx.abs() >= dy.abs()) return dx >= 0 ? OffsetSide.right : OffsetSide.left;
  return dy >= 0 ? OffsetSide.below : OffsetSide.above;
}

/// English phrase for [offsetSide]: "to the right of", "above"...
String describeOffset(double dx, double dy) => switch (offsetSide(dx, dy)) {
      OffsetSide.right => 'to the right of',
      OffsetSide.left => 'to the left of',
      OffsetSide.below => 'below',
      OffsetSide.above => 'above',
    };
