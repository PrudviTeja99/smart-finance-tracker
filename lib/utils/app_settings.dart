import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static int snackBarDurationMs = 1500; // Default 1.5s
  static bool autoHideEnabled = false;
  static int autoHideSeconds = 5; // Default 5s
  static String currencySymbol = '₹'; // Default rupee
  static String numberLocale =
      'auto'; // 'auto', 'en_IN', 'en_US', 'de_DE', 'en_GB'
  static String appLanguageCode = 'en';
  static bool autoDeleteArchive = false;
  static int autoDeleteValue = 30;
  static String autoDeleteUnit = 'days'; // 'days', 'months', 'years'
  static bool smartTrackingEnabled = true;
  static List<String> allowedNotificationApps = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    snackBarDurationMs = prefs.getInt('snackbar_duration_ms') ?? 1500;
    autoHideEnabled = prefs.getBool('auto_hide_enabled') ?? false;
    autoHideSeconds = prefs.getInt('auto_hide_seconds') ?? 5;
    currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    numberLocale = prefs.getString('number_locale') ?? 'auto';
    appLanguageCode = prefs.getString('app_language_code') ?? 'en';
    autoDeleteArchive = prefs.getBool('auto_delete_archive') ?? false;
    autoDeleteValue = prefs.getInt('auto_delete_value') ?? 30;
    autoDeleteUnit = prefs.getString('auto_delete_unit') ?? 'days';
    if (autoDeleteUnit == 'years') {
      autoDeleteUnit = 'months';
    }
    smartTrackingEnabled = prefs.getBool('smart_tracking_enabled') ?? true;
    allowedNotificationApps =
        prefs.getStringList('allowed_notification_apps') ?? [];
  }

  static Future<void> setSnackBarDuration(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('snackbar_duration_ms', ms);
    snackBarDurationMs = ms;
  }

  static Future<void> setAutoHideEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_hide_enabled', enabled);
    autoHideEnabled = enabled;
  }

  static Future<void> setAutoHideSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_hide_seconds', seconds);
    autoHideSeconds = seconds;
  }

  static Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    currencySymbol = symbol;
  }

  static Future<void> setNumberLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('number_locale', locale);
    numberLocale = locale;
  }

  static Future<void> setAppLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', languageCode);
    appLanguageCode = languageCode;
  }

  static Future<void> setAutoDeleteArchive(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_delete_archive', enabled);
    autoDeleteArchive = enabled;
  }

  static Future<void> setAutoDeleteValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_delete_value', value);
    autoDeleteValue = value;
  }

  static Future<void> setAutoDeleteUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auto_delete_unit', unit);
    autoDeleteUnit = unit;
  }

  static Future<void> setSmartTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_tracking_enabled', enabled);
    smartTrackingEnabled = enabled;
  }

  static Future<void> setAllowedNotificationApps(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    allowedNotificationApps = List.from(packages);
    await prefs.setStringList('allowed_notification_apps', packages);
  }
}
