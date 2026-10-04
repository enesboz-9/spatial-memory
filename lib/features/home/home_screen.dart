import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/environment.dart';
import '../../core/models/game_config.dart';
import '../../core/services/music_player.dart';
import '../../core/services/progress_store.dart';
import '../../data/environments/environments.dart';
import '../../data/game_configs/game_configs.dart';
import '../common/language_switcher.dart';
import '../common/sound_button.dart';
import '../game/game_screen.dart';
import '../survival/score_board.dart';
import '../survival/survival_screen.dart';
import '../tutorial/tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Environment _environment = Environments.spaceStation;
  GameConfig _config = GameConfigs.easy;

  @override
  void initState() {
    super.initState();
    // First launch: show the tutorial once. It counts as seen as soon as it
    // opens, so leaving it early never brings it back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MusicScope.of(context).playFor(_environment);
      final store = ProgressScope.read(context);
      if (store.tutorialSeen) return;
      store.markTutorialSeen();
      _openTutorial();
    });
  }

  void _openTutorial() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TutorialScreen()),
    );
  }

  void _play() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(environment: _environment, config: _config),
      ),
    );
  }

  void _playSurvival({bool resume = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SurvivalScreen(environment: _environment, resume: resume),
      ),
    );
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _starText(int stars) =>
      '★' * stars + '☆' * (stars >= 3 ? 0 : 3 - stars);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final store = ProgressScope.of(context);

    final environments = Environments.all;
    final configs = GameConfigs.all;
    final totalStars = store.totalStars(environments, configs);
    final record = store.record(_environment, _config);
    final survivalRecord = store.survivalRecord(_environment);
    final savedRun = store.savedSurvivalRun(_environment);
    final levelOpen = store.isLevelUnlocked(_environment, _config, configs);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: strings.howToPlay,
                        icon: const Icon(Icons.help_outline),
                        onPressed: _openTutorial,
                      ),
                      const SoundButton(),
                      const Spacer(),
                      const LanguageSwitcher(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.titleTop,
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w300, letterSpacing: 8),
                  ),
                  Text(
                    strings.titleBottom,
                    style: theme.textTheme.displayMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.starsTotal(totalStars),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: const Color(0xFFFFC107)),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < environments.length; i++)
                        _environmentChip(store, strings, environments[i], i),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.ruleHint(_environment, _config),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < configs.length; i++)
                        _levelChip(store, strings, configs[i], i),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(strings.levelInfo(_config), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    levelOpen
                        ? strings.levelStats(
                            record.bestScore,
                            (record.averageAccuracy * 100).round(),
                            record.rounds,
                          )
                        : _levelLockedText(strings),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: levelOpen ? _play : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(strings.play),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (savedRun != null) ...[
                    FilledButton.tonalIcon(
                      onPressed: () => _playSurvival(resume: true),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(
                        '${strings.continueRun} · '
                        '${strings.continueRunInfo(savedRun.nextRound, savedRun.totalScore)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _playSurvival,
                    icon: const Icon(Icons.all_inclusive),
                    label: Text(
                      savedRun != null ? strings.newRun : strings.survival,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (survivalRecord.bestScore > 0)
                    ScoreBoard(
                      title: strings.scoreboardTitle,
                      score: survivalRecord.bestScore,
                      round: survivalRecord.bestRound,
                      best: survivalRecord.bestScore,
                      showBest: false,
                      highlight: true,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    strings.survivalInfo(
                      GameConstants.survivalStartObjects,
                      GameConstants.survivalRampObjects,
                      (GameConstants.survivalMinAccuracy * 100).round(),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    strings.survivalRecord(
                      survivalRecord.bestRound,
                      survivalRecord.bestScore,
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _environmentChip(
    ProgressStore store,
    AppStrings strings,
    Environment environment,
    int index,
  ) {
    final environments = Environments.all;
    final unlocked =
        store.isEnvironmentUnlocked(environment, environments, GameConfigs.all);
    return ChoiceChip(
      avatar: Icon(unlocked ? environment.icon : Icons.lock, size: 18),
      label: Text(strings.environmentName(environment)),
      selected: unlocked && environment == _environment,
      onSelected: (_) {
        if (!unlocked) {
          _say(
            strings.environmentLocked(
              ProgressStore.environmentStarsNeeded(index),
              store.totalStars(environments, GameConfigs.all),
            ),
          );
          return;
        }
        MusicScope.of(context).playFor(environment);
        setState(() {
          _environment = environment;
          // Levels unlock per environment: fall back if this one is closed.
          if (!store.isLevelUnlocked(environment, _config, GameConfigs.all)) {
            _config = GameConfigs.easy;
          }
        });
      },
    );
  }

  Widget _levelChip(
    ProgressStore store,
    AppStrings strings,
    GameConfig config,
    int index,
  ) {
    final unlocked = store.isLevelUnlocked(_environment, config, GameConfigs.all);
    final stars = store.record(_environment, config).bestStars;
    return ChoiceChip(
      avatar: unlocked ? null : const Icon(Icons.lock, size: 18),
      label: Text(
        unlocked
            ? '${strings.difficultyName(config)}  ${_starText(stars)}'
            : strings.difficultyName(config),
      ),
      selected: unlocked && config == _config,
      onSelected: (_) {
        if (!unlocked) {
          _say(
            strings.levelLocked(
              strings.difficultyName(GameConfigs.all[index - 1]),
              GameConstants.starsToUnlockLevel,
            ),
          );
          return;
        }
        setState(() => _config = config);
      },
    );
  }

  String _levelLockedText(AppStrings strings) {
    final index = GameConfigs.all.indexOf(_config);
    return strings.levelLocked(
      strings.difficultyName(GameConfigs.all[index > 0 ? index - 1 : 0]),
      GameConstants.starsToUnlockLevel,
    );
  }
}
