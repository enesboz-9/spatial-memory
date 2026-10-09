import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/environment.dart';
import '../../core/models/game_config.dart';
import '../../core/models/score_result.dart';
import '../../core/services/game_feedback.dart';
import '../../core/services/progress_store.dart';
import '../../core/utils/format.dart';
import '../../core/utils/hint_builder.dart';
import '../../data/game_configs/game_configs.dart';
import '../common/sound_button.dart';
import '../result/result_screen.dart';
import 'game_controller.dart';
import 'widgets/environment_background.dart';
import 'widgets/object_badge.dart';
import 'widgets/relation_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.environment,
    required this.config,
  });

  final Environment environment;
  final GameConfig config;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  late GameConfig _config;

  /// Set when a round ends, shown on the result screen.
  bool _newRecord = false;
  GameConfig? _unlockedLevel;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _controller = _newController();
    _controller.start();
  }

  GameController _newController() => GameController(
        environment: widget.environment,
        config: _config,
        onRoundFinished: _onRoundFinished,
      );

  void _onRoundFinished(ScoreResult score) {
    final store = ProgressScope.read(context);
    final before = store.record(widget.environment, _config);
    final nextIndex = GameConfigs.all.indexOf(_config) + 1;
    final hadNext = nextIndex < GameConfigs.all.length &&
        store.isLevelUnlocked(
          widget.environment,
          GameConfigs.all[nextIndex],
          GameConfigs.all,
        );

    store.recordRound(widget.environment, _config, score);

    final unlockedNext = nextIndex < GameConfigs.all.length &&
        !hadNext &&
        store.isLevelUnlocked(
          widget.environment,
          GameConfigs.all[nextIndex],
          GameConfigs.all,
        );
    _newRecord = before.rounds > 0 && score.finalScore > before.bestScore;
    _unlockedLevel = unlockedNext ? GameConfigs.all[nextIndex] : null;
  }

  /// The next difficulty, when this round earned enough stars to open it.
  GameConfig? get _nextConfig {
    final score = _controller.score;
    final index = GameConfigs.all.indexOf(_config) + 1;
    if (score == null || index >= GameConfigs.all.length) return null;
    return score.stars >= GameConstants.starsToUnlockLevel
        ? GameConfigs.all[index]
        : null;
  }

  void _playNext(GameConfig next) {
    final old = _controller;
    setState(() {
      _config = next;
      _controller = _newController()..start();
    });
    // Dispose after the rebuild, once nothing listens to it any more.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    // Cancels the countdown, so leaving mid-game never leaves a stray timer.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.phase == GamePhase.result) {
          final strings = AppStrings.of(context);
          final next = _nextConfig;
          final unlocked = _unlockedLevel;
          return ResultScreen(
            controller: _controller,
            notes: [
              if (_newRecord) strings.newRecord,
              if (unlocked != null)
                strings.levelUnlocked(strings.difficultyName(unlocked)),
            ],
            primaryLabel: next != null
                ? strings.nextLevel(strings.difficultyName(next))
                : strings.playAgain,
            onPrimary: next != null ? () => _playNext(next) : _controller.start,
            secondaryLabel: next != null ? strings.playAgain : null,
            onSecondary: next != null ? _controller.start : null,
            onHome: () => Navigator.of(context).pop(),
          );
        }
        return PlayScaffold(controller: _controller);
      },
    );
  }
}

/// The memorize / place screen. Shared by the normal game, survival mode and
/// the tutorial; [banner] is an optional coach strip under the header.
class PlayScaffold extends StatelessWidget {
  const PlayScaffold({super.key, required this.controller, this.banner});

