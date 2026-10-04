import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/services/progress_store.dart';

/// The speaker icon. Tapping it opens a small panel with the volume slider
/// and a switch that turns everything off (music, sounds, vibration).
class SoundButton extends StatelessWidget {
  const SoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final store = ProgressScope.of(context);
    final muted = !store.feedbackEnabled || store.musicVolume == 0;
    return IconButton(
      tooltip: store.feedbackEnabled ? strings.soundOn : strings.soundOff,
      icon: Icon(
        muted
            ? Icons.volume_off
            : store.musicVolume < 0.4
                ? Icons.volume_down
                : Icons.volume_up,
      ),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _SoundDialog(),
      ),
    );
  }
}

class _SoundDialog extends StatelessWidget {
  const _SoundDialog();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final store = ProgressScope.of(context);
    final on = store.feedbackEnabled;
    return AlertDialog(
      title: Text(strings.soundSettings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.soundSwitchLabel),
            value: on,
            onChanged: (value) => store.feedbackEnabled = value,
          ),
          const SizedBox(height: 8),
          Text(strings.musicVolumeLabel),
          Row(
            children: [
              Icon(
                store.musicVolume == 0 ? Icons.volume_mute : Icons.volume_down,
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: store.musicVolume,
                  onChanged: on ? (value) => store.musicVolume = value : null,
                ),
              ),
              Text('${(store.musicVolume * 100).round()}%'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.close),
        ),
      ],
    );
  }
}
