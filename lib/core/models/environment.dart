import 'package:flutter/widgets.dart';

import 'game_config.dart';
import 'game_object.dart';

/// The twist that makes an environment play differently from the others.
enum EnvironmentMechanic {
  /// Some objects have a heading that must be remembered and restored.
  direction,

  /// Some objects stand at a set distance from another object.
  relative,

  /// Same-shaped objects are told apart by their color only.
  color,

  /// Some objects belong together and stand close to each other.
  cluster,
}

/// Which backdrop an environment draws.
enum BackgroundStyle { stars, sea, laboratory, streets, meadow }

/// Island: [childId] stands at a fixed distance from [anchorId].
class RelationPair {
  const RelationPair({required this.anchorId, required this.childId});

  final String anchorId;
  final String childId;
}

class Environment {
  const Environment({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.background,
    required this.objectPool,
    required this.mechanic,
    required this.ruleHint,
    required this.placeHint,
    this.directionSteps = 0,
    this.relationPairs = const [],
    this.clusters = const [],
  });

  final String id;
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final BackgroundStyle background;

  /// All objects that can appear here; each game draws a random subset.
  final List<ObjectDefinition> objectPool;

  final EnvironmentMechanic mechanic;

  /// Short rule shown while memorizing / while placing.
  final String ruleHint;
  final String placeHint;

  /// Direction: number of distinct headings of a directional object.
  final int directionSteps;

  /// Island: object pairs that can be generated.
  final List<RelationPair> relationPairs;

  /// Camp: object ids that belong together.
  final List<List<String>> clusters;

  /// Background music loop, relative to `assets/` (see tools/generate_music.py).
  String get musicAsset => 'music/$id.wav';

  /// How many objects of the pool can be turned (0 when the environment has
  /// no headings). Survival never rotates more objects than this.
  int get rotatableCount => directionSteps > 0
      ? objectPool.where((definition) => definition.isDirectional).length
      : 0;

  /// Rule text for [config]. Rotation only exists from Hard on (and in the
  /// later survival rounds), so on easier levels a direction environment is a
  /// plain position game.
  String ruleHintFor(GameConfig config) {
    if (mechanic != EnvironmentMechanic.direction || config.rotationEnabled) {
      return ruleHint;
    }
    return config.id == 'survival'
        ? 'Remember where each object stands. Turning objects comes later.'
        : 'Remember where each object stands. Turning objects starts at Hard.';
  }

  String placeHintFor(GameConfig config) =>
      mechanic == EnvironmentMechanic.direction && !config.rotationEnabled
          ? 'Drag each object back to its spot.'
          : placeHint;

  ObjectDefinition definitionById(String id) =>
      objectPool.firstWhere((definition) => definition.id == id);
}
