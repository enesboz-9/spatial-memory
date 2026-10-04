import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_memory/core/constants/game_constants.dart';
import 'package:spatial_memory/core/l10n/app_language.dart';
import 'package:spatial_memory/core/l10n/app_strings.dart';
import 'package:spatial_memory/core/models/environment.dart';
import 'package:spatial_memory/core/models/game_object.dart';
import 'package:spatial_memory/core/models/score_result.dart';
import 'package:spatial_memory/core/utils/format.dart';
import 'package:spatial_memory/core/utils/hint_builder.dart';
import 'package:spatial_memory/core/utils/level_generator.dart';
import 'package:spatial_memory/core/utils/score_calculator.dart';
import 'package:spatial_memory/data/environments/environments.dart';
import 'package:spatial_memory/data/game_configs/game_configs.dart';
import 'package:spatial_memory/features/game/game_controller.dart';

void main() {
  group('ScoreCalculator', () {
    test('distance is Euclidean', () {
      expect(ScoreCalculator.distance(0, 0, 0.3, 0.4), closeTo(0.5, 1e-9));
    });

    test('accuracy: perfect inside radius, zero at max distance', () {
      expect(ScoreCalculator.accuracyForDistance(0), 1);
      expect(ScoreCalculator.accuracyForDistance(GameConstants.perfectRadius), 1);
      expect(
        ScoreCalculator.accuracyForDistance(GameConstants.maxAccuracyDistance),
        0,
      );
      expect(ScoreCalculator.accuracyForDistance(0.9), 0);
    });

    test('accuracy decreases as distance grows', () {
      final near = ScoreCalculator.accuracyForDistance(0.08);
      final far = ScoreCalculator.accuracyForDistance(0.2);
      expect(near, greaterThan(far));
    });

    test('unplaced objects count as zero accuracy', () {
      final placed = GameObject(
        definition: Environments.spaceStation.objectPool[0],
        targetX: 0.3,
        targetY: 0.3,
      )
        ..placedX = 0.3
        ..placedY = 0.3;
      final unplaced = GameObject(
        definition: Environments.spaceStation.objectPool[1],
        targetX: 0.7,
        targetY: 0.7,
      );

      final result = ScoreCalculator.calculate(
        objects: [placed, unplaced],
        config: GameConfigs.easy,
        remainingSeconds: 30,
      );

      expect(result.averageAccuracy, closeTo(0.5, 1e-9));
      expect(result.placedCount, 1);
    });

    test('placing nothing scores zero, even with time left', () {
      final object = GameObject(
        definition: Environments.spaceStation.objectPool[0],
        targetX: 0.5,
        targetY: 0.5,
      );
      final result = ScoreCalculator.calculate(
        objects: [object],
        config: GameConfigs.easy,
        remainingSeconds: 60,
      );
      expect(result.finalScore, 0);
    });

    test('difficulty multiplier scales the final score', () {
      GameObject perfect() => GameObject(
            definition: Environments.spaceStation.objectPool[0],
            targetX: 0.5,
            targetY: 0.5,
          )
            ..placedX = 0.5
            ..placedY = 0.5;

      final easy = ScoreCalculator.calculate(
        objects: [perfect()],
        config: GameConfigs.easy,
        remainingSeconds: 0,
      );
      final medium = ScoreCalculator.calculate(
        objects: [perfect()],
        config: GameConfigs.medium,
        remainingSeconds: 0,
      );
      expect(medium.finalScore, (easy.finalScore * 1.5).round());
    });
  });

  group('LevelGenerator', () {
    test('same seed gives the same level', () {
      final a = LevelGenerator.generate(
        environment: Environments.spaceStation,
        config: GameConfigs.easy,
        seed: 42,
      );
      final b = LevelGenerator.generate(
        environment: Environments.spaceStation,
        config: GameConfigs.easy,
        seed: 42,
      );
      expect(a.map((o) => o.id), b.map((o) => o.id));
      expect(a.map((o) => o.targetX), b.map((o) => o.targetX));
      expect(a.map((o) => o.targetY), b.map((o) => o.targetY));
    });

    test('objects respect minimum distance and stay inside the area', () {
      for (final environment in Environments.all) {
        for (final config in GameConfigs.all) {
          for (var seed = 0; seed < 100; seed++) {
            final objects = LevelGenerator.generate(
              environment: environment,
              config: config,
              seed: seed,
            );
            expect(objects.length, config.objectCount);
            expect(objects.map((o) => o.id).toSet().length, objects.length);
            for (var i = 0; i < objects.length; i++) {
              expect(objects[i].targetX, inInclusiveRange(0, 1));
              expect(objects[i].targetY, inInclusiveRange(0, 1));
              for (var j = i + 1; j < objects.length; j++) {
                final d = ScoreCalculator.distance(
                  objects[i].targetX,
                  objects[i].targetY,
                  objects[j].targetX,
                  objects[j].targetY,
                );
                expect(
                  d,
                  greaterThanOrEqualTo(GameConstants.minimumObjectDistance),
                );
              }
            }
          }
        }
      }
    });

    test('same seed gives the same level in every environment', () {
      for (final environment in Environments.all) {
        final a = LevelGenerator.generate(
          environment: environment,
          config: GameConfigs.medium,
          seed: 7,
        );
        final b = LevelGenerator.generate(
          environment: environment,
          config: GameConfigs.medium,
          seed: 7,
        );
        expect(a.map((o) => o.id), b.map((o) => o.id));
        expect(a.map((o) => o.targetX), b.map((o) => o.targetX));
        expect(a.map((o) => o.targetAngleStep), b.map((o) => o.targetAngleStep));
        expect(a.map((o) => o.anchorId), b.map((o) => o.anchorId));
        expect(a.map((o) => o.clusterId), b.map((o) => o.clusterId));
      }
    });

    test('falls back to a grid when random placement cannot succeed', () {
      // 40 objects can never fit with the minimum distance, so the generator
      // must return a layout anyway instead of looping or throwing.
      final positions =
          LevelGenerator.generatePositions(count: 40, random: Random(1));
      expect(positions.length, 40);
    });
  });

  group('Perfect Memory', () {
    GameObject objectAt(double offset) => GameObject(
          definition: Environments.spaceStation.objectPool[0],
          targetX: 0.5,
          targetY: 0.5,
        )
          ..placedX = 0.5 + offset
          ..placedY = 0.5;

    PlacementResult evaluate(GameObject object) => ScoreCalculator.calculate(
          objects: [object],
          config: GameConfigs.easy,
          remainingSeconds: 0,
        ).placements.single;

    test('98% accuracy and above is PERFECT', () {
      expect(evaluate(objectAt(0)).isPerfect, isTrue);
      // 0.034 away: accuracy is about 98.5%.
      final close = evaluate(objectAt(0.034));
      expect(close.accuracy, greaterThanOrEqualTo(0.98));
      expect(close.isPerfect, isTrue);
    });

    test('just below 98% is not PERFECT', () {
      // 0.04 away: accuracy is about 96%.
      final result = evaluate(objectAt(0.04));
      expect(result.accuracy, lessThan(0.98));
      expect(result.isPerfect, isFalse);
    });

    test('an unplaced object is never PERFECT', () {
      final object = GameObject(
        definition: Environments.spaceStation.objectPool[0],
        targetX: 0.5,
        targetY: 0.5,
      );
      expect(evaluate(object).isPerfect, isFalse);
    });

    test('perfect bonus is paid per object, flawless only when all are', () {
      GameObject exact() => objectAt(0);
      GameObject off() => objectAt(0.2);

      final mixed = ScoreCalculator.calculate(
        objects: [exact(), off()],
        config: GameConfigs.easy,
        remainingSeconds: 0,
      );
      expect(mixed.perfectCount, 1);
      expect(mixed.perfectBonus, GameConstants.perfectBonusPerObject.round());
      expect(mixed.isFlawless, isFalse);
      expect(mixed.flawlessBonus, 0);

      final flawless = ScoreCalculator.calculate(
        objects: [exact(), exact()],
        config: GameConfigs.easy,
        remainingSeconds: 0,
      );
      expect(flawless.perfectCount, 2);
      expect(flawless.isFlawless, isTrue);
      expect(flawless.flawlessBonus, GameConstants.flawlessBonus.round());
      expect(
        flawless.finalScore,
        flawless.objectScore +
            flawless.timeBonus +
            flawless.perfectBonus +
            flawless.flawlessBonus,
      );
    });
  });

  group('Direction (space station, city)', () {
    GameObject antenna({required int target, required int placed}) =>
        GameObject(
          definition: Environments.spaceStation.definitionById('antenna'),
          targetX: 0.5,
          targetY: 0.5,
          directionSteps: 8,
          targetAngleStep: target,
        )
          ..placedX = 0.5
          ..placedY = 0.5
          ..placedAngleStep = placed;

    PlacementResult evaluate(GameObject object) => ScoreCalculator.calculate(
          objects: [object],
          config: GameConfigs.easy,
          remainingSeconds: 0,
        ).placements.single;

    test('exact position and heading is 100% and PERFECT', () {
      final result = evaluate(antenna(target: 2, placed: 2));
      expect(result.accuracy, 1);
      expect(result.isPerfect, isTrue);
      expect(result.angleErrorDegrees, 0);
    });

    test('a heading one step off costs accuracy and the PERFECT label', () {
      final result = evaluate(antenna(target: 2, placed: 3));
      expect(result.directionAccuracy, closeTo(0.75, 1e-9));
      expect(result.angleErrorDegrees, 45);
      expect(result.accuracy, closeTo(0.9, 1e-9));
      expect(result.isPerfect, isFalse);
    });

    test('the opposite heading keeps only the non-penalized share', () {
      final result = evaluate(antenna(target: 0, placed: 4));
      expect(result.directionAccuracy, 0);
      expect(result.angleErrorDegrees, 180);
      expect(
        result.accuracy,
        closeTo(1 - GameConstants.directionPenaltyWeight, 1e-9),
      );
    });

    test('heading error is measured the short way around', () {
      expect(antenna(target: 0, placed: 7).angleErrorSteps, 1);
      expect(antenna(target: 7, placed: 0).angleErrorSteps, 1);
      expect(antenna(target: 1, placed: 6).angleErrorSteps, 3);
    });

    test('rotate() cycles through every heading and wraps around', () {
      final object = antenna(target: 0, placed: 0);
      for (var i = 0; i < 8; i++) {
        object.rotate();
      }
      expect(object.placedAngleStep, 0);
      object.rotate();
      expect(object.placedAngleStep, 1);
    });

    test('non-directional objects ignore headings', () {
      final object = GameObject(
        definition: Environments.spaceStation.definitionById('book'),
        targetX: 0.5,
        targetY: 0.5,
      )
        ..placedX = 0.5
        ..placedY = 0.5;
      object.rotate();
      expect(object.placedAngleStep, 0);
      final result = evaluate(object);
      expect(result.directionAccuracy, isNull);
      expect(result.accuracy, 1);
    });

    test('levels always contain directional objects with valid headings', () {
      for (final environment in [Environments.spaceStation, Environments.city]) {
        for (var seed = 0; seed < 100; seed++) {
          final objects = LevelGenerator.generate(
            environment: environment,
            config: GameConfigs.hard,
            seed: seed,
          );
          final directional = objects.where((o) => o.isDirectional).toList();
          expect(
            directional.length,
            greaterThanOrEqualTo(GameConstants.minDirectionalObjects),
          );
          for (final object in objects) {
            expect(object.definition.isDirectional, object.isDirectional);
            if (object.isDirectional) {
              expect(object.directionSteps, environment.directionSteps);
              expect(object.targetAngleStep, inInclusiveRange(0, object.directionSteps - 1));
            }
          }
        }
      }
    });
  });

  group('Difficulty levels', () {
    test('rotation is off on Easy and Medium and on from Hard', () {
      expect(GameConfigs.easy.rotationEnabled, isFalse);
      expect(GameConfigs.medium.rotationEnabled, isFalse);
      for (final config in GameConfigs.all.skip(2)) {
        expect(config.rotationEnabled, isTrue, reason: config.id);
      }
    });

    test('Easy levels have no headings, even in direction environments', () {
      for (final environment in [Environments.spaceStation, Environments.city]) {
        for (var seed = 0; seed < 100; seed++) {
          final objects = LevelGenerator.generate(
            environment: environment,
            config: GameConfigs.easy,
            seed: seed,
          );
          for (final object in objects) {
            expect(object.isDirectional, isFalse);
            expect(object.directionSteps, 0);
            expect(object.targetAngleStep, 0);
          }
        }
      }
    });

    test('Easy and Medium hints do not promise rotation, Hard hints do', () {
      for (final config in [GameConfigs.easy, GameConfigs.medium]) {
        expect(
          Environments.spaceStation.ruleHintFor(config),
          contains('Hard'),
        );
      }
      expect(
        Environments.spaceStation.ruleHintFor(GameConfigs.hard),
        Environments.spaceStation.ruleHint,
      );
      expect(
        Environments.island.ruleHintFor(GameConfigs.easy),
        Environments.island.ruleHint,
      );
    });

    test('normal levels add 2 objects per step', () {
      expect(
        GameConfigs.all.map((c) => c.objectCount).toList(),
        [5, 7, 9, 11, 13],
      );
    });

    test('levels get harder step by step', () {
      final configs = GameConfigs.all;
      for (var i = 1; i < configs.length; i++) {
        expect(configs[i].objectCount, greaterThan(configs[i - 1].objectCount));
        expect(
          configs[i].scoreMultiplier,
          greaterThan(configs[i - 1].scoreMultiplier),
        );
        expect(
          configs[i].fakeCount,
          greaterThanOrEqualTo(configs[i - 1].fakeCount),
        );
      }
      expect(configs.map((c) => c.id).toSet().length, configs.length);
    });

    test('every level has 30 s to memorize and 60 s to place', () {
      for (final config in GameConfigs.all) {
        expect(config.memorizeSeconds, 30, reason: config.id);
        expect(config.placementSeconds, 60, reason: config.id);
      }
    });

    test('fake objects: none before Hard, then 1 / 2 / 3', () {
      expect(GameConfigs.easy.fakeCount, 0);
      expect(GameConfigs.medium.fakeCount, 0);
      expect(GameConfigs.hard.fakeCount, 1);
      expect(GameConfigs.expert.fakeCount, 2);
      expect(GameConfigs.extreme.fakeCount, 3);
    });

    test('every environment pool fits the biggest level', () {
      // Survival goes further than the normal levels, so the pool size is
      // set by it (15 objects + 3 fakes).
      expect(
        GameConfigs.all.map((c) => c.objectCount + c.fakeCount).reduce(max),
        lessThanOrEqualTo(GameConfigs.requiredPoolSize),
      );
      for (final environment in Environments.all) {
        expect(
          environment.objectPool.length,
          greaterThanOrEqualTo(GameConfigs.requiredPoolSize),
          reason: environment.id,
        );
        final ids = environment.objectPool.map((d) => d.id);
        expect(ids.toSet().length, ids.length, reason: environment.id);
      }
    });

    test('mechanics survive the biggest level in every environment', () {
      for (var seed = 0; seed < 100; seed++) {
        for (final environment in Environments.all) {
          final objects = LevelGenerator.generate(
            environment: environment,
            config: GameConfigs.extreme,
            seed: seed,
          );
          switch (environment.mechanic) {
            case EnvironmentMechanic.direction:
              expect(objects.where((o) => o.isDirectional).length,
                  greaterThanOrEqualTo(GameConstants.minDirectionalObjects));
            case EnvironmentMechanic.relative:
              expect(objects.where((o) => o.anchorId != null), isNotEmpty);
            case EnvironmentMechanic.color:
              expect(objects.where((o) => o.definition.tint != null).length, 3);
            case EnvironmentMechanic.cluster:
              expect(objects.where((o) => o.clusterId != null), isNotEmpty);
          }
        }
      }
    });
  });

  group('Relative positions (island)', () {
    GameObject chest({required double x, required double y}) => GameObject(
          definition: Environments.island.definitionById('treasure_chest'),
          targetX: 0.5,
          targetY: 0.3,
          anchorId: 'palm_tree',
        )
          ..placedX = x
          ..placedY = y;

    GameObject tree({double? x, double? y}) => GameObject(
          definition: Environments.island.definitionById('palm_tree'),
          targetX: 0.3,
          targetY: 0.3,
        )
          ..placedX = x
          ..placedY = y;

    List<PlacementResult> score(List<GameObject> objects) =>
        ScoreCalculator.calculate(
          objects: objects,
          config: GameConfigs.easy,
          remainingSeconds: 0,
        ).placements;

    test('partner scores by distance to its anchor when that is better', () {
      // Both placed (+0.1, +0.2) away from the truth: the chest is still
      // exactly 2 m right of the tree.
      final results = score([
        tree(x: 0.4, y: 0.5),
        chest(x: 0.6, y: 0.5),
      ]);
      final treeResult = results[0];
      final chestResult = results[1];
      expect(chestResult.accuracy, 1);
      expect(chestResult.scoredRelative, isTrue);
      expect(chestResult.isPerfect, isTrue);
      expect(treeResult.accuracy, lessThan(0.5));
    });

    test('without a placed anchor only the exact spot counts', () {
      final results = score([
        tree(),
        chest(x: 0.6, y: 0.5),
      ]);
      expect(results[1].scoredRelative, isFalse);
      expect(results[1].accuracy, lessThan(0.5));
    });

    test('exact spot still scores when the relation is wrong', () {
      final results = score([
        tree(x: 0.8, y: 0.8),
        chest(x: 0.5, y: 0.3),
      ]);
      expect(results[1].accuracy, 1);
      expect(results[1].scoredRelative, isFalse);
    });

    test('generated pairs are axis-aligned, 2 or 3 m apart', () {
      for (var seed = 0; seed < 100; seed++) {
        final objects = LevelGenerator.generate(
          environment: Environments.island,
          config: GameConfigs.hard,
          seed: seed,
        );
        final children = objects.where((o) => o.anchorId != null).toList();
        expect(children.length, 2);
        for (final child in children) {
          final anchor = objects.singleWhere((o) => o.id == child.anchorId);
          final dx = (child.targetX - anchor.targetX).abs();
          final dy = (child.targetY - anchor.targetY).abs();
          expect(dx < 1e-9 || dy < 1e-9, isTrue);
          final meters = (dx + dy) * GameConstants.islandSideMeters;
          expect(GameConstants.relationMeters.any((m) => (m - meters).abs() < 1e-9), isTrue);
        }
      }
    });

    test('memorize hint names the real distance and side', () {
      final objects = LevelGenerator.generate(
        environment: Environments.island,
        config: GameConfigs.easy,
        seed: 3,
      );
      final hints = HintBuilder.memorizeHints(Environments.island, objects);
      expect(hints.length, 1);
      expect(
        hints.single,
        matches(
          RegExp(
            r'^The .+ is \d(\.\d)? m (to the right of|to the left of|below|above) the .+\.$',
          ),
        ),
      );
    });

    test('formatMeters rounds to half meters', () {
      expect(formatMeters(0.2), '2 m');
      expect(formatMeters(0.3), '3 m');
      expect(formatMeters(0.25), '2.5 m');
    });
  });

  group('Color (laboratory)', () {
    test('same-shaped bottles differ only by color and id', () {
      final bottles = Environments.laboratory.objectPool
          .where((d) => d.tint != null)
          .toList();
      expect(bottles.length, 3);
      expect(bottles.map((d) => d.icon.codePoint).toSet().length, 1);
      expect(bottles.map((d) => d.tint).toSet().length, 3);
      expect(bottles.map((d) => d.id).toSet().length, 3);
    });

    test('every level contains all three bottles', () {
      for (final config in GameConfigs.all) {
        for (var seed = 0; seed < 100; seed++) {
          final objects = LevelGenerator.generate(
            environment: Environments.laboratory,
            config: config,
            seed: seed,
          );
          expect(objects.where((o) => o.definition.tint != null).length, 3);
        }
      }
    });

    test('swapping two bottles is punished', () {
      final red = GameObject(
        definition: Environments.laboratory.definitionById('bottle_red'),
        targetX: 0.3,
        targetY: 0.3,
      )
        ..placedX = 0.7
        ..placedY = 0.7;
      final blue = GameObject(
        definition: Environments.laboratory.definitionById('bottle_blue'),
        targetX: 0.7,
        targetY: 0.7,
      )
        ..placedX = 0.3
        ..placedY = 0.3;
      final result = ScoreCalculator.calculate(
        objects: [red, blue],
        config: GameConfigs.easy,
        remainingSeconds: 0,
      );
      expect(result.averageAccuracy, 0);
    });
  });

  group('Groups (camp)', () {
    GameObject member(String id, double x, double y, {double dx = 0, double dy = 0, bool placed = true}) {
      final object = GameObject(
        definition: Environments.camp.definitionById(id),
        targetX: x,
        targetY: y,
        clusterId: 0,
      );
      if (placed) {
        object
          ..placedX = x + dx
          ..placedY = y + dy;
      }
      return object;
    }

    List<PlacementResult> score(List<GameObject> objects) =>
        ScoreCalculator.calculate(
          objects: objects,
          config: GameConfigs.easy,
          remainingSeconds: 0,
        ).placements;

    test('a group kept together scores fully even when shifted', () {
      final results = score([
        member('tent', 0.3, 0.3, dx: 0.2, dy: 0.1),
        member('backpack', 0.5, 0.3, dx: 0.2, dy: 0.1),
        member('flashlight', 0.4, 0.47, dx: 0.2, dy: 0.1),
      ]);
      for (final result in results) {
        expect(result.accuracy, 1);
        expect(result.scoredRelative, isTrue);
      }
    });

    test('a group that was pulled apart does not', () {
      final results = score([
        member('tent', 0.3, 0.3),
        member('backpack', 0.5, 0.3, dx: 0.25),
        member('flashlight', 0.4, 0.47),
      ]);
      expect(results[1].accuracy, lessThan(0.9));
    });

    test('an unplaced member means only exact spots count', () {
      final results = score([
        member('tent', 0.3, 0.3, dx: 0.2),
        member('backpack', 0.5, 0.3, dx: 0.2),
        member('flashlight', 0.4, 0.47, placed: false),
      ]);
      expect(results[0].scoredRelative, isFalse);
      expect(results[0].accuracy, lessThan(0.5));
    });

    test('generated groups keep their members close together', () {
      for (var seed = 0; seed < 100; seed++) {
        final objects = LevelGenerator.generate(
          environment: Environments.camp,
          config: GameConfigs.hard,
          seed: seed,
        );
        final groups = <int, List<GameObject>>{};
        for (final object in objects) {
          final id = object.clusterId;
          if (id != null) (groups[id] ??= []).add(object);
        }
        expect(groups.length, 2);
        for (final members in groups.values) {
          expect(members.length, 3);
          for (final a in members) {
            for (final b in members) {
              final d = ScoreCalculator.distance(a.targetX, a.targetY, b.targetX, b.targetY);
              expect(d, lessThan(2 * GameConstants.clusterRadius + 1e-9));
            }
          }
        }
      }
    });

    test('memorize hint lists the members of each group', () {
      final objects = LevelGenerator.generate(
        environment: Environments.camp,
        config: GameConfigs.easy,
        seed: 5,
      );
      final hints = HintBuilder.memorizeHints(Environments.camp, objects);
      expect(hints.length, 1);
      expect(hints.single, contains('close together'));
    });
  });

  group('Fake objects', () {
    test('each level gets its number of fakes, never a real object', () {
      for (final environment in Environments.all) {
        for (final config in GameConfigs.all) {
          for (var seed = 0; seed < 50; seed++) {
            final objects = LevelGenerator.generate(
              environment: environment,
              config: config,
              seed: seed,
            );
            final fakes = LevelGenerator.generateFakes(
              environment: environment,
              config: config,
              objects: objects,
              seed: seed,
            );
            expect(fakes.length, config.fakeCount, reason: config.id);
            final realIds = objects.map((o) => o.id).toSet();
            final fakeIds = fakes.map((f) => f.id).toSet();
            expect(fakeIds.length, fakes.length);
            expect(fakeIds.intersection(realIds), isEmpty);
            for (final fake in fakes) {
              expect(fake.isPlaced, isFalse);
              expect(
                fake.directionSteps,
                fake.definition.isDirectional ? environment.directionSteps : 0,
              );
            }
          }
        }
      }
    });

    test('same seed gives the same fakes', () {
      List<String> fakeIds() {
        final objects = LevelGenerator.generate(
          environment: Environments.city,
          config: GameConfigs.extreme,
          seed: 11,
        );
        return LevelGenerator.generateFakes(
          environment: Environments.city,
          config: GameConfigs.extreme,
          objects: objects,
          seed: 11,
        ).map((f) => f.id).toList();
      }

      expect(fakeIds(), fakeIds());
    });

    test('fakes do not change the real layout', () {
      final withFakes = LevelGenerator.generate(
        environment: Environments.camp,
        config: GameConfigs.hard,
        seed: 5,
      );
      final again = LevelGenerator.generate(
        environment: Environments.camp,
        config: GameConfigs.hard,
        seed: 5,
      );
      expect(withFakes.map((o) => o.targetX), again.map((o) => o.targetX));
    });

    GameObject exact() => GameObject(
          definition: Environments.spaceStation.objectPool[0],
          targetX: 0.5,
          targetY: 0.5,
        )
          ..placedX = 0.5
          ..placedY = 0.5;

    FakeObject fake({bool placed = true}) {
      final f = FakeObject(definition: Environments.spaceStation.objectPool[1]);
      if (placed) {
        f
          ..placedX = 0.2
          ..placedY = 0.2;
      }
      return f;
    }

    test('a placed fake costs points and rules out the flawless bonus', () {
      final clean = ScoreCalculator.calculate(
        objects: [exact()],
        config: GameConfigs.hard,
        remainingSeconds: 0,
        fakes: [fake(placed: false)],
      );
      expect(clean.fakeTotal, 1);
      expect(clean.fakePlacedCount, 0);
      expect(clean.fakeAvoidedCount, 1);
      expect(clean.fakePenalty, 0);
      expect(clean.isFlawless, isTrue);

      final fooled = ScoreCalculator.calculate(
        objects: [exact()],
        config: GameConfigs.hard,
        remainingSeconds: 0,
        fakes: [fake()],
      );
      expect(fooled.fakePlacedCount, 1);
      expect(
        fooled.fakePenalty,
        GameConstants.fakePenaltyPerObject.round(),
      );
      expect(fooled.isFlawless, isFalse);
      expect(fooled.flawlessBonus, 0);
      expect(fooled.finalScore, lessThan(clean.finalScore));
    });

    test('the penalty is applied before the multiplier and never goes below 0',
        () {
      final result = ScoreCalculator.calculate(
        objects: [
          GameObject(
            definition: Environments.spaceStation.objectPool[0],
            targetX: 0.5,
            targetY: 0.5,
          ),
        ],
        config: GameConfigs.extreme,
        remainingSeconds: 0,
        fakes: [fake(), fake(), fake()],
      );
      expect(result.fakePlacedCount, 3);
      expect(result.finalScore, 0);
    });

    test('scoring without fakes is unchanged', () {
      final result = ScoreCalculator.calculate(
        objects: [exact()],
        config: GameConfigs.easy,
        remainingSeconds: 0,
      );
      expect(result.fakeTotal, 0);
      expect(result.fakePenalty, 0);
    });
  });

  group('GameController', () {
    test('fakes are mixed into the tray and can be placed and scored', () {
      final controller = GameController(
        environment: Environments.spaceStation,
        config: GameConfigs.extreme,
        seed: 3,
      )..start();
      addTearDown(controller.dispose);

      controller.skipMemorize();
      expect(controller.phase, GamePhase.place);
      expect(controller.fakes.length, 3);
      expect(controller.unplacedTray.length, 15 + 3);

      final fake = controller.fakes.first;
      controller.placeObject(fake.id, 0.4, 0.4);
      expect(controller.placedFakeCount, 1);
      expect(controller.placedCount, 0);
      expect(controller.unplacedTray.length, 15 + 3 - 1);

      controller.finish();
      expect(controller.phase, GamePhase.result);
      expect(controller.score!.fakePlacedCount, 1);
    });

    test('skipMemorize moves to placement with the full placement time', () {
      final controller = GameController(
        environment: Environments.island,
        config: GameConfigs.medium,
        seed: 1,
      )..start();
      addTearDown(controller.dispose);

      expect(controller.phase, GamePhase.memorize);
      expect(controller.secondsLeft, 30);
      controller.skipMemorize();
      expect(controller.phase, GamePhase.place);
      expect(controller.secondsLeft, 60);
      expect(controller.fakes, isEmpty);

      // Skipping again (or later) does nothing.
      controller.skipMemorize();
      expect(controller.phase, GamePhase.place);
      expect(controller.secondsLeft, 60);
    });

    test('objects cannot be placed while memorizing', () {
      final controller = GameController(
        environment: Environments.city,
        config: GameConfigs.hard,
        seed: 2,
      )..start();
      addTearDown(controller.dispose);

      controller.placeObject(controller.objects.first.id, 0.5, 0.5);
      expect(controller.placedCount, 0);
    });
  });

  group('Languages', () {
    const en = AppStrings(AppLanguage.en);
    const tr = AppStrings(AppLanguage.tr);

    test('every object of every environment has a Turkish name', () {
      for (final environment in Environments.all) {
        for (final definition in environment.objectPool) {
          expect(
            AppStrings.objectLabelsTr.containsKey(definition.id),
            isTrue,
            reason: '${environment.id}/${definition.id}',
          );
          expect(tr.objectName(definition), isNotEmpty);
        }
      }
    });

    test('English keeps the original labels and names', () {
      final definition = Environments.island.definitionById('treasure_chest');
      expect(en.objectName(definition), definition.label);
      expect(
        en.environmentName(Environments.spaceStation),
        Environments.spaceStation.name,
      );
      for (final config in GameConfigs.all) {
        expect(en.difficultyName(config), config.name);
      }
    });

    test('Turkish names for environments and levels', () {
      expect(tr.environmentName(Environments.spaceStation), 'Uzay İstasyonu');
      expect(tr.environmentName(Environments.camp), 'Kamp');
      expect(tr.difficultyName(GameConfigs.medium), 'Orta');
      expect(tr.difficultyName(GameConfigs.extreme), 'Ekstrem');
      expect(tr.language.code, 'tr');
    });

    test('every environment and level has a Turkish hint', () {
      for (final environment in Environments.all) {
        for (final config in GameConfigs.all) {
          final enRule = en.ruleHint(environment, config);
          final trRule = tr.ruleHint(environment, config);
          expect(trRule, isNotEmpty);
          expect(trRule, isNot(enRule));
          expect(tr.placeHint(environment, config),
              isNot(en.placeHint(environment, config)));
        }
      }
    });

    test('Turkish hints are written from the real level', () {
      final island = LevelGenerator.generate(
        environment: Environments.island,
        config: GameConfigs.easy,
        seed: 3,
      );
      final hint =
          HintBuilder.memorizeHints(Environments.island, island, tr).single;
      expect(
        hint,
        matches(RegExp(r'^.+, .+ nesnesinin \d(\.\d)? m '
            r'(sağında|solunda|altında|üstünde)\.$')),
      );

      final camp = LevelGenerator.generate(
        environment: Environments.camp,
        config: GameConfigs.easy,
        seed: 5,
      );
      final campHint =
          HintBuilder.memorizeHints(Environments.camp, camp, tr).single;
      expect(campHint, endsWith('birbirine yakındı.'));

      final plain = HintBuilder.memorizeHints(
        Environments.city,
        LevelGenerator.generate(
          environment: Environments.city,
          config: GameConfigs.easy,
          seed: 1,
        ),
        tr,
      );
      expect(plain.single, tr.defaultHint);
    });

    test('fake warnings use the right number', () {
      expect(en.fakeWarning(1), contains('1 fake object '));
      expect(en.fakeWarning(3), contains('3 fake objects'));
      expect(tr.fakeWarning(2), contains('2 sahte nesne'));
    });

    test('level info mentions fakes only when there are some', () {
      expect(en.levelInfo(GameConfigs.medium), isNot(contains('fake')));
      expect(en.levelInfo(GameConfigs.hard), contains('1 fake'));
      expect(tr.levelInfo(GameConfigs.expert), contains('2 sahte'));
      expect(tr.levelInfo(GameConfigs.easy), contains('30 sn ezberleme'));
    });

    test('offsetSide agrees with the English phrase', () {
      expect(offsetSide(0.2, 0), OffsetSide.right);
      expect(offsetSide(-0.2, 0), OffsetSide.left);
      expect(offsetSide(0, 0.2), OffsetSide.below);
      expect(offsetSide(0, -0.2), OffsetSide.above);
      expect(describeOffset(0.2, 0), 'to the right of');
    });
  });
}
