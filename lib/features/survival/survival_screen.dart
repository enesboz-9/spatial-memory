import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/environment.dart';
import '../../core/models/game_config.dart';
import '../../core/models/score_result.dart';
import '../../core/services/game_feedback.dart';
import '../../core/services/progress_store.dart';
import '../../data/game_configs/game_configs.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';
import '../result/result_screen.dart';
import 'score_board.dart';

/// Endless mode. It starts with 1 object and grows to 5, then 1 to 5 of those
/// objects start turning, and after that every round adds an object or turns
/// one more (see [GameConfigs.survivalRound]). The run ends when a round's
/// average accuracy falls below [GameConstants.survivalMinAccuracy].
///
/// Records are saved after every cleared round, so closing the app mid-run
/// never loses them. The run itself is saved too: after a cleared round the
/// player can leave and later continue from the next round with the same
/// total score ([resume]). Only game over erases the saved run.
class SurvivalScreen extends StatefulWidget {
  const SurvivalScreen({
    super.key,
    required this.environment,
    this.resume = false,
  });

  final Environment environment;

  /// Continue the saved run of this environment (if there is one).
  final bool resume;

  @override
  State<SurvivalScreen> createState() => _SurvivalScreenState();
}

class _SurvivalScreenState extends State<SurvivalScreen> {
  late GameController _controller;
  late GameConfig _config;

  int _round = 1;
  int _totalScore = 0;
  int _cleared = 0;
  bool _over = false;
  bool _newRecord = false;

  @override
  void initState() {
    super.initState();
    final store = ProgressScope.read(context);
    final saved =
        widget.resume ? store.savedSurvivalRun(widget.environment) : null;
    if (saved != null) {
      _round = saved.nextRound;
      _totalScore = saved.totalScore;
      _cleared = saved.roundsCleared;
    } else {
      store.clearSurvivalRun(widget.environment);
      store.recordSurvivalStart(widget.environment);
    }
    _config = _roundConfig(_round);
    _controller = _newController()..start();
  }

  GameConfig _roundConfig(int round) => GameConfigs.survivalRound(
        round,
        rotatable: widget.environment.rotatableCount,
      );

  GameController _newController() => GameController(
        environment: widget.environment,
        config: _config,
        onRoundFinished: _onRoundFinished,
      );

  void _onRoundFinished(ScoreResult score) {
    final store = ProgressScope.read(context);
    final before = store.survivalRecord(widget.environment);
    _totalScore += score.finalScore;

    final passed = score.averageAccuracy >= GameConstants.survivalMinAccuracy;
    if (passed) {
      _cleared = _round;
      if (before.bestRound > 0 && _cleared > before.bestRound) {
        _newRecord = true;
      }
    } else {
      _over = true;
      GameFeedback.of(context).gameOver();
    }
    if (passed) {
      // Remember where the run stands, so it can be continued next time.
      store.saveSurvivalRun(
        widget.environment,
        nextRound: _round + 1,
        totalScore: _totalScore,
      );
    } else {
      store.clearSurvivalRun(widget.environment);
    }
    store.recordSurvivalProgress(
      widget.environment,
      roundsCleared: _cleared,
      totalScore: _totalScore,
    );
  }

  void _swapController() {
    final old = _controller;
    setState(() {
      _config = _roundConfig(_round);
      _controller = _newController()..start();
    });
    // Dispose after the rebuild, once nothing listens to it any more.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _nextRound() {
    _round++;
    _swapController();
  }

  void _restart() {
    ProgressScope.read(context).recordSurvivalStart(widget.environment);
    _round = 1;
    _totalScore = 0;
    _cleared = 0;
    _over = false;
    _newRecord = false;
    _swapController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.phase != GamePhase.result) {
          return PlayScaffold(
            controller: _controller,
            banner: Column(
              children: [
                ScoreBoard(
                  compact: true,
                  score: _totalScore,
                  round: _round,
                  best: ProgressScope.of(context)
                      .survivalRecord(widget.environment)
                      .bestScore,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.survivalRound(
                    _round,
                    _config.objectCount,
                    _config.rotatedObjects ?? 0,
                  ),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          );
        }
        return ResultScreen(
          controller: _controller,
          notes: [
            _over ? strings.survivalOver : strings.survivalCleared,
            if (_newRecord) strings.newRecord,
            if (!_over) strings.runSaved,
          ],
          extra: _RunSummary(
            round: _round,
            config: _config,
            nextConfig: _roundConfig(_round + 1),
            totalScore: _totalScore,
            cleared: _cleared,
            over: _over,
            best: ProgressScope.of(context)
                .survivalRecord(widget.environment)
                .bestScore,
            newRecord: _newRecord,
          ),
          primaryLabel: _over ? strings.playAgain : strings.nextRound(_round + 1),
          onPrimary: _over ? _restart : _nextRound,
          homeLabel: _over ? null : strings.endRun,
          onHome: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _RunSummary extends StatelessWidget {
  const _RunSummary({
    required this.round,
    required this.config,
    required this.nextConfig,
    required this.totalScore,
    required this.cleared,
    required this.over,
    required this.best,
    required this.newRecord,
  });

  final int round;
  final GameConfig config;
  final GameConfig nextConfig;
  final int totalScore;
  final int cleared;
  final bool over;
  final int best;
  final bool newRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final minPercent = (GameConstants.survivalMinAccuracy * 100).round();

    final String detail;
    if (over) {
      detail = strings.survivalOverDetail(cleared, totalScore, minPercent);
    } else if (nextConfig.objectCount == config.objectCount &&
        nextConfig.rotatedObjects == config.rotatedObjects) {
      detail = strings.survivalMaxInfo;
    } else {
      detail = strings.survivalNextInfo(
        nextConfig.objectCount,
        nextConfig.rotatedObjects ?? 0,
      );
    }

    return Column(
      children: [
        ScoreBoard(
          score: totalScore,
          round: round,
          best: best,
          highlight: newRecord,
        ),
        const SizedBox(height: 8),
        Text(
          strings.survivalRound(round, config.objectCount, config.rotatedObjects ?? 0),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(detail, textAlign: TextAlign.center),
      ],
    );
  }
}
