import 'dart:math' show min;

import '../../core/constants/game_constants.dart';
import '../../core/models/game_config.dart';

/// Normal levels add 2 objects per step (5, 7, 9, 11, 13). Headings start at
/// Hard, fake objects at Hard as well.
///
/// Every environment pool must hold at least [GameConfigs.requiredPoolSize]
/// objects (real objects + fakes of the biggest level, survival included).
/// Random placement stays
/// reliable up to about 15 real objects with the current minimum object
/// distance. Raise the counts only together with both.
///
/// All levels share the same timers (see [GameConstants]); difficulty comes
/// from the object count, rotation, fake objects and the score multiplier.
abstract final class GameConfigs {
  static const GameConfig easy = GameConfig(
    id: 'easy',
    name: 'Easy',
    objectCount: 5,
    memorizeSeconds: GameConstants.defaultMemorizeSeconds,
    placementSeconds: GameConstants.defaultPlacementSeconds,
    scoreMultiplier: 1.0,
    rotationEnabled: false,
  );

  static const GameConfig medium = GameConfig(
    id: 'medium',
    name: 'Medium',
    objectCount: 7,
    memorizeSeconds: GameConstants.defaultMemorizeSeconds,
    placementSeconds: GameConstants.defaultPlacementSeconds,
    scoreMultiplier: 1.5,
    rotationEnabled: false,
  );

  static const GameConfig hard = GameConfig(
    id: 'hard',
    name: 'Hard',
    objectCount: 9,
    memorizeSeconds: GameConstants.defaultMemorizeSeconds,
    placementSeconds: GameConstants.defaultPlacementSeconds,
    scoreMultiplier: 2.0,
    rotationEnabled: true,
    fakeCount: 1,
  );

  static const GameConfig expert = GameConfig(
    id: 'expert',
    name: 'Expert',
    objectCount: 11,
    memorizeSeconds: GameConstants.defaultMemorizeSeconds,
    placementSeconds: GameConstants.defaultPlacementSeconds,
    scoreMultiplier: 2.5,
    rotationEnabled: true,
    fakeCount: 2,
  );

  static const GameConfig extreme = GameConfig(
    id: 'extreme',
    name: 'Extreme',
    objectCount: 13,
    memorizeSeconds: GameConstants.defaultMemorizeSeconds,
    placementSeconds: GameConstants.defaultPlacementSeconds,
    scoreMultiplier: 3.0,
    rotationEnabled: true,
    fakeCount: 3,
  );

  /// Tiny, untimed round used by the first-launch tutorial.
  static const GameConfig tutorial = GameConfig(
    id: 'tutorial',
    name: 'Tutorial',
    objectCount: 3,
    memorizeSeconds: 0,
    placementSeconds: 0,
    scoreMultiplier: 1.0,
    rotationEnabled: true,
    fakeCount: 1,
    timed: false,
  );

  /// Objects and rotated objects of survival round [round] (1-based).
  ///
  /// [rotatable] is how many objects of the environment can turn (see
  /// `Environment.rotatableCount`); 0 means the environment has no headings,
  /// so rotation steps are skipped and every round just adds an object.
  ///
  /// 1. Rounds 1-5: 1, 2, 3, 4, 5 objects, nothing turns.
  /// 2. Next 5 rounds: 5 objects with 1, 2, 3, 4, 5 of them turning.
  /// 3. After that every round either adds an object or makes one more object
  ///    turn, alternating (object first). When one of the two is not possible
  ///    any more (object limit, or every object already turns) the other one
  ///    is used. At the limit of both the round stays the same.
  static ({int objects, int rotated}) survivalStage(
    int round, {
    int rotatable = 0,
  }) {
    const ramp = GameConstants.survivalRampObjects;
    const maxObjects = GameConstants.survivalMaxObjects;
    var objects = GameConstants.survivalStartObjects;
    var rotated = 0;
    var preferObject = true;

    bool canAddObject() => objects < maxObjects;
    bool canRotate() => rotated < min(objects, rotatable);

    for (var step = 1; step < round; step++) {
      if (objects < ramp) {
        objects++;
      } else if (rotated < min(ramp, rotatable)) {
        rotated++;
      } else {
        final addObject =
            preferObject ? canAddObject() : !canRotate() && canAddObject();
        if (addObject) {
          objects++;
        } else if (canRotate()) {
          rotated++;
        }
        preferObject = !preferObject;
      }
    }
    return (objects: objects, rotated: rotated);
  }

  /// Survival round [round] (1-based). See [survivalStage] for the ramp.
  /// Fakes switch on at the same object counts as the normal levels.
  static GameConfig survivalRound(int round, {int rotatable = 0}) {
    final stage = survivalStage(round, rotatable: rotatable);
    final objects = stage.objects;
    return GameConfig(
      id: 'survival',
      name: 'Survival',
      objectCount: objects,
      memorizeSeconds: GameConstants.defaultMemorizeSeconds,
      placementSeconds: GameConstants.defaultPlacementSeconds,
      scoreMultiplier: min(
        1 + GameConstants.survivalMultiplierStep * (round - 1),
        GameConstants.survivalMaxMultiplier,
      ),
      rotationEnabled: stage.rotated > 0,
      rotatedObjects: stage.rotated,
      fakeCount: objects >= extreme.objectCount
          ? 3
          : objects >= expert.objectCount
              ? 2
              : objects >= hard.objectCount
                  ? 1
                  : 0,
    );
  }

  static const List<GameConfig> all = [easy, medium, hard, expert, extreme];

  /// Objects an environment pool needs: survival tops out at 15 real objects
  /// + 3 fakes (the biggest normal level, Extreme, is 13 + 3).
  static const int requiredPoolSize = 18;
}
