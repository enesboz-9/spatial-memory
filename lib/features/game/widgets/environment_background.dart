import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/models/environment.dart';

/// Stylized 2D backdrop for an environment (flat color plus simple details).
class EnvironmentBackground extends StatelessWidget {
  const EnvironmentBackground({super.key, required this.environment});

  final Environment environment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: environment.backgroundColor,
        child: SizedBox.expand(
          child: CustomPaint(painter: _painterFor(environment.background)),
        ),
      ),
    );
  }
}

CustomPainter _painterFor(BackgroundStyle style) => switch (style) {
      BackgroundStyle.stars => const _StarFieldPainter(),
      BackgroundStyle.sea => const _SeaPainter(),
      BackgroundStyle.laboratory => const _LaboratoryPainter(),
      BackgroundStyle.streets => const _StreetsPainter(),
      BackgroundStyle.meadow => const _MeadowPainter(),
    };

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  static const int _starCount = 40;
  static const int _seed = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(_seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (var i = 0; i < _starCount; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        0.8 + random.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Waves around a sandy island with a green middle.
class _SeaPainter extends CustomPainter {
  const _SeaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(11);
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 18; i++) {
      canvas.drawArc(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          18,
          8,
        ),
        0,
        pi,
        false,
        wave,
      );
    }

    final center = size.center(Offset.zero);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.92,
        height: size.height * 0.86,
      ),
      Paint()..color = const Color(0xFFE3C98F).withValues(alpha: 0.75),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.74,
        height: size.height * 0.68,
      ),
      Paint()..color = const Color(0xFF4C9A5B).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floor tiles.
class _LaboratoryPainter extends CustomPainter {
  const _LaboratoryPainter();

  static const int _cells = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < _cells; i++) {
      final x = size.width * i / _cells;
      final y = size.height * i / _cells;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Two crossing roads with dashed center lines.
class _StreetsPainter extends CustomPainter {
  const _StreetsPainter();

  static const double _roadWidth = 0.16;
  static const double _dash = 9;
  static const double _gap = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xFF3A3F49);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * (0.5 - _roadWidth / 2),
        size.width,
        size.height * _roadWidth,
      ),
      road,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * (0.5 - _roadWidth / 2),
        0,
        size.width * _roadWidth,
        size.height,
      ),
      road,
    );

    final marking = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += _dash + _gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + _dash, size.height / 2),
        marking,
      );
    }
    for (var y = 0.0; y < size.height; y += _dash + _gap) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + _dash),
        marking,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Grass tufts.
class _MeadowPainter extends CustomPainter {
  const _MeadowPainter();

  static const int _tuftCount = 70;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(5);
    final light = Paint()..color = const Color(0xFF3F7A45).withValues(alpha: 0.7);
    final dark = Paint()..color = const Color(0xFF24492A).withValues(alpha: 0.7);
    for (var i = 0; i < _tuftCount; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        2 + random.nextDouble() * 3,
        i.isEven ? light : dark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
