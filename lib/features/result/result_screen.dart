import 'dart:async';
import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../core/constants/game_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/game_object.dart';
import '../../core/models/score_result.dart';
import '../../core/services/game_feedback.dart';
import '../game/game_controller.dart';
import '../game/widgets/environment_background.dart';
import '../game/widgets/object_badge.dart';
import '../game/widgets/relation_overlay.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.controller,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onHome,
    this.secondaryLabel,
    this.onSecondary,
    this.notes = const [],
    this.extra,
    this.homeLabel,
  });

  final GameController controller;

  /// Main button ("Play again", "Next level", "Next round"...).
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onHome;
  final String? homeLabel;

  /// Short highlights under the stars ("New record!", "Level unlocked").
  final List<String> notes;

  /// Optional block under the notes (survival run status).
  final Widget? extra;

  static const Color _targetColor = Colors.redAccent;
  static const Color _placedColor = Colors.greenAccent;
  static const Color _perfectColor = Color(0xFFFFC107);
  static const Color _fakeColor = Colors.deepOrangeAccent;

  @override
  Widget build(BuildContext context) {
    final score = controller.score;
    if (score == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final fakes = controller.fakes;
    final penaltyEach = GameConstants.fakePenaltyPerObject.round();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(strings.resultTitle, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 4),
            _StarReveal(score: score),
            Center(
              child: Text(
                '${(score.averageAccuracy * 100).round()}%',
                style: theme.textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Center(
              child: Text(
                strings.objectsPlaced(score.placedCount, score.placements.length),
              ),
            ),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: _NoteChip(label: note)),
              ),
            if (extra != null) ...[
              const SizedBox(height: 12),
              extra!,
            ],
            const SizedBox(height: 12),
            _PerfectSummary(score: score),
            const SizedBox(height: 16),
            _ResultMap(controller: controller, score: score),
            const SizedBox(height: 8),
            _Legend(
              showPerfect: score.perfectCount > 0,
              showFake: score.fakePlacedCount > 0,
            ),
            const SizedBox(height: 16),
            for (final placement in score.placements)
              _PlacementRow(placement: placement),
            if (fakes.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                strings.fakeSectionTitle(score.fakeAvoidedCount, score.fakeTotal),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final fake in fakes) _FakeRow(fake: fake),
            ],
            const Divider(height: 32),
            _ScoreRow(label: strings.objectScore, value: '${score.objectScore}'),
            _ScoreRow(label: strings.timeBonus, value: '+${score.timeBonus}'),
            _ScoreRow(
              label: strings.perfectBonus(
                score.perfectCount,
                GameConstants.perfectBonusPerObject.round(),
              ),
              value: '+${score.perfectBonus}',
            ),
            if (score.isFlawless)
              _ScoreRow(
                label: strings.flawlessBonus,
                value: '+${score.flawlessBonus}',
              ),
            if (score.fakePlacedCount > 0)
              _ScoreRow(
                label: strings.fakePenalty(score.fakePlacedCount, penaltyEach),
                value: '-${score.fakePenalty}',
              ),
            _ScoreRow(
              label: strings.difficultyRow(
                strings.difficultyName(controller.config),
              ),
              value: '×${controller.config.scoreMultiplier.toStringAsFixed(1)}',
            ),
            _ScoreRow(
              label: strings.finalScore,
              value: '${score.finalScore}',
              emphasized: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPrimary,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onSecondary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(secondaryLabel!),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onHome,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(homeLabel ?? strings.mainMenu),
            ),
          ],
        ),
      ),
    );
  }
}

/// The second goal of a round: not just finishing, but nailing objects.
class _PerfectSummary extends StatelessWidget {
  const _PerfectSummary({required this.score});

  final ScoreResult score;

