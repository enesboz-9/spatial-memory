import 'package:flutter/material.dart';

import '../core/l10n/app_language.dart';
import '../core/l10n/app_strings.dart';
import '../core/services/music_player.dart';
import '../core/services/progress_store.dart';
import '../features/home/home_screen.dart';
import 'theme.dart';

class SpatialMemoryApp extends StatefulWidget {
  const SpatialMemoryApp({super.key, required this.progress});

  final ProgressStore progress;

  @override
  State<SpatialMemoryApp> createState() => _SpatialMemoryAppState();
}

class _SpatialMemoryAppState extends State<SpatialMemoryApp>
    with WidgetsBindingObserver {
  // The game always starts in English; the player can switch on the home
  // screen or in the tutorial.
  final LanguageController _language = LanguageController(AppLanguage.en);
  final MusicPlayer _music = MusicPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncMusicSwitch();
    widget.progress.addListener(_syncMusicSwitch);
  }

  // Music follows the sound switch and the volume slider.
  void _syncMusicSwitch() {
    _music.userVolume = widget.progress.musicVolume;
    _music.enabled = widget.progress.feedbackEnabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _music.inBackground = state != AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.progress.removeListener(_syncMusicSwitch);
    _music.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      store: widget.progress,
      child: MusicScope(
        music: _music,
        child: LanguageScope(
          controller: _language,
          child: ValueListenableBuilder<AppLanguage>(
            valueListenable: _language,
            builder: (context, language, _) => MaterialApp(
              onGenerateTitle: (_) => AppStrings(language).appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
