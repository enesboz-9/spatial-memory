/// Every tunable number of the game lives here (no magic numbers elsewhere).
///
/// All distances are in normalized coordinates (0.0 - 1.0 of the play area side).
abstract final class GameConstants {
  // --- Level generation -----------------------------------------------------

  /// Minimum distance between two object centers. An object is ~0.17 of the
  /// play area wide on a phone, so this keeps them from visually overlapping.
  static const double minimumObjectDistance = 0.18;

  /// Objects never spawn closer than this to the edge of the play area.
  static const double spawnMargin = 0.12;

  /// Attempts per object (or object group) before the layout is retried.
  static const int maxPlacementAttempts = 100;

  /// Whole-layout retries before falling back to a deterministic grid layout.
  static const int maxLayoutAttempts = 25;

  // --- Scoring --------------------------------------------------------------

  /// Within this distance of the real position an object scores 100%.
  static const double perfectRadius = 0.03;

  /// At this distance (or further) an object scores 0%.
  static const double maxAccuracyDistance = 0.30;

  /// Object score when every object is placed perfectly.
  static const double maxObjectScore = 1000;

  /// Time bonus when finishing instantly with perfect accuracy. The bonus is
  /// scaled by accuracy, so rushing with a bad layout earns (almost) nothing.
  static const double maxTimeBonus = 200;

  // --- Perfect Memory -------------------------------------------------------

  /// An object at or above this accuracy (98-100%) is a PERFECT placement.
  static const double perfectAccuracyThreshold = 0.98;

  /// Bonus points for every PERFECT object (before the difficulty multiplier).
  static const double perfectBonusPerObject = 50;

  /// Extra bonus when every object of the level is PERFECT.
  static const double flawlessBonus = 500;

  // --- Timing -----------------------------------------------------------------

  /// Every difficulty level uses the same timers. The memorize phase can be
  /// skipped early from the game screen.
  static const int defaultMemorizeSeconds = 30;
  static const int defaultPlacementSeconds = 60;

  // --- Fake objects -----------------------------------------------------------

  /// Points lost (before the difficulty multiplier) for every fake object the
  /// player puts in the scene. Fakes never appeared during memorizing.
  static const double fakePenaltyPerObject = 100;

  // --- Environment mechanics ------------------------------------------------

  /// Direction: how much a completely wrong heading costs an object. 0.4 means
  /// a fully opposite heading keeps only 60% of the position accuracy.
  static const double directionPenaltyWeight = 0.4;

  /// Direction: a level always contains at least this many directional objects
  /// (if the environment has that many).
  static const int minDirectionalObjects = 2;

  /// Island: the play area side, in "meters", used for distance hints.
  static const double islandSideMeters = 10;

  /// Island: distances a partner object can have from its anchor object.
  static const List<double> relationMeters = [2, 3];

  /// Camp: members of a group stand on a circle with (at least) this radius.
  static const double clusterRadius = 0.12;

  /// Island and camp: one pair / group per this many objects (at least one).
  static const int objectsPerSpecialGroup = 4;

  // --- Stars & progression ----------------------------------------------------

  /// Average accuracy needed for 1, 2 and 3 stars. Below the first value a
  /// round earns no star.
  static const double oneStarAccuracy = 0.50;
  static const double twoStarAccuracy = 0.65;
  static const double threeStarAccuracy = 0.80;

  /// At this average accuracy the round is PERFECT and a gift 4th star is
  /// added on top of the three.
  static const double perfectRoundAccuracy = 0.90;
  static const int maxStars = 4;

  /// A difficulty level opens when the previous level of the same environment
  /// was finished with at least this many stars.
  static const int starsToUnlockLevel = 2;

  /// Total stars (over every environment and level) needed to open the n-th
  /// environment in [Environments.all]. The first one is always open.
  static const List<int> environmentUnlockStars = [0, 4, 10, 18, 28];

  /// Debug switch: opens every level and environment.
  static const bool unlockEverything = false;

  // --- Survival mode ----------------------------------------------------------

  /// Survival ramp:
  ///  1. Rounds with 1, 2 ... [survivalRampObjects] objects, no rotation.
  ///  2. [survivalRampObjects] objects with 1, 2 ... [survivalRampObjects]
  ///     rotated objects.
  ///  3. From then on every round either adds one object or rotates one more
  ///     object, alternating (see GameConfigs.survivalRound).
  static const int survivalStartObjects = 1;
  static const int survivalRampObjects = 5;
  static const int survivalMaxObjects = 15;

  /// The run ends when a round's average accuracy drops below this.
  static const double survivalMinAccuracy = 0.40;

  /// Score multiplier grows by this much per round (capped).
  static const double survivalMultiplierStep = 0.1;
  static const double survivalMaxMultiplier = 3.0;

  // --- Feedback ---------------------------------------------------------------

  /// Delay between the stars / perfect pops on the result screen.
  static const Duration feedbackStagger = Duration(milliseconds: 380);

  // --- UI -------------------------------------------------------------------

  static const double objectSize = 56;
  static const double resultMarkerSize = 28;
  static const double directionArrowLength = 9;
  static const int memorizeWarningSeconds = 3;
  static const int placementUrgentSeconds = 10;
  static const Duration tick = Duration(seconds: 1);
}
