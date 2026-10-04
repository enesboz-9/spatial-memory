import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'progress_store.dart';

/// Sound and vibration cues (background music lives in MusicPlayer).
/// Everything goes through here, so a real audio
/// package can replace [SystemSound] later without touching the screens.
///
/// [SystemSound] only has the platform's click / alert sounds, which is
/// enough for a first version and needs no assets.
class GameFeedback {
  const GameFeedback({required this.enabled});

  /// Follows the sound / vibration switch on the home screen.
  factory GameFeedback.of(BuildContext context) =>
      GameFeedback(enabled: ProgressScope.read(context).feedbackEnabled);

  final bool enabled;

  /// An object was dropped on the play area.
  void drop() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// A placed object was turned.
  void rotate() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// One star was revealed on the result screen.
  void star() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// A PERFECT placement lit up on the result screen.
  void perfect() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// All objects PERFECT.
  void flawless() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  /// A survival run ended.
  void gameOver() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
