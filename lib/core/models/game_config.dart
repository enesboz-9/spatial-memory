/// Difficulty settings. Never hard-code these values elsewhere.
class GameConfig {
  const GameConfig({
    required this.id,
    required this.name,
    required this.objectCount,
    required this.memorizeSeconds,
    required this.placementSeconds,
    required this.scoreMultiplier,
    required this.rotationEnabled,
    this.fakeCount = 0,
    this.timed = true,
    this.rotatedObjects,
  });

  final String id;
  final String name;
  final int objectCount;
  final int memorizeSeconds;
  final int placementSeconds;
  final double scoreMultiplier;

  /// Whether directional objects (antenna, vehicles...) have a heading that
  /// must be remembered and restored. Off on Easy and Medium, on from Hard.
  final bool rotationEnabled;

  /// Decoy objects mixed into the tray (never shown while memorizing).
  /// 0 on Easy and Medium.
  final int fakeCount;

  /// How many directional objects actually turn. Null means every directional
  /// object of the level (normal levels); survival raises it step by step.
  /// Only meaningful while [rotationEnabled] is true.
  final int? rotatedObjects;

  /// False for the tutorial: no countdowns, the player moves on by button.
  final bool timed;

  @override
  bool operator ==(Object other) => other is GameConfig && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
