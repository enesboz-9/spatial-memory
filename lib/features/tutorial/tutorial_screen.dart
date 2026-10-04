import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/environments/environments.dart';
import '../../data/game_configs/game_configs.dart';
import '../common/language_switcher.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';

/// First-launch tutorial: one tiny untimed round on the space station
/// (3 objects, headings on, 1 fake) with a coach strip that follows what the
/// player does. Afterwards a card lists the rule of every environment.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  static const int _totalSteps = 4;

  late final GameController _controller = GameController(
    environment: Environments.spaceStation,
    config: GameConfigs.tutorial,
  )..start();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// What the coach says right now, and which step of the tour that is.
  (String, int) _coach(AppStrings strings) {
    if (_controller.phase == GamePhase.memorize) {
      return (strings.tutorialMemorize, 1);
    }
    final allPlaced = _controller.placedCount == _controller.objects.length;
    if (!allPlaced) return (strings.tutorialDrag, 2);
    final unturned = _controller.objects
        .any((o) => o.isDirectional && o.placedAngleStep == 0);
    if (unturned) return (strings.tutorialRotate, 3);
    return (strings.tutorialFake, 4);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.phase == GamePhase.result) {
          return _TutorialDone(onStart: () => Navigator.of(context).pop());
        }
        final (text, step) = _coach(strings);
        return PlayScaffold(
          controller: _controller,
          banner: _CoachBanner(
            text: text,
            step: step,
            total: _totalSteps,
            onSkip: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}

class _CoachBanner extends StatelessWidget {
  const _CoachBanner({
    required this.text,
    required this.step,
    required this.total,
    required this.onSkip,
  });

  final String text;
  final int step;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      strings.tutorialStep(step, total),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    const LanguageSwitcher(compact: true),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(strings.tutorialSkip),
                    ),
                  ],
                ),
                Text(
                  text,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialDone extends StatelessWidget {
  const _TutorialDone({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LanguageSwitcher(),
            ),
            Icon(Icons.emoji_events, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              strings.tutorialDoneTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(strings.tutorialDoneBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            for (final environment in Environments.all)
              ListTile(
                leading: Icon(environment.icon),
                title: Text(strings.environmentName(environment)),
                // Hard has headings on, so the full rule is shown.
                subtitle: Text(
                  strings.ruleHint(environment, GameConfigs.hard),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onStart,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(strings.startPlaying),
            ),
          ],
        ),
      ),
    );
  }
}
