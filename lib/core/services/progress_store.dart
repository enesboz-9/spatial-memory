import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/game_constants.dart';
import '../models/environment.dart';
import '../models/game_config.dart';
import '../models/score_result.dart';

/// Saved numbers for one environment + difficulty pair.
class LevelRecord {
  const LevelRecord({
    this.bestScore = 0,
    this.bestStars = 0,
    this.rounds = 0,
    this.accuracySum = 0,
  });

  final int bestScore;
  final int bestStars;
  final int rounds;

  /// Sum of every round's average accuracy (0-1); divide by [rounds].
  final double accuracySum;

  double get averageAccuracy => rounds == 0 ? 0 : accuracySum / rounds;

  LevelRecord afterRound(ScoreResult score) => LevelRecord(
        bestScore: score.finalScore > bestScore ? score.finalScore : bestScore,
        bestStars: score.stars > bestStars ? score.stars : bestStars,
        rounds: rounds + 1,
        accuracySum: accuracySum + score.averageAccuracy,
      );

  Map<String, Object> toJson() => {
        'bestScore': bestScore,
        'bestStars': bestStars,
        'rounds': rounds,
        'accuracySum': accuracySum,
      };

  factory LevelRecord.fromJson(Map<String, dynamic> json) => LevelRecord(
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        bestStars: (json['bestStars'] as num?)?.toInt() ?? 0,
        rounds: (json['rounds'] as num?)?.toInt() ?? 0,
        accuracySum: (json['accuracySum'] as num?)?.toDouble() ?? 0,
      );
}

/// Saved numbers for survival mode in one environment.
class SurvivalRecord {
  const SurvivalRecord({this.bestRound = 0, this.bestScore = 0, this.runs = 0});

  /// Most rounds cleared in one run.
  final int bestRound;
  final int bestScore;
  final int runs;

  Map<String, Object> toJson() => {
        'bestRound': bestRound,
        'bestScore': bestScore,
        'runs': runs,
      };

  factory SurvivalRecord.fromJson(Map<String, dynamic> json) => SurvivalRecord(
        bestRound: (json['bestRound'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
      );
}

/// An unfinished endless run that can be continued later.
class SurvivalRun {
  const SurvivalRun({required this.nextRound, required this.totalScore});

  /// The round the player will play when continuing (cleared rounds + 1).
  final int nextRound;
  final int totalScore;

  int get roundsCleared => nextRound - 1;

  Map<String, Object> toJson() => {
        'nextRound': nextRound,
        'totalScore': totalScore,
      };

  static SurvivalRun? fromJson(Map<String, dynamic> json) {
    final round = (json['nextRound'] as num?)?.toInt() ?? 0;
    if (round < 2) return null;
    return SurvivalRun(
      nextRound: round,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Everything the game remembers between launches, in one JSON string inside
/// `shared_preferences`. Notifies listeners on every change.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs, Map<String, dynamic> data) {
    final levels = data['levels'];
    if (levels is Map<String, dynamic>) {
      for (final entry in levels.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          _levels[entry.key] = LevelRecord.fromJson(value);
        }
      }
    }
    final survival = data['survival'];
    if (survival is Map<String, dynamic>) {
      for (final entry in survival.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          _survival[entry.key] = SurvivalRecord.fromJson(value);
        }
      }
    }
    final runs = data['survivalRuns'];
    if (runs is Map<String, dynamic>) {
      for (final entry in runs.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final run = SurvivalRun.fromJson(value);
          if (run != null) _survivalRuns[entry.key] = run;
        }
      }
    }
    _tutorialSeen = data['tutorialSeen'] == true;
    final volume = data['musicVolume'];
    if (volume is num) _musicVolume = volume.toDouble().clamp(0.0, 1.0);
    _feedbackEnabled = data['feedbackEnabled'] != false;
  }

  static const String _storageKey = 'progress_v1';

  final SharedPreferences? _prefs;
  final Map<String, LevelRecord> _levels = {};
  final Map<String, SurvivalRecord> _survival = {};
  final Map<String, SurvivalRun> _survivalRuns = {};
  bool _tutorialSeen = false;
  bool _feedbackEnabled = true;
  double _musicVolume = 0.7;

