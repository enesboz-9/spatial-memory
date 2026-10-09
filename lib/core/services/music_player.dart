import 'dart:async';
import 'dart:math' show max;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../models/environment.dart';

/// Looping background music, one track per environment
/// ([Environment.musicAsset]).
///
/// The screens only say which environment is on ([playFor]); the player
/// fades between tracks, keeps the same track going while the player moves
/// between the home screen and a round of that environment, and stays quiet
/// while sound is switched off or the app is in the background.
///
/// Audio must never break the game: every platform error is swallowed.
class MusicPlayer {
  MusicPlayer({AudioPlayer Function()? playerFactory, double volume = 0.4})
      : _playerFactory = playerFactory ?? AudioPlayer.new,
        _baseVolume = volume;

  /// Loudness at the slider's top position (0.0 - 1.0). The tracks are mixed
  /// quietly already, so this stays well below 1.
  final double _baseVolume;

  /// The player's own volume setting (0.0 - 1.0), from the volume slider.
  double _userVolume = 1.0;

  /// Real playback volume: the base level scaled by the slider.
  double get volume => _baseVolume * _userVolume;

  static const Duration _fadeOut = Duration(milliseconds: 350);
  static const Duration _fadeIn = Duration(milliseconds: 900);
  static const Duration _fadeStep = Duration(milliseconds: 50);

  final AudioPlayer Function() _playerFactory;

  /// Created on first use, so tests that never play music need no plugin.
  AudioPlayer? _player;

  String? _wanted;
  String? _loaded;
  bool _enabled = true;
  bool _inBackground = false;
  double _level = 0;

  /// Every [_sync] bumps this; an older run stops as soon as it notices.
  int _token = 0;

  /// The track of [environment] should be playing (if music is allowed).
  void playFor(Environment environment) {
    if (_wanted == environment.musicAsset) return;
    _wanted = environment.musicAsset;
    unawaited(_sync());
  }

  /// Follows the volume slider. Applies at once to what is playing, and
  /// (re)starts the music when it should be audible but is not playing yet
  /// (e.g. the browser blocked autoplay until the first tap).
  set userVolume(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    if (_userVolume == clamped) return;
    _userVolume = clamped;
    if (_player == null && _wanted == null) return;
    // A running fade would overwrite the new level; restart the sync with a
    // very short fade so the slider feels immediate.
    unawaited(_sync(fadeIn: _fadeStep));
  }

  /// Follows the sound switch of the home screen.
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    unawaited(_sync());
  }

  /// The app went to the background (true) or came back (false).
  set inBackground(bool value) {
    if (_inBackground == value) return;
    _inBackground = value;
    unawaited(_sync());
  }

  Future<void> dispose() async {
    _token++;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }

  Future<void> _sync({Duration fadeIn = _fadeIn}) async {
    final token = ++_token;
    final wanted = _wanted;
    final shouldPlay = _enabled && !_inBackground && wanted != null;
    try {
      final player = _player ??= _createPlayer();
      if (!shouldPlay) {
        if (player.state == PlayerState.playing || _loaded != null) {
          await _fadeTo(player, 0, _fadeOut, token);
          if (token == _token) await player.pause();
        }
        return;
      }
      if (_loaded != wanted) {
        if (_loaded != null && player.state == PlayerState.playing) {
          await _fadeTo(player, 0, _fadeOut, token);
          if (token != _token) return;
        }
        _level = 0;
        await player.play(AssetSource(wanted), volume: 0);
        _loaded = wanted;
        if (token != _token) {
          // Switched off / backgrounded while the track was starting.
          if (!(_enabled && !_inBackground)) await player.pause();
          return;
        }
      } else if (player.state != PlayerState.playing) {
        await player.setVolume(0);
        _level = 0;
        await player.resume();
        if (token != _token) return;
      }
      await _fadeTo(player, volume, fadeIn, token);
    } catch (_) {
      // No audio device, autoplay blocked on the web, missing plugin...
      // The next change (a tap on a chip, the sound switch) tries again.
    }
  }

  AudioPlayer _createPlayer() {
    final player = _playerFactory();
    unawaited(player.setReleaseMode(ReleaseMode.loop));
    return player;
  }

  Future<void> _fadeTo(
    AudioPlayer player,
    double target,
    Duration duration,
    int token,
  ) async {
    final steps = max(1, duration.inMilliseconds ~/ _fadeStep.inMilliseconds);
    final from = _level;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(_fadeStep);
      if (token != _token) return;
      _level = from + (target - from) * i / steps;
      await player.setVolume(_level);
    }
  }
}

/// Makes the [MusicPlayer] available to every screen.
class MusicScope extends InheritedWidget {
  const MusicScope({super.key, required this.music, required super.child});

  final MusicPlayer music;

  static MusicPlayer of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<MusicScope>();
    assert(scope != null, 'No MusicScope above this widget');
    return scope!.music;
  }

  @override
  bool updateShouldNotify(MusicScope oldWidget) => music != oldWidget.music;
}
