import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';

/// A big, eye-catching score panel: total points in large type, with the
/// round and the personal best next to it. Used during the endless run, on
/// its result screen and on the home screen.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.score,
    required this.round,
    required this.best,
    this.highlight = false,
    this.compact = false,
    this.title,
    this.showBest = true,
  });

  final int score;

  /// Round number (or rounds cleared on the home screen).
  final int round;

  /// Best score ever reached in this environment.
  final int best;

  /// Gold glow, e.g. when the run just set a new record.
  final bool highlight;

  /// Smaller version for the in-game strip.
  final bool compact;

  /// Optional heading above the numbers (home screen).
  final String? title;

  /// Hide the BEST column when the score itself is the best.
  final bool showBest;

  static const Color gold = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final accent = highlight ? gold : theme.colorScheme.primary;
    final isBest = score > 0 && score >= best;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: highlight ? 0.45 : 0.2),
            blurRadius: highlight ? 20 : 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 3,
                color: gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
        children: [
          Expanded(
            flex: 3,
            child: _Stat(
              label: strings.scoreLabel,
              value: '$score',
              valueStyle: (compact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(
                fontWeight: FontWeight.w800,
                color: isBest ? gold : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              alignStart: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: _Stat(
              label: strings.roundLabel,
              value: '$round',
              valueStyle: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (showBest)
          Expanded(
            flex: 2,
            child: _Stat(
              label: strings.bestLabel,
              value: '${best > score ? best : score}',
              valueStyle: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w700, color: gold),
              icon: Icons.emoji_events,
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueStyle,
    this.icon,
    this.alignStart = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final IconData? icon;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: ScoreBoard.gold),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: valueStyle),
        ),
      ],
    );
  }
}