  /// Reads the saved data. Corrupt data is ignored (the game starts fresh
  /// instead of crashing).
  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) data = decoded;
      } on FormatException {
        // Ignore: start fresh.
      }
    }
    return ProgressStore._(prefs, data);
  }

  /// A store that never touches the disk (tests, previews).
  factory ProgressStore.memory() => ProgressStore._(null, {});

  static String _key(Environment environment, GameConfig config) =>
      '${environment.id}:${config.id}';

  // --- Reading ----------------------------------------------------------------

  LevelRecord record(Environment environment, GameConfig config) =>
      _levels[_key(environment, config)] ?? const LevelRecord();

  SurvivalRecord survivalRecord(Environment environment) =>
      _survival[environment.id] ?? const SurvivalRecord();

  /// The unfinished endless run of [environment], if there is one.
  SurvivalRun? savedSurvivalRun(Environment environment) =>
      _survivalRuns[environment.id];

  /// Music loudness chosen by the player (0.0 - 1.0).
  double get musicVolume => _musicVolume;

  bool get tutorialSeen => _tutorialSeen;
  bool get feedbackEnabled => _feedbackEnabled;

  /// Stars earned on every level of [environment] (best per level).
  int starsIn(Environment environment, List<GameConfig> configs) => [
        for (final config in configs) record(environment, config).bestStars,
      ].fold(0, (a, b) => a + b);

  int totalStars(List<Environment> environments, List<GameConfig> configs) => [
        for (final environment in environments) starsIn(environment, configs),
      ].fold(0, (a, b) => a + b);

  int totalRounds(List<Environment> environments, List<GameConfig> configs) =>
      [
        for (final environment in environments)
          for (final config in configs) record(environment, config).rounds,
      ].fold(0, (a, b) => a + b);

  bool isEnvironmentUnlocked(
    Environment environment,
    List<Environment> environments,
    List<GameConfig> configs,
  ) {
    if (GameConstants.unlockEverything) return true;
    final index = environments.indexOf(environment);
    if (index <= 0) return true;
    return totalStars(environments, configs) >= environmentStarsNeeded(index);
  }

  /// Total stars needed to open the environment at [index].
  static int environmentStarsNeeded(int index) {
    const needs = GameConstants.environmentUnlockStars;
    return index < needs.length ? needs[index] : needs.last;
  }

  bool isLevelUnlocked(
    Environment environment,
    GameConfig config,
    List<GameConfig> configs,
  ) {
    if (GameConstants.unlockEverything) return true;
    final index = configs.indexOf(config);
    if (index <= 0) return true;
    return record(environment, configs[index - 1]).bestStars >=
        GameConstants.starsToUnlockLevel;
  }

  // --- Writing ----------------------------------------------------------------

  void recordRound(
    Environment environment,
    GameConfig config,
    ScoreResult score,
  ) {
    final key = _key(environment, config);
    _levels[key] = (_levels[key] ?? const LevelRecord()).afterRound(score);
    _save();
  }

  /// A new survival run began in [environment].
  void recordSurvivalStart(Environment environment) {
    final old = survivalRecord(environment);
    _survival[environment.id] = SurvivalRecord(
      bestRound: old.bestRound,
      bestScore: old.bestScore,
      runs: old.runs + 1,
    );
    _save();
  }

  /// Called after every cleared survival round, so closing the app mid-run
  /// keeps the progress. Only ever raises the bests.
  void recordSurvivalProgress(
    Environment environment, {
    required int roundsCleared,
    required int totalScore,
  }) {
    final old = survivalRecord(environment);
    _survival[environment.id] = SurvivalRecord(
      bestRound: roundsCleared > old.bestRound ? roundsCleared : old.bestRound,
      bestScore: totalScore > old.bestScore ? totalScore : old.bestScore,
      runs: old.runs,
    );
    _save();
  }

  /// Remembers where the endless run stands, so it can be continued later.
  void saveSurvivalRun(
    Environment environment, {
    required int nextRound,
    required int totalScore,
  }) {
    _survivalRuns[environment.id] =
        SurvivalRun(nextRound: nextRound, totalScore: totalScore);
    _save();
  }

  /// The run ended (game over or a fresh start): nothing to continue.
  void clearSurvivalRun(Environment environment) {
    if (_survivalRuns.remove(environment.id) != null) _save();
  }

  void markTutorialSeen() {
    if (_tutorialSeen) return;
    _tutorialSeen = true;
    _save();
  }

  set musicVolume(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (_musicVolume == clamped) return;
    _musicVolume = clamped;
    _save();
  }

  set feedbackEnabled(bool value) {
    if (_feedbackEnabled == value) return;
    _feedbackEnabled = value;
    _save();
  }

  void _save() {
    notifyListeners();
    _prefs?.setString(
      _storageKey,
      jsonEncode({
        'levels': {for (final e in _levels.entries) e.key: e.value.toJson()},
        'survival': {
          for (final e in _survival.entries) e.key: e.value.toJson(),
        },
        'survivalRuns': {
          for (final e in _survivalRuns.entries) e.key: e.value.toJson(),
        },
        'musicVolume': _musicVolume,
        'tutorialSeen': _tutorialSeen,
        'feedbackEnabled': _feedbackEnabled,
      }),
    );
  }
}

/// Makes the [ProgressStore] available to every screen.
class ProgressScope extends InheritedNotifier<ProgressStore> {
  const ProgressScope({
    super.key,
    required ProgressStore store,
    required super.child,
  }) : super(notifier: store);

  /// Rebuilds the caller whenever the saved data changes.
  static ProgressStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'No ProgressScope above this context.');
    return scope!.notifier!;
  }

  /// Reads the store without subscribing (for callbacks).
  static ProgressStore read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'No ProgressScope above this context.');
    return scope!.notifier!;
  }
}
