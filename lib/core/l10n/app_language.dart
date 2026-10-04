import 'package:flutter/widgets.dart';

enum AppLanguage {
  en('en', 'English'),
  tr('tr', 'Türkçe');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

}

/// Holds the language the player picked on the home screen.
class LanguageController extends ValueNotifier<AppLanguage> {
  LanguageController([super.value = AppLanguage.en]);
}

/// Makes the [LanguageController] available to every screen. Widgets that
/// read it through [AppStrings.of] rebuild when the language changes.
class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'No LanguageScope above this context.');
    return scope!.notifier!;
  }
}
