import 'dart:math';

import '../constants/game_constants.dart';
import '../models/game_config.dart';
import '../models/game_object.dart';
import '../models/score_result.dart';

abstract final class ScoreCalculator {
  /// Euclidean distance between two normalized points.
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  /// 1.0 inside the perfect radius, then falls off linearly to 0.0 at
  /// [GameConstants.maxAccuracyDistance].
  static double accuracyForDistance(double distance) {
    if (distance <= GameConstants.perfectRadius) return 1;
    const span =
        GameConstants.maxAccuracyDistance - GameConstants.perfectRadius;
    final accuracy = 1 - (distance - GameConstants.perfectRadius) / span;
    return accuracy.clamp(0.0, 1.0).toDouble();
  }

  /// 1.0 for the exact heading, 0.0 for the opposite one, linear in between.
  static double angleAccuracy(int errorSteps, int steps) {
    if (steps < 2) return 1;
    return (1 - errorSteps / (steps / 2)).clamp(0.0, 1.0).toDouble();
  }

  /// 0-4 stars for a round's average accuracy. The 4th star is the gift for
  /// a PERFECT round ([GameConstants.perfectRoundAccuracy]).
  static int starsFor(double averageAccuracy) {
    if (averageAccuracy >= GameConstants.perfectRoundAccuracy) return 4;
    if (averageAccuracy >= GameConstants.threeStarAccuracy) return 3;
    if (averageAccuracy >= GameConstants.twoStarAccuracy) return 2;
    if (averageAccuracy >= GameConstants.oneStarAccuracy) return 1;
    return 0;
  }

  /// Final score =
  /// (object score + time bonus + perfect bonus + flawless bonus
  ///   - fake penalty, at least 0) * difficulty.
  ///
  /// The time bonus is scaled by accuracy so speed only pays off when the
  /// player actually remembered the layout.
  static ScoreResult calculate({
    required List<GameObject> objects,
    required GameConfig config,
    required int remainingSeconds,
    List<FakeObject> fakes = const [],
  }) {
    final placements = [
      for (final object in objects) _evaluate(object, objects),
    ];

    final averageAccuracy = placements.isEmpty
        ? 0.0
        : placements.fold<double>(0, (sum, p) => sum + p.accuracy) /
            placements.length;

    final objectScore = (averageAccuracy * GameConstants.maxObjectScore).round();

    final timeFraction = config.placementSeconds <= 0
        ? 0.0
        : (remainingSeconds / config.placementSeconds).clamp(0.0, 1.0).toDouble();
    final timeBonus =
        (GameConstants.maxTimeBonus * timeFraction * averageAccuracy).round();

    final perfectCount = placements.where((p) => p.isPerfect).length;
    final perfectBonus =
        (perfectCount * GameConstants.perfectBonusPerObject).round();

    // Fakes never appeared in the scene: every one that was put down costs
    // points and also rules out the flawless bonus.
    final fakePlacedCount = fakes.where((f) => f.isPlaced).length;
    final fakePenalty =
        (fakePlacedCount * GameConstants.fakePenaltyPerObject).round();

    final isFlawless = placements.isNotEmpty &&
        perfectCount == placements.length &&
        fakePlacedCount == 0;
    final flawlessBonus = isFlawless ? GameConstants.flawlessBonus.round() : 0;

    final subtotal =
        objectScore + timeBonus + perfectBonus + flawlessBonus - fakePenalty;
    final finalScore =
        (max(0, subtotal) * config.scoreMultiplier).round();

    return ScoreResult(
      placements: placements,
      averageAccuracy: averageAccuracy,
      objectScore: objectScore,
      timeBonus: timeBonus,
      perfectBonus: perfectBonus,
      flawlessBonus: flawlessBonus,
      finalScore: finalScore,
      fakeTotal: fakes.length,
      fakePlacedCount: fakePlacedCount,
      fakePenalty: fakePenalty,
    );
  }

  static PlacementResult _evaluate(GameObject object, List<GameObject> all) {
    final placedX = object.placedX;
    final placedY = object.placedY;
    if (placedX == null || placedY == null) {
      return PlacementResult(object: object, distance: null, accuracy: 0);
    }

    final d = distance(object.targetX, object.targetY, placedX, placedY);
    var positionAccuracy = accuracyForDistance(d);

    // Island / camp: an object also counts as right when it is right
    // relative to its partner / group, even if the whole thing is shifted.
    var scoredRelative = false;
    final relative = _relativeDistance(object, all);
    if (relative != null) {
      final relativeAccuracy = accuracyForDistance(relative);
      if (relativeAccuracy > positionAccuracy) {
        positionAccuracy = relativeAccuracy;
        scoredRelative = true;
      }
    }

    // Direction: a wrong heading costs part of the position accuracy.
    var accuracy = positionAccuracy;
    double? directionAccuracy;
    int? angleErrorDegrees;
    if (object.isDirectional) {
      final errorSteps = object.angleErrorSteps;
      directionAccuracy = angleAccuracy(errorSteps, object.directionSteps);
      angleErrorDegrees = (errorSteps * 360 / object.directionSteps).round();
      accuracy = positionAccuracy *
          (1 - GameConstants.directionPenaltyWeight * (1 - directionAccuracy));
    }

    return PlacementResult(
      object: object,
      distance: d,
      accuracy: accuracy,
      positionAccuracy: positionAccuracy,
      directionAccuracy: directionAccuracy,
      angleErrorDegrees: angleErrorDegrees,
      scoredRelative: scoredRelative,
    );
  }

  /// How far the object is from where it should be *relative to* its anchor
  /// (island) or to the center of its group (camp). Null when the object has no
  /// such partner, or the partner was not placed, so only the exact spot counts.
  static double? _relativeDistance(GameObject object, List<GameObject> all) {
    final anchorId = object.anchorId;
    if (anchorId != null) {
      final anchor = all.where((o) => o.id == anchorId).firstOrNull;
      if (anchor == null || !anchor.isPlaced) return null;
      return distance(
        object.targetX - anchor.targetX,
        object.targetY - anchor.targetY,
        object.placedX! - anchor.placedX!,
        object.placedY! - anchor.placedY!,
      );
    }

    final clusterId = object.clusterId;
    if (clusterId != null) {
      final members = all.where((o) => o.clusterId == clusterId).toList();
      if (members.length < 2 || members.any((m) => !m.isPlaced)) return null;
      double mean(double Function(GameObject) value) =>
          members.fold<double>(0, (sum, m) => sum + value(m)) / members.length;
      final targetCenterX = mean((m) => m.targetX);
      final targetCenterY = mean((m) => m.targetY);
      final placedCenterX = mean((m) => m.placedX!);
      final placedCenterY = mean((m) => m.placedY!);
      return distance(
        object.targetX - targetCenterX,
        object.targetY - targetCenterY,
        object.placedX! - placedCenterX,
        object.placedY! - placedCenterY,
      );
    }

    return null;
  }
}
