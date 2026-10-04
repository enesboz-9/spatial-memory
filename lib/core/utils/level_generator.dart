import 'dart:math';
import 'dart:ui' show Offset;

import '../constants/game_constants.dart';
import '../models/environment.dart';
import '../models/game_config.dart';
import '../models/game_object.dart';

/// Builds a level. The same seed always produces the same objects, positions
/// and headings (used later for the Daily Challenge).
abstract final class LevelGenerator {
  static List<GameObject> generate({
    required Environment environment,
    required GameConfig config,
    required int seed,
  }) {
    final random = Random(seed);
    final pool = [...environment.objectPool]..shuffle(random);
    final count = min(config.objectCount, pool.length);

    final units = _buildUnits(
      environment: environment,
      pool: pool,
      count: count,
      rotationEnabled: config.rotationEnabled,
      rotatedObjects: config.rotatedObjects,
      random: random,
    );
    final total = units.fold<int>(0, (sum, u) => sum + u.definitions.length);

    final placed = _placeUnits([for (final u in units) u.offsets], random);
    final positions = placed == null
        ? _gridPositions(total)
        : [for (final shape in placed) ...shape];

    final objects = <GameObject>[];
    var cursor = 0;
    var nextClusterId = 0;
    // Units start with the signature (directional) objects, so with a limited
    // rotation count the first directional objects are the ones that turn.
    var rotationsLeft = config.rotatedObjects ?? count;
    for (final unit in units) {
      final clusterId =
          unit.kind == _UnitKind.cluster ? nextClusterId++ : null;
      for (var i = 0; i < unit.definitions.length; i++) {
        final definition = unit.definitions[i];
        final position = positions[cursor++];
        var steps = 0;
        if (definition.isDirectional &&
            config.rotationEnabled &&
            rotationsLeft > 0) {
          steps = environment.directionSteps;
          rotationsLeft--;
        }
        objects.add(
          GameObject(
            definition: definition,
            targetX: position.dx,
            targetY: position.dy,
            directionSteps: steps,
            targetAngleStep: steps > 0 ? random.nextInt(steps) : 0,
            anchorId: unit.kind == _UnitKind.pair && i == 1
                ? unit.definitions.first.id
                : null,
            clusterId: clusterId,
          ),
        );
      }
    }

    // Partners are generated next to each other; shuffle so the tray order
    // does not give the structure away.
    objects.shuffle(random);
    return objects;
  }

  /// Decoys for the tray: objects of the environment that are not part of
  /// [objects]. Deterministic for a seed, and drawn from their own random
  /// stream so the real layout does not change when fakes are switched on.
  static List<FakeObject> generateFakes({
    required Environment environment,
    required GameConfig config,
    required List<GameObject> objects,
    required int seed,
  }) {
    if (config.fakeCount <= 0) return const [];
    final realIds = {for (final o in objects) o.id};
    final candidates = environment.objectPool
        .where((d) => !realIds.contains(d.id))
        .toList()
      ..shuffle(Random(seed + 7919));
    return [
      for (final definition in candidates.take(config.fakeCount))
        FakeObject(
          definition: definition,
          directionSteps: definition.isDirectional && config.rotationEnabled
              ? environment.directionSteps
              : 0,
        ),
    ];
  }

  /// Random positions that keep [GameConstants.minimumObjectDistance] between
  /// each other. If the objects cannot be placed, a grid layout is returned
  /// instead, so generation never loops forever or fails.
  static List<Offset> generatePositions({
    required int count,
    required Random random,
  }) {
    final placed = _placeUnits(
      [
        for (var i = 0; i < count; i++) const [Offset.zero],
      ],
      random,
    );
    if (placed == null) return _gridPositions(count);
    return [for (final shape in placed) ...shape];
  }

  // --- Units ----------------------------------------------------------------

  /// Splits the level into units that are placed as one rigid shape: single
  /// objects, island pairs and camp groups. Groups come first because they are
  /// the hardest to fit.
  static List<_Unit> _buildUnits({
    required Environment environment,
    required List<ObjectDefinition> pool,
    required int count,
    required bool rotationEnabled,
    required int? rotatedObjects,
    required Random random,
  }) {
    final units = <_Unit>[];
    final used = <String>{};
    var remaining = count;
    final groupCount = max(1, count ~/ GameConstants.objectsPerSpecialGroup);
    final mechanic = environment.mechanic;

    if (mechanic == EnvironmentMechanic.relative) {
      final pairs = [...environment.relationPairs]..shuffle(random);
      for (final pair in pairs.take(groupCount)) {
        if (remaining < 2) break;
        units.add(_pairUnit(environment, pair, random));
        used
          ..add(pair.anchorId)
          ..add(pair.childId);
        remaining -= 2;
      }
    } else if (mechanic == EnvironmentMechanic.cluster) {
      final groups = [...environment.clusters]..shuffle(random);
      for (final ids in groups.take(groupCount)) {
        if (remaining < ids.length) break;
        units.add(_clusterUnit(environment, ids, random));
        used.addAll(ids);
        remaining -= ids.length;
      }
    }

    // Single objects. The environment's signature objects (directional ones,
    // the colored bottles) are picked first so the mechanic is always in play.
    final candidates = pool.where((d) => !used.contains(d.id)).toList();
    final List<ObjectDefinition> signature;
    if (mechanic == EnvironmentMechanic.direction && rotationEnabled) {
      signature = candidates
          .where((d) => d.isDirectional)
          .take(rotatedObjects ?? GameConstants.minDirectionalObjects)
          .toList();
    } else if (mechanic == EnvironmentMechanic.color) {
      signature = candidates.where((d) => d.tint != null).toList();
    } else {
      signature = const [];
    }

    final singles = <ObjectDefinition>[...signature.take(remaining)];
    for (final definition in candidates) {
      if (singles.length >= remaining) break;
      if (!singles.contains(definition)) singles.add(definition);
    }
    for (final definition in singles) {
      units.add(
        _Unit(
          kind: _UnitKind.single,
          definitions: [definition],
          offsets: const [Offset.zero],
        ),
      );
    }
    return units;
  }

