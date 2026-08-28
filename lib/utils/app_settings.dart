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
  static bool autoStartEnabled = false;
  static bool batteryExemptionEnabled = false;
  static List<String> allowedNotificationApps = [];

  // Chart Trend Line Preferences (Default: Expense ON, Income OFF, Transfer OFF)
  static bool showExpenseTrendLine = true;
  static bool showIncomeTrendLine = false;
  static bool showTransferTrendLine = false;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    snackBarDurationMs = prefs.getInt('snackbar_duration_ms') ?? 1500;
    autoHideEnabled = prefs.getBool('auto_hide_enabled') ?? false;
    autoHideSeconds = prefs.getInt('auto_hide_seconds') ?? 5;
    currencySymbol = prefs.getString('currency_symbol') ?? '₹';
    numberLocale = prefs.getString('number_locale') ?? 'auto';
    appLanguageCode = prefs.getString('app_language_code') ?? 'en';
    smartTrackingEnabled = prefs.getBool('smart_tracking_enabled') ?? true;
    autoStartEnabled = prefs.getBool('auto_start_enabled') ?? false;
    batteryExemptionEnabled = prefs.getBool('battery_exemption_enabled') ?? false;
    final userDisabledAutoDelete = prefs.getBool('auto_delete_user_disabled') ?? false;
    if (smartTrackingEnabled && !userDisabledAutoDelete) {
      autoDeleteArchive = true;
      autoDeleteValue = prefs.getInt('auto_delete_value') ?? 1;
      autoDeleteUnit = prefs.getString('auto_delete_unit') ?? 'months';
      await prefs.setBool('auto_delete_archive', true);
      await prefs.setInt('auto_delete_value', autoDeleteValue);
      await prefs.setString('auto_delete_unit', autoDeleteUnit);
    } else {
      autoDeleteArchive = prefs.getBool('auto_delete_archive') ?? false;
      autoDeleteValue = prefs.getInt('auto_delete_value') ?? 1;
      autoDeleteUnit = prefs.getString('auto_delete_unit') ?? 'months';
    }
    if (autoDeleteUnit == 'years') {
      autoDeleteUnit = 'months';
    }
    allowedNotificationApps =
        prefs.getStringList('allowed_notification_apps') ?? [];

    showExpenseTrendLine = prefs.getBool('show_expense_trend_line') ?? true;
    showIncomeTrendLine = prefs.getBool('show_income_trend_line') ?? false;
    showTransferTrendLine = prefs.getBool('show_transfer_trend_line') ?? false;
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
    await prefs.setBool('auto_delete_user_disabled', !enabled);
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

  static Future<void> setAutoStartEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_enabled', enabled);
    autoStartEnabled = enabled;
  }

  static Future<void> setBatteryExemptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_exemption_enabled', enabled);
    batteryExemptionEnabled = enabled;
  }

  static Future<void> setSmartTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_tracking_enabled', enabled);
    smartTrackingEnabled = enabled;

    final userDisabledAutoDelete = prefs.getBool('auto_delete_user_disabled') ?? false;

    if (enabled) {
      if (!userDisabledAutoDelete) {
        await prefs.setBool('auto_delete_archive', true);
        await prefs.setInt('auto_delete_value', 1);
        await prefs.setString('auto_delete_unit', 'months');
        autoDeleteArchive = true;
        autoDeleteValue = 1;
        autoDeleteUnit = 'months';
      }
    } else {
      await prefs.setBool('auto_delete_archive', false);
      autoDeleteArchive = false;
    }
  }

  static Future<void> setAllowedNotificationApps(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    allowedNotificationApps = List.from(packages);
    await prefs.setStringList('allowed_notification_apps', packages);
  }

  static Future<void> setShowExpenseTrendLine(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_expense_trend_line', enabled);
    showExpenseTrendLine = enabled;
  }

  static Future<void> setShowIncomeTrendLine(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_income_trend_line', enabled);
    showIncomeTrendLine = enabled;
  }

  static Future<void> setShowTransferTrendLine(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_transfer_trend_line', enabled);
    showTransferTrendLine = enabled;
  }
}
