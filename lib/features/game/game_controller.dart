import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../core/constants/game_constants.dart';
import '../../core/models/environment.dart';
import '../../core/models/game_config.dart';
import '../../core/models/game_object.dart';
import '../../core/models/score_result.dart';
import '../../core/utils/level_generator.dart';
import '../../core/utils/score_calculator.dart';

enum GamePhase { memorize, place, result }

/// One item waiting in the tray. Real objects and fakes look the same here.
class TrayEntry {
  const TrayEntry(this.definition, this.angle);

  final ObjectDefinition definition;

  /// Heading in radians for directional items, null otherwise.
  final double? angle;
}

/// Game logic and state machine (MEMORIZE -> PLACE -> RESULT). Contains no
/// widgets. There is only ever one timer, and it is cancelled on every phase
/// change, on restart and on dispose.
class GameController extends ChangeNotifier {
  GameController({
    required this.environment,
    required this.config,
    int? seed,
    this.onRoundFinished,
  }) : _fixedSeed = seed;

  final Environment environment;
  final GameConfig config;
  final int? _fixedSeed;

  /// Called once per round, right when the score is known (before the result
  /// screen shows). Progress saving and feedback hook in here.
  final void Function(ScoreResult score)? onRoundFinished;

  List<GameObject> _objects = const [];
  List<FakeObject> _fakes = const [];

  /// Tray order: real objects and fakes shuffled together, so the position in
  /// the tray never gives a fake away.
  List<String> _trayOrder = const [];
  GamePhase _phase = GamePhase.memorize;
  int _secondsLeft = 0;
  Timer? _timer;
  ScoreResult? _score;

  List<GameObject> get objects => _objects;
  List<FakeObject> get fakes => _fakes;
  GamePhase get phase => _phase;
  int get secondsLeft => _secondsLeft;
  ScoreResult? get score => _score;
  int get placedCount => _objects.where((o) => o.isPlaced).length;
  int get placedFakeCount => _fakes.where((f) => f.isPlaced).length;

  /// Everything that is still in the tray (real objects and fakes).
  List<TrayEntry> get unplacedTray {
    final entries = <TrayEntry>[];
    for (final id in _trayOrder) {
      final object = _objects.where((o) => o.id == id).firstOrNull;
      if (object != null) {
        if (!object.isPlaced) {
          entries.add(
            TrayEntry(
              object.definition,
              object.isDirectional ? object.placedAngle : null,
            ),
          );
        }
        continue;
      }
      final fake = _fakes.where((f) => f.id == id).firstOrNull;
      if (fake != null && !fake.isPlaced) {
        entries.add(
          TrayEntry(
            fake.definition,
            fake.isDirectional ? fake.placedAngle : null,
          ),
        );
      }
    }
    return entries;
  }

  /// Starts a fresh round. Also used for "play again": any running timer is
  /// cancelled first, so rapid restarts cannot stack timers.
  void start() {
    _cancelTimer();
    final seed = _fixedSeed ?? DateTime.now().microsecondsSinceEpoch;
    _objects = LevelGenerator.generate(
      environment: environment,
      config: config,
      seed: seed,
    );
    _fakes = LevelGenerator.generateFakes(
      environment: environment,
      config: config,
      objects: _objects,
      seed: seed,
    );
    _trayOrder = [
      for (final object in _objects) object.id,
      for (final fake in _fakes) fake.id,
    ]..shuffle(Random(seed + 1));
    _score = null;
    _phase = GamePhase.memorize;
    if (config.timed) {
      _runCountdown(config.memorizeSeconds, _beginPlacement);
    } else {
      _secondsLeft = 0;
    }
    notifyListeners();
  }

  /// Ends the memorize phase early (the player is ready before the timer).
  void skipMemorize() {
    if (_phase != GamePhase.memorize) return;
    _beginPlacement();
  }

  /// Stores where the player dropped an object (normalized, clamped to 0..1).
  /// Works for real objects and fakes alike.
  void placeObject(String id, double x, double y) {
    if (_phase != GamePhase.place) return;
    final clampedX = x.clamp(0.0, 1.0).toDouble();
    final clampedY = y.clamp(0.0, 1.0).toDouble();
    for (final object in _objects) {
      if (object.id == id) {
        object.placedX = clampedX;
        object.placedY = clampedY;
        notifyListeners();
        return;
      }
    }
    for (final fake in _fakes) {
      if (fake.id == id) {
        fake.placedX = clampedX;
        fake.placedY = clampedY;
        notifyListeners();
        return;
      }
    }
  }

  /// Turns a placed, directional object to its next heading (tap on it).
  void rotateObject(String id) {
    if (_phase != GamePhase.place) return;
    for (final object in _objects) {
      if (object.id == id) {
        if (!object.isPlaced || !object.isDirectional) return;
        object.rotate();
        notifyListeners();
        return;
      }
    }
    for (final fake in _fakes) {
      if (fake.id == id) {
        if (!fake.isPlaced || !fake.isDirectional) return;
        fake.rotate();
        notifyListeners();
        return;
      }
    }
  }

  /// Ends the placement phase (Finish button or timer reaching zero).
  void finish() {
    if (_phase != GamePhase.place) return;
    final remaining = _secondsLeft;
    _cancelTimer();
    _score = ScoreCalculator.calculate(
      objects: _objects,
      config: config,
      remainingSeconds: remaining,
      fakes: _fakes,
    );
    _phase = GamePhase.result;
    onRoundFinished?.call(_score!);
    notifyListeners();
  }

  void _beginPlacement() {
    _phase = GamePhase.place;
    if (config.timed) {
      _runCountdown(config.placementSeconds, finish);
    } else {
      _secondsLeft = 0;
    }
    notifyListeners();
  }

  void _runCountdown(int seconds, VoidCallback onDone) {
    _cancelTimer();
    _secondsLeft = seconds;
    _timer = Timer.periodic(GameConstants.tick, (timer) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        timer.cancel();
        _timer = null;
        onDone();
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
