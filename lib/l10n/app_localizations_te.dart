// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'స్మార్ట్ ఫైనాన్స్ ట్రాకర్';

  @override
  String get navigationDashboard => 'డాష్‌బోర్డ్';

  @override
  String get navigationInbox => 'ఇన్‌బాక్స్';

  @override
  String get navigationSettings => 'సెట్టింగ్‌లు';

  @override
  String get inboxTitle => 'లావాదేవీల ఇన్‌బాక్స్';

  @override
  String get settingsTitle => 'సెట్టింగ్‌లు';

  @override
  String get settingsAppLanguage => 'యాప్ భాష';

  @override
  String get settingsAppLanguageSubtitle => 'యాప్‌లో కనిపించే భాషను ఎంచుకోండి';

  @override
  String get languageEnglish => 'ఇంగ్లీష్ (English)';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get settingsPreferences => 'ప్రాధాన్యతలు';

  @override
  String get settingsManageAccounts => 'పేమెంట్ ఖాతాల నిర్వహణ';

  @override
  String settingsActiveAccounts(int count) {
    return '$count క్రియాశీల ఖాతాలు';
  }

  @override
  String get settingsManageCategories => 'లావాదేవీ వర్గాల నిర్వహణ';

  @override
  String settingsActiveCategories(int count) {
    return '$count క్రియాశీల వర్గాలు';
  }

  @override
  String get settingsCurrencySymbol => 'కరెన్సీ గుర్తు';

  @override
  String get settingsCurrencySymbolSubtitle =>
      'యాప్‌లో కరెన్సీ గుర్తును చూపించు';

  @override
  String get settingsNumberFormat => 'సంఖ్యల కామా ఫార్మాట్';

  @override
  String get settingsNumberFormatSubtitle => 'కామా విడదీత & సంఖ్యల స్థానికీకరణ';

  @override
  String get settingsAutoHideBalances =>
      'యాప్‌లోకి వచ్చినపుడు బ్యాలెన్స్‌లను ఆటో-హైడ్ చేయండి';

  @override
  String get settingsAutoHideBalancesSubtitle =>
      'యాప్ తెరిచినప్పుడు డాష్‌బోర్డ్ విలువలను దాచిపెడుతుంది';

  @override
  String get settingsHideDuration => 'దాచే సమయం';

  @override
  String get inboxDrafts => 'డ్రాఫ్ట్‌లు';

  @override
  String get inboxCapturedAlerts => 'క్యాప్చర్ చేసిన అలర్ట్‌లు';

  @override
  String get inboxAllCaughtUp => 'అంతా పూర్తయింది!';

  @override
  String get inboxEmpty => 'పెండింగ్ డ్రాఫ్ట్ లావాదేవీలు లేవు.';

  @override
  String get inboxTrackingDisabled => 'స్మార్ట్ ట్రాకింగ్ నిలిపివేయబడింది';

  @override
  String get inboxTrackingDisabledDescription =>
      'నోటిఫికేషన్‌లను ఆటోమేటిక్‌గా డ్రాఫ్ట్‌లుగా క్యాప్చర్ చేయడానికి స్మార్ట్ ట్రాకింగ్‌ను ఆన్ చేయండి.';

  @override
  String get inboxEnableTracking => 'స్మార్ట్ ట్రాకింగ్ ప్రారంభించు';

  @override
  String get inboxNoCapturedAlerts => 'క్యాప్చర్ చేసిన అలర్ట్‌లు లేవు';

  @override
  String get inboxCapturedAlertsEnabledDescription =>
      'ఆర్థిక యాప్‌ల నుండి అలర్ట్‌లు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get inboxCapturedAlertsDisabledDescription =>
      'అలర్ట్‌లను క్యాప్చర్ చేయడానికి సెట్టింగ్‌లలో స్మార్ట్ ట్రాకింగ్‌ను ప్రారంభించండి.';

  @override
  String get dashboardSearchHint => 'మర్చంట్ లేదా మొత్తాన్ని శోధించండి...';

  @override
  String get dashboardIncome => 'ఆదాయం';

  @override
  String get dashboardExpenses => 'ఖర్చులు';

  @override
  String get dashboardAccounts => 'ఖాతాలు';

  @override
  String dashboardTotalBalance(Object amount) {
    return 'మొత్తం బ్యాలెన్స్: $amount';
  }

  @override
  String get dashboardClearFilter => 'ఫిల్టర్ తొలగించు';

  @override
  String get dashboardIncomeAnalysis => 'ఆదాయాల వివరాలు';

  @override
  String get dashboardExpenseAnalysis => 'ఖర్చుల వివరాలు';

  @override
  String get dashboardTransferAnalysis => 'బదిలీల వివరాలు';

  @override
  String get dashboardAllTransactionsAnalysis => 'లావాదేవీల వివరాలు';

  @override
  String get settingsSmartTracking => 'స్మార్ట్ ట్రాకింగ్';

  @override
  String get settingsSmartTrackingSubtitle =>
      'బ్యాక్‌గ్రౌండ్‌లో వచ్చే లావాదేవీ నోటిఫికేషన్‌లను చదవండి';

  @override
  String get settingsDisableSmartTrackingTitle =>
      'స్మార్ట్ ట్రాకింగ్‌ను నిలిపివేయాలా?';

  @override
  String get settingsDisableSmartTrackingDescription =>
      'యాప్ బ్యాక్‌గ్రౌండ్‌లో నోటిఫికేషన్‌లను వినడం ఆపివేస్తుంది. మీరు దీన్ని తిరిగి ప్రారంభించే వరకు కొత్త లావాదేవీలు ఆటోమేటిక్‌గా క్యాప్చర్ చేయబడవు.\n\nఆర్కైవ్ చేసిన అలర్ట్‌లు, ఆటోమేషన్ లాగ్‌లు మరియు క్యూ డేటా బ్యాక్‌గ్రౌండ్‌లో తీసివేయబడతాయి. మీ నిర్ధారించిన లావాదేవీలు మరియు నేర్చుకున్న AI మోడల్ భద్రపరచబడతాయి.';

  @override
  String get settingsKeepEnabled => 'ప్రారంభంలోనే ఉంచు';

  @override
  String get settingsDisable => 'నిలిపివేయి';

  @override
  String get settingsReliabilityRecommendations => 'పనితీరు సూచనలు';

  @override
  String get settingsReliabilityRecommendationsSubtitle =>
      'స్మార్ట్ ట్రాకింగ్ పనితీరును పెంచడానికి క్రింది వికల్పాలను కాన్ఫిగర్ చేయండి.';

  @override
  String get settingsHighlyRecommendedTag => 'అత్యంత సిఫార్సు చేయబడింది';

  @override
  String get settingsEnableAutoStartTitle => 'ఆటో స్టార్ట్ ప్రారంభించు';

  @override
  String get settingsEnableAutoStartDescription =>
      'రీబూట్ తర్వాత మరియు నోటిఫికేషన్‌లు వచ్చినప్పుడు స్మార్ట్ ఫైనాన్స్ ట్రాకర్‌ను ఆటోమేటిక్‌గా ప్రారంభించడానికి అనుమతిస్తుంది.';

  @override
  String get settingsEnableAutoStartBtn => 'ఆటో స్టార్ట్ ప్రారంభించు';

  @override
  String get settingsEnableUnrestrictedRunTitle =>
      'పరిమితులు లేని రన్ ప్రారంభించు';

  @override
  String get settingsEnableUnrestrictedRunDescription =>
      'నోటిఫికేషన్ లిజనర్‌ను ఆండ్రాయిడ్ స్లీప్‌లోకి పంపకుండా నిరోధిస్తుంది.';

  @override
  String get settingsEnableUnrestrictedRunBtn =>
      'పరిమితులు లేని రన్ ప్రారంభించు';

  @override
  String get settingsKeepNotificationAccessTitle =>
      'నోటిఫికేషన్ యాక్సెస్ ప్రారంభంలో ఉంచండి';

  @override
  String get settingsKeepNotificationAccessDescription =>
      'నోటిఫికేషన్‌లను క్యాప్చర్ చేయడానికి నోటిఫికేషన్ యాక్సెస్ అవసరం.';

  @override
  String get settingsOpenNotificationAccessBtn =>
      'నోటిఫికేషన్ యాక్సెస్ తెరవండి';

  @override
  String get settingsAutoDeleteArchivedAlerts =>
      'ఆర్కైవ్ చేసిన అలర్ట్‌లను ఆటో-డిలీట్ చేయండి';

  @override
  String get settingsAutoDeleteSubtitle =>
      'పాత నోటిఫికేషన్ లాగ్‌లను ఆటోమేటిక్‌గా తొలగించండి';

  @override
  String get settingsAutoDeleteRequiresSmartTracking =>
      'స్మార్ట్ ట్రాకింగ్ ప్రారంభంలో ఉండాలి';

  @override
  String get settingsDisableAutoDeleteTitle => 'ఆటో-డిలీట్ నిలిపివేయాలా?';

  @override
  String get settingsDisableAutoDeleteDescription =>
      'ఆర్కైవ్ చేసిన అలర్ట్‌లు ఇకపై ఆటోమేటిక్‌గా క్లీన్ చేయబడవు.';

  @override
  String get settingsDeleteOlderThan => 'వీటి కంటే పాతవి తొలగించు';

  @override
  String get settingsViewArchivedAlerts => 'ఆర్కైవ్ చేసిన అలర్ట్‌లను చూడండి';

  @override
  String get settingsViewArchivedAlertsSubtitle =>
      'ఆర్కైవ్ అలర్ట్‌లను చూడండి మరియు పునరుద్ధరించండి';

  @override
  String get settingsDataAndBackups => 'డేటా & బ్యాకప్‌లు';

  @override
  String get settingsExportDataBackup => 'డేటా ఎగుమతి / బ్యాకప్';

  @override
  String get settingsExportSubtitle =>
      'లావాదేవీలను JSON లేదా Excel/CSV ఫార్మాట్‌లో ఎగుమతి చేయండి';

  @override
  String get settingsImportDataRestore => 'డేటా దిగుమతి / పునరుద్ధరణ';

  @override
  String get settingsImportSubtitle =>
      '.json లేదా .csv ఫైల్‌ను ఎంచుకుని డేటాను జోడించండి లేదా మార్చండి';

  @override
  String get settingsExportFormatTitle => 'ఎగుమతి ఫార్మాట్';

  @override
  String get settingsExportFormatSubtitle =>
      'డేటా బ్యాకప్ కోసం ఫార్మాట్‌ను ఎంచుకోండి';

  @override
  String get settingsExportJsonTitle => 'JSON బ్యాకప్ ఫైల్ (.json)';

  @override
  String get settingsExportJsonSubtitle =>
      'పూర్తి డేటాబేస్ బ్యాకప్ (ఖాతాలు, వర్గాలు, లావాదేవీలు)';

  @override
  String get settingsExportCsvTitle => 'Excel / CSV షీట్ (.csv)';

  @override
  String get settingsExportCsvSubtitle =>
      'Excel & Google Sheets కోసం ఫార్మాట్ చేసిన లావాదేవీల ఫైల్';

  @override
  String settingsExportDestinationTitle(String format) {
    return '$format ఫైల్‌ను ఎగుమతి చేయండి';
  }

  @override
  String get settingsExportDestinationSubtitle =>
      'ఎగుమతి చేసే ఫైల్ కోసం లొకేషన్‌ను ఎంచుకోండి';

  @override
  String get settingsSaveLocally => 'ఫోన్‌లో సేవ్ చేయండి';

  @override
  String get settingsSaveLocallySubtitle =>
      'డౌన్‌లోడ్‌లు లేదా స్థానిక ఫోల్డర్‌లో నేరుగా సేవ్ చేయండి';

  @override
  String get settingsShareViaApps => 'యాప్‌ల ద్వారా షేర్ చేయండి';

  @override
  String get settingsShareViaAppsSubtitle =>
      'WhatsApp, Email, Google Drive వంటి యాప్‌ల ద్వారా పంపండి';

  @override
  String settingsFileSavedTo(String path) {
    return 'ఫైల్ సేవ్ చేయబడింది: $path';
  }

  @override
  String get settingsExportCanceled =>
      'ఎగుమతి రద్దు చేయబడింది లేదా లభ్యం కాలేదు.';

  @override
  String get settingsInvalidFileFormat =>
      'చెల్లని ఫైల్ ఫార్మాట్. దయచేసి .json లేదా .csv ఫైల్‌ను ఎంచుకోండి.';

  @override
  String get settingsImportDataTitle => 'డేటా దిగుమతి';

  @override
  String settingsImportSelected(String fileName) {
    return 'ఎంచుకున్నది: $fileName';
  }

  @override
  String get settingsAppendToExisting => 'ఉన్న డేటాకు జోడించు';

  @override
  String get settingsAppendSubtitle =>
      'ప్రస్తుత డేటాను తొలగించకుండా కొత్త లావాదేవీలను సురక్షితంగా కలపండి.';

  @override
  String get settingsOverrideReplaceAll => 'భర్తీ చేయి (అన్నీ మార్చు)';

  @override
  String get settingsOverrideSubtitle =>
      'ప్రస్తుత లావాదేవీలను తొలగించి ఫైల్ డేటాతో భర్తీ చేయండి.';

  @override
  String get settingsConfirmDataOverrideTitle => 'డేటా భర్తీని నిర్ధారించండి';

  @override
  String get settingsConfirmDataOverrideDescription =>
      'మీరు ప్రస్తుత డేటాబేస్ రికార్డులన్నింటినీ మార్చాలనుకుంటున్నారా?';

  @override
  String get settingsReplaceAll => 'అన్నీ భర్తీ చేయి';

  @override
  String get settingsFailedToReadImportFile =>
      'దిగుమతి ఫైల్‌ను చదవడం విఫలమైంది.';

  @override
  String get settingsDatabaseReplacedSuccess =>
      'డేటాబేస్ విజయవంతంగా మార్చబడింది!';

  @override
  String get settingsDataImportedSuccess =>
      'డేటా దిగుమతి మరియు విలీనం విజయవంతమైంది!';

  @override
  String get settingsInvalidImportFile =>
      'చెల్లని లేదా దెబ్బతిన్న దిగుమతి ఫైల్.';

  @override
  String get settingsCancel => 'రద్దు చేయి';

  @override
  String get settingsAutoDeleteRetentionTitle => 'ఆటో-డిలీట్ వ్యవధి';

  @override
  String get settingsAutoDeleteRetentionSubtitle =>
      'అలర్ట్‌లను శాశ్వతంగా తొలగించడానికి సమయాన్ని ఎంచుకోండి.';

  @override
  String get settingsSaveRetentionPeriod => 'సమయాన్ని సేవ్ చేయండి';

  @override
  String get settingsManageAccountsTitle => 'ఖాతాల నిర్వహణ';

  @override
  String get settingsNoAccountsYet =>
      'ఇంకా ఖాతాలు లేవు. జోడించడానికి + ని నొక్కండి.';

  @override
  String get settingsDeleteConfigTitle => 'ఖాతాను తొలగించాలా?';

  @override
  String settingsDeleteConfigConfirm(String name) {
    return 'మీరు ఖచ్చితంగా \"$name\"ని తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get settingsDelete => 'తొలగించు';

  @override
  String get settingsEditAccount => 'ఖాతాను సవరించు';

  @override
  String get settingsAddAccount => 'ఖాతాను జోడించు';

  @override
  String get settingsAccountType => 'ఖాతా రకం';

  @override
  String get settingsAccountName => 'ఖాతా పేరు';

  @override
  String get settingsMatchingKeywords =>
      'సరిపోలే కీవర్డ్‌లు (కామాతో విడదీయబడినవి)';

  @override
  String get settingsMatchingKeywordsHelper =>
      'ఉదా. \"5678, SBI\" (ఈ ఖాతాను గుర్తించడానికి ఉపయోగిస్తారు)';

  @override
  String settingsStartingBalance(String currency) {
    return 'ప్రారంభ బ్యాలెన్స్ ($currency)';
  }

  @override
  String get settingsSave => 'సేవ్ చేయి';

  @override
  String get settingsAdd => 'జోడించు';

  @override
  String get settingsEditCategory => 'వర్గాన్ని సవరించు';

  @override
  String get settingsAddCategory => 'వర్గాన్ని జోడించు';

  @override
  String get settingsCategoryName => 'వర్గం పేరు';

  @override
  String get settingsThemeColor => 'థీమ్ రంగు';

  @override
  String get settingsCategoryIcon => 'వర్గం ఐకాన్';

  @override
  String settingsIconLabel(String icon) {
    return 'ఐకాన్: \"$icon\"';
  }

  @override
  String get settingsBrowseIconsSubtitle =>
      '60+ ఆధునిక ఐకాన్‌ల నుండి శోధించండి';

  @override
  String get settingsBrowse => 'బ్రౌజ్ చేయండి';

  @override
  String get settingsSearchCategoryIcons => 'వర్గం ఐకాన్‌లను శోధించండి';

  @override
  String get settingsSearchIconsHint =>
      'కీవర్డ్ ద్వారా శోధించండి (ఉదా. ఆహారం, టాక్సీ, బిల్లు...)';

  @override
  String get settingsNoIconsFound =>
      'సరిపోలే ఐకాన్‌లు కనుగొనబడలేదు.\nమరొక కీవర్డ్‌ని ప్రయత్నించండి!';

  @override
  String get settingsPickCustomColor => 'రంగును ఎంచుకోండి';

  @override
  String get settingsShade => 'షేడ్';

  @override
  String get settingsHue => 'హ్యూ';

  @override
  String get settingsSelectColor => 'రంగును ఎంచుకోండి';

  @override
  String get settingsAccountTypeBank => 'బ్యాంక్';

  @override
  String get settingsAccountTypeCard => 'కార్డ్';

  @override
  String get settingsAccountTypeWallet => 'వ్యాలెట్';

  @override
  String get settingsAccountTypeCash => 'నగదు';

  @override
  String get settingsAdvancedSettings => 'అధునాతన సెట్టింగ్‌లు';

  @override
  String get settingsTrainYourModel => 'AI మోడల్‌కి శిక్షణ ఇవ్వండి';

  @override
  String get settingsTrainYourModelSubtitle =>
      'సాంపిల్ నోటిఫికేషన్‌లను ఉపయోగించి AIకి శిక్షణ ఇవ్వండి';

  @override
  String get settingsSnackBarDuration => 'స్నాక్‌బార్ కనిపించే వ్యవధి';

  @override
  String settingsSnackBarDurationSubtitle(String seconds) {
    return '$seconds సెకన్లు';
  }

  @override
  String get settingsDeveloperOptions => 'డెవలపర్ ఆప్షన్‌లు';

  @override
  String get settingsLogInspector => 'లాగ్ ఇన్‌స్పెక్టర్';

  @override
  String get settingsLogInspectorSubtitle => 'యాప్ లైవ్ లాగ్‌లను చూడండి';

  @override
  String get settingsSimulateNotification => 'నోటిఫికేషన్‌ను సిమ్యులేట్ చేయండి';

  @override
  String get settingsSimulateNotificationSubtitle =>
      'పరీక్షించడానికి వచ్చే నోటిఫికేషన్‌లను సిమ్యులేట్ చేయండి';

  @override
  String get settingsModelAuditLogTitle => 'AI మోడల్ ఆటోమేషన్ లాగ్';

  @override
  String get settingsModelAuditLogSubtitle =>
      'ఆన్-డివైస్ AI ద్వారా చేయబడిన చర్యల వివరాలు.';

  @override
  String get settingsNoAutomatedActionsYet =>
      'ఈరోజు ఎటువంటి ఆటోమేటెడ్ చర్యలు లాగ్ చేయబడలేదు.';

  @override
  String get settingsAutoDraftedBadge => 'ఆటో-డ్రాఫ్ట్ చేయబడింది';

  @override
  String get settingsAutoDismissedBadge => 'ఆటో-డిస్మిస్ చేయబడింది';

  @override
  String settingsConfidencePct(int pct) {
    return '$pct% నమ్మకం';
  }

  @override
  String get settingsUndoAutoDraft => 'ఆటో-డ్రాఫ్ట్ రద్దు చేయి';

  @override
  String get settingsUndoAutoDismiss => 'ఆటో-డిస్మిస్ రద్దు చేయి';

  @override
  String get settingsRestoredToCapturedAlerts =>
      'క్యాప్చర్ చేసిన అలర్ట్‌లకు పునరుద్ధరించబడింది!';

  @override
  String get settingsUndoDraftLearnedIgnore =>
      'క్యాప్చర్ చేసిన అలర్ట్‌లకు తరలించబడింది. ఇటువంటి వాటిని విస్మరించడానికి AI నేర్చుకుంది.';

  @override
  String get settingsSimulateNotificationTitle =>
      'నోటిఫికేషన్‌ను సిమ్యులేట్ చేయండి';

  @override
  String get settingsSimulateNotificationDescription =>
      'టెంప్లేట్‌ను ఎంచుకోండి లేదా నోటిఫికేషన్ డేటాను వ్రాసి పరీక్షించండి.';

  @override
  String get settingsQuickTemplates => 'త్వరిత టెంప్లేట్‌లు';

  @override
  String get settingsAppPackageName => 'యాప్ ప్యాకేజీ పేరు';

  @override
  String get settingsAppPackageHint => 'ఉదా. com.android.messaging';

  @override
  String get settingsNotificationTitleLabel => 'నోటిఫికేషన్ శీర్షిక';

  @override
  String get settingsNotificationTitleHint => 'ఉదా. HDFC Bank';

  @override
  String get settingsNotificationBodyLabel => 'నోటిఫికేషన్ బాడీ (మెసేజ్ పాఠం)';

  @override
  String get settingsNotificationBodyHint =>
      'లావాదేవీ మెసేజ్ పాఠాన్ని ఇక్కడ వ్రాయండి...';

  @override
  String get settingsSimulateAndProcess => 'సిమ్యులేట్ & ప్రాసెస్ చేయి';

  @override
  String get settingsSimulateRequiredError =>
      'ప్యాకేజీ పేరు మరియు నోటిఫికేషన్ పాఠం అవసరం.';

  @override
  String get settingsSimulateSuccess =>
      'నోటిఫికేషన్ విజయవంతంగా ప్రాసెస్ చేయబడింది! ఇన్‌బాక్స్‌ని చూడండి.';

  @override
  String settingsSimulateFailure(String error) {
    return 'సిమ్యులేషన్ విఫలమైంది: $error';
  }

  @override
  String inboxPendingDraftsTab(int count) {
    return 'పెండింగ్ డ్రాఫ్ట్‌లు ($count)';
  }

  @override
  String inboxCapturedAlertsTab(int count) {
    return 'క్యాప్చర్ చేసిన అలర్ట్‌లు ($count)';
  }

  @override
  String get inboxKeepAiIndividual => 'AI నియమాన్ని ఉంచు';

  @override
  String get inboxSelectAll => 'అన్నీ ఎంచుకోండి';

  @override
  String get inboxDeselectAll => 'ఎంపికను తీసివేయండి';

  @override
  String inboxConfirmSelected(int count) {
    return 'నిర్ధారించండి ($count)';
  }

  @override
  String inboxDiscardSelected(int count) {
    return 'తీసివేయండి ($count)';
  }

  @override
  String inboxCategorySelected(int count) {
    return 'వర్గం ($count)';
  }

  @override
  String get inboxDiscardSelectedDraftsTitle =>
      'ఎంచుకున్న డ్రాఫ్ట్‌లను తీసివేయాలా?';

  @override
  String inboxDiscardSelectedDraftsConfirm(int count) {
    return 'మీరు ఎంచుకున్న $count డ్రాఫ్ట్ లావాదేవీలను తీసివేయాలనుకుంటున్నారా?';
  }

  @override
  String get inboxDiscardAllDraftsTitle => 'అన్ని డ్రాఫ్ట్‌లను తీసివేయాలా?';

  @override
  String inboxDiscardAllDraftsConfirm(int count) {
    return 'మీరు పెండింగ్‌లో ఉన్న అన్ని $count డ్రాఫ్ట్ లావాదేవీలను తీసివేయాలనుకుంటున్నారా?';
  }

  @override
  String get inboxClearAllAlertsTitle => 'అన్ని అలర్ట్‌లను తొలగించాలా?';

  @override
  String inboxClearAllAlertsConfirm(int count) {
    return 'మీరు క్యాప్చర్ చేసిన అన్ని $count నోటిఫికేషన్ లాగ్‌లను తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get inboxNoDraftsYet => 'పెండింగ్ డ్రాఫ్ట్ లావాదేవీలు లేవు!';

  @override
  String get inboxNoDraftsSubtitle =>
      'SMS మరియు యాప్ నోటిఫికేషన్‌లు ఇక్కడ ప్రత్యక్షమవుతాయి.';

  @override
  String get inboxNoAlertsYet => 'క్యాప్చర్ చేసిన అలర్ట్‌లు లేవు!';

  @override
  String get inboxNoAlertsSubtitle =>
      'స్మార్ట్ ట్రాకింగ్ ఆర్థిక యాప్ నోటిఫికేషన్‌లను ఇక్కడ రికార్డ్ చేస్తుంది.';

  @override
  String inboxConfirmedSuccess(String category) {
    return '\"$category\" కింద లావాదేవీ నిర్ధారించబడింది! ఈ నమూనా నేర్చుకోబడింది.';
  }

  @override
  String get inboxDiscardedSuccess => 'నోటిఫికేషన్ తీసివేయబడింది.';

  @override
  String inboxConfirmedBatchSuccess(int count) {
    return '$count డ్రాఫ్ట్ లావాదేవీలు నిర్ధారించబడ్డాయి!';
  }

  @override
  String inboxDiscardedBatchSuccess(int count) {
    return '$count డ్రాఫ్ట్ లావాదేవీలు తీసివేయబడ్డాయి.';
  }

  @override
  String inboxUpdatedCategoryBatchSuccess(int count) {
    return '$count డ్రాఫ్ట్ లావాదేవీల వర్గం నవీకరించబడింది.';
  }

  @override
  String inboxClearedAlertsSuccess(int count) {
    return '$count నోటిఫికేషన్ అలర్ట్‌లు తొలగించబడ్డాయి.';
  }

  @override
  String get inboxInvalidAmountWarning => 'దయచేసి సరైన మొత్తాన్ని నమోదు చేయండి';

  @override
  String get inboxAuditLogTitle => 'AI ఆటోమేషన్ లాగ్';

  @override
  String get inboxAuditLogSubtitle =>
      'మీ పరికరంలోని AI మోడల్ తీసుకున్న నిర్ణయాల లైవ్ లాగ్.';

  @override
  String get inboxClearAuditLogTitle => 'ఆడిట్ లాగ్‌ను తొలగించాలా?';

  @override
  String get inboxClearAuditLogConfirm =>
      'మీరు నమోదు చేసిన ఆటోమేటెడ్ చర్యలన్నింటినీ తొలగించాలనుకుంటున్నారా?';

  @override
  String get inboxClearAll => 'అన్నీ తొలగించు';

  @override
  String get inboxNoAutomatedActions =>
      'ఈరోజు ఆటోమేటెడ్ నిర్ణయాలేవీ రికార్డ్ కాలేదు.';

  @override
  String get inboxAutoDraftedBadge => 'ఆటో-డ్రాఫ్ట్ చేయబడింది';

  @override
  String get inboxAutoDismissedBadge => 'ఆటో-డిస్మిస్ చేయబడింది';

  @override
  String get inboxUndoAutoDraft => 'ఆటో-డ్రాఫ్ట్ రద్దు చేయి';

  @override
  String get inboxUndoAutoDismiss => 'ఆటో-డిస్మిస్ రద్దు చేయి';

  @override
  String inboxProcessingBatch(int count) {
    return '$count అలర్ట్‌లను ప్రాసెస్ చేస్తోంది...';
  }

  @override
  String inboxBatchProgress(int current, int total) {
    return '$total లో $current నోటిఫికేషన్‌లు విశ్లేషించబడ్డాయి';
  }

  @override
  String get inboxReviewTransaction => 'లావాదేవీని సరిచూడండి';

  @override
  String get inboxIgnoreAlert => 'అలర్ట్‌ను విస్మరించు';

  @override
  String inboxAlertCount(int count) {
    return '$count అలర్ట్‌లు';
  }

  @override
  String get inboxClearAppAlerts => 'అలర్ట్‌లను ఖాళీ చేయి';

  @override
  String inboxBatchRuleTitle(String appName) {
    return '$appName కోసం ఆటో-రూల్ సెట్టింగ్‌లు';
  }

  @override
  String get inboxBatchRuleSubtitle =>
      'ఈ యాప్ నుండి వచ్చే నోటిఫికేషన్‌లను ఎలా హ్యాండిల్ చేయాలో ఎంచుకోండి.';

  @override
  String get inboxAlwaysDraftOption => 'ఎల్లప్పుడూ లావాదేవీలుగా డ్రాఫ్ట్ చేయి';

  @override
  String get inboxAlwaysIgnoreOption => 'ఎల్లప్పుడూ నోటిఫికేషన్‌లను విస్మరించు';

  @override
  String get inboxAskEveryTimeOption => 'ప్రతిసారీ అడుగు (డిఫాల్ట్)';

  @override
  String get inboxVerifyAndConfirm => 'సరిచూసి నిర్ధారించండి';

  @override
  String get inboxEditTransactionDraft => 'డ్రాఫ్ట్ లావాదేవీని సవరించు';

  @override
  String get inboxTransactionAmount => 'మొత్తం';

  @override
  String get inboxMerchantTitle => 'మర్చంట్ / శీర్షిక';

  @override
  String get inboxSelectAccount => 'ఖాతాను ఎంచుకోండి';

  @override
  String get inboxSelectCategory => 'వర్గాన్ని ఎంచుకోండి';

  @override
  String get inboxTransactionType => 'లావాదేవీ రకం';

  @override
  String get inboxTypeExpense => 'ఖర్చు';

  @override
  String get inboxTypeIncome => 'ఆదాయం';

  @override
  String get inboxTypeTransfer => 'బదిలీ';

  @override
  String get inboxNoteOrMemo => 'నోట్ / మెమో (ఐచ్ఛికం)';

  @override
  String get inboxModelLearnedPattern => 'AI మోడల్ కొత్త నమూనాను నేర్చుకుంది';

  @override
  String get inboxViewAuditTrail => 'ఆడిట్ లాగ్ చూడండి';

  @override
  String get inboxConfirm => 'నిర్ధారించు';

  @override
  String get inboxDiscard => 'తీసివేయి';

  @override
  String get inboxDiscardAll => 'అన్నీ తీసివేయి';

  @override
  String get inboxEdit => 'సవరించు';

  @override
  String get inboxClearAllAlerts => 'అన్ని అలర్ట్‌లను తొలగించు';

  @override
  String get inboxSelect => 'ఎంచుకోండి';

  @override
  String get inboxCancel => 'రద్దు చేయి';

  @override
  String get inboxConfirmDrafts => 'డ్రాఫ్ట్‌లను నిర్ధారించండి';

  @override
  String get inboxTransactionSingle => 'లావాదేవీ';

  @override
  String get inboxTransactionPlural => 'లావాదేవీలు';

  @override
  String get inboxDraftSingle => 'డ్రాఫ్ట్';

  @override
  String get inboxDraftPlural => 'డ్రాఫ్ట్‌లు';

  @override
  String get inboxBulkCategoryAssignment =>
      'బల్క్ కేటగిరీ అసైన్‌మెంట్ (ఐచ్ఛికం)';

  @override
  String inboxTodaysAutomatedDecisions(int drafted, int archived) {
    return 'ఈరోజు ఆటోమేటెడ్ నిర్ణయాలు: ఆటో-డ్రాఫ్ట్ $drafted, ఆటో-డిస్మిస్ $archived';
  }

  @override
  String get inboxViewLog => 'లాగ్ చూడండి';

  @override
  String get inboxTrackAppNotificationsTitle => 'ట్రాక్ చేయాల్సిన యాప్‌లు';

  @override
  String get inboxTrackAppNotificationsSubtitle =>
      'లావాదేవీల కోసం ఏ యాప్‌లను ట్రాక్ చేయాలో ఎంచుకోండి.';

  @override
  String get inboxSearchInstalledApps => 'యాప్‌లను శోధించండి...';

  @override
  String get inboxNoMatchingApps => 'సరిపోలే యాప్‌లు కనుగొనబడలేదు';

  @override
  String get inboxSaveTrackingSettings => 'ట్రాకింగ్ సెట్టింగ్‌లను సేవ్ చేయి';

  @override
  String get inboxTrackingSettingsSaved =>
      'ట్రాకింగ్ ప్రాధాన్యతలు సేవ్ చేయబడ్డాయి.';

  @override
  String get inboxClearSelectedAlertsTitle =>
      'ఎంచుకున్న అలర్ట్‌లను తొలగించాలా?';

  @override
  String inboxClearSelectedAlertsConfirm(int count) {
    return 'మీరు ఎంచుకున్న $count అలర్ట్‌లను తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get inboxReviewSelectedAlertsTitle =>
      'ఎంచుకున్న అలర్ట్‌లను రివ్యూ చేయాలా?';

  @override
  String inboxReviewSelectedAlertsConfirm(int count) {
    return 'మీరు ఎంచుకున్న $count అలర్ట్‌లను డ్రాఫ్ట్ లావాదేవీలుగా మార్చాలనుకుంటున్నారా?';
  }

  @override
  String inboxPromotedAlertsSuccess(int count) {
    return '$count అలర్ట్‌లు డ్రాఫ్ట్‌లుగా మార్చబడ్డాయి!';
  }

  @override
  String inboxClearAllAppAlertsConfirm(int count, String appName) {
    return '\"$appName\" నుండి వచ్చిన అన్ని $count అలర్ట్‌లను తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get inboxClear => 'తొలగించు';

  @override
  String get inboxReview => 'రివ్యూ';

  @override
  String inboxSelectedCount(int count) {
    return '$count ఎంచుకోబడ్డాయి';
  }

  @override
  String get transactionsTitle => 'లావాదేవీలు';

  @override
  String get transactionsSortBy => 'లావాదేవీల క్రమం';

  @override
  String get transactionsSortNewestFirst => 'కొత్తవి మొదట';

  @override
  String get transactionsSortOldestFirst => 'పాతవి మొదట';

  @override
  String get transactionsSortHighestAmount => 'ఎక్కువ మొత్తం';

  @override
  String get transactionsSortLowestAmount => 'తక్కువ మొత్తం';

  @override
  String get transactionsFilterTitle => 'లావాదేవీలను ఫిల్టర్ చేయండి';

  @override
  String get transactionsTimePeriod => 'సమయం';

  @override
  String get transactionsThisMonth => 'ఈ నెల';

  @override
  String get transactionsThisWeek => 'ఈ వారం';

  @override
  String get transactionsThisYear => 'ఈ సంవత్సరం';

  @override
  String get transactionsSelectMonth => 'నెలను ఎంచుకోండి...';

  @override
  String get transactionsSelectYear => 'సంవత్సరాన్ని ఎంచుకోండి...';

  @override
  String get transactionsAllTime => 'ఇప్పటివరకు';

  @override
  String get transactionsSelectSpecificYear => 'సంవత్సరాన్ని ఎంచుకోండి';

  @override
  String get transactionsAllAccounts => 'అన్ని ఖాతాలు';

  @override
  String get transactionsAllCategories => 'అన్ని వర్గాలు';

  @override
  String get transactionsApplyFilters => 'ఫిల్టర్‌లను వర్తింపజేయి';

  @override
  String get transactionsReset => 'రీసెట్ చేయి';

  @override
  String get transactionsResetAll => 'అన్నీ రీసెట్ చేయి';

  @override
  String get transactionsSearchHint => 'వివరాలు, మొత్తాన్ని శోధించండి...';

  @override
  String get transactionsAllType => 'అన్నీ';

  @override
  String get transactionsExpensesType => 'ఖర్చులు';

  @override
  String get transactionsIncomeType => 'ఆదాయం';

  @override
  String get transactionsTransfersType => 'బదిలీలు';

  @override
  String transactionsShowingCount(int count, int total, String sortLabel) {
    return '$total లో $count వస్తువులు చూపిస్తోంది • $sortLabel';
  }

  @override
  String get transactionsNotFound => 'లావాదేవీలు కనుగొనబడలేదు';

  @override
  String get transactionsNotFoundSubtitle =>
      'మీ శోధన లేదా ఫిల్టర్‌లను సవరించండి';

  @override
  String get transactionsClearFilters => 'ఫిల్టర్‌లను తొలగించు';

  @override
  String get transactionFormNewTitle => 'కొత్త లావాదేవీ';

  @override
  String get transactionFormEditTitle => 'లావాదేవీని సవరించు';

  @override
  String get transactionFormExpense => 'ఖర్చు';

  @override
  String get transactionFormIncome => 'ఆదాయం';

  @override
  String get transactionFormTransfer => 'బదిలీ';

  @override
  String get transactionFormAmount => 'మొత్తం';

  @override
  String get transactionFormDescription => 'మర్చంట్ / శీర్షిక';

  @override
  String get transactionFormCategory => 'వర్గం';

  @override
  String get transactionFormFromAccount => 'పంపే ఖాతా';

  @override
  String get transactionFormToAccount => 'పొందే ఖాతా';

  @override
  String get transactionFormAccount => 'ఖాతా';

  @override
  String get transactionFormDateTime => 'తేదీ & సమయం';

  @override
  String get transactionFormSave => 'లావాదేవీని సేవ్ చేయి';

  @override
  String get transactionFormUpdate => 'లావాదేవీని అప్‌డేట్ చేయి';

  @override
  String get transactionFormDelete => 'లావాదేవీని తొలగించు';

  @override
  String get transactionFormDeleteConfirm =>
      'మీరు ఈ లావాదేవీని తొలగించాలనుకుంటున్నారా?';

  @override
  String get transactionFormSavedSuccess =>
      'లావాదేవీ విజయవంతంగా సేవ్ చేయబడింది.';

  @override
  String get transactionFormDeletedSuccess =>
      'లావాదేవీ విజయవంతంగా తొలగించబడింది.';

  @override
  String get transactionFormEnterValidAmount =>
      'దయచేసి సరైన మొత్తాన్ని నమోదు చేయండి';

  @override
  String get transactionFormVerifyDraft => 'డ్రాఫ్ట్ లావాదేవీని సరిచూడండి';

  @override
  String get transactionFormAddTitle => 'లావాదేవీని జోడించు';

  @override
  String get transactionFormDiscardDraftTitle => 'డ్రాఫ్ట్‌ను తీసివేయాలా?';

  @override
  String get transactionFormDiscardDraftConfirm =>
      'ఇది ఈ లావాదేవీ డ్రాఫ్ట్‌ను తీసివేస్తుంది.';

  @override
  String get transactionFormDeleteConfirmBody =>
      'ఇది ఈ లావాదేవీని శాశ్వతంగా తొలగిస్తుంది.';

  @override
  String get transactionFormSelectSourceAccount => 'పంపే ఖాతాను ఎంచుకోండి';

  @override
  String get transactionFormSelectDestinationAccount =>
      'పొందే ఖాతాను ఎంచుకోండి';

  @override
  String get transactionFormSelectCategory => 'వర్గాన్ని ఎంచుకోండి';

  @override
  String get transactionFormManage => 'నిర్వహణ';

  @override
  String get transactionFormConfirmAndVerify => 'నిర్ధారించండి & సరిచూడండి';

  @override
  String get transactionFormSaveChanges => 'మార్పులను సేవ్ చేయి';

  @override
  String get transactionFormConfirmTransaction => 'లావాదేవీని నిర్ధారించండి';

  @override
  String get transactionFormAiCategorySuggestions => 'AI వర్గం సూచనలు:';

  @override
  String get archivedAlertsTitle => 'ఆర్కైవ్ చేసిన అలర్ట్‌లు';

  @override
  String get archivedAlertsSubtitle =>
      'ప్రాసెస్ చేసిన మరియు విస్మరించిన అలర్ట్‌ల హిస్టరీ.';

  @override
  String get archivedAlertsRestore => 'అలర్ట్‌ను పునరుద్ధరించు';

  @override
  String get archivedAlertsDelete => 'శాశ్వతంగా తొలగించు';

  @override
  String get archivedAlertsClearAll => 'ఆర్కైవ్‌లను ఖాళీ చేయి';

  @override
  String get archivedAlertsRestoredSuccess => 'అలర్ట్ పునరుద్ధరించబడింది.';

  @override
  String get archivedAlertsDeletedSuccess => 'అలర్ట్ శాశ్వతంగా తొలగించబడింది.';

  @override
  String get archivedAlertsNoAlerts => 'ఆర్కైవ్ చేసిన అలర్ట్‌లు లేవు';

  @override
  String get archivedAlertsNoAlertsSubtitle =>
      'విస్మరించిన నోటిఫికేషన్ లాగ్‌లు ఇక్కడ ఆర్కైవ్ చేయబడతాయి.';

  @override
  String get archivedAlertsDeleteSelectedTitle => 'ఎంచుకున్నవి తొలగించు';

  @override
  String archivedAlertsDeleteSelectedConfirm(int count) {
    return 'మీరు ఎంచుకున్న $count అలర్ట్‌లను శాశ్వతంగా తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String archivedAlertsBatchDeletedSuccess(int count) {
    return '$count అలర్ట్‌లు శాశ్వతంగా తొలగించబడ్డాయి.';
  }

  @override
  String archivedAlertsRestoredSelectedSuccess(int count) {
    return '$count అలర్ట్‌లు పునరుద్ధరించబడ్డాయి.';
  }

  @override
  String get archivedAlertsClearAllTitle => 'అన్ని ఆర్కైవ్‌లను ఖాళీ చేయి';

  @override
  String get archivedAlertsClearAllConfirm =>
      'మీరు ఆర్కైవ్ చేసిన అలర్ట్‌లన్నింటినీ శాశ్వతంగా తొలగించాలనుకుంటున్నారా?';

  @override
  String get archivedAlertsClearAllSuccess =>
      'ఆర్కైవ్ అలర్ట్‌లన్నీ ఖాళీ చేయబడ్డాయి.';

  @override
  String archivedAlertsRestoredAppCategoriesSuccess(int count, int appCount) {
    return '$appCount యాప్‌ల నుండి $count అలర్ట్‌లు పునరుద్ధరించబడ్డాయి.';
  }

  @override
  String archivedAlertsDeleteAppCategoriesTitle(int count) {
    return '$count ఆర్కైవ్ చేసిన అలర్ట్‌లను తొలగించాలా?';
  }

  @override
  String archivedAlertsDeleteAppCategoriesConfirm(int count, int appCount) {
    return 'మీరు $appCount యాప్‌ల నుండి $count అలర్ట్‌లను శాశ్వతంగా తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String archivedAlertsDeletedAppCategoriesSuccess(int count) {
    return '$count అలర్ట్‌లు శాశ్వతంగా తొలగించబడ్డాయి.';
  }

  @override
  String get archivedAlertsSearchHint => 'ఆర్కైవ్ అలర్ట్‌లను శోధించండి...';

  @override
  String get archivedAlertsExitSelection => 'ఎంపిక మోడ్ నుండి నిష్క్రమించండి';

  @override
  String get archivedAlertsRestoreSelected => 'ఎంచుకున్నవి పునరుద్ధరించు';

  @override
  String get archivedAlertsDeleteSelected => 'ఎంచుకున్నవి తొలగించు';

  @override
  String archivedAlertsAppsSelected(int count) {
    return '$count యాప్‌లు ఎంచుకోబడ్డాయి';
  }

  @override
  String get archivedAlertsRestoreSelectedApps =>
      'ఎంచుకున్న యాప్‌లను పునరుద్ధరించు';

  @override
  String get archivedAlertsDeleteSelectedAppsPermanently =>
      'ఎంచుకున్న యాప్‌లను శాశ్వతంగా తొలగించు';

  @override
  String get archivedAlertsSelectApps => 'యాప్‌లను ఎంచుకోండి';

  @override
  String get archivedAlertsNoSearchResults => 'శోధన ఫలితాలు లేవు';

  @override
  String get archivedAlertsNoSearchResultsSubtitle =>
      'వేరొక కీవర్డ్‌తో ప్రయత్నించండి.';

  @override
  String get archivedAlertsEmptyStateSubtitle =>
      'మీరు విస్మరించిన అలర్ట్‌లు ఇక్కడ నిల్వ చేయబడతాయి.';

  @override
  String get modelTrainingTitle => 'AI మోడల్‌కి శిక్షణ ఇవ్వండి';

  @override
  String get modelTrainingStartOver => 'మళ్ళీ ప్రారంభించు';

  @override
  String get modelTrainingHeaderInstruction =>
      'నోటిఫికేషన్‌ను పేస్ట్ చేయండి, మోడల్ అంచనాను చూడండి, తప్పులను సరిదిద్ది నిర్ధారించండి.';

  @override
  String get modelTrainingNotificationText => 'నోటిఫికేషన్ పాఠం';

  @override
  String get modelTrainingPredict => 'అంచనా వేయి';

  @override
  String get modelTrainingAnalyzing => 'విశ్లేషిస్తోంది...';

  @override
  String get modelTrainingRerunPrediction => 'అంచనాను మళ్ళీ రన్ చేయి';

  @override
  String get modelTrainingDetectedTransaction =>
      'లావాదేవీగా గుర్తించబడింది — క్రింది ఫీల్డ్‌లను పరిశీలించండి';

  @override
  String get modelTrainingNotDetectedTransaction =>
      'లావాదేవీగా గుర్తించబడలేదు — సరైన వివరాలను పూరించండి';

  @override
  String get modelTrainingCorrectAnswers => 'సరైన సమాధానాలు';

  @override
  String get modelTrainingAccountIdentifier => 'మెసేజ్‌లో ఖాతా గుర్తింపు';

  @override
  String get modelTrainingAccountIdentifierSubtitle =>
      'ఏ ఖాతా అని మోడల్‌కు చెప్పే పాఠం (ఉదా. \"XX1234\" లేదా \"SBI\")';

  @override
  String get modelTrainingNotATransaction => 'ఇది లావాదేవీ కాదు';

  @override
  String get modelTrainingConfirmAndTrain => 'నిర్ధారించి శిక్షణ ఇవ్వండి';

  @override
  String get modelTrainingPasteNotificationWarning =>
      'ముందుగా నోటిఫికేషన్ మెసేజ్‌ని పేస్ట్ చేయండి';

  @override
  String get modelTrainingEnterValidAmount => 'సరైన మొత్తాన్ని ఎంటర్ చేయండి';

  @override
  String get modelTrainingEnterDescription => 'మర్చంట్ వివరాలను ఎంటర్ చేయండి';

  @override
  String get modelTrainingAddAccountCategoryFirst =>
      'ముందుగా ఖాతా మరియు వర్గాన్ని జోడించండి';

  @override
  String get modelTrainingTrainedSuccess =>
      'ఈ ఉదాహరణపై మోడల్‌కి శిక్షణ ఇవ్వబడింది!';

  @override
  String get modelTrainingPatternIgnoredSuccess =>
      'మోడల్ శిక్షణ పూర్తయింది: ఈ నమూనా విస్మరించబడుతుంది.';

  @override
  String get categoriesTitle => 'వర్గాల నిర్వహణ';

  @override
  String get categoriesEmpty =>
      'ఇంకా వర్గాలు లేవు. జోడించడానికి + ని నొక్కండి.';

  @override
  String get categoriesDeleteTitle => 'వర్గాన్ని తొలగించాలా?';

  @override
  String categoriesDeleteConfirm(String name) {
    return 'మీరు \"$name\"ని తొలగించాలనుకుంటున్నారా?';
  }

  @override
  String get categoriesAddTitle => 'వర్గాన్ని జోడించు';

  @override
  String get categoriesEditTitle => 'వర్గాన్ని సవరించు';

  @override
  String get categoriesNameLabel => 'వర్గం పేరు';

  @override
  String get categoriesThemeColor => 'థీమ్ రంగు';

  @override
  String get categoriesIconLabel => 'వర్గం ఐకాన్';

  @override
  String get categoriesSearchIconPrompt => '60+ ఐకాన్‌ల నుండి శోధించండి';

  @override
  String get categoriesBrowseIcons => 'బ్రౌజ్ చేయండి';

  @override
  String get categoriesSearchIconTitle => 'వర్గం ఐకాన్‌లను శోధించండి';

  @override
  String get categoriesSearchIconHint =>
      'కీవర్డ్ ద్వారా శోధించండి (ఉదా. ఆహారం, టాక్సీ...)';

  @override
  String get categoriesNoIconsFound => 'సరిపోలే ఐకాన్‌లు కనుగొనబడలేదు';

  @override
  String get accountFilterTitle => 'ఖాతా ఫిల్టర్‌ను ఎంచుకోండి';

  @override
  String get timeframeFilterTitle => 'తేదీ ఫిల్టర్‌ను ఎంచుకోండి';

  @override
  String get timeframeToday => 'ఈరోజు';

  @override
  String get timeframeYesterday => 'నిన్న';

  @override
  String get timeframeSpecificDate => 'నిర్దిష్ట తేదీ...';

  @override
  String get timeframeSpecificMonth => 'నిర్దిష్ట నెల...';

  @override
  String get timeframeCustomRange => 'తేదీ వ్యవధి...';

  @override
  String get pickerSelectMonthYear => 'నెల & సంవత్సరాన్ని ఎంచుకోండి';

  @override
  String get pickerApply => 'వర్తింపజేయి';

  @override
  String get logInspectorTitle => 'లాగ్ ఇన్‌స్పెక్టర్';

  @override
  String get logInspectorSearchHint => 'లాగ్‌లను శోధించండి...';

  @override
  String get logInspectorCloseSearch => 'శోధన మూసివేయి';

  @override
  String get logInspectorSearchLogs => 'లాగ్‌లను శోధించండి';

  @override
  String get logInspectorAutoScrollOn => 'ఆటో-స్క్రోల్ ON';

  @override
  String get logInspectorAutoScrollOff => 'ఆటో-స్క్రోల్ OFF';

  @override
  String get logInspectorDeleteDay => 'ఈ రోజు లాగ్‌ను తొలగించు';

  @override
  String get logInspectorClearTodayTitle => 'ఈరోజు లాగ్‌లను తొలగించాలా?';

  @override
  String get logInspectorDeleteFileTitle => 'ఈ రోజు లాగ్ ఫైల్‌ను తొలగించాలా?';

  @override
  String logInspectorDeleteConfirm(String date) {
    return '$date కోసం లాగ్ ఫైల్ శాశ్వతంగా తొలగించబడుతుంది.';
  }

  @override
  String get logInspectorToday => 'ఈరోజు';

  @override
  String logInspectorNoLogsMatch(String query) {
    return '\"$query\" తో సరిపోలే లాగ్‌లు లేవు';
  }

  @override
  String get logInspectorNoLogsForDay => 'ఈ రోజుకు ఎటువంటి లాగ్‌లు లేవు.';

  @override
  String get dashboardOverviewTitle => 'ఓవర్‌వ్యూ';

  @override
  String get dashboardLockClockTooltip => 'విలువలను చూడటానికి నొక్కండి';

  @override
  String get dashboardLatestTransactions => 'తాజా లావాదేవీలు';

  @override
  String get dashboardNoTransactions => 'ఇంకా లావాదేవీలు నమోదు చేయబడలేదు.';

  @override
  String get dashboardShowMore => 'మరిన్ని చూడండి';

  @override
  String get heroNetCashflow => 'నికర నగదు ప్రవాహం';

  @override
  String heroSavedPct(String pct) {
    return '+$pct% ఆదా అయింది';
  }

  @override
  String heroOverspentPct(String pct) {
    return '$pct% అదనపు ఖర్చు';
  }

  @override
  String get donutNoIncome => 'ఈ సమయానికి ఎటువంటి ఆదాయ లావాదేవీలు నమోదు కావు.';

  @override
  String get donutNoExpense =>
      'ఈ సమయానికి ఎటువంటి ఖర్చు లావాదేవీలు నమోదు కావు.';

  @override
  String get donutTotalIncome => 'మొత్తం ఆదాయం';

  @override
  String get donutTotalSpent => 'మొత్తం ఖర్చు';

  @override
  String get donutTransfers => 'బదిలీలు';

  @override
  String get donutTotalVolume => 'మొత్తం పరిమాణం';

  @override
  String donutTxCount(int count) {
    return '$count లావాదేవీలు';
  }

  @override
  String donutPctOfTotal(String pct) {
    return 'మొత్తంలో $pct%';
  }

  @override
  String get catFood => 'ఆహారం';

  @override
  String get catShopping => 'షాపింగ్';

  @override
  String get catTravel => 'ప్రయాణం';

  @override
  String get catBills => 'బిల్లులు & సేవలు';

  @override
  String get catSalary => 'జీతం';

  @override
  String get catSentMoney => 'పంపిన డబ్బు';

  @override
  String get catReceivedMoney => 'వచ్చిన డబ్బు';

  @override
  String get catOthers => 'ఇతరులు';

  @override
  String get catTransfer => 'బదిలీ';

  @override
  String get archivedAlertsRestoreAlert => 'అలర్ట్‌ను పునరుద్ధరించు';

  @override
  String get archivedAlertsDeleteAlert => 'అలర్ట్‌ను తొలగించు';

  @override
  String get inboxPromotedAlertToDrafts => 'అలర్ట్ డ్రాఫ్ట్‌లకు మార్చబడింది!';

  @override
  String get inboxRestoredToCapturedAlerts =>
      'క్యాప్చర్ చేసిన అలర్ట్‌లకు పునరుద్ధరించబడింది!';

  @override
  String get barChartNoData => 'ఈ వ్యవధికి విశ్లేషణ సమాచారం అందుబాటులో లేదు.';

  @override
  String barChartAvg(String amount) {
    return 'సగటు: $amount';
  }

  @override
  String barChartPeak(String period) {
    return 'అత్యధికం: $period';
  }

  @override
  String get barChartTapToClose => '(మూసివేయడానికి నొక్కండి)';

  @override
  String get barChartTapForDays => '(రోజుల వివరాలకు వారం బార్‌పై నొక్కండి)';

  @override
  String get barChartTapMonthForWeeks =>
      '(వారాల వివరాలకు నెల బార్‌పై నొక్కండి)';

  @override
  String barChartMonthBreakdown(String monthName) {
    return '$monthName వివరాలు';
  }

  @override
  String barChartWeekBreakdown(int weekNum, String dateRange) {
    return 'వారం $weekNum వివరాలు ($dateRange)';
  }
}
