import 'dart:io';
import 'dart:math' show max;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_memory/core/constants/game_constants.dart';
import 'package:spatial_memory/core/models/game_object.dart';
import 'package:spatial_memory/core/models/score_result.dart';
import 'package:spatial_memory/core/services/progress_store.dart';
import 'package:spatial_memory/core/utils/level_generator.dart';
import 'package:spatial_memory/core/utils/score_calculator.dart';
import 'package:spatial_memory/data/environments/environments.dart';
import 'package:spatial_memory/data/game_configs/game_configs.dart';
import 'package:spatial_memory/features/game/game_controller.dart';

/// A one-object round: perfectly placed (3 stars) or not placed (0 stars).
ScoreResult _score({required bool perfect}) {
  final object = GameObject(
    definition: Environments.spaceStation.objectPool[0],
    targetX: 0.5,
    targetY: 0.5,
  );
  if (perfect) {
    object
      ..placedX = 0.5
      ..placedY = 0.5;
  }
  return ScoreCalculator.calculate(
    objects: [object],
    config: GameConfigs.easy,
    remainingSeconds: 0,
  );
}

void main() {
  musicTests();
  group('stars', () {
    test('thresholds', () {
      expect(ScoreCalculator.starsFor(0.49), 0);
      expect(ScoreCalculator.starsFor(0.50), 1);
      expect(ScoreCalculator.starsFor(0.64), 1);
      expect(ScoreCalculator.starsFor(0.65), 2);
      expect(ScoreCalculator.starsFor(0.79), 2);
      expect(ScoreCalculator.starsFor(0.80), 3);
      expect(ScoreCalculator.starsFor(0.89), 3);
      expect(ScoreCalculator.starsFor(0.90), 4); // PERFECT + gift star
      expect(ScoreCalculator.starsFor(1), 4);
    });

    test('a score knows its stars and whether it is PERFECT', () {
      expect(_score(perfect: true).stars, 4);
      expect(_score(perfect: true).isPerfectRound, isTrue);
      expect(_score(perfect: false).stars, 0);
      expect(_score(perfect: false).isPerfectRound, isFalse);
    });
  });

  group('ProgressStore', () {
    test('records best score, stars, rounds and average accuracy', () {
      final store = ProgressStore.memory();
      final env = Environments.spaceStation;
      final config = GameConfigs.easy;

      store.recordRound(env, config, _score(perfect: true));
      store.recordRound(env, config, _score(perfect: false));

      final record = store.record(env, config);
      expect(record.rounds, 2);
      expect(record.bestStars, 4);
      expect(record.bestScore, _score(perfect: true).finalScore);
      expect(record.averageAccuracy, closeTo(0.5, 1e-9));
      expect(store.record(Environments.island, config).rounds, 0);
    });

    test('levels open with stars on the previous level', () {
      final store = ProgressStore.memory();
      final env = Environments.spaceStation;
      final all = GameConfigs.all;

      expect(store.isLevelUnlocked(env, GameConfigs.easy, all), isTrue);
      expect(store.isLevelUnlocked(env, GameConfigs.medium, all), isFalse);

      store.recordRound(env, GameConfigs.easy, _score(perfect: false));
      expect(store.isLevelUnlocked(env, GameConfigs.medium, all), isFalse);

      store.recordRound(env, GameConfigs.easy, _score(perfect: true));
      expect(store.isLevelUnlocked(env, GameConfigs.medium, all), isTrue);
      // Per environment: the island is not affected.
      expect(
        store.isLevelUnlocked(Environments.island, GameConfigs.medium, all),
        isFalse,
      );
    });

    test('environments open with total stars', () {
      final store = ProgressStore.memory();
      final envs = Environments.all;
      final all = GameConfigs.all;

      expect(store.isEnvironmentUnlocked(envs[0], envs, all), isTrue);
      expect(store.isEnvironmentUnlocked(envs[1], envs, all), isFalse);

      // 4 stars per perfect level: easy + medium = 8 (>= 4, < 10).
      for (final config in [GameConfigs.easy, GameConfigs.medium]) {
        store.recordRound(envs[0], config, _score(perfect: true));
      }
      expect(store.totalStars(envs, all), 8);
      expect(store.isEnvironmentUnlocked(envs[1], envs, all), isTrue);
      expect(store.isEnvironmentUnlocked(envs[2], envs, all), isFalse);
    });

    test('survival bests only go up', () {
      final store = ProgressStore.memory();
      final env = Environments.camp;
      store.recordSurvivalStart(env);
      store.recordSurvivalProgress(env, roundsCleared: 5, totalScore: 4000);
      store.recordSurvivalProgress(env, roundsCleared: 3, totalScore: 5000);

      final record = store.survivalRecord(env);
      expect(record.bestRound, 5);
      expect(record.bestScore, 5000);
      expect(record.runs, 1);
    });

    test('data survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await ProgressStore.load();
      first.recordRound(
        Environments.city,
        GameConfigs.hard,
        _score(perfect: true),
      );
      first.markTutorialSeen();
      first.feedbackEnabled = false;

      final second = await ProgressStore.load();
      expect(second.record(Environments.city, GameConfigs.hard).rounds, 1);
      expect(second.record(Environments.city, GameConfigs.hard).bestStars, 4);
      expect(second.tutorialSeen, isTrue);
      expect(second.feedbackEnabled, isFalse);
    });

    test('an unfinished survival run can be continued after a restart',
        () async {
      SharedPreferences.setMockInitialValues({});
      final first = await ProgressStore.load();
      final env = Environments.camp;
      expect(first.savedSurvivalRun(env), isNull);
      first.saveSurvivalRun(env, nextRound: 4, totalScore: 2500);
      first.musicVolume = 0.3;

      final second = await ProgressStore.load();
      final run = second.savedSurvivalRun(env);
      expect(run, isNotNull);
      expect(run!.nextRound, 4);
      expect(run.roundsCleared, 3);
      expect(run.totalScore, 2500);
      expect(second.savedSurvivalRun(Environments.city), isNull);
      expect(second.musicVolume, closeTo(0.3, 1e-9));

      second.clearSurvivalRun(env);
      final third = await ProgressStore.load();
      expect(third.savedSurvivalRun(env), isNull);
    });

    test('music volume stays between 0 and 1', () {
      final store = ProgressStore.memory();
      store.musicVolume = 3;
      expect(store.musicVolume, 1.0);
      store.musicVolume = -1;
      expect(store.musicVolume, 0.0);
    });

    test('corrupt saved data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'progress_v1': '{not json'});
      final store = await ProgressStore.load();
      expect(store.tutorialSeen, isFalse);
      expect(store.record(Environments.city, GameConfigs.easy).rounds, 0);
    });
  });

  group('survival rounds', () {
    List<(int, int)> stages(int rounds, int rotatable) => [
          for (var r = 1; r <= rounds; r++)
            (
              GameConfigs.survivalStage(r, rotatable: rotatable).objects,
              GameConfigs.survivalStage(r, rotatable: rotatable).rotated,
            ),
        ];

    test('starts with one object and grows to five without rotation', () {
      expect(GameConstants.survivalStartObjects, 1);
      expect(
        stages(5, 8),
        [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0)],
      );
      for (var r = 1; r <= 5; r++) {
        expect(GameConfigs.survivalRound(r, rotatable: 8).rotationEnabled,
            isFalse);
      }
    });

    test('then five objects with one to five rotating', () {
      expect(
        stages(10, 8).skip(5).toList(),
        [(5, 1), (5, 2), (5, 3), (5, 4), (5, 5)],
      );
      final config = GameConfigs.survivalRound(8, rotatable: 8);
      expect(config.rotationEnabled, isTrue);
      expect(config.rotatedObjects, 3);
    });

    test('afterwards every round adds an object or rotates one more', () {
      final all = stages(30, 8);
      for (var i = 10; i < all.length; i++) {
        final before = all[i - 1];
        final now = all[i];
        final addedObject = now.$1 == before.$1 + 1 && now.$2 == before.$2;
        final addedRotation = now.$1 == before.$1 && now.$2 == before.$2 + 1;
        final stuck = now == before;
        expect(addedObject || addedRotation || stuck, isTrue, reason: 'r${i + 1}');
        expect(now.$2, lessThanOrEqualTo(now.$1));
        expect(now.$1, lessThanOrEqualTo(GameConstants.survivalMaxObjects));
      }
      expect(all.last, (GameConstants.survivalMaxObjects, 8));
    });

    test('rotation never exceeds what the environment can turn', () {
      // Space station: five directional objects, so rounds 11+ only add objects.
      final station = stages(40, Environments.spaceStation.rotatableCount);
      expect(Environments.spaceStation.rotatableCount, 5);
      expect(station.map((s) => s.$2).reduce(max), 5);
      // No headings at all: rotation steps are skipped.
      final plain = stages(20, 0);
      expect(plain.map((s) => s.$2).reduce(max), 0);
      expect(plain[5], (6, 0));
      expect(plain.last, (GameConstants.survivalMaxObjects, 0));
    });

    test('headings never turn on when no object rotates', () {
      final config = GameConfigs.survivalRound(3, rotatable: 5);
      expect(config.rotationEnabled, isFalse);
      expect(config.rotatedObjects, 0);
    });

    test('multiplier grows and is capped', () {
      expect(GameConfigs.survivalRound(1).scoreMultiplier, 1.0);
      expect(
        GameConfigs.survivalRound(3).scoreMultiplier,
        greaterThan(GameConfigs.survivalRound(2).scoreMultiplier),
      );
      expect(
        GameConfigs.survivalRound(100).scoreMultiplier,
        GameConstants.survivalMaxMultiplier,
      );
    });

    test('every round fits every environment pool', () {
      for (final environment in Environments.all) {
        for (var round = 1; round <= 40; round++) {
          final config = GameConfigs.survivalRound(
            round,
            rotatable: environment.rotatableCount,
          );
          expect(
            config.objectCount + config.fakeCount,
            lessThanOrEqualTo(environment.objectPool.length),
            reason: '${environment.id} round $round',
          );
          final objects = LevelGenerator.generate(
            environment: environment,
            config: config,
            seed: round,
          );
          expect(objects.length, config.objectCount);
        }
      }
    });

    test('generated levels rotate exactly the planned number of objects', () {
      for (final environment in [Environments.spaceStation, Environments.city]) {
        for (var round = 1; round <= 40; round++) {
          final config = GameConfigs.survivalRound(
            round,
            rotatable: environment.rotatableCount,
          );
          for (var seed = 0; seed < 20; seed++) {
            final objects = LevelGenerator.generate(
              environment: environment,
              config: config,
              seed: seed,
            );
            expect(
              objects.where((o) => o.isDirectional).length,
              config.rotatedObjects,
              reason: '${environment.id} round $round seed $seed',
            );
          }
        }
      }
    });

    test('environments without headings never rotate in survival', () {
      for (final environment in [
        Environments.island,
        Environments.laboratory,
        Environments.camp,
      ]) {
        expect(environment.rotatableCount, 0);
        for (var round = 1; round <= 20; round++) {
          final config = GameConfigs.survivalRound(round, rotatable: 0);
          final objects = LevelGenerator.generate(
            environment: environment,
            config: config,
            seed: round,
          );
          expect(objects.where((o) => o.isDirectional), isEmpty);
        }
      }
    });
  });

  group('tutorial round', () {
    test('is untimed and reports its result once', () {
      var finished = 0;
      final controller = GameController(
        environment: Environments.spaceStation,
        config: GameConfigs.tutorial,
        seed: 3,
        onRoundFinished: (_) => finished++,
      )..start();

      expect(controller.phase, GamePhase.memorize);
      expect(controller.fakes, isNotEmpty);
      expect(controller.objects.where((o) => o.isDirectional).length, greaterThan(1));

      controller.skipMemorize();
      expect(controller.phase, GamePhase.place);
      for (final object in controller.objects) {
        controller.placeObject(object.id, object.targetX, object.targetY);
      }
      controller.finish();
      controller.finish(); // second call is ignored

      expect(controller.phase, GamePhase.result);
      expect(finished, 1);
      controller.dispose();
    });
  });
}

void musicTests() {
  group('background music', () {
    test('every environment has its own track that ships with the app', () {
      final assets = <String>{};
      for (final environment in Environments.all) {
        expect(assets.add(environment.musicAsset), isTrue,
            reason: 'two environments share ${environment.musicAsset}');
        expect(File('assets/${environment.musicAsset}').existsSync(), isTrue,
            reason: environment.id);
      }
    });

    test('the music folder is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/music/'));
      expect(pubspec, contains('audioplayers:'));
    });
  });
}
