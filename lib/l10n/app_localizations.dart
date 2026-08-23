import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Finance Tracker'**
  String get appTitle;

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navigationInbox;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Inbox'**
  String get inboxTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsAppLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the display language for the app'**
  String get settingsAppLanguageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsManageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Payment Accounts'**
  String get settingsManageAccounts;

  /// No description provided for @settingsActiveAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count} active accounts'**
  String settingsActiveAccounts(int count);

  /// No description provided for @settingsManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Transaction Categories'**
  String get settingsManageCategories;

  /// No description provided for @settingsActiveCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} active categories'**
  String settingsActiveCategories(int count);

  /// No description provided for @settingsCurrencySymbol.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get settingsCurrencySymbol;

  /// No description provided for @settingsCurrencySymbolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display currency across the app'**
  String get settingsCurrencySymbolSubtitle;

  /// No description provided for @settingsNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number Comma Format'**
  String get settingsNumberFormat;

  /// No description provided for @settingsNumberFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comma separation & number localization'**
  String get settingsNumberFormatSubtitle;

  /// No description provided for @settingsAutoHideBalances.
  ///
  /// In en, this message translates to:
  /// **'Auto-Hide Balances on Entry'**
  String get settingsAutoHideBalances;

  /// No description provided for @settingsAutoHideBalancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Masks Dashboard values when app opens'**
  String get settingsAutoHideBalancesSubtitle;

  /// No description provided for @settingsHideDuration.
  ///
  /// In en, this message translates to:
  /// **'Hide Duration'**
  String get settingsHideDuration;

  /// No description provided for @inboxDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get inboxDrafts;

  /// No description provided for @inboxCapturedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Captured Alerts'**
  String get inboxCapturedAlerts;

  /// No description provided for @inboxAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All Caught Up!'**
  String get inboxAllCaughtUp;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending draft transactions. Incoming alerts will show up here.'**
  String get inboxEmpty;

  /// No description provided for @inboxTrackingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Smart Tracking Disabled'**
  String get inboxTrackingDisabled;

  /// No description provided for @inboxTrackingDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on Smart Tracking to automatically capture incoming financial SMS and notification alerts into drafts.'**
  String get inboxTrackingDisabledDescription;

  /// No description provided for @inboxEnableTracking.
  ///
  /// In en, this message translates to:
  /// **'Enable Smart Tracking'**
  String get inboxEnableTracking;

  /// No description provided for @inboxNoCapturedAlerts.
  ///
  /// In en, this message translates to:
  /// **'No Captured Alerts'**
  String get inboxNoCapturedAlerts;

  /// No description provided for @inboxCapturedAlertsEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart Tracking is listening. Notification alerts from financial apps will appear here.'**
  String get inboxCapturedAlertsEnabledDescription;

  /// No description provided for @inboxCapturedAlertsDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable Smart Tracking in Settings to capture notification alerts.'**
  String get inboxCapturedAlertsDisabledDescription;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search merchant or amount...'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboardIncome;

  /// No description provided for @dashboardExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get dashboardExpenses;

  /// No description provided for @dashboardAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get dashboardAccounts;

  /// No description provided for @dashboardTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance: {amount}'**
  String dashboardTotalBalance(Object amount);

  /// No description provided for @dashboardClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get dashboardClearFilter;

  /// No description provided for @dashboardIncomeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Income Analysis'**
  String get dashboardIncomeAnalysis;

  /// No description provided for @dashboardExpenseAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Expense Analysis'**
  String get dashboardExpenseAnalysis;

  /// No description provided for @dashboardTransferAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Transfer Analysis'**
  String get dashboardTransferAnalysis;

  /// No description provided for @dashboardAllTransactionsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'All Transactions Analysis'**
  String get dashboardAllTransactionsAnalysis;

  /// No description provided for @settingsSmartTracking.
  ///
  /// In en, this message translates to:
  /// **'Smart Tracking'**
  String get settingsSmartTracking;

  /// No description provided for @settingsSmartTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read incoming transaction notifications in background'**
  String get settingsSmartTrackingSubtitle;

  /// No description provided for @settingsDisableSmartTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Smart Tracking?'**
  String get settingsDisableSmartTrackingTitle;

  /// No description provided for @settingsDisableSmartTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'The app will stop listening to incoming notifications in the background. New transactions will not be captured automatically until you re-enable this.\n\nArchived alerts, automation logs, and processed queue data will be cleaned up in the background. Your confirmed transactions and learned AI model weights will be preserved.'**
  String get settingsDisableSmartTrackingDescription;

  /// No description provided for @settingsKeepEnabled.
  ///
  /// In en, this message translates to:
  /// **'Keep Enabled'**
  String get settingsKeepEnabled;

  /// No description provided for @settingsDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get settingsDisable;

  /// No description provided for @settingsReliabilityRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Reliability Recommendations'**
  String get settingsReliabilityRecommendations;

  /// No description provided for @settingsReliabilityRecommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure the options below to maximize Smart Tracking reliability, especially on devices with aggressive background management.'**
  String get settingsReliabilityRecommendationsSubtitle;

  /// No description provided for @settingsEnableAutoStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Start (Highly Recommended)'**
  String get settingsEnableAutoStartTitle;

  /// No description provided for @settingsEnableAutoStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows Android to automatically start Smart Finance Tracker after reboot and when notifications arrive. This improves notification capture reliability on many devices with aggressive battery management.'**
  String get settingsEnableAutoStartDescription;

  /// No description provided for @settingsEnableAutoStartBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable Auto Start'**
  String get settingsEnableAutoStartBtn;

  /// No description provided for @settingsEnableUnrestrictedRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Unrestricted Run'**
  String get settingsEnableUnrestrictedRunTitle;

  /// No description provided for @settingsEnableUnrestrictedRunDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevent Android from putting Smart Finance Tracker\'s notification listener to sleep. The app only wakes for a few milliseconds when a notification arrives, so battery impact is minimal.'**
  String get settingsEnableUnrestrictedRunDescription;

  /// No description provided for @settingsEnableUnrestrictedRunBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable Unrestricted Run'**
  String get settingsEnableUnrestrictedRunBtn;

  /// No description provided for @settingsKeepNotificationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Notification Access Enabled'**
  String get settingsKeepNotificationAccessTitle;

  /// No description provided for @settingsKeepNotificationAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Smart Tracking requires notification access to capture incoming transaction alerts. If notification access is disabled, automatic transaction detection will stop working.'**
  String get settingsKeepNotificationAccessDescription;

  /// No description provided for @settingsOpenNotificationAccessBtn.
  ///
  /// In en, this message translates to:
  /// **'Open Notification Access'**
  String get settingsOpenNotificationAccessBtn;

  /// No description provided for @settingsAutoDeleteArchivedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Auto-Delete Archived Alerts'**
  String get settingsAutoDeleteArchivedAlerts;

  /// No description provided for @settingsAutoDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically purge old ignored notification logs'**
  String get settingsAutoDeleteSubtitle;

  /// No description provided for @settingsAutoDeleteRequiresSmartTracking.
  ///
  /// In en, this message translates to:
  /// **'Requires Smart Tracking to be enabled'**
  String get settingsAutoDeleteRequiresSmartTracking;

  /// No description provided for @settingsDisableAutoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Auto-Delete?'**
  String get settingsDisableAutoDeleteTitle;

  /// No description provided for @settingsDisableAutoDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Archived alerts will no longer be automatically cleaned up. Over time, this may increase storage usage as old notification logs accumulate.\n\nYou can still manually delete alerts from the Archived Alerts screen.'**
  String get settingsDisableAutoDeleteDescription;

  /// No description provided for @settingsDeleteOlderThan.
  ///
  /// In en, this message translates to:
  /// **'Delete older than'**
  String get settingsDeleteOlderThan;

  /// No description provided for @settingsViewArchivedAlerts.
  ///
  /// In en, this message translates to:
  /// **'View Archived Alerts'**
  String get settingsViewArchivedAlerts;

  /// No description provided for @settingsViewArchivedAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and restore ignored notifications'**
  String get settingsViewArchivedAlertsSubtitle;

  /// No description provided for @settingsDataAndBackups.
  ///
  /// In en, this message translates to:
  /// **'Data & Backups'**
  String get settingsDataAndBackups;

  /// No description provided for @settingsExportDataBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Data / Backup'**
  String get settingsExportDataBackup;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export transactions as JSON or Excel/CSV (Save or Share)'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportDataRestore.
  ///
  /// In en, this message translates to:
  /// **'Import Data / Restore'**
  String get settingsImportDataRestore;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select file (.json or .csv) to append or replace data'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsExportFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get settingsExportFormatTitle;

  /// No description provided for @settingsExportFormatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select format for transaction export or database backup'**
  String get settingsExportFormatSubtitle;

  /// No description provided for @settingsExportJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'JSON Backup File (.json)'**
  String get settingsExportJsonTitle;

  /// No description provided for @settingsExportJsonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full database backup (accounts, categories, transactions)'**
  String get settingsExportJsonSubtitle;

  /// No description provided for @settingsExportCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Excel / CSV Sheet (.csv)'**
  String get settingsExportCsvTitle;

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Formatted transaction ledger for Excel & Google Sheets'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsExportDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {format} File'**
  String settingsExportDestinationTitle(String format);

  /// No description provided for @settingsExportDestinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose destination for your exported file'**
  String get settingsExportDestinationSubtitle;

  /// No description provided for @settingsSaveLocally.
  ///
  /// In en, this message translates to:
  /// **'Save Locally'**
  String get settingsSaveLocally;

  /// No description provided for @settingsSaveLocallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save directly to phone downloads or local folder'**
  String get settingsSaveLocallySubtitle;

  /// No description provided for @settingsShareViaApps.
  ///
  /// In en, this message translates to:
  /// **'Share via Apps'**
  String get settingsShareViaApps;

  /// No description provided for @settingsShareViaAppsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp, Email, Google Drive, etc.'**
  String get settingsShareViaAppsSubtitle;

  /// No description provided for @settingsFileSavedTo.
  ///
  /// In en, this message translates to:
  /// **'File saved to: {path}'**
  String settingsFileSavedTo(String path);

  /// No description provided for @settingsExportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled or unavailable.'**
  String get settingsExportCanceled;

  /// No description provided for @settingsInvalidFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format. Please select a .json or .csv file.'**
  String get settingsInvalidFileFormat;

  /// No description provided for @settingsImportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportDataTitle;

  /// No description provided for @settingsImportSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {fileName}'**
  String settingsImportSelected(String fileName);

  /// No description provided for @settingsAppendToExisting.
  ///
  /// In en, this message translates to:
  /// **'Append to Existing Data'**
  String get settingsAppendToExisting;

  /// No description provided for @settingsAppendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safely merge new transactions without deleting current data. Duplicates auto-skipped.'**
  String get settingsAppendSubtitle;

  /// No description provided for @settingsOverrideReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Override (Replace All)'**
  String get settingsOverrideReplaceAll;

  /// No description provided for @settingsOverrideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe existing transactions and replace completely with file data.'**
  String get settingsOverrideSubtitle;

  /// No description provided for @settingsConfirmDataOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Data Override'**
  String get settingsConfirmDataOverrideTitle;

  /// No description provided for @settingsConfirmDataOverrideDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to replace all current database records? Existing transactions will be overwritten.'**
  String get settingsConfirmDataOverrideDescription;

  /// No description provided for @settingsReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get settingsReplaceAll;

  /// No description provided for @settingsFailedToReadImportFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to read import file.'**
  String get settingsFailedToReadImportFile;

  /// No description provided for @settingsDatabaseReplacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database replaced successfully!'**
  String get settingsDatabaseReplacedSuccess;

  /// No description provided for @settingsDataImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported & merged successfully!'**
  String get settingsDataImportedSuccess;

  /// No description provided for @settingsInvalidImportFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid or corrupted import file.'**
  String get settingsInvalidImportFile;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsAutoDeleteRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Delete Retention'**
  String get settingsAutoDeleteRetentionTitle;

  /// No description provided for @settingsAutoDeleteRetentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select or type the age of alerts to permanently remove.'**
  String get settingsAutoDeleteRetentionSubtitle;

  /// No description provided for @settingsSaveRetentionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Save Retention Period'**
  String get settingsSaveRetentionPeriod;

  /// No description provided for @settingsManageAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get settingsManageAccountsTitle;

  /// No description provided for @settingsNoAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet. Tap + to add one.'**
  String get settingsNoAccountsYet;

  /// No description provided for @settingsDeleteConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete configuration?'**
  String get settingsDeleteConfigTitle;

  /// No description provided for @settingsDeleteConfigConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String settingsDeleteConfigConfirm(String name);

  /// No description provided for @settingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// No description provided for @settingsEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get settingsEditAccount;

  /// No description provided for @settingsAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get settingsAddAccount;

  /// No description provided for @settingsAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get settingsAccountType;

  /// No description provided for @settingsAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get settingsAccountName;

  /// No description provided for @settingsMatchingKeywords.
  ///
  /// In en, this message translates to:
  /// **'Matching Keywords (comma separated)'**
  String get settingsMatchingKeywords;

  /// No description provided for @settingsMatchingKeywordsHelper.
  ///
  /// In en, this message translates to:
  /// **'E.g. \"5678, SBI\" (used to auto-predict this account)'**
  String get settingsMatchingKeywordsHelper;

  /// No description provided for @settingsStartingBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance ({currency})'**
  String settingsStartingBalance(String currency);

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get settingsAdd;

  /// No description provided for @settingsEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get settingsEditCategory;

  /// No description provided for @settingsAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get settingsAddCategory;

  /// No description provided for @settingsCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get settingsCategoryName;

  /// No description provided for @settingsThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get settingsThemeColor;

  /// No description provided for @settingsCategoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get settingsCategoryIcon;

  /// No description provided for @settingsIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon: \"{icon}\"'**
  String settingsIconLabel(String icon);

  /// No description provided for @settingsBrowseIconsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search from 60+ modern icons'**
  String get settingsBrowseIconsSubtitle;

  /// No description provided for @settingsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get settingsBrowse;

  /// No description provided for @settingsSearchCategoryIcons.
  ///
  /// In en, this message translates to:
  /// **'Search Category Icons'**
  String get settingsSearchCategoryIcons;

  /// No description provided for @settingsSearchIconsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword (e.g. food, taxi, bill...)'**
  String get settingsSearchIconsHint;

  /// No description provided for @settingsNoIconsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching icons found.\nTry another keyword!'**
  String get settingsNoIconsFound;

  /// No description provided for @settingsPickCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a Custom Color'**
  String get settingsPickCustomColor;

  /// No description provided for @settingsShade.
  ///
  /// In en, this message translates to:
  /// **'Shade'**
  String get settingsShade;

  /// No description provided for @settingsHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get settingsHue;

  /// No description provided for @settingsSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get settingsSelectColor;

  /// No description provided for @settingsAccountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get settingsAccountTypeBank;

  /// No description provided for @settingsAccountTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get settingsAccountTypeCard;

  /// No description provided for @settingsAccountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get settingsAccountTypeWallet;

  /// No description provided for @settingsAccountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get settingsAccountTypeCash;

  /// No description provided for @settingsAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get settingsAdvancedSettings;

  /// No description provided for @settingsTrainYourModel.
  ///
  /// In en, this message translates to:
  /// **'Train Your Model'**
  String get settingsTrainYourModel;

  /// No description provided for @settingsTrainYourModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually teach the AI using sample notifications'**
  String get settingsTrainYourModelSubtitle;

  /// No description provided for @settingsSnackBarDuration.
  ///
  /// In en, this message translates to:
  /// **'SnackBar Display Duration'**
  String get settingsSnackBarDuration;

  /// No description provided for @settingsSnackBarDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String settingsSnackBarDurationSubtitle(String seconds);

  /// No description provided for @settingsDeveloperOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get settingsDeveloperOptions;

  /// No description provided for @settingsLogInspector.
  ///
  /// In en, this message translates to:
  /// **'Log Inspector'**
  String get settingsLogInspector;

  /// No description provided for @settingsLogInspectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View live app logs in real time'**
  String get settingsLogInspectorSubtitle;

  /// No description provided for @settingsSimulateNotification.
  ///
  /// In en, this message translates to:
  /// **'Simulate Notification'**
  String get settingsSimulateNotification;

  /// No description provided for @settingsSimulateNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simulate incoming notifications for testing parser/AI'**
  String get settingsSimulateNotificationSubtitle;

  /// No description provided for @settingsModelAuditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Model Automation Audit Log'**
  String get settingsModelAuditLogTitle;

  /// No description provided for @settingsModelAuditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full transparency into automatic actions performed by your on-device AI.'**
  String get settingsModelAuditLogSubtitle;

  /// No description provided for @settingsNoAutomatedActionsYet.
  ///
  /// In en, this message translates to:
  /// **'No automated actions logged yet today.'**
  String get settingsNoAutomatedActionsYet;

  /// No description provided for @settingsAutoDraftedBadge.
  ///
  /// In en, this message translates to:
  /// **'AUTO-DRAFTED'**
  String get settingsAutoDraftedBadge;

  /// No description provided for @settingsAutoDismissedBadge.
  ///
  /// In en, this message translates to:
  /// **'AUTO-DISMISSED'**
  String get settingsAutoDismissedBadge;

  /// No description provided for @settingsConfidencePct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% Conf.'**
  String settingsConfidencePct(int pct);

  /// No description provided for @settingsUndoAutoDraft.
  ///
  /// In en, this message translates to:
  /// **'Undo Auto-Draft'**
  String get settingsUndoAutoDraft;

  /// No description provided for @settingsUndoAutoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Undo Auto-Dismiss'**
  String get settingsUndoAutoDismiss;

  /// No description provided for @settingsRestoredToCapturedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Restored to Captured Alerts!'**
  String get settingsRestoredToCapturedAlerts;

  /// No description provided for @settingsUndoDraftLearnedIgnore.
  ///
  /// In en, this message translates to:
  /// **'Moved back to Captured Alerts. AI learned to ignore similar alerts.'**
  String get settingsUndoDraftLearnedIgnore;

  /// No description provided for @settingsSimulateNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulate Notification'**
  String get settingsSimulateNotificationTitle;

  /// No description provided for @settingsSimulateNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a pre-seeded template or write custom notification data to test parsing, drafts, and active ignore learning.'**
  String get settingsSimulateNotificationDescription;

  /// No description provided for @settingsQuickTemplates.
  ///
  /// In en, this message translates to:
  /// **'Quick Templates'**
  String get settingsQuickTemplates;

  /// No description provided for @settingsAppPackageName.
  ///
  /// In en, this message translates to:
  /// **'App Package Name'**
  String get settingsAppPackageName;

  /// No description provided for @settingsAppPackageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. com.android.messaging'**
  String get settingsAppPackageHint;

  /// No description provided for @settingsNotificationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get settingsNotificationTitleLabel;

  /// No description provided for @settingsNotificationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HDFC Bank'**
  String get settingsNotificationTitleHint;

  /// No description provided for @settingsNotificationBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Body (Message Text)'**
  String get settingsNotificationBodyLabel;

  /// No description provided for @settingsNotificationBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Write transaction message alert text here...'**
  String get settingsNotificationBodyHint;

  /// No description provided for @settingsSimulateAndProcess.
  ///
  /// In en, this message translates to:
  /// **'Simulate & Process'**
  String get settingsSimulateAndProcess;

  /// No description provided for @settingsSimulateRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Package name and notification body are required.'**
  String get settingsSimulateRequiredError;

  /// No description provided for @settingsSimulateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Simulated notification processed successfully! Check Transaction Inbox.'**
  String get settingsSimulateSuccess;

  /// No description provided for @settingsSimulateFailure.
  ///
  /// In en, this message translates to:
  /// **'Simulation failed: {error}'**
  String settingsSimulateFailure(String error);

  /// No description provided for @inboxPendingDraftsTab.
  ///
  /// In en, this message translates to:
  /// **'Pending Drafts ({count})'**
  String inboxPendingDraftsTab(int count);

  /// No description provided for @inboxCapturedAlertsTab.
  ///
  /// In en, this message translates to:
  /// **'Captured Alerts ({count})'**
  String inboxCapturedAlertsTab(int count);

  /// No description provided for @inboxKeepAiIndividual.
  ///
  /// In en, this message translates to:
  /// **'Keep AI/Individual'**
  String get inboxKeepAiIndividual;

  /// No description provided for @inboxSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get inboxSelectAll;

  /// No description provided for @inboxDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get inboxDeselectAll;

  /// No description provided for @inboxConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String inboxConfirmSelected(int count);

  /// No description provided for @inboxDiscardSelected.
  ///
  /// In en, this message translates to:
  /// **'Discard ({count})'**
  String inboxDiscardSelected(int count);

  /// No description provided for @inboxCategorySelected.
  ///
  /// In en, this message translates to:
  /// **'Category ({count})'**
  String inboxCategorySelected(int count);

  /// No description provided for @inboxDiscardSelectedDraftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Selected Drafts?'**
  String get inboxDiscardSelectedDraftsTitle;

  /// No description provided for @inboxDiscardSelectedDraftsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard {count} selected draft transactions?'**
  String inboxDiscardSelectedDraftsConfirm(int count);

  /// No description provided for @inboxDiscardAllDraftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard All Drafts?'**
  String get inboxDiscardAllDraftsTitle;

  /// No description provided for @inboxDiscardAllDraftsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard all {count} pending draft transactions? This action cannot be undone.'**
  String inboxDiscardAllDraftsConfirm(int count);

  /// No description provided for @inboxClearAllAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Alerts?'**
  String get inboxClearAllAlertsTitle;

  /// No description provided for @inboxClearAllAlertsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all {count} captured notification logs? Old logs will be archived.'**
  String inboxClearAllAlertsConfirm(int count);

  /// No description provided for @inboxNoDraftsYet.
  ///
  /// In en, this message translates to:
  /// **'No pending draft transactions!'**
  String get inboxNoDraftsYet;

  /// No description provided for @inboxNoDraftsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming SMS and app notification alerts will show up here for 1-tap confirmation.'**
  String get inboxNoDraftsSubtitle;

  /// No description provided for @inboxNoAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No captured notification alerts!'**
  String get inboxNoAlertsYet;

  /// No description provided for @inboxNoAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Tracking will automatically record financial app notifications here.'**
  String get inboxNoAlertsSubtitle;

  /// No description provided for @inboxConfirmedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Confirmed transaction under \"{category}\"! Learned this pattern.'**
  String inboxConfirmedSuccess(String category);

  /// No description provided for @inboxDiscardedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Discarded notification.'**
  String get inboxDiscardedSuccess;

  /// No description provided for @inboxConfirmedBatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {count} draft transactions!'**
  String inboxConfirmedBatchSuccess(int count);

  /// No description provided for @inboxDiscardedBatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Discarded {count} draft transactions.'**
  String inboxDiscardedBatchSuccess(int count);

  /// No description provided for @inboxUpdatedCategoryBatchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated category for {count} draft transactions.'**
  String inboxUpdatedCategoryBatchSuccess(int count);

  /// No description provided for @inboxClearedAlertsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count} notification alerts.'**
  String inboxClearedAlertsSuccess(int count);

  /// No description provided for @inboxInvalidAmountWarning.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get inboxInvalidAmountWarning;

  /// No description provided for @inboxAuditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Automation Log'**
  String get inboxAuditLogTitle;

  /// No description provided for @inboxAuditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time decision log of automatic actions performed by your on-device perceptron model.'**
  String get inboxAuditLogSubtitle;

  /// No description provided for @inboxClearAuditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Audit Log?'**
  String get inboxClearAuditLogTitle;

  /// No description provided for @inboxClearAuditLogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all logged automated actions? This will not affect your transactions.'**
  String get inboxClearAuditLogConfirm;

  /// No description provided for @inboxClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get inboxClearAll;

  /// No description provided for @inboxNoAutomatedActions.
  ///
  /// In en, this message translates to:
  /// **'No automated decisions logged yet today.'**
  String get inboxNoAutomatedActions;

  /// No description provided for @inboxAutoDraftedBadge.
  ///
  /// In en, this message translates to:
  /// **'AUTO-DRAFTED'**
  String get inboxAutoDraftedBadge;

  /// No description provided for @inboxAutoDismissedBadge.
  ///
  /// In en, this message translates to:
  /// **'AUTO-DISMISSED'**
  String get inboxAutoDismissedBadge;

  /// No description provided for @inboxUndoAutoDraft.
  ///
  /// In en, this message translates to:
  /// **'Undo Auto-Draft'**
  String get inboxUndoAutoDraft;

  /// No description provided for @inboxUndoAutoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Undo Auto-Dismiss'**
  String get inboxUndoAutoDismiss;

  /// No description provided for @inboxProcessingBatch.
  ///
  /// In en, this message translates to:
  /// **'Processing {count} incoming alerts...'**
  String inboxProcessingBatch(int count);

  /// No description provided for @inboxBatchProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total} notifications parsed'**
  String inboxBatchProgress(int current, int total);

  /// No description provided for @inboxReviewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Review Transaction'**
  String get inboxReviewTransaction;

  /// No description provided for @inboxIgnoreAlert.
  ///
  /// In en, this message translates to:
  /// **'Ignore Alert'**
  String get inboxIgnoreAlert;

  /// No description provided for @inboxAlertCount.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts'**
  String inboxAlertCount(int count);

  /// No description provided for @inboxClearAppAlerts.
  ///
  /// In en, this message translates to:
  /// **'Clear Alerts'**
  String get inboxClearAppAlerts;

  /// No description provided for @inboxBatchRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Rule Settings for {appName}'**
  String inboxBatchRuleTitle(String appName);

  /// No description provided for @inboxBatchRuleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Smart Tracking handles future notifications from this app.'**
  String get inboxBatchRuleSubtitle;

  /// No description provided for @inboxAlwaysDraftOption.
  ///
  /// In en, this message translates to:
  /// **'Always Draft as Transactions'**
  String get inboxAlwaysDraftOption;

  /// No description provided for @inboxAlwaysIgnoreOption.
  ///
  /// In en, this message translates to:
  /// **'Always Ignore Notifications'**
  String get inboxAlwaysIgnoreOption;

  /// No description provided for @inboxAskEveryTimeOption.
  ///
  /// In en, this message translates to:
  /// **'Ask Every Time (Default)'**
  String get inboxAskEveryTimeOption;

  /// No description provided for @inboxVerifyAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Verify & Confirm'**
  String get inboxVerifyAndConfirm;

  /// No description provided for @inboxEditTransactionDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit Draft Transaction'**
  String get inboxEditTransactionDraft;

  /// No description provided for @inboxTransactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get inboxTransactionAmount;

  /// No description provided for @inboxMerchantTitle.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Title'**
  String get inboxMerchantTitle;

  /// No description provided for @inboxSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get inboxSelectAccount;

  /// No description provided for @inboxSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get inboxSelectCategory;

  /// No description provided for @inboxTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get inboxTransactionType;

  /// No description provided for @inboxTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get inboxTypeExpense;

  /// No description provided for @inboxTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get inboxTypeIncome;

  /// No description provided for @inboxTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get inboxTypeTransfer;

  /// No description provided for @inboxNoteOrMemo.
  ///
  /// In en, this message translates to:
  /// **'Note / Memo (Optional)'**
  String get inboxNoteOrMemo;

  /// No description provided for @inboxModelLearnedPattern.
  ///
  /// In en, this message translates to:
  /// **'AI model learned a new pattern'**
  String get inboxModelLearnedPattern;

  /// No description provided for @inboxViewAuditTrail.
  ///
  /// In en, this message translates to:
  /// **'View Audit Trail'**
  String get inboxViewAuditTrail;

  /// No description provided for @inboxConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get inboxConfirm;

  /// No description provided for @inboxDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get inboxDiscard;

  /// No description provided for @inboxDiscardAll.
  ///
  /// In en, this message translates to:
  /// **'Discard All'**
  String get inboxDiscardAll;

  /// No description provided for @inboxEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get inboxEdit;

  /// No description provided for @inboxClearAllAlerts.
  ///
  /// In en, this message translates to:
  /// **'Clear All Alerts'**
  String get inboxClearAllAlerts;

  /// No description provided for @inboxSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get inboxSelect;

  /// No description provided for @inboxCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get inboxCancel;

  /// No description provided for @inboxConfirmDrafts.
  ///
  /// In en, this message translates to:
  /// **'Confirm Drafts'**
  String get inboxConfirmDrafts;

  /// No description provided for @inboxTransactionSingle.
  ///
  /// In en, this message translates to:
  /// **'transaction'**
  String get inboxTransactionSingle;

  /// No description provided for @inboxTransactionPlural.
  ///
  /// In en, this message translates to:
  /// **'transactions'**
  String get inboxTransactionPlural;

  /// No description provided for @inboxDraftSingle.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get inboxDraftSingle;

  /// No description provided for @inboxDraftPlural.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get inboxDraftPlural;

  /// No description provided for @inboxBulkCategoryAssignment.
  ///
  /// In en, this message translates to:
  /// **'Bulk Category Assignment (Optional)'**
  String get inboxBulkCategoryAssignment;

  /// No description provided for @inboxTodaysAutomatedDecisions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Automated Decisions: Auto-drafted {drafted}, Auto-dismissed {archived}'**
  String inboxTodaysAutomatedDecisions(int drafted, int archived);

  /// No description provided for @inboxViewLog.
  ///
  /// In en, this message translates to:
  /// **'View Log'**
  String get inboxViewLog;

  /// No description provided for @inboxTrackAppNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Track App Notifications'**
  String get inboxTrackAppNotificationsTitle;

  /// No description provided for @inboxTrackAppNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select which apps should be tracked for auto-drafting and transaction capture.'**
  String get inboxTrackAppNotificationsSubtitle;

  /// No description provided for @inboxSearchInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Search installed apps...'**
  String get inboxSearchInstalledApps;

  /// No description provided for @inboxNoMatchingApps.
  ///
  /// In en, this message translates to:
  /// **'No matching applications found'**
  String get inboxNoMatchingApps;

  /// No description provided for @inboxSaveTrackingSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Tracking Settings'**
  String get inboxSaveTrackingSettings;

  /// No description provided for @inboxTrackingSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification tracking preferences saved successfully.'**
  String get inboxTrackingSettingsSaved;

  /// No description provided for @inboxClearSelectedAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Selected Alerts?'**
  String get inboxClearSelectedAlertsTitle;

  /// No description provided for @inboxClearSelectedAlertsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear {count} selected alerts? They will be moved to your Archived Alerts feed.'**
  String inboxClearSelectedAlertsConfirm(int count);

  /// No description provided for @inboxReviewSelectedAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Selected Alerts?'**
  String get inboxReviewSelectedAlertsTitle;

  /// No description provided for @inboxReviewSelectedAlertsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to promote {count} selected alerts into draft transactions?'**
  String inboxReviewSelectedAlertsConfirm(int count);

  /// No description provided for @inboxPromotedAlertsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promoted {count} alerts to draft transactions!'**
  String inboxPromotedAlertsSuccess(int count);

  /// No description provided for @inboxClearAllAppAlertsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all {count} alerts for \"{appName}\"? They will be moved to your Archived Alerts feed.'**
  String inboxClearAllAppAlertsConfirm(int count, String appName);

  /// No description provided for @inboxClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get inboxClear;

  /// No description provided for @inboxReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get inboxReview;

  /// No description provided for @inboxSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String inboxSelectedCount(int count);

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @transactionsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort Transactions By'**
  String get transactionsSortBy;

  /// No description provided for @transactionsSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get transactionsSortNewestFirst;

  /// No description provided for @transactionsSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get transactionsSortOldestFirst;

  /// No description provided for @transactionsSortHighestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest Amount'**
  String get transactionsSortHighestAmount;

  /// No description provided for @transactionsSortLowestAmount.
  ///
  /// In en, this message translates to:
  /// **'Lowest Amount'**
  String get transactionsSortLowestAmount;

  /// No description provided for @transactionsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get transactionsFilterTitle;

  /// No description provided for @transactionsTimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get transactionsTimePeriod;

  /// No description provided for @transactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get transactionsThisMonth;

  /// No description provided for @transactionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get transactionsThisWeek;

  /// No description provided for @transactionsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get transactionsThisYear;

  /// No description provided for @transactionsSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month...'**
  String get transactionsSelectMonth;

  /// No description provided for @transactionsSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year...'**
  String get transactionsSelectYear;

  /// No description provided for @transactionsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get transactionsAllTime;

  /// No description provided for @transactionsSelectSpecificYear.
  ///
  /// In en, this message translates to:
  /// **'Select Specific Year'**
  String get transactionsSelectSpecificYear;

  /// No description provided for @transactionsAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get transactionsAllAccounts;

  /// No description provided for @transactionsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get transactionsAllCategories;

  /// No description provided for @transactionsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get transactionsApplyFilters;

  /// No description provided for @transactionsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get transactionsReset;

  /// No description provided for @transactionsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get transactionsResetAll;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description, amount...'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsAllType.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsAllType;

  /// No description provided for @transactionsExpensesType.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get transactionsExpensesType;

  /// No description provided for @transactionsIncomeType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionsIncomeType;

  /// No description provided for @transactionsTransfersType.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transactionsTransfersType;

  /// No description provided for @transactionsShowingCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} items • {sortLabel}'**
  String transactionsShowingCount(int count, int total, String sortLabel);

  /// No description provided for @transactionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get transactionsNotFound;

  /// No description provided for @transactionsNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get transactionsNotFoundSubtitle;

  /// No description provided for @transactionsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get transactionsClearFilters;

  /// No description provided for @transactionFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get transactionFormNewTitle;

  /// No description provided for @transactionFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transactionFormEditTitle;

  /// No description provided for @transactionFormExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionFormExpense;

  /// No description provided for @transactionFormIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionFormIncome;

  /// No description provided for @transactionFormTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionFormTransfer;

  /// No description provided for @transactionFormAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionFormAmount;

  /// No description provided for @transactionFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Title'**
  String get transactionFormDescription;

  /// No description provided for @transactionFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionFormCategory;

  /// No description provided for @transactionFormFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get transactionFormFromAccount;

  /// No description provided for @transactionFormToAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get transactionFormToAccount;

  /// No description provided for @transactionFormAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionFormAccount;

  /// No description provided for @transactionFormDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get transactionFormDateTime;

  /// No description provided for @transactionFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get transactionFormSave;

  /// No description provided for @transactionFormUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get transactionFormUpdate;

  /// No description provided for @transactionFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get transactionFormDelete;

  /// No description provided for @transactionFormDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get transactionFormDeleteConfirm;

  /// No description provided for @transactionFormSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully.'**
  String get transactionFormSavedSuccess;

  /// No description provided for @transactionFormDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully.'**
  String get transactionFormDeletedSuccess;

  /// No description provided for @transactionFormEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get transactionFormEnterValidAmount;

  /// No description provided for @transactionFormVerifyDraft.
  ///
  /// In en, this message translates to:
  /// **'Verify Draft Transaction'**
  String get transactionFormVerifyDraft;

  /// No description provided for @transactionFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionFormAddTitle;

  /// No description provided for @transactionFormDiscardDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Draft?'**
  String get transactionFormDiscardDraftTitle;

  /// No description provided for @transactionFormDiscardDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will discard this transaction draft.'**
  String get transactionFormDiscardDraftConfirm;

  /// No description provided for @transactionFormDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this transaction.'**
  String get transactionFormDeleteConfirmBody;

  /// No description provided for @transactionFormSelectSourceAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Source Account'**
  String get transactionFormSelectSourceAccount;

  /// No description provided for @transactionFormSelectDestinationAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Destination Account'**
  String get transactionFormSelectDestinationAccount;

  /// No description provided for @transactionFormSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get transactionFormSelectCategory;

  /// No description provided for @transactionFormManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get transactionFormManage;

  /// No description provided for @transactionFormConfirmAndVerify.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Verify'**
  String get transactionFormConfirmAndVerify;

  /// No description provided for @transactionFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get transactionFormSaveChanges;

  /// No description provided for @transactionFormConfirmTransaction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get transactionFormConfirmTransaction;

  /// No description provided for @transactionFormAiCategorySuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Category Suggestions:'**
  String get transactionFormAiCategorySuggestions;

  /// No description provided for @archivedAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived Alerts'**
  String get archivedAlertsTitle;

  /// No description provided for @archivedAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'History of processed and ignored notification alerts.'**
  String get archivedAlertsSubtitle;

  /// No description provided for @archivedAlertsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Alert'**
  String get archivedAlertsRestore;

  /// No description provided for @archivedAlertsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get archivedAlertsDelete;

  /// No description provided for @archivedAlertsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear Archived Alerts'**
  String get archivedAlertsClearAll;

  /// No description provided for @archivedAlertsRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Alert restored to Captured Alerts.'**
  String get archivedAlertsRestoredSuccess;

  /// No description provided for @archivedAlertsDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Alert permanently deleted.'**
  String get archivedAlertsDeletedSuccess;

  /// No description provided for @archivedAlertsNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No archived alerts'**
  String get archivedAlertsNoAlerts;

  /// No description provided for @archivedAlertsNoAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cleared or ignored notification logs will be archived here.'**
  String get archivedAlertsNoAlertsSubtitle;

  /// No description provided for @archivedAlertsDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get archivedAlertsDeleteSelectedTitle;

  /// No description provided for @archivedAlertsDeleteSelectedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete {count} selected alerts?'**
  String archivedAlertsDeleteSelectedConfirm(int count);

  /// No description provided for @archivedAlertsBatchDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts permanently deleted.'**
  String archivedAlertsBatchDeletedSuccess(int count);

  /// No description provided for @archivedAlertsRestoredSelectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} alerts to Captured Alerts.'**
  String archivedAlertsRestoredSelectedSuccess(int count);

  /// No description provided for @archivedAlertsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Archives'**
  String get archivedAlertsClearAllTitle;

  /// No description provided for @archivedAlertsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all archived alerts?'**
  String get archivedAlertsClearAllConfirm;

  /// No description provided for @archivedAlertsClearAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All archived alerts cleared.'**
  String get archivedAlertsClearAllSuccess;

  /// No description provided for @archivedAlertsRestoredAppCategoriesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} alerts from {appCount} apps back to Captured Alerts.'**
  String archivedAlertsRestoredAppCategoriesSuccess(int count, int appCount);

  /// No description provided for @archivedAlertsDeleteAppCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} Archived Alerts?'**
  String archivedAlertsDeleteAppCategoriesTitle(int count);

  /// No description provided for @archivedAlertsDeleteAppCategoriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete {count} alerts from {appCount} apps? This action cannot be undone.'**
  String archivedAlertsDeleteAppCategoriesConfirm(int count, int appCount);

  /// No description provided for @archivedAlertsDeletedAppCategoriesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted {count} alerts.'**
  String archivedAlertsDeletedAppCategoriesSuccess(int count);

  /// No description provided for @archivedAlertsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search archived alerts...'**
  String get archivedAlertsSearchHint;

  /// No description provided for @archivedAlertsExitSelection.
  ///
  /// In en, this message translates to:
  /// **'Exit selection mode'**
  String get archivedAlertsExitSelection;

  /// No description provided for @archivedAlertsRestoreSelected.
  ///
  /// In en, this message translates to:
  /// **'Restore Selected'**
  String get archivedAlertsRestoreSelected;

  /// No description provided for @archivedAlertsDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get archivedAlertsDeleteSelected;

  /// No description provided for @archivedAlertsAppsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} Apps Selected'**
  String archivedAlertsAppsSelected(int count);

  /// No description provided for @archivedAlertsRestoreSelectedApps.
  ///
  /// In en, this message translates to:
  /// **'Restore Selected Apps'**
  String get archivedAlertsRestoreSelectedApps;

  /// No description provided for @archivedAlertsDeleteSelectedAppsPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Apps Permanently'**
  String get archivedAlertsDeleteSelectedAppsPermanently;

  /// No description provided for @archivedAlertsSelectApps.
  ///
  /// In en, this message translates to:
  /// **'Select Apps'**
  String get archivedAlertsSelectApps;

  /// No description provided for @archivedAlertsNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No Search Results'**
  String get archivedAlertsNoSearchResults;

  /// No description provided for @archivedAlertsNoSearchResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try searching for a different keyword or app name.'**
  String get archivedAlertsNoSearchResultsSubtitle;

  /// No description provided for @archivedAlertsEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts you choose to ignore will be stored in this archive feed.'**
  String get archivedAlertsEmptyStateSubtitle;

  /// No description provided for @modelTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Train Your Model'**
  String get modelTrainingTitle;

  /// No description provided for @modelTrainingStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get modelTrainingStartOver;

  /// No description provided for @modelTrainingHeaderInstruction.
  ///
  /// In en, this message translates to:
  /// **'Paste a notification, see what the model predicts, correct any mistakes, then confirm to reinforce the learning.'**
  String get modelTrainingHeaderInstruction;

  /// No description provided for @modelTrainingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Notification Text'**
  String get modelTrainingNotificationText;

  /// No description provided for @modelTrainingPredict.
  ///
  /// In en, this message translates to:
  /// **'Predict'**
  String get modelTrainingPredict;

  /// No description provided for @modelTrainingAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get modelTrainingAnalyzing;

  /// No description provided for @modelTrainingRerunPrediction.
  ///
  /// In en, this message translates to:
  /// **'Re-run Prediction'**
  String get modelTrainingRerunPrediction;

  /// No description provided for @modelTrainingDetectedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Detected as a transaction — review the fields below'**
  String get modelTrainingDetectedTransaction;

  /// No description provided for @modelTrainingNotDetectedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Not detected as a transaction — fill in the correct fields, or confirm it should be ignored'**
  String get modelTrainingNotDetectedTransaction;

  /// No description provided for @modelTrainingCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get modelTrainingCorrectAnswers;

  /// No description provided for @modelTrainingAccountIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Account Identifier in Message'**
  String get modelTrainingAccountIdentifier;

  /// No description provided for @modelTrainingAccountIdentifierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The exact text (e.g. \"XX1234\" or \"SBI\") that tells the model which account this is'**
  String get modelTrainingAccountIdentifierSubtitle;

  /// No description provided for @modelTrainingNotATransaction.
  ///
  /// In en, this message translates to:
  /// **'Not a Transaction'**
  String get modelTrainingNotATransaction;

  /// No description provided for @modelTrainingConfirmAndTrain.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Train'**
  String get modelTrainingConfirmAndTrain;

  /// No description provided for @modelTrainingPasteNotificationWarning.
  ///
  /// In en, this message translates to:
  /// **'Paste a notification message first'**
  String get modelTrainingPasteNotificationWarning;

  /// No description provided for @modelTrainingEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get modelTrainingEnterValidAmount;

  /// No description provided for @modelTrainingEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the merchant/description'**
  String get modelTrainingEnterDescription;

  /// No description provided for @modelTrainingAddAccountCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an account and category first'**
  String get modelTrainingAddAccountCategoryFirst;

  /// No description provided for @modelTrainingTrainedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Model trained on this example!'**
  String get modelTrainingTrainedSuccess;

  /// No description provided for @modelTrainingPatternIgnoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Model trained: this pattern will be ignored.'**
  String get modelTrainingPatternIgnoredSuccess;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Tap + to add one.'**
  String get categoriesEmpty;

  /// No description provided for @categoriesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get categoriesDeleteTitle;

  /// No description provided for @categoriesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String categoriesDeleteConfirm(String name);

  /// No description provided for @categoriesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoriesAddTitle;

  /// No description provided for @categoriesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoriesEditTitle;

  /// No description provided for @categoriesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoriesNameLabel;

  /// No description provided for @categoriesThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get categoriesThemeColor;

  /// No description provided for @categoriesIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get categoriesIconLabel;

  /// No description provided for @categoriesSearchIconPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search from 60+ modern icons'**
  String get categoriesSearchIconPrompt;

  /// No description provided for @categoriesBrowseIcons.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get categoriesBrowseIcons;

  /// No description provided for @categoriesSearchIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Category Icons'**
  String get categoriesSearchIconTitle;

  /// No description provided for @categoriesSearchIconHint.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword (e.g. food, taxi, bill...)'**
  String get categoriesSearchIconHint;

  /// No description provided for @categoriesNoIconsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching icons found'**
  String get categoriesNoIconsFound;

  /// No description provided for @accountFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Account Filter'**
  String get accountFilterTitle;

  /// No description provided for @timeframeFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Date Filter'**
  String get timeframeFilterTitle;

  /// No description provided for @timeframeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeframeToday;

  /// No description provided for @timeframeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeframeYesterday;

  /// No description provided for @timeframeSpecificDate.
  ///
  /// In en, this message translates to:
  /// **'Specific Date...'**
  String get timeframeSpecificDate;

  /// No description provided for @timeframeSpecificMonth.
  ///
  /// In en, this message translates to:
  /// **'Specific Month...'**
  String get timeframeSpecificMonth;

  /// No description provided for @timeframeCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range...'**
  String get timeframeCustomRange;

  /// No description provided for @pickerSelectMonthYear.
  ///
  /// In en, this message translates to:
  /// **'Select Month & Year'**
  String get pickerSelectMonthYear;

  /// No description provided for @pickerApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get pickerApply;

  /// No description provided for @logInspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Inspector'**
  String get logInspectorTitle;

  /// No description provided for @logInspectorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get logInspectorSearchHint;

  /// No description provided for @logInspectorCloseSearch.
  ///
  /// In en, this message translates to:
  /// **'Close Search'**
  String get logInspectorCloseSearch;

  /// No description provided for @logInspectorSearchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search Logs'**
  String get logInspectorSearchLogs;

  /// No description provided for @logInspectorAutoScrollOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll ON'**
  String get logInspectorAutoScrollOn;

  /// No description provided for @logInspectorAutoScrollOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll OFF'**
  String get logInspectorAutoScrollOff;

  /// No description provided for @logInspectorDeleteDay.
  ///
  /// In en, this message translates to:
  /// **'Delete This Day\'s Log'**
  String get logInspectorDeleteDay;

  /// No description provided for @logInspectorClearTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Today\'s Logs?'**
  String get logInspectorClearTodayTitle;

  /// No description provided for @logInspectorDeleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete This Day\'s Log File?'**
  String get logInspectorDeleteFileTitle;

  /// No description provided for @logInspectorDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the log file for {date}.'**
  String logInspectorDeleteConfirm(String date);

  /// No description provided for @logInspectorToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get logInspectorToday;

  /// No description provided for @logInspectorNoLogsMatch.
  ///
  /// In en, this message translates to:
  /// **'No logs match \"{query}\"'**
  String logInspectorNoLogsMatch(String query);

  /// No description provided for @logInspectorNoLogsForDay.
  ///
  /// In en, this message translates to:
  /// **'No logs for this day.'**
  String get logInspectorNoLogsForDay;

  /// No description provided for @dashboardOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverviewTitle;

  /// No description provided for @dashboardLockClockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal amounts'**
  String get dashboardLockClockTooltip;

  /// No description provided for @dashboardLatestTransactions.
  ///
  /// In en, this message translates to:
  /// **'Latest Transactions'**
  String get dashboardLatestTransactions;

  /// No description provided for @dashboardNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet.'**
  String get dashboardNoTransactions;

  /// No description provided for @dashboardShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get dashboardShowMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