  @override
  Widget build(BuildContext context) {
    final total = score.placements.length;
    final strings = AppStrings.of(context);
    if (score.isFlawless) {
      return Center(
        child: _PerfectChip(label: strings.flawless(total), large: true),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star, color: ResultScreen._perfectColor, size: 20),
        const SizedBox(width: 4),
        Text(
          strings.perfectSummary(
            score.perfectCount,
            total,
            (GameConstants.perfectAccuracyThreshold * 100).round(),
          ),
        ),
      ],
    );
  }
}

/// Gold "PERFECT!" label that pops in.
class _PerfectChip extends StatelessWidget {
  const _PerfectChip({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 16 : 8,
          vertical: large ? 8 : 3,
        ),
        decoration: BoxDecoration(
          color: ResultScreen._perfectColor,
          borderRadius: BorderRadius.circular(large ? 20 : 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: large ? 18 : 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ResultMap extends StatelessWidget {
  const _ResultMap({required this.controller, required this.score});

  final GameController controller;
  final ScoreResult score;

  @override
  Widget build(BuildContext context) {
    const markerSize = GameConstants.resultMarkerSize;
    const placedSize = markerSize * 0.8;
    final objects = [for (final p in score.placements) p.object];

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child:
                    EnvironmentBackground(environment: controller.environment),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ErrorLinePainter(score.placements),
                ),
              ),
              // Island lines / camp rings: real ones, then the player's.
              Positioned.fill(
                child: RelationOverlay(
                  objects: objects,
                  ringPadding: markerSize,
                ),
              ),
              Positioned.fill(
                child: RelationOverlay(
                  objects: objects,
                  usePlaced: true,
                  showLabels: false,
                  color: ResultScreen._placedColor,
                  ringPadding: markerSize,
                ),
              ),
              for (final placement in score.placements) ...[
                // Real position: red ring (gold when PERFECT).
                Positioned(
                  left: placement.object.targetX * side - markerSize / 2,
                  top: placement.object.targetY * side - markerSize / 2,
                  child: _PerfectGlow(
                    active: placement.isPerfect,
                    size: markerSize,
                    child: _Marker(
                      definition: placement.object.definition,
                      size: markerSize,
                      ringColor: placement.isPerfect
                          ? ResultScreen._perfectColor
                          : ResultScreen._targetColor,
                      angle: placement.object.isDirectional
                          ? placement.object.targetAngle
                          : null,
                    ),
                  ),
                ),
                // Player position: green ring.
                if (placement.isPlaced)
                  Positioned(
                    left: placement.object.placedX! * side - placedSize / 2,
                    top: placement.object.placedY! * side - placedSize / 2,
                    child: _Marker(
                      definition: placement.object.definition,
                      size: placedSize,
                      ringColor: ResultScreen._placedColor,
                      angle: placement.object.isDirectional
                          ? placement.object.placedAngle
                          : null,
                    ),
                  ),
              ],
              // Fakes the player put down (they were never in the scene).
              for (final fake in controller.fakes)
                if (fake.isPlaced)
                  Positioned(
                    left: fake.placedX! * side - placedSize / 2,
                    top: fake.placedY! * side - placedSize / 2,
                    child: _Marker(
                      definition: fake.definition,
                      size: placedSize,
                      ringColor: ResultScreen._fakeColor,
                      angle: fake.isDirectional ? fake.placedAngle : null,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Small round marker: the object's icon (in its own color, if it has one) in
/// a ring, plus a heading arrow for directional objects.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.definition,
    required this.size,
    required this.ringColor,
    this.angle,
  });

  final ObjectDefinition definition;
  final double size;
  final Color ringColor;
  final double? angle;

  @override
  Widget build(BuildContext context) {
    final angle = this.angle;
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: ringColor, width: 3),
      ),
      child: Icon(
        definition.icon,
        size: size * 0.5,
        color: definition.tint ?? const Color(0xFF1B2440),
      ),
    );
    if (angle == null) return disc;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        disc,
        Positioned.fill(
          child: DirectionArrow(
            angle: angle,
            size: size,
            length: size * 0.3,
            color: ringColor,
          ),
        ),
      ],
    );
  }
}

