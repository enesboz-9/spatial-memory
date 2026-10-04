import '../constants/game_constants.dart';
import '../utils/score_calculator.dart';
import 'game_object.dart';

class PlacementResult {
  const PlacementResult({
    required this.object,
    required this.distance,
    required this.accuracy,
    this.positionAccuracy = 0,
    this.directionAccuracy,
    this.angleErrorDegrees,
    this.scoredRelative = false,
  });

  final GameObject object;

  /// Euclidean distance in normalized coordinates, or null if never placed.
  final double? distance;

  /// 0.0 - 1.0, final accuracy of this object (position and, for directional
  /// objects, heading). Unplaced objects score 0.
  final double accuracy;

  /// 0.0 - 1.0, position part only.
  final double positionAccuracy;

  /// 0.0 - 1.0 for directional objects, null otherwise.
  final double? directionAccuracy;

  /// How far the heading is off, in degrees (directional objects only).
  final int? angleErrorDegrees;

  /// True when the position was scored relative to its partner / group
  /// because that was better than the exact spot.
  final bool scoredRelative;

  bool get isPlaced => distance != null;

  /// 98-100% accuracy.
  bool get isPerfect =>
      isPlaced && accuracy >= GameConstants.perfectAccuracyThreshold;
}

class ScoreResult {
  const ScoreResult({
    required this.placements,
    required this.averageAccuracy,
    required this.objectScore,
    required this.timeBonus,
    required this.perfectBonus,
    required this.flawlessBonus,
    required this.finalScore,
    this.fakeTotal = 0,
    this.fakePlacedCount = 0,
    this.fakePenalty = 0,
  });

  final List<PlacementResult> placements;
  final double averageAccuracy;
  final int objectScore;
  final int timeBonus;

  /// Bonus for the PERFECT objects (before the difficulty multiplier).
  final int perfectBonus;

  /// Bonus when every object is PERFECT (before the difficulty multiplier).
  final int flawlessBonus;
  final int finalScore;

  /// Fake objects in this round, how many of them the player put down, and
  /// the points that cost (before the difficulty multiplier).
  final int fakeTotal;
  final int fakePlacedCount;
  final int fakePenalty;

  /// PERFECT round: average accuracy at or above 90%.
  bool get isPerfectRound =>
      averageAccuracy >= GameConstants.perfectRoundAccuracy;

  /// 0-4 stars (4 = three stars plus the PERFECT gift star).
  int get stars => ScoreCalculator.starsFor(averageAccuracy);

  int get fakeAvoidedCount => fakeTotal - fakePlacedCount;

  int get placedCount => placements.where((p) => p.isPlaced).length;
  int get perfectCount => placements.where((p) => p.isPerfect).length;
  bool get isFlawless =>
      placements.isNotEmpty &&
      perfectCount == placements.length &&
      fakePlacedCount == 0;
}
