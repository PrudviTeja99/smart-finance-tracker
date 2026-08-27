import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../utils/app_settings.dart';
import '../l10n/app_localizations.dart';

/// A supported in-app display language. Add future languages here first, then
/// provide their translation resources before exposing them to users.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;

  Locale get locale => Locale(code);
}

class AppLanguageService {
  AppLanguageService._();

  static final AppLanguageService instance = AppLanguageService._();

  List<AppLanguage> get supportedLanguages => AppLocalizations.supportedLocales
      .map((locale) {
        final code = locale.languageCode;
        if (code == 'te') {
          return const AppLanguage(
            code: 'te',
            name: 'Telugu',
            nativeName: 'తెలుగు (Telugu)',
          );
        }
        return const AppLanguage(
          code: 'en',
          name: 'English',
          nativeName: 'English',
        );
      })
      .toList(growable: false);

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  AppLanguage get selectedLanguage =>
      languageForCode(AppSettings.appLanguageCode);

  AppLanguage languageForCode(String code) {
    return supportedLanguages.firstWhere(
      (language) => language.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Applies the persisted setting after [AppSettings.load] completes.
  void initialize() {
    locale.value = selectedLanguage.locale;
  }

  Future<void> selectLanguage(String code) async {
    final selected = languageForCode(code);
    await AppSettings.setAppLanguageCode(selected.code);
    locale.value = selected.locale;
  }
}