  static const List<Offset> _directions = [
    Offset(1, 0),
    Offset(-1, 0),
    Offset(0, 1),
    Offset(0, -1),
  ];

  /// Anchor at the origin, the partner a few "meters" to one side of it.
  static _Unit _pairUnit(
    Environment environment,
    RelationPair pair,
    Random random,
  ) {
    final direction = _directions[random.nextInt(_directions.length)];
    final meters = GameConstants
        .relationMeters[random.nextInt(GameConstants.relationMeters.length)];
    return _Unit(
      kind: _UnitKind.pair,
      definitions: [
        environment.definitionById(pair.anchorId),
        environment.definitionById(pair.childId),
      ],
      offsets: [
        Offset.zero,
        direction * (meters / GameConstants.islandSideMeters),
      ],
    );
  }

  /// Group members on a small circle, rotated randomly. The circle is at least
  /// large enough to keep [GameConstants.minimumObjectDistance] between them.
  static _Unit _clusterUnit(
    Environment environment,
    List<String> ids,
    Random random,
  ) {
    final n = ids.length;
    final minRadius = n < 2
        ? 0.0
        : GameConstants.minimumObjectDistance / (2 * sin(pi / n)) * 1.02;
    final radius = max(GameConstants.clusterRadius, minRadius);
    final startAngle = random.nextDouble() * 2 * pi;
    return _Unit(
      kind: _UnitKind.cluster,
      definitions: [for (final id in ids) environment.definitionById(id)],
      offsets: [
        for (var i = 0; i < n; i++)
          Offset.fromDirection(startAngle + 2 * pi * i / n, radius),
      ],
    );
  }

  // --- Placement ------------------------------------------------------------

  /// Places every shape (a list of offsets from a shared origin) inside the
  /// play area, keeping [GameConstants.minimumObjectDistance] between all
  /// points. The whole layout is retried a few times; null means it never fit.
  static List<List<Offset>>? _placeUnits(
    List<List<Offset>> shapes,
    Random random,
  ) {
    for (var layout = 0; layout < GameConstants.maxLayoutAttempts; layout++) {
      final placed = _tryLayout(shapes, random);
      if (placed != null) return placed;
    }
    return null;
  }

  static List<List<Offset>>? _tryLayout(
    List<List<Offset>> shapes,
    Random random,
  ) {
    const margin = GameConstants.spawnMargin;
    final taken = <Offset>[];
    final result = <List<Offset>>[];

    for (final shape in shapes) {
      final minX = shape.map((o) => o.dx).reduce(min);
      final maxX = shape.map((o) => o.dx).reduce(max);
      final minY = shape.map((o) => o.dy).reduce(min);
      final maxY = shape.map((o) => o.dy).reduce(max);

      // Range the shape's origin may take so every point stays in bounds.
      final loX = margin - minX;
      final hiX = 1 - margin - maxX;
      final loY = margin - minY;
      final hiY = 1 - margin - maxY;
      if (hiX < loX || hiY < loY) return null;

      List<Offset>? accepted;
      for (var attempt = 0;
          attempt < GameConstants.maxPlacementAttempts && accepted == null;
          attempt++) {
        final origin = Offset(
          loX + random.nextDouble() * (hiX - loX),
          loY + random.nextDouble() * (hiY - loY),
        );
        final candidate = [for (final o in shape) origin + o];
        final isFarEnough = candidate.every(
          (p) => taken.every(
            (t) => (t - p).distance >= GameConstants.minimumObjectDistance,
          ),
        );
        if (isFarEnough) accepted = candidate;
      }
      if (accepted == null) return null;
      taken.addAll(accepted);
      result.add(accepted);
    }
    return result;
  }

  static List<Offset> _gridPositions(int count) {
    const margin = GameConstants.spawnMargin;
    const span = 1 - 2 * margin;
    final columns = sqrt(count).ceil();
    final rows = (count / columns).ceil();

    double along(int index, int total) =>
        total <= 1 ? 0.5 : margin + span * index / (total - 1);

    return [
      for (var i = 0; i < count; i++)
        Offset(along(i % columns, columns), along(i ~/ columns, rows)),
    ];
  }
}

enum _UnitKind { single, pair, cluster }

/// Objects that are placed together as one rigid shape.
class _Unit {
  const _Unit({
    required this.kind,
    required this.definitions,
    required this.offsets,
  });

  final _UnitKind kind;

  /// For a pair: the anchor first, then the partner.
  final List<ObjectDefinition> definitions;

  /// Position of each definition relative to the unit's origin.
  final List<Offset> offsets;
}