class _ErrorLinePainter extends CustomPainter {
  const _ErrorLinePainter(this.placements);

  final List<PlacementResult> placements;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (final placement in placements) {
      final object = placement.object;
      if (!placement.isPlaced) continue;
      canvas.drawLine(
        Offset(object.targetX * size.width, object.targetY * size.height),
        Offset(object.placedX! * size.width, object.placedY! * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ErrorLinePainter oldDelegate) =>
      oldDelegate.placements != placements;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.showPerfect, required this.showFake});

  final bool showPerfect;
  final bool showFake;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 4,
      children: [
        _LegendItem(
          color: ResultScreen._targetColor,
          label: strings.legendActual,
        ),
        _LegendItem(
          color: ResultScreen._placedColor,
          label: strings.legendYours,
        ),
        if (showPerfect)
          _LegendItem(
            color: ResultScreen._perfectColor,
            label: strings.legendPerfect,
          ),
        if (showFake)
          _LegendItem(
            color: ResultScreen._fakeColor,
            label: strings.legendFake,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.radio_button_unchecked, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _PlacementRow extends StatelessWidget {
  const _PlacementRow({required this.placement});

  final PlacementResult placement;

  /// Extra line under the name: heading error and/or how it was scored.
  String? _detail(AppStrings strings) {
    if (!placement.isPlaced) return null;
    final parts = <String>[];
    final degrees = placement.angleErrorDegrees;
    if (degrees != null) {
      parts.add(
        degrees == 0 ? strings.directionExact : strings.directionOff(degrees),
      );
    }
    if (placement.scoredRelative) {
      parts.add(
        placement.object.anchorId != null
            ? strings.scoredByPartner
            : strings.scoredByGroup,
      );
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final definition = placement.object.definition;
    final percent = (placement.accuracy * 100).round();
    final detail = _detail(strings);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(definition.icon, size: 22, color: definition.tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.objectName(definition)),
                if (detail != null)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: LinearProgressIndicator(
              value: placement.accuracy,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Align(
              alignment: Alignment.centerRight,
              child: placement.isPerfect
                  ? _PerfectChip(label: strings.perfectChip)
                  : Text(placement.isPlaced ? '$percent%' : strings.notPlaced),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

/// One decoy in the result list: did the player fall for it or not?
class _FakeRow extends StatelessWidget {
  const _FakeRow({required this.fake});

  final FakeObject fake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final placed = fake.isPlaced;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(fake.definition.icon, size: 22, color: fake.definition.tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.objectName(fake.definition)),
                Text(
                  placed ? strings.fakePlacedDetail : strings.fakeAvoidedDetail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          placed
              ? Text(
                  '-${GameConstants.fakePenaltyPerObject.round()}',
                  style: TextStyle(
                    color: ResultScreen._fakeColor,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : const Icon(Icons.check_circle, color: ResultScreen._placedColor),
        ],
      ),
    );
  }
}

/// Up to 4 stars that pop in one by one, each with a small tick. A PERFECT
/// round (90%+) gets a gift 4th star that arrives with a burst of sparks and
/// a "PERFECT!" label. After the stars, every PERFECT object pulses once.
class _StarReveal extends StatefulWidget {
  const _StarReveal({required this.score});

  final ScoreResult score;

  /// Pulses beyond this many would just be a long buzz.
  static const int _maxPerfectPulses = 5;

  static const Color _giftColor = Colors.cyanAccent;

  @override
  State<_StarReveal> createState() => _StarRevealState();
}

class _StarRevealState extends State<_StarReveal>
    with SingleTickerProviderStateMixin {
  final List<Timer> _timers = [];
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  int _shown = 0;
  bool _started = false;

  bool get _hasGift => widget.score.isPerfectRound;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final feedback = GameFeedback.of(context);
    final stars = widget.score.stars;
    var step = 1;
    Duration at() => GameConstants.feedbackStagger * step++;

    for (var i = 1; i <= stars; i++) {
      final isGift = _hasGift && i == GameConstants.maxStars;
      _timers.add(Timer(at(), () {
        if (!mounted) return;
        setState(() => _shown = i);
        if (isGift) {
          _burst.forward(from: 0);
          feedback.flawless();
        } else {
          feedback.star();
        }
      }));
    }
    final pulses = widget.score.perfectCount > _StarReveal._maxPerfectPulses
        ? _StarReveal._maxPerfectPulses
        : widget.score.perfectCount;
    for (var i = 0; i < pulses; i++) {
      _timers.add(Timer(at(), feedback.perfect));
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _burst.dispose();
    super.dispose();
  }

  Widget _slot(int index) {
    final isGift = index == GameConstants.maxStars;
    final color = isGift ? _StarReveal._giftColor : ResultScreen._perfectColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.star_border_rounded, size: 48, color: Colors.white38),
          AnimatedScale(
            scale: _shown >= index ? (isGift ? 1.25 : 1) : 0,
            duration: Duration(milliseconds: isGift ? 800 : 550),
            curve: Curves.elasticOut,
            child: Icon(Icons.star_rounded, size: 48, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final slots = _hasGift ? GameConstants.maxStars : 3;
    final giftShown = _hasGift && _shown >= GameConstants.maxStars;

    return Column(
      children: [
        SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [for (var i = 1; i <= slots; i++) _slot(i)],
              ),
              if (_hasGift)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BurstPainter(
                        progress: _burst,
                        colors: const [
                          ResultScreen._perfectColor,
                          _StarReveal._giftColor,
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedScale(
          scale: giftShown ? 1 : 0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          child: AnimatedOpacity(
            opacity: giftShown ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Column(
              children: [
                Text(
                  strings.roundPerfect,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: ResultScreen._perfectColor,
                      ),
                ),
                Text(
                  strings.bonusStarGift,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _StarReveal._giftColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Sparks that fly outwards from the centre of the star row and fade out.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.colors})
      : super(repaint: progress);

  final Animation<double> progress;
  final List<Color> colors;

  static const int _sparks = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(progress.value);
    if (progress.value == 0 || progress.value == 1) return;
    final center = size.center(Offset.zero);
    final reach = size.width * 0.45;
    final fade = (1 - progress.value).clamp(0.0, 1.0);

    for (var i = 0; i < _sparks; i++) {
      // Fixed pseudo-random spread, so the burst looks the same every time.
      final angle = 2 * pi * i / _sparks + (i.isEven ? 0.0 : 0.11);
      final distance = reach * t * (0.55 + 0.45 * ((i * 37) % 10) / 10);
      final position = center + Offset(cos(angle), sin(angle)) * distance;
      final radius = (3.5 - 2.0 * progress.value) * (i % 3 == 0 ? 1.4 : 1);
      canvas.drawCircle(
        position,
        radius,
        Paint()..color = colors[i % colors.length].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A soft gold glow that pulses a few times around a PERFECT marker.
class _PerfectGlow extends StatefulWidget {
  const _PerfectGlow({
    required this.active,
    required this.size,
    required this.child,
  });

  final bool active;
  final double size;
  final Widget child;

  @override
  State<_PerfectGlow> createState() => _PerfectGlowState();
}

class _PerfectGlowState extends State<_PerfectGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      // Starts after the first star popped, runs a few times, then rests.
      Future<void>.delayed(GameConstants.feedbackStagger, () {
        if (mounted) _pulse.repeat(reverse: true, count: 6);
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ResultScreen._perfectColor
                  .withValues(alpha: 0.35 + 0.45 * _pulse.value),
              blurRadius: 4 + 14 * _pulse.value,
              spreadRadius: 1 + 4 * _pulse.value,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// A highlighted one-line message ("New record!").
class _NoteChip extends StatelessWidget {
  const _NoteChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
