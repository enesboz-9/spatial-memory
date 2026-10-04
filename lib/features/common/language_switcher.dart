import 'package:flutter/material.dart';

import '../../core/l10n/app_language.dart';

/// Small EN / TR switch. Used on the home screen and in the tutorial.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  /// Short labels ("EN", "TR") and tighter spacing, for crowded strips.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.controllerOf(context);
    return SegmentedButton<AppLanguage>(
      showSelectedIcon: false,
      style: compact
          ? const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      segments: [
        for (final language in AppLanguage.values)
          ButtonSegment(
            value: language,
            label: Text(
              compact ? language.code.toUpperCase() : language.nativeName,
            ),
          ),
      ],
      selected: {controller.value},
      onSelectionChanged: (selection) => controller.value = selection.first,
    );
  }
}
