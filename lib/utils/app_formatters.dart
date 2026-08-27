import 'dart:io';
import 'package:intl/intl.dart';
import 'app_settings.dart';

class AppFormatters {
  static final Map<String, NumberFormat> _formatterCache = {};

  /// Resolves the effective locale string for localized number formatting
  static String get effectiveLocale {
    if (AppSettings.numberLocale != 'auto') {
      return AppSettings.numberLocale;
    }
    // Auto-detect best matching locale based on currency symbol or system locale
    if (AppSettings.currencySymbol == '₹') {
      return 'en_IN';
    } else if (AppSettings.currencySymbol == '€') {
      return 'de_DE';
    } else if (AppSettings.currencySymbol == '£') {
      return 'en_GB';
    } else if (AppSettings.currencySymbol == '¥') {
      return 'ja_JP';
    } else {
      try {
        final sysLocale = Platform.localeName;
        return sysLocale.isNotEmpty ? sysLocale : 'en_US';
      } catch (_) {
        return 'en_US';
      }
    }
  }

  /// Clears formatter cache when settings (locale/symbol) change
  static void clearCache() {
    _formatterCache.clear();
  }

  /// Formats a double amount into a localized string with proper comma separators.
  /// Example (en_IN): 1234567.89 -> "₹12,34,567.89"
  /// Example (en_US): 1234567.89 -> "$1,234,567.89"
  /// Example (de_DE): 1234567.89 -> "1.234.567,89 €"
  static String formatAmount(
    double amount, {
    bool includeSymbol = true,
    int? decimalDigits,
    bool shouldHide = false,
  }) {
    if (shouldHide) {
      return includeSymbol ? '${AppSettings.currencySymbol}••••' : '••••';
    }

    final decimals = decimalDigits ?? (amount % 1 == 0 ? 0 : 2);
    final locale = effectiveLocale;
    final symbol = includeSymbol ? AppSettings.currencySymbol : '';

    final cacheKey = '$locale|$symbol|$decimals';

    NumberFormat formatter = _formatterCache[cacheKey] ??= NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimals,
    );

    return formatter.format(amount).trim();
  }
}