  final GameController controller;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final isPlacing = controller.phase == GamePhase.place;
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _PhaseHeader(controller: controller),
              if (banner != null) ...[
                const SizedBox(height: 8),
                banner!,
              ],
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side =
                        min(constraints.maxWidth, constraints.maxHeight);
                    return Center(
                      child: _PlayArea(controller: controller, side: side),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // The tray is always laid out (just hidden while memorizing) so
              // the play area keeps the same size in both phases.
              Stack(
                alignment: Alignment.center,
                children: [
                  Visibility(
                    visible: isPlacing,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: _PlacementTray(controller: controller),
                  ),
                  if (!isPlacing)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final hint in [
                          ...HintBuilder.memorizeHints(
                            controller.environment,
                            controller.objects,
                            strings,
                          ),
                          if (controller.fakes.isNotEmpty)
                            strings.fakeWarning(controller.fakes.length),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(hint, textAlign: TextAlign.center),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: controller.skipMemorize,
                          icon: const Icon(Icons.fast_forward),
                          label: Text(strings.skipMemorize),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
            // Volume / mute is reachable during a round too, not only on
            // the home screen.
            const Positioned(top: 0, right: 0, child: SoundButton()),
          ],
        ),
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isMemorizing = controller.phase == GamePhase.memorize;
    final totalSeconds = isMemorizing
        ? controller.config.memorizeSeconds
        : controller.config.placementSeconds;
    final urgentAt = isMemorizing
        ? GameConstants.memorizeWarningSeconds
        : GameConstants.placementUrgentSeconds;
    final isUrgent = controller.secondsLeft <= urgentAt;
    final color =
        isUrgent ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final progress =
        totalSeconds == 0 ? 0.0 : controller.secondsLeft / totalSeconds;

    return Column(
      children: [
        Text(
          isMemorizing ? strings.rememberScene : strings.placeObjects,
          style: theme.textTheme.titleMedium,
        ),
        if (controller.config.timed) ...[
          Text(
            formatSeconds(controller.secondsLeft),
            style: theme.textTheme.displayMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          isMemorizing
              ? strings.ruleHint(controller.environment, controller.config)
              : [
                  strings.placeHint(controller.environment, controller.config),
                  if (controller.fakes.isNotEmpty) strings.fakePlaceNote,
                ].join(' '),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PlayArea extends StatefulWidget {
  const _PlayArea({required this.controller, required this.side});

  final GameController controller;
  final double side;

  @override
  State<_PlayArea> createState() => _PlayAreaState();
}

class _PlayAreaState extends State<_PlayArea> {
  final GlobalKey _areaKey = GlobalKey();

  void _handleDrop(DragTargetDetails<String> details) {
    final box = _areaKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    // details.offset is the top-left of the dragged badge; use its center.
    const halfObject = GameConstants.objectSize / 2;
    final center = box.globalToLocal(
      details.offset + const Offset(halfObject, halfObject),
    );

    // Keep the whole object inside the play area.
    final side = widget.side;
    final halfNormalized = min(0.5, halfObject / side);
    double normalize(double value) =>
        (value / side).clamp(halfNormalized, 1 - halfNormalized).toDouble();

    widget.controller.placeObject(
      details.data,
      normalize(center.dx),
      normalize(center.dy),
    );
    GameFeedback.of(context).drop();
  }

  void _rotate(String id) {
    widget.controller.rotateObject(id);
    GameFeedback.of(context).rotate();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final side = widget.side;
    const half = GameConstants.objectSize / 2;
    final isPlacing = controller.phase == GamePhase.place;

    return SizedBox.square(
      key: _areaKey,
      dimension: side,
      child: DragTarget<String>(
        onAcceptWithDetails: _handleDrop,
        builder: (context, candidate, rejected) => Stack(
          // Direction arrows sit just outside the tiles.
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: EnvironmentBackground(environment: controller.environment),
            ),
            for (final object in controller.objects)
              if (!isPlacing)
                Positioned(
                  left: object.targetX * side - half,
                  top: object.targetY * side - half,
                  child: ObjectBadge(
                    definition: object.definition,
                    angle: object.isDirectional ? object.targetAngle : null,
                  ),
                )
              else if (object.isPlaced)
                Positioned(
                  left: object.placedX! * side - half,
                  top: object.placedY! * side - half,
                  child: DraggableObject(
                    definition: object.definition,
                    angle: object.isDirectional ? object.placedAngle : null,
                    onTap: object.isDirectional
                        ? () => _rotate(object.id)
                        : null,
                  ),
                ),
            // Fakes look exactly like real objects once they are put down.
            if (isPlacing)
              for (final fake in controller.fakes)
                if (fake.isPlaced)
                  Positioned(
                    left: fake.placedX! * side - half,
                    top: fake.placedY! * side - half,
                    child: DraggableObject(
                      definition: fake.definition,
                      angle: fake.isDirectional ? fake.placedAngle : null,
                      onTap: fake.isDirectional
                          ? () => _rotate(fake.id)
                          : null,
                    ),
                  ),
            // Island lines and camp rings are shown while memorizing only.
            if (!isPlacing)
              Positioned.fill(
                child: RelationOverlay(objects: controller.objects),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlacementTray extends StatelessWidget {
  const _PlacementTray({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final unplaced = controller.unplacedTray;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: unplaced.isEmpty
              ? Center(child: Text(strings.allPlaced))
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in unplaced)
                      SizedBox(
                        width: GameConstants.objectSize,
                        child: Column(
                          children: [
                            DraggableObject(
                              definition: entry.definition,
                              angle: entry.angle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.objectName(entry.definition),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: controller.finish,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(
            strings.finish(controller.placedCount, controller.objects.length),
          ),
        ),
      ],
    );
  }
}
