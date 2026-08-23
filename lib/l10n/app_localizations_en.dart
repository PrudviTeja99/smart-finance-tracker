// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Finance Tracker';

  @override
  String get navigationDashboard => 'Dashboard';

  @override
  String get navigationInbox => 'Inbox';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get inboxTitle => 'Transaction Inbox';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppLanguage => 'App Language';

  @override
  String get settingsAppLanguageSubtitle =>
      'Choose the display language for the app';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsManageAccounts => 'Manage Payment Accounts';

  @override
  String settingsActiveAccounts(int count) {
    return '$count active accounts';
  }

  @override
  String get settingsManageCategories => 'Manage Transaction Categories';

  @override
  String settingsActiveCategories(int count) {
    return '$count active categories';
  }

  @override
  String get settingsCurrencySymbol => 'Currency Symbol';

  @override
  String get settingsCurrencySymbolSubtitle =>
      'Display currency across the app';

  @override
  String get settingsNumberFormat => 'Number Comma Format';

  @override
  String get settingsNumberFormatSubtitle =>
      'Comma separation & number localization';

  @override
  String get settingsAutoHideBalances => 'Auto-Hide Balances on Entry';

  @override
  String get settingsAutoHideBalancesSubtitle =>
      'Masks Dashboard values when app opens';

  @override
  String get settingsHideDuration => 'Hide Duration';

  @override
  String get inboxDrafts => 'Drafts';

  @override
  String get inboxCapturedAlerts => 'Captured Alerts';

  @override
  String get inboxAllCaughtUp => 'All Caught Up!';

  @override
  String get inboxEmpty =>
      'No pending draft transactions. Incoming alerts will show up here.';

  @override
  String get inboxTrackingDisabled => 'Smart Tracking Disabled';

  @override
  String get inboxTrackingDisabledDescription =>
      'Turn on Smart Tracking to automatically capture incoming financial SMS and notification alerts into drafts.';

  @override
  String get inboxEnableTracking => 'Enable Smart Tracking';

  @override
  String get inboxNoCapturedAlerts => 'No Captured Alerts';

  @override
  String get inboxCapturedAlertsEnabledDescription =>
      'Smart Tracking is listening. Notification alerts from financial apps will appear here.';

  @override
  String get inboxCapturedAlertsDisabledDescription =>
      'Enable Smart Tracking in Settings to capture notification alerts.';

  @override
  String get dashboardSearchHint => 'Search merchant or amount...';

  @override
  String get dashboardIncome => 'Income';

  @override
  String get dashboardExpenses => 'Expenses';

  @override
  String get dashboardAccounts => 'Accounts';

  @override
  String dashboardTotalBalance(Object amount) {
    return 'Total Balance: $amount';
  }

  @override
  String get dashboardClearFilter => 'Clear Filter';

  @override
  String get dashboardIncomeAnalysis => 'Income Analysis';

  @override
  String get dashboardExpenseAnalysis => 'Expense Analysis';

  @override
  String get dashboardTransferAnalysis => 'Transfer Analysis';

  @override
  String get dashboardAllTransactionsAnalysis => 'All Transactions Analysis';

  @override
  String get settingsSmartTracking => 'Smart Tracking';

  @override
  String get settingsSmartTrackingSubtitle =>
      'Read incoming transaction notifications in background';

  @override
  String get settingsDisableSmartTrackingTitle => 'Disable Smart Tracking?';

  @override
  String get settingsDisableSmartTrackingDescription =>
      'The app will stop listening to incoming notifications in the background. New transactions will not be captured automatically until you re-enable this.\n\nArchived alerts, automation logs, and processed queue data will be cleaned up in the background. Your confirmed transactions and learned AI model weights will be preserved.';

  @override
  String get settingsKeepEnabled => 'Keep Enabled';

  @override
  String get settingsDisable => 'Disable';

  @override
  String get settingsReliabilityRecommendations =>
      'Reliability Recommendations';

  @override
  String get settingsReliabilityRecommendationsSubtitle =>
      'Configure the options below to maximize Smart Tracking reliability, especially on devices with aggressive background management.';

  @override
  String get settingsEnableAutoStartTitle =>
      'Enable Auto Start (Highly Recommended)';

  @override
  String get settingsEnableAutoStartDescription =>
      'Allows Android to automatically start Smart Finance Tracker after reboot and when notifications arrive. This improves notification capture reliability on many devices with aggressive battery management.';

  @override
  String get settingsEnableAutoStartBtn => 'Enable Auto Start';

  @override
  String get settingsEnableUnrestrictedRunTitle => 'Enable Unrestricted Run';

  @override
  String get settingsEnableUnrestrictedRunDescription =>
      'Prevent Android from putting Smart Finance Tracker\'s notification listener to sleep. The app only wakes for a few milliseconds when a notification arrives, so battery impact is minimal.';

  @override
  String get settingsEnableUnrestrictedRunBtn => 'Enable Unrestricted Run';

  @override
  String get settingsKeepNotificationAccessTitle =>
      'Keep Notification Access Enabled';

  @override
  String get settingsKeepNotificationAccessDescription =>
      'Smart Tracking requires notification access to capture incoming transaction alerts. If notification access is disabled, automatic transaction detection will stop working.';

  @override
  String get settingsOpenNotificationAccessBtn => 'Open Notification Access';

  @override
  String get settingsAutoDeleteArchivedAlerts => 'Auto-Delete Archived Alerts';

  @override
  String get settingsAutoDeleteSubtitle =>
      'Automatically purge old ignored notification logs';

  @override
  String get settingsAutoDeleteRequiresSmartTracking =>
      'Requires Smart Tracking to be enabled';

  @override
  String get settingsDisableAutoDeleteTitle => 'Disable Auto-Delete?';

  @override
  String get settingsDisableAutoDeleteDescription =>
      'Archived alerts will no longer be automatically cleaned up. Over time, this may increase storage usage as old notification logs accumulate.\n\nYou can still manually delete alerts from the Archived Alerts screen.';

  @override
  String get settingsDeleteOlderThan => 'Delete older than';

  @override
  String get settingsViewArchivedAlerts => 'View Archived Alerts';

  @override
  String get settingsViewArchivedAlertsSubtitle =>
      'View and restore ignored notifications';

  @override
  String get settingsDataAndBackups => 'Data & Backups';

  @override
  String get settingsExportDataBackup => 'Export Data / Backup';

  @override
  String get settingsExportSubtitle =>
      'Export transactions as JSON or Excel/CSV (Save or Share)';

  @override
  String get settingsImportDataRestore => 'Import Data / Restore';

  @override
  String get settingsImportSubtitle =>
      'Select file (.json or .csv) to append or replace data';

  @override
  String get settingsExportFormatTitle => 'Export Format';

  @override
  String get settingsExportFormatSubtitle =>
      'Select format for transaction export or database backup';

  @override
  String get settingsExportJsonTitle => 'JSON Backup File (.json)';

  @override
  String get settingsExportJsonSubtitle =>
      'Full database backup (accounts, categories, transactions)';

  @override
  String get settingsExportCsvTitle => 'Excel / CSV Sheet (.csv)';

  @override
  String get settingsExportCsvSubtitle =>
      'Formatted transaction ledger for Excel & Google Sheets';

  @override
  String settingsExportDestinationTitle(String format) {
    return 'Export $format File';
  }

  @override
  String get settingsExportDestinationSubtitle =>
      'Choose destination for your exported file';

  @override
  String get settingsSaveLocally => 'Save Locally';

  @override
  String get settingsSaveLocallySubtitle =>
      'Save directly to phone downloads or local folder';

  @override
  String get settingsShareViaApps => 'Share via Apps';

  @override
  String get settingsShareViaAppsSubtitle =>
      'Send via WhatsApp, Email, Google Drive, etc.';

  @override
  String settingsFileSavedTo(String path) {
    return 'File saved to: $path';
  }

  @override
  String get settingsExportCanceled => 'Export canceled or unavailable.';

  @override
  String get settingsInvalidFileFormat =>
      'Invalid file format. Please select a .json or .csv file.';

  @override
  String get settingsImportDataTitle => 'Import Data';

  @override
  String settingsImportSelected(String fileName) {
    return 'Selected: $fileName';
  }

  @override
  String get settingsAppendToExisting => 'Append to Existing Data';

  @override
  String get settingsAppendSubtitle =>
      'Safely merge new transactions without deleting current data. Duplicates auto-skipped.';

  @override
  String get settingsOverrideReplaceAll => 'Override (Replace All)';

  @override
  String get settingsOverrideSubtitle =>
      'Wipe existing transactions and replace completely with file data.';

  @override
  String get settingsConfirmDataOverrideTitle => 'Confirm Data Override';

  @override
  String get settingsConfirmDataOverrideDescription =>
      'Are you sure you want to replace all current database records? Existing transactions will be overwritten.';

  @override
  String get settingsReplaceAll => 'Replace All';

  @override
  String get settingsFailedToReadImportFile => 'Failed to read import file.';

  @override
  String get settingsDatabaseReplacedSuccess =>
      'Database replaced successfully!';

  @override
  String get settingsDataImportedSuccess =>
      'Data imported & merged successfully!';

  @override
  String get settingsInvalidImportFile => 'Invalid or corrupted import file.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsAutoDeleteRetentionTitle => 'Auto-Delete Retention';

  @override
  String get settingsAutoDeleteRetentionSubtitle =>
      'Select or type the age of alerts to permanently remove.';

  @override
  String get settingsSaveRetentionPeriod => 'Save Retention Period';

  @override
  String get settingsManageAccountsTitle => 'Manage Accounts';

  @override
  String get settingsNoAccountsYet => 'No accounts yet. Tap + to add one.';

  @override
  String get settingsDeleteConfigTitle => 'Delete configuration?';

  @override
  String settingsDeleteConfigConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsEditAccount => 'Edit Account';

  @override
  String get settingsAddAccount => 'Add Account';

  @override
  String get settingsAccountType => 'Account Type';

  @override
  String get settingsAccountName => 'Account Name';

  @override
  String get settingsMatchingKeywords => 'Matching Keywords (comma separated)';

  @override
  String get settingsMatchingKeywordsHelper =>
      'E.g. \"5678, SBI\" (used to auto-predict this account)';

  @override
  String settingsStartingBalance(String currency) {
    return 'Starting Balance ($currency)';
  }

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsAdd => 'Add';

  @override
  String get settingsEditCategory => 'Edit Category';

  @override
  String get settingsAddCategory => 'Add Category';

  @override
  String get settingsCategoryName => 'Category Name';

  @override
  String get settingsThemeColor => 'Theme Color';

  @override
  String get settingsCategoryIcon => 'Category Icon';

  @override
  String settingsIconLabel(String icon) {
    return 'Icon: \"$icon\"';
  }

  @override
  String get settingsBrowseIconsSubtitle => 'Search from 60+ modern icons';

  @override
  String get settingsBrowse => 'Browse';

  @override
  String get settingsSearchCategoryIcons => 'Search Category Icons';

  @override
  String get settingsSearchIconsHint =>
      'Search by keyword (e.g. food, taxi, bill...)';

  @override
  String get settingsNoIconsFound =>
      'No matching icons found.\nTry another keyword!';

  @override
  String get settingsPickCustomColor => 'Pick a Custom Color';

  @override
  String get settingsShade => 'Shade';

  @override
  String get settingsHue => 'Hue';

  @override
  String get settingsSelectColor => 'Select Color';

  @override
  String get settingsAccountTypeBank => 'Bank';

  @override
  String get settingsAccountTypeCard => 'Card';

  @override
  String get settingsAccountTypeWallet => 'Wallet';

  @override
  String get settingsAccountTypeCash => 'Cash';

  @override
  String get settingsAdvancedSettings => 'Advanced Settings';

  @override
  String get settingsTrainYourModel => 'Train Your Model';

  @override
  String get settingsTrainYourModelSubtitle =>
      'Manually teach the AI using sample notifications';

  @override
  String get settingsSnackBarDuration => 'SnackBar Display Duration';

  @override
  String settingsSnackBarDurationSubtitle(String seconds) {
    return '$seconds seconds';
  }

  @override
  String get settingsDeveloperOptions => 'Developer Options';

  @override
  String get settingsLogInspector => 'Log Inspector';

  @override
  String get settingsLogInspectorSubtitle => 'View live app logs in real time';

  @override
  String get settingsSimulateNotification => 'Simulate Notification';

  @override
  String get settingsSimulateNotificationSubtitle =>
      'Simulate incoming notifications for testing parser/AI';

  @override
  String get settingsModelAuditLogTitle => 'Model Automation Audit Log';

  @override
  String get settingsModelAuditLogSubtitle =>
      'Full transparency into automatic actions performed by your on-device AI.';

  @override
  String get settingsNoAutomatedActionsYet =>
      'No automated actions logged yet today.';

  @override
  String get settingsAutoDraftedBadge => 'AUTO-DRAFTED';

  @override
  String get settingsAutoDismissedBadge => 'AUTO-DISMISSED';

  @override
  String settingsConfidencePct(int pct) {
    return '$pct% Conf.';
  }

  @override
  String get settingsUndoAutoDraft => 'Undo Auto-Draft';

  @override
  String get settingsUndoAutoDismiss => 'Undo Auto-Dismiss';

  @override
  String get settingsRestoredToCapturedAlerts => 'Restored to Captured Alerts!';

  @override
  String get settingsUndoDraftLearnedIgnore =>
      'Moved back to Captured Alerts. AI learned to ignore similar alerts.';

  @override
  String get settingsSimulateNotificationTitle => 'Simulate Notification';

  @override
  String get settingsSimulateNotificationDescription =>
      'Select a pre-seeded template or write custom notification data to test parsing, drafts, and active ignore learning.';

  @override
  String get settingsQuickTemplates => 'Quick Templates';

  @override
  String get settingsAppPackageName => 'App Package Name';

  @override
  String get settingsAppPackageHint => 'e.g. com.android.messaging';

  @override
  String get settingsNotificationTitleLabel => 'Notification Title';

  @override
  String get settingsNotificationTitleHint => 'e.g. HDFC Bank';

  @override
  String get settingsNotificationBodyLabel =>
      'Notification Body (Message Text)';

  @override
  String get settingsNotificationBodyHint =>
      'Write transaction message alert text here...';

  @override
  String get settingsSimulateAndProcess => 'Simulate & Process';

  @override
  String get settingsSimulateRequiredError =>
      'Package name and notification body are required.';

  @override
  String get settingsSimulateSuccess =>
      'Simulated notification processed successfully! Check Transaction Inbox.';

  @override
  String settingsSimulateFailure(String error) {
    return 'Simulation failed: $error';
  }

  @override
  String inboxPendingDraftsTab(int count) {
    return 'Pending Drafts ($count)';
  }

  @override
  String inboxCapturedAlertsTab(int count) {
    return 'Captured Alerts ($count)';
  }

  @override
  String get inboxKeepAiIndividual => 'Keep AI/Individual';

  @override
  String get inboxSelectAll => 'Select All';

  @override
  String get inboxDeselectAll => 'Deselect All';

  @override
  String inboxConfirmSelected(int count) {
    return 'Confirm ($count)';
  }

  @override
  String inboxDiscardSelected(int count) {
    return 'Discard ($count)';
  }

  @override
  String inboxCategorySelected(int count) {
    return 'Category ($count)';
  }

  @override
  String get inboxDiscardSelectedDraftsTitle => 'Discard Selected Drafts?';

  @override
  String inboxDiscardSelectedDraftsConfirm(int count) {
    return 'Are you sure you want to discard $count selected draft transactions?';
  }

  @override
  String get inboxDiscardAllDraftsTitle => 'Discard All Drafts?';

  @override
  String inboxDiscardAllDraftsConfirm(int count) {
    return 'Are you sure you want to discard all $count pending draft transactions? This action cannot be undone.';
  }

  @override
  String get inboxClearAllAlertsTitle => 'Clear All Alerts?';

  @override
  String inboxClearAllAlertsConfirm(int count) {
    return 'Are you sure you want to clear all $count captured notification logs? Old logs will be archived.';
  }

  @override
  String get inboxNoDraftsYet => 'No pending draft transactions!';

  @override
  String get inboxNoDraftsSubtitle =>
      'Incoming SMS and app notification alerts will show up here for 1-tap confirmation.';

  @override
  String get inboxNoAlertsYet => 'No captured notification alerts!';

  @override
  String get inboxNoAlertsSubtitle =>
      'Smart Tracking will automatically record financial app notifications here.';

  @override
  String inboxConfirmedSuccess(String category) {
    return 'Confirmed transaction under \"$category\"! Learned this pattern.';
  }

  @override
  String get inboxDiscardedSuccess => 'Discarded notification.';

  @override
  String inboxConfirmedBatchSuccess(int count) {
    return 'Confirmed $count draft transactions!';
  }

  @override
  String inboxDiscardedBatchSuccess(int count) {
    return 'Discarded $count draft transactions.';
  }

  @override
  String inboxUpdatedCategoryBatchSuccess(int count) {
    return 'Updated category for $count draft transactions.';
  }

  @override
  String inboxClearedAlertsSuccess(int count) {
    return 'Cleared $count notification alerts.';
  }

  @override
  String get inboxInvalidAmountWarning => 'Please enter a valid amount';

  @override
  String get inboxAuditLogTitle => 'AI Automation Log';

  @override
  String get inboxAuditLogSubtitle =>
      'Real-time decision log of automatic actions performed by your on-device perceptron model.';

  @override
  String get inboxClearAuditLogTitle => 'Clear Audit Log?';

  @override
  String get inboxClearAuditLogConfirm =>
      'Are you sure you want to clear all logged automated actions? This will not affect your transactions.';

  @override
  String get inboxClearAll => 'Clear All';

  @override
  String get inboxNoAutomatedActions =>
      'No automated decisions logged yet today.';

  @override
  String get inboxAutoDraftedBadge => 'AUTO-DRAFTED';

  @override
  String get inboxAutoDismissedBadge => 'AUTO-DISMISSED';

  @override
  String get inboxUndoAutoDraft => 'Undo Auto-Draft';

  @override
  String get inboxUndoAutoDismiss => 'Undo Auto-Dismiss';

  @override
  String inboxProcessingBatch(int count) {
    return 'Processing $count incoming alerts...';
  }

  @override
  String inboxBatchProgress(int current, int total) {
    return '$current of $total notifications parsed';
  }

  @override
  String get inboxReviewTransaction => 'Review Transaction';

  @override
  String get inboxIgnoreAlert => 'Ignore Alert';

  @override
  String inboxAlertCount(int count) {
    return '$count alerts';
  }

  @override
  String get inboxClearAppAlerts => 'Clear Alerts';

  @override
  String inboxBatchRuleTitle(String appName) {
    return 'Auto-Rule Settings for $appName';
  }

  @override
  String get inboxBatchRuleSubtitle =>
      'Choose how Smart Tracking handles future notifications from this app.';

  @override
  String get inboxAlwaysDraftOption => 'Always Draft as Transactions';

  @override
  String get inboxAlwaysIgnoreOption => 'Always Ignore Notifications';

  @override
  String get inboxAskEveryTimeOption => 'Ask Every Time (Default)';

  @override
  String get inboxVerifyAndConfirm => 'Verify & Confirm';

  @override
  String get inboxEditTransactionDraft => 'Edit Draft Transaction';

  @override
  String get inboxTransactionAmount => 'Amount';

  @override
  String get inboxMerchantTitle => 'Merchant / Title';

  @override
  String get inboxSelectAccount => 'Select Account';

  @override
  String get inboxSelectCategory => 'Select Category';

  @override
  String get inboxTransactionType => 'Transaction Type';

  @override
  String get inboxTypeExpense => 'Expense';

  @override
  String get inboxTypeIncome => 'Income';

  @override
  String get inboxTypeTransfer => 'Transfer';

  @override
  String get inboxNoteOrMemo => 'Note / Memo (Optional)';

  @override
  String get inboxModelLearnedPattern => 'AI model learned a new pattern';

  @override
  String get inboxViewAuditTrail => 'View Audit Trail';

  @override
  String get inboxConfirm => 'Confirm';

  @override
  String get inboxDiscard => 'Discard';

  @override
  String get inboxDiscardAll => 'Discard All';

  @override
  String get inboxEdit => 'Edit';

  @override
  String get inboxClearAllAlerts => 'Clear All Alerts';

  @override
  String get inboxSelect => 'Select';

  @override
  String get inboxCancel => 'Cancel';

  @override
  String get inboxConfirmDrafts => 'Confirm Drafts';

  @override
  String get inboxTransactionSingle => 'transaction';

  @override
  String get inboxTransactionPlural => 'transactions';

  @override
  String get inboxDraftSingle => 'Draft';

  @override
  String get inboxDraftPlural => 'Drafts';

  @override
  String get inboxBulkCategoryAssignment =>
      'Bulk Category Assignment (Optional)';

  @override
  String inboxTodaysAutomatedDecisions(int drafted, int archived) {
    return 'Today\'s Automated Decisions: Auto-drafted $drafted, Auto-dismissed $archived';
  }

  @override
  String get inboxViewLog => 'View Log';

  @override
  String get inboxTrackAppNotificationsTitle => 'Track App Notifications';

  @override
  String get inboxTrackAppNotificationsSubtitle =>
      'Select which apps should be tracked for auto-drafting and transaction capture.';

  @override
  String get inboxSearchInstalledApps => 'Search installed apps...';

  @override
  String get inboxNoMatchingApps => 'No matching applications found';

  @override
  String get inboxSaveTrackingSettings => 'Save Tracking Settings';

  @override
  String get inboxTrackingSettingsSaved =>
      'Notification tracking preferences saved successfully.';

  @override
  String get inboxClearSelectedAlertsTitle => 'Clear Selected Alerts?';

  @override
  String inboxClearSelectedAlertsConfirm(int count) {
    return 'Are you sure you want to clear $count selected alerts? They will be moved to your Archived Alerts feed.';
  }

  @override
  String get inboxReviewSelectedAlertsTitle => 'Review Selected Alerts?';

  @override
  String inboxReviewSelectedAlertsConfirm(int count) {
    return 'Are you sure you want to promote $count selected alerts into draft transactions?';
  }

  @override
  String inboxPromotedAlertsSuccess(int count) {
    return 'Promoted $count alerts to draft transactions!';
  }

  @override
  String inboxClearAllAppAlertsConfirm(int count, String appName) {
    return 'Are you sure you want to clear all $count alerts for \"$appName\"? They will be moved to your Archived Alerts feed.';
  }

  @override
  String get inboxClear => 'Clear';

  @override
  String get inboxReview => 'Review';

  @override
  String inboxSelectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsSortBy => 'Sort Transactions By';

  @override
  String get transactionsSortNewestFirst => 'Newest First';

  @override
  String get transactionsSortOldestFirst => 'Oldest First';

  @override
  String get transactionsSortHighestAmount => 'Highest Amount';

  @override
  String get transactionsSortLowestAmount => 'Lowest Amount';

  @override
  String get transactionsFilterTitle => 'Filter Transactions';

  @override
  String get transactionsTimePeriod => 'Time Period';

  @override
  String get transactionsThisMonth => 'This Month';

  @override
  String get transactionsThisWeek => 'This Week';

  @override
  String get transactionsThisYear => 'This Year';

  @override
  String get transactionsSelectMonth => 'Select Month...';

  @override
  String get transactionsSelectYear => 'Select Year...';

  @override
  String get transactionsAllTime => 'All Time';

  @override
  String get transactionsSelectSpecificYear => 'Select Specific Year';

  @override
  String get transactionsAllAccounts => 'All Accounts';

  @override
  String get transactionsAllCategories => 'All Categories';

  @override
  String get transactionsApplyFilters => 'Apply Filters';

  @override
  String get transactionsReset => 'Reset';

  @override
  String get transactionsResetAll => 'Reset All';

  @override
  String get transactionsSearchHint => 'Search description, amount...';

  @override
  String get transactionsAllType => 'All';

  @override
  String get transactionsExpensesType => 'Expenses';

  @override
  String get transactionsIncomeType => 'Income';

  @override
  String get transactionsTransfersType => 'Transfers';

  @override
  String transactionsShowingCount(int count, int total, String sortLabel) {
    return 'Showing $count of $total items • $sortLabel';
  }

  @override
  String get transactionsNotFound => 'No transactions found';

  @override
  String get transactionsNotFoundSubtitle =>
      'Try adjusting your search or filters';

  @override
  String get transactionsClearFilters => 'Clear Filters';

  @override
  String get transactionFormNewTitle => 'New Transaction';

  @override
  String get transactionFormEditTitle => 'Edit Transaction';

  @override
  String get transactionFormExpense => 'Expense';

  @override
  String get transactionFormIncome => 'Income';

  @override
  String get transactionFormTransfer => 'Transfer';

  @override
  String get transactionFormAmount => 'Amount';

  @override
  String get transactionFormDescription => 'Merchant / Title';

  @override
  String get transactionFormCategory => 'Category';

  @override
  String get transactionFormFromAccount => 'From Account';

  @override
  String get transactionFormToAccount => 'To Account';

  @override
  String get transactionFormAccount => 'Account';

  @override
  String get transactionFormDateTime => 'Date & Time';

  @override
  String get transactionFormSave => 'Save Transaction';

  @override
  String get transactionFormUpdate => 'Update Transaction';

  @override
  String get transactionFormDelete => 'Delete Transaction';

  @override
  String get transactionFormDeleteConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get transactionFormSavedSuccess => 'Transaction saved successfully.';

  @override
  String get transactionFormDeletedSuccess =>
      'Transaction deleted successfully.';

  @override
  String get transactionFormEnterValidAmount => 'Please enter a valid amount';

  @override
  String get transactionFormVerifyDraft => 'Verify Draft Transaction';

  @override
  String get transactionFormAddTitle => 'Add Transaction';

  @override
  String get transactionFormDiscardDraftTitle => 'Discard Draft?';

  @override
  String get transactionFormDiscardDraftConfirm =>
      'This will discard this transaction draft.';

  @override
  String get transactionFormDeleteConfirmBody =>
      'This will permanently delete this transaction.';

  @override
  String get transactionFormSelectSourceAccount => 'Select Source Account';

  @override
  String get transactionFormSelectDestinationAccount =>
      'Select Destination Account';

  @override
  String get transactionFormSelectCategory => 'Select Category';

  @override
  String get transactionFormManage => 'Manage';

  @override
  String get transactionFormConfirmAndVerify => 'Confirm & Verify';

  @override
  String get transactionFormSaveChanges => 'Save Changes';

  @override
  String get transactionFormConfirmTransaction => 'Confirm Transaction';

  @override
  String get transactionFormAiCategorySuggestions => 'AI Category Suggestions:';

  @override
  String get archivedAlertsTitle => 'Archived Alerts';

  @override
  String get archivedAlertsSubtitle =>
      'History of processed and ignored notification alerts.';

  @override
  String get archivedAlertsRestore => 'Restore Alert';

  @override
  String get archivedAlertsDelete => 'Delete Permanently';

  @override
  String get archivedAlertsClearAll => 'Clear Archived Alerts';

  @override
  String get archivedAlertsRestoredSuccess =>
      'Alert restored to Captured Alerts.';

  @override
  String get archivedAlertsDeletedSuccess => 'Alert permanently deleted.';

  @override
  String get archivedAlertsNoAlerts => 'No archived alerts';

  @override
  String get archivedAlertsNoAlertsSubtitle =>
      'Cleared or ignored notification logs will be archived here.';

  @override
  String get archivedAlertsDeleteSelectedTitle => 'Delete Selected';

  @override
  String archivedAlertsDeleteSelectedConfirm(int count) {
    return 'Are you sure you want to permanently delete $count selected alerts?';
  }

  @override
  String archivedAlertsBatchDeletedSuccess(int count) {
    return '$count alerts permanently deleted.';
  }

  @override
  String archivedAlertsRestoredSelectedSuccess(int count) {
    return 'Restored $count alerts to Captured Alerts.';
  }

  @override
  String get archivedAlertsClearAllTitle => 'Clear All Archives';

  @override
  String get archivedAlertsClearAllConfirm =>
      'Are you sure you want to permanently delete all archived alerts?';

  @override
  String get archivedAlertsClearAllSuccess => 'All archived alerts cleared.';

  @override
  String archivedAlertsRestoredAppCategoriesSuccess(int count, int appCount) {
    return 'Restored $count alerts from $appCount apps back to Captured Alerts.';
  }

  @override
  String archivedAlertsDeleteAppCategoriesTitle(int count) {
    return 'Delete $count Archived Alerts?';
  }

  @override
  String archivedAlertsDeleteAppCategoriesConfirm(int count, int appCount) {
    return 'Are you sure you want to permanently delete $count alerts from $appCount apps? This action cannot be undone.';
  }

  @override
  String archivedAlertsDeletedAppCategoriesSuccess(int count) {
    return 'Permanently deleted $count alerts.';
  }

  @override
  String get archivedAlertsSearchHint => 'Search archived alerts...';

  @override
  String get archivedAlertsExitSelection => 'Exit selection mode';

  @override
  String get archivedAlertsRestoreSelected => 'Restore Selected';

  @override
  String get archivedAlertsDeleteSelected => 'Delete Selected';

  @override
  String archivedAlertsAppsSelected(int count) {
    return '$count Apps Selected';
  }

  @override
  String get archivedAlertsRestoreSelectedApps => 'Restore Selected Apps';

  @override
  String get archivedAlertsDeleteSelectedAppsPermanently =>
      'Delete Selected Apps Permanently';

  @override
  String get archivedAlertsSelectApps => 'Select Apps';

  @override
  String get archivedAlertsNoSearchResults => 'No Search Results';

  @override
  String get archivedAlertsNoSearchResultsSubtitle =>
      'Try searching for a different keyword or app name.';

  @override
  String get archivedAlertsEmptyStateSubtitle =>
      'Alerts you choose to ignore will be stored in this archive feed.';

  @override
  String get modelTrainingTitle => 'Train Your Model';

  @override
  String get modelTrainingStartOver => 'Start Over';

  @override
  String get modelTrainingHeaderInstruction =>
      'Paste a notification, see what the model predicts, correct any mistakes, then confirm to reinforce the learning.';

  @override
  String get modelTrainingNotificationText => 'Notification Text';

  @override
  String get modelTrainingPredict => 'Predict';

  @override
  String get modelTrainingAnalyzing => 'Analyzing...';

  @override
  String get modelTrainingRerunPrediction => 'Re-run Prediction';

  @override
  String get modelTrainingDetectedTransaction =>
      'Detected as a transaction — review the fields below';

  @override
  String get modelTrainingNotDetectedTransaction =>
      'Not detected as a transaction — fill in the correct fields, or confirm it should be ignored';

  @override
  String get modelTrainingCorrectAnswers => 'Correct Answers';

  @override
  String get modelTrainingAccountIdentifier => 'Account Identifier in Message';

  @override
  String get modelTrainingAccountIdentifierSubtitle =>
      'The exact text (e.g. \"XX1234\" or \"SBI\") that tells the model which account this is';

  @override
  String get modelTrainingNotATransaction => 'Not a Transaction';

  @override
  String get modelTrainingConfirmAndTrain => 'Confirm & Train';

  @override
  String get modelTrainingPasteNotificationWarning =>
      'Paste a notification message first';

  @override
  String get modelTrainingEnterValidAmount => 'Enter a valid amount';

  @override
  String get modelTrainingEnterDescription => 'Enter the merchant/description';

  @override
  String get modelTrainingAddAccountCategoryFirst =>
      'Add an account and category first';

  @override
  String get modelTrainingTrainedSuccess => 'Model trained on this example!';

  @override
  String get modelTrainingPatternIgnoredSuccess =>
      'Model trained: this pattern will be ignored.';

  @override
  String get categoriesTitle => 'Manage Categories';

  @override
  String get categoriesEmpty => 'No categories yet. Tap + to add one.';

  @override
  String get categoriesDeleteTitle => 'Delete Category?';

  @override
  String categoriesDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get categoriesAddTitle => 'Add Category';

  @override
  String get categoriesEditTitle => 'Edit Category';

  @override
  String get categoriesNameLabel => 'Category Name';

  @override
  String get categoriesThemeColor => 'Theme Color';

  @override
  String get categoriesIconLabel => 'Category Icon';

  @override
  String get categoriesSearchIconPrompt => 'Search from 60+ modern icons';

  @override
  String get categoriesBrowseIcons => 'Browse';

  @override
  String get categoriesSearchIconTitle => 'Search Category Icons';

  @override
  String get categoriesSearchIconHint =>
      'Search by keyword (e.g. food, taxi, bill...)';

  @override
  String get categoriesNoIconsFound => 'No matching icons found';

  @override
  String get accountFilterTitle => 'Select Account Filter';

  @override
  String get timeframeFilterTitle => 'Select Date Filter';

  @override
  String get timeframeToday => 'Today';

  @override
  String get timeframeYesterday => 'Yesterday';

  @override
  String get timeframeSpecificDate => 'Specific Date...';

  @override
  String get timeframeSpecificMonth => 'Specific Month...';

  @override
  String get timeframeCustomRange => 'Custom Date Range...';

  @override
  String get pickerSelectMonthYear => 'Select Month & Year';

  @override
  String get pickerApply => 'Apply';

  @override
  String get logInspectorTitle => 'Log Inspector';

  @override
  String get logInspectorSearchHint => 'Search logs...';

  @override
  String get logInspectorCloseSearch => 'Close Search';

  @override
  String get logInspectorSearchLogs => 'Search Logs';

  @override
  String get logInspectorAutoScrollOn => 'Auto-scroll ON';

  @override
  String get logInspectorAutoScrollOff => 'Auto-scroll OFF';

  @override
  String get logInspectorDeleteDay => 'Delete This Day\'s Log';

  @override
  String get logInspectorClearTodayTitle => 'Clear Today\'s Logs?';

  @override
  String get logInspectorDeleteFileTitle => 'Delete This Day\'s Log File?';

  @override
  String logInspectorDeleteConfirm(String date) {
    return 'This permanently deletes the log file for $date.';
  }

  @override
  String get logInspectorToday => 'Today';

  @override
  String logInspectorNoLogsMatch(String query) {
    return 'No logs match \"$query\"';
  }

  @override
  String get logInspectorNoLogsForDay => 'No logs for this day.';

  @override
  String get dashboardOverviewTitle => 'Overview';

  @override
  String get dashboardLockClockTooltip => 'Tap to reveal amounts';

  @override
  String get dashboardLatestTransactions => 'Latest Transactions';

  @override
  String get dashboardNoTransactions => 'No transactions recorded yet.';

  @override
  String get dashboardShowMore => 'Show More';

  @override
  String get heroNetCashflow => 'NET CASHFLOW';

  @override
  String heroSavedPct(String pct) {
    return '+$pct% saved';
  }

  @override
  String heroOverspentPct(String pct) {
    return '$pct% overspent';
  }

  @override
  String get donutNoIncome =>
      'No income transactions recorded for this period.';

  @override
  String get donutNoExpense =>
      'No expense transactions recorded for this period.';

  @override
  String get donutTotalIncome => 'TOTAL INCOME';

  @override
  String get donutTotalSpent => 'TOTAL SPENT';

  @override
  String get donutTransfers => 'TRANSFERS';

  @override
  String get donutTotalVolume => 'TOTAL VOLUME';

  @override
  String donutTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String donutPctOfTotal(String pct) {
    return '$pct% of total';
  }

  @override
  String get catFood => 'Food';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catTravel => 'Travel';

  @override
  String get catBills => 'Bills & Utilities';

  @override
  String get catSalary => 'Salary';

  @override
  String get catSentMoney => 'Sent Money';

  @override
  String get catReceivedMoney => 'Received Money';

  @override
  String get catOthers => 'Others';

  @override
  String get catTransfer => 'Transfer';

  @override
  String get archivedAlertsRestoreAlert => 'Restore Alert';

  @override
  String get archivedAlertsDeleteAlert => 'Delete Alert';

  @override
  String get inboxPromotedAlertToDrafts =>
      'Promoted alert to Transaction Drafts!';

  @override
  String get inboxRestoredToCapturedAlerts => 'Restored to Captured Alerts!';
}
