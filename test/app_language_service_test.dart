import 'package:finance_tracker/services/app_language_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English is the only language currently exposed', () {
    expect(AppLanguageService.instance.supportedLanguages, hasLength(1));
    expect(AppLanguageService.instance.supportedLanguages.single.code, 'en');
  });

  test('unknown persisted language codes safely fall back to English', () {
    final language = AppLanguageService.instance.languageForCode('unknown');

    expect(language.code, 'en');
    expect(language.locale.languageCode, 'en');
  });
}
