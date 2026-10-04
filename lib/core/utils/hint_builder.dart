import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../models/environment.dart';
import '../models/game_object.dart';
import 'format.dart';
import 'score_calculator.dart';

/// Text shown under the play area while the player memorizes the scene.
abstract final class HintBuilder {
  static const String defaultHint =
      'Study the positions. The objects will disappear.';

  /// Island and camp get a sentence per pair / group, written from the real
  /// level (so it is always true). Other environments show the default text.
  /// English unless [strings] says otherwise.
  static List<String> memorizeHints(
    Environment environment,
    List<GameObject> objects, [
    AppStrings strings = const AppStrings(AppLanguage.en),
  ]) {
    final hints = <String>[];

    if (environment.mechanic == EnvironmentMechanic.relative) {
      final byId = {for (final o in objects) o.id: o};
      for (final child in objects) {
        final anchor = byId[child.anchorId];
        if (anchor == null) continue;
        final dx = child.targetX - anchor.targetX;
        final dy = child.targetY - anchor.targetY;
        final meters = formatMeters(ScoreCalculator.distance(dx, dy, 0, 0));
        hints.add(
          strings.relationHint(
            child.definition,
            anchor.definition,
            meters,
            offsetSide(dx, dy),
          ),
        );
      }
    } else if (environment.mechanic == EnvironmentMechanic.cluster) {
      final groups = <int, List<ObjectDefinition>>{};
      for (final object in objects) {
        final clusterId = object.clusterId;
        if (clusterId == null) continue;
        (groups[clusterId] ??= []).add(object.definition);
      }
      for (final members in groups.values) {
        hints.add(strings.clusterHint(members));
      }
    }

    return hints.isEmpty ? [strings.defaultHint] : hints;
  }
}
