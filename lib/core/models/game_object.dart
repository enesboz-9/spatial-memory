import 'dart:math' show min, pi;

import 'package:flutter/widgets.dart';

/// Static description of an object type (what it is and how it looks).
///
/// Phase 1 uses Material icons as placeholder art. Swap [icon] for an asset
/// path once the illustrations exist.
class ObjectDefinition {
  const ObjectDefinition({
    required this.id,
    required this.label,
    required this.icon,
    this.isDirectional = false,
    this.tint,
  });

  /// Unique inside an environment. Objects that share an icon (for example the
  /// colored bottles) still need different ids.
  final String id;
  final String label;
  final IconData icon;

  /// Whether this object's heading matters (antenna, vehicle...). The number
  /// of possible headings comes from the environment.
  final bool isDirectional;

  /// Color that distinguishes this object from same-shaped ones (lab bottles).
  final Color? tint;
}

/// One object in a running game: its real position and where the player put it.
///
/// Coordinates are normalized (0.0 - 1.0) so the layout is identical on every
/// screen size.
class GameObject {
  GameObject({
    required this.definition,
    required this.targetX,
    required this.targetY,
    this.directionSteps = 0,
    this.targetAngleStep = 0,
    this.anchorId,
    this.clusterId,
  });

  final ObjectDefinition definition;
  final double targetX;
  final double targetY;

  /// Number of distinct headings (e.g. 8 = every 45 degrees). 0 means the
  /// heading of this object does not matter.
  final int directionSteps;

  /// Real heading, as a step index (0 = pointing up, clockwise).
  final int targetAngleStep;

  /// Island: id of the object this one is positioned relative to.
  final String? anchorId;

  /// Camp: objects with the same cluster id belong together.
  final int? clusterId;

  double? placedX;
  double? placedY;

  /// Heading chosen by the player (starts pointing up).
  int placedAngleStep = 0;

  String get id => definition.id;
  bool get isPlaced => placedX != null && placedY != null;
  bool get isDirectional => directionSteps > 0;

  /// Radians, clockwise from "up" (matches Flutter's Transform.rotate).
  double get targetAngle => _radians(targetAngleStep);
  double get placedAngle => _radians(placedAngleStep);

  /// How many steps the placed heading is away from the real one (0 to
  /// directionSteps / 2, measured the short way around).
  int get angleErrorSteps {
    if (!isDirectional) return 0;
    final diff = (placedAngleStep - targetAngleStep).abs() % directionSteps;
    return min(diff, directionSteps - diff);
  }

  /// Turns the placed object to its next heading.
  void rotate() {
    if (!isDirectional) return;
    placedAngleStep = (placedAngleStep + 1) % directionSteps;
  }

  double _radians(int step) =>
      directionSteps == 0 ? 0 : 2 * pi * step / directionSteps;
}

/// A decoy. It looks like a real object and waits in the tray, but it was
/// never part of the scene, so putting it down costs points.
///
/// Fakes have no target position. A directional fake is turned like a real
/// one, so it cannot be told apart by its arrow.
class FakeObject {
  FakeObject({required this.definition, this.directionSteps = 0});

  final ObjectDefinition definition;

  /// Number of distinct headings, 0 when the heading does not matter.
  final int directionSteps;

  double? placedX;
  double? placedY;

  /// Heading chosen by the player (starts pointing up).
  int placedAngleStep = 0;

  String get id => definition.id;
  bool get isPlaced => placedX != null && placedY != null;
  bool get isDirectional => directionSteps > 0;

  /// Radians, clockwise from "up".
  double get placedAngle =>
      directionSteps == 0 ? 0 : 2 * pi * placedAngleStep / directionSteps;

  void rotate() {
    if (!isDirectional) return;
    placedAngleStep = (placedAngleStep + 1) % directionSteps;
  }
}
