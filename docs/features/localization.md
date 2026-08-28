# Localization (l10n) Architecture

## 1. Overview
The app supports multi-language UI rendering using Flutter's official localization framework (`flutter_localizations`). Supported locales include **English (`en`)** and **Telugu (`te`)**.

---

## 2. Structure & Binding

- **`lib/l10n/app_en.arb`**: English localization definitions.
- **`lib/l10n/app_te.arb`**: Telugu localization definitions.
- **`AppLanguageService`**: Singleton service handling app-wide locale switching.

---

## 3. Best Practices
- Keep state variables bound to canonical internal keys (e.g. `'This Month'`, `'bank'`, `'debit'`).
- Translate only display labels using `AppLocalizations.of(context)!`.

