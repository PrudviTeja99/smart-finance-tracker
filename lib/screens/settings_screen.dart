import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:file_picker/file_picker.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/notification_handler.dart';
import '../services/app_language_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/transaction_parser.dart';
import '../utils/bio_tagger.dart';
import '../utils/app_settings.dart';
import '../utils/icon_helper.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_formatters.dart';
import '../services/perceptron_storage_service.dart';
import 'archived_alerts_screen.dart';
import 'model_training_screen.dart';
import '../shared/sheets/manage_categories_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'developer/log_inspector_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isActive;

  const SettingsScreen({super.key, required this.isActive});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isServiceEnabled = false;
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _loadSettingsData();
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadSettingsData();
    }
  }

  Future<void> _loadSettingsData() async {
    final dbService = DatabaseService.instance;
    final accountsList = await dbService.getAllAccounts();
    final categoriesList = await dbService.getAllCategories();
    final running = await NotificationHandler.isServiceRunning();
    final permission = await NotificationHandler.hasPermission();

    // Start or stop service based on persistent user setting
    if (permission && !running && AppSettings.smartTrackingEnabled) {
      await NotificationHandler.startService();
    } else if (running && !AppSettings.smartTrackingEnabled) {
      await NotificationHandler.stopService();
    }

    final serviceEnabled = permission && AppSettings.smartTrackingEnabled;

    if (mounted) {
      setState(() {
        _accounts = accountsList;
        _categories = categoriesList;
        _isServiceEnabled = serviceEnabled;
      });
    }
  }

  // Toggle Background interceptor
  Future<void> _toggleService(bool value) async {
    await AppSettings.setSmartTrackingEnabled(value);
    if (value) {
      final hasPerm = await NotificationHandler.hasPermission();
      if (!hasPerm) {
        setState(() => _isServiceEnabled = true); // Cache intent
        await NotificationHandler.openPermissionSettings();
      } else {
        await NotificationHandler.startService();
      }

      // Auto-enable Auto-Delete with a default of 1 month
      if (!AppSettings.autoDeleteArchive) {
        await AppSettings.setAutoDeleteArchive(true);
        await AppSettings.setAutoDeleteValue(1);
        await AppSettings.setAutoDeleteUnit('months');
      }
    } else {
      // Confirmation dialog before disabling
      final strings = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 36),
          title: Text(strings.settingsDisableSmartTrackingTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: Text(
            strings.settingsDisableSmartTrackingDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.settingsKeepEnabled,
                  style: const TextStyle(
                      color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.settingsDisable,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        // Revert setting if user cancelled dialog
        await AppSettings.setSmartTrackingEnabled(true);
        return;
      }
      await NotificationHandler.stopService();
      await AppSettings.setAutoDeleteArchive(false);

      // Asynchronous background cleanup — doesn't block the UI
      final dbService = DatabaseService.instance;
      Future.wait([
        dbService.deleteAllArchivedAlerts(),
        dbService.deleteAllModelAuditLogs(),
        dbService.deleteProcessedRawNotifications(),
      ]).then((_) {
        debugPrint(
            '🧹 Background cleanup complete: archived alerts, audit logs, and processed queue cleared.');
      });
    }
    _loadSettingsData();
  }

  void _showExportFormatSheet() {
    final strings = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.settingsExportFormatTitle,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                strings.settingsExportFormatSubtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code_rounded,
                      color: Color(0xFF6366F1), size: 22),
                ),
                title: Text(strings.settingsExportJsonTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                    strings.settingsExportJsonSubtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                  _showExportDestinationSheet(ExportFormat.json);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.table_chart_rounded,
                      color: Color(0xFF10B981), size: 22),
                ),
                title: Text(strings.settingsExportCsvTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                    strings.settingsExportCsvSubtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                  _showExportDestinationSheet(ExportFormat.csv);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportDestinationSheet(ExportFormat format) {
    final strings = AppLocalizations.of(context)!;
    final formatName = format == ExportFormat.json ? 'JSON' : 'CSV';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.settingsExportDestinationTitle(formatName),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                strings.settingsExportDestinationSubtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.save_alt_rounded,
                      color: Color(0xFF38BDF8), size: 22),
                ),
                title: Text(strings.settingsSaveLocally,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                    strings.settingsSaveLocallySubtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
                onTap: () async {
                  Navigator.pop(context);
                  String? path;
                  if (format == ExportFormat.json) {
                    path = await BackupService.exportBackupJSON(
                        destination: ExportDestination.saveLocally);
                  } else {
                    path = await BackupService.exportToCSV(
                        destination: ExportDestination.saveLocally);
                  }
                  if (mounted) {
                    if (path != null) {
                      AppSnackBar.show(context, strings.settingsFileSavedTo(path),
                          type: SnackBarType.success);
                    } else {
                      AppSnackBar.show(
                          context, strings.settingsExportCanceled,
                          type: SnackBarType.neutral);
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                tileColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA80FC).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded,
                      color: Color(0xFFEA80FC), size: 22),
                ),
                title: Text(strings.settingsShareViaApps,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                    strings.settingsShareViaAppsSubtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
                onTap: () async {
                  Navigator.pop(context);
                  if (format == ExportFormat.json) {
                    await BackupService.exportBackupJSON(
                        destination: ExportDestination.share);
                  } else {
                    await BackupService.exportToCSV(
                        destination: ExportDestination.share);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImportWorkflow() async {
    try {
      // Step 1: Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final isJson = filePath.toLowerCase().endsWith('.json');
      final isCsv = filePath.toLowerCase().endsWith('.csv');

      if (!isJson && !isCsv) {
        if (mounted) {
          final strings = AppLocalizations.of(context)!;
          AppSnackBar.show(context,
              strings.settingsInvalidFileFormat,
              type: SnackBarType.warning);
        }
        return;
      }

      final file = File(filePath);
      final content = await file.readAsString();

      if (!mounted) return;

      // Step 2: Show Import Mode Selection Sheet (Append vs Override)
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0F172A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final strings = AppLocalizations.of(context)!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.settingsImportDataTitle,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.settingsImportSelected(fileName),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  tileColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: Color(0xFF10B981), size: 22),
                  ),
                  title: Text(strings.settingsAppendToExisting,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                      strings.settingsAppendSubtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  onTap: () {
                    Navigator.pop(context);
                    _executeImport(content,
                        isJson: isJson, isCsv: isCsv, mode: ImportMode.append);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  tileColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444), size: 22),
                  ),
                  title: Text(strings.settingsOverrideReplaceAll,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFCA5A5))),
                  subtitle: Text(
                      strings.settingsOverrideSubtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        icon: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444), size: 36),
                        title: Text(strings.settingsConfirmDataOverrideTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                        content: Text(
                            strings.settingsConfirmDataOverrideDescription),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(strings.settingsCancel,
                                style: const TextStyle(color: Colors.white60)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(strings.settingsReplaceAll),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      _executeImport(content,
                          isJson: isJson,
                          isCsv: isCsv,
                          mode: ImportMode.override);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Import file picker error: $e');
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.settingsFailedToReadImportFile,
            type: SnackBarType.error);
      }
    }
  }

  Future<void> _executeImport(
    String content, {
    required bool isJson,
    required bool isCsv,
    required ImportMode mode,
  }) async {
    bool success = false;
    if (isJson) {
      success = await BackupService.importBackupJSON(content, mode: mode);
    } else if (isCsv) {
      success = await BackupService.importFromCSV(content, mode: mode);
    }

    if (mounted) {
      final strings = AppLocalizations.of(context)!;
      AppSnackBar.show(
        context,
        success
            ? (mode == ImportMode.override
                ? strings.settingsDatabaseReplacedSuccess
                : strings.settingsDataImportedSuccess)
            : strings.settingsInvalidImportFile,
        type: success ? SnackBarType.success : SnackBarType.error,
      );
      if (success) {
        _loadSettingsData();
      }
    }
  }

  void _showDurationPickerSheet() {
    int tempValue = AppSettings.autoDeleteValue;
    String tempUnit = AppSettings.autoDeleteUnit;

    final units = ['days', 'months', 'years'];
    final unitIndex = units.indexOf(tempUnit).clamp(0, 2);

    final valueScrollController =
        FixedExtentScrollController(initialItem: tempValue - 1);
    final unitScrollController =
        FixedExtentScrollController(initialItem: unitIndex);
    final textController = TextEditingController(text: '$tempValue');

    bool isUpdatingFromWheel = false;
    bool isUpdatingFromText = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final strings = AppLocalizations.of(context)!;
          void onTextChanged() {
            if (isUpdatingFromWheel) return;
            isUpdatingFromText = true;
            final text = textController.text.trim();
            final parsed = int.tryParse(text);
            if (parsed != null && parsed >= 1 && parsed <= 90) {
              tempValue = parsed;
              if (valueScrollController.hasClients) {
                valueScrollController.jumpToItem(parsed - 1);
              }
              setSheetState(() {});
            }
            isUpdatingFromText = false;
          }

          textController.removeListener(onTextChanged);
          textController.addListener(onTextChanged);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.settingsAutoDeleteRetentionTitle,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.settingsAutoDeleteRetentionSubtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  const SizedBox(height: 20),

                  // Numeric input & Unit preview pill combined
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Number TextField
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: textController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 6),
                                hintText: '00',
                                hintStyle: TextStyle(color: Colors.white12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit Preview Label
                          Text(
                            tempUnit,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cupertino Pickers
                  SizedBox(
                    height: 140,
                    child: Row(
                      children: [
                        // Value Picker (1 to 90)
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: valueScrollController,
                            itemExtent: 38,
                            onSelectedItemChanged: (index) {
                              if (isUpdatingFromText) return;
                              isUpdatingFromWheel = true;
                              tempValue = index + 1;
                              textController.text = '$tempValue';
                              textController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: textController.text.length),
                              );
                              isUpdatingFromWheel = false;
                              setSheetState(() {});
                            },
                            children: List.generate(
                                90,
                                (index) => Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )),
                          ),
                        ),
                        // Unit Picker (days, months, years)
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: unitScrollController,
                            itemExtent: 38,
                            onSelectedItemChanged: (index) {
                              tempUnit = units[index];
                              setSheetState(() {});
                            },
                            children: units
                                .map((u) => Center(
                                      child: Text(
                                        u,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final enteredValue =
                          int.tryParse(textController.text) ?? tempValue;
                      await AppSettings.setAutoDeleteValue(
                          enteredValue.clamp(1, 999));
                      await AppSettings.setAutoDeleteUnit(tempUnit);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      setState(() {});
                    },
                    child: Text(strings.settingsSaveRetentionPeriod,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background soft design circle
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.04),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 100), // padding for bottom navigation strap
            children: [
              // 1. Preferences Card (Top)
              _buildSettingsGroup(
                title: strings.settingsPreferences,
                icon: Icons.tune_rounded,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF6366F1)),
                    title: Text(strings.settingsManageAccounts,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(strings.settingsActiveAccounts(_accounts.length),
                        style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.white54),
                    onTap: _showManageAccountsSheet,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: Color(0xFF6366F1)),
                    title: Text(strings.settingsAppLanguage,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      strings.settingsAppLanguageSubtitle,
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            AppLanguageService.instance.selectedLanguage.code,
                        dropdownColor: const Color(0xFF1E293B),
                        isDense: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF818CF8),
                          fontSize: 13,
                        ),
                        items: AppLanguageService.instance.supportedLanguages
                            .map(
                              (language) => DropdownMenuItem(
                                value: language.code,
                                child: Text(language.code == 'en'
                                    ? strings.languageEnglish
                                    : language.nativeName),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (code) async {
                          if (code == null) return;
                          await AppLanguageService.instance
                              .selectLanguage(code);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.category_rounded,
                        color: Color(0xFF6366F1)),
                    title: Text(strings.settingsManageCategories,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(strings.settingsActiveCategories(_categories.length),
                        style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.white54),
                    onTap: _showManageCategoriesSheet,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_rounded,
                        color: Color(0xFF6366F1)),
                    title: Text(strings.settingsCurrencySymbol,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(strings.settingsCurrencySymbolSubtitle,
                        style: TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.25)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: AppSettings.currencySymbol,
                          dropdownColor: const Color(0xFF1E293B),
                          isDense: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                            fontSize: 13,
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF6366F1), size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: '₹', child: Text('INR (₹)')),
                            DropdownMenuItem(
                                value: '\$', child: Text('USD (\$)')),
                            DropdownMenuItem(
                                value: '€', child: Text('EUR (€)')),
                            DropdownMenuItem(
                                value: '£', child: Text('GBP (£)')),
                            DropdownMenuItem(
                                value: '¥', child: Text('JPY/CNY (¥)')),
                            DropdownMenuItem(
                                value: '₩', child: Text('KRW (₩)')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await AppSettings.setCurrencySymbol(val);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading:
                        const Icon(Icons.pin_rounded, color: Color(0xFF6366F1)),
                    title: Text(strings.settingsNumberFormat,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(strings.settingsNumberFormatSubtitle,
                        style: TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.25)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: AppSettings.numberLocale,
                          dropdownColor: const Color(0xFF1E293B),
                          isDense: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                            fontSize: 13,
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF6366F1), size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'auto', child: Text('🌐 Auto (System)')),
                            DropdownMenuItem(
                                value: 'en_IN',
                                child: Text('🇮🇳 Indian (12,34,567)')),
                            DropdownMenuItem(
                                value: 'en_US',
                                child: Text('🌍 Standard (1,234,567)')),
                            DropdownMenuItem(
                                value: 'de_DE',
                                child: Text('🇪🇺 European (1.234.567)')),
                            DropdownMenuItem(
                                value: 'en_GB',
                                child: Text('🇬🇧 UK (1,234,567)')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await AppSettings.setNumberLocale(val);
                              AppFormatters.clearCache();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    title: Text(strings.settingsAutoHideBalances,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(strings.settingsAutoHideBalancesSubtitle,
                        style: TextStyle(fontSize: 11)),
                    value: AppSettings.autoHideEnabled,
                    activeColor: const Color(0xFF6366F1),
                    secondary: const Icon(Icons.visibility_off_rounded,
                        color: Color(0xFF6366F1)),
                    onChanged: (val) async {
                      await AppSettings.setAutoHideEnabled(val);
                      setState(() {});
                    },
                  ),
                  if (AppSettings.autoHideEnabled)
                    Container(
                      margin: const EdgeInsets.only(
                          left: 56, right: 16, bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.02)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.settingsHideDuration,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white70),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: AppSettings.autoHideSeconds > 1
                                      ? Colors.white60
                                      : Colors.white24,
                                  size: 22,
                                ),
                                onPressed: AppSettings.autoHideSeconds > 1
                                    ? () async {
                                        await AppSettings.setAutoHideSeconds(
                                            AppSettings.autoHideSeconds - 1);
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.25)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: AppSettings.autoHideSeconds,
                                    dropdownColor: const Color(0xFF1E293B),
                                    icon: const SizedBox.shrink(),
                                    alignment: Alignment.center,
                                    isDense: true,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                      fontSize: 13,
                                    ),
                                    items: (() {
                                      final presets = [
                                        1,
                                        2,
                                        3,
                                        5,
                                        10,
                                        15,
                                        30,
                                        45,
                                        60
                                      ];
                                      final currentVal =
                                          AppSettings.autoHideSeconds;
                                      final itemsList =
                                          presets.contains(currentVal)
                                              ? presets
                                              : (List<int>.from(presets)
                                                ..add(currentVal)
                                                ..sort());
                                      return itemsList.map((val) {
                                        return DropdownMenuItem<int>(
                                          value: val,
                                          child: Center(
                                            child: Text(
                                              '${val}s',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    })(),
                                    onChanged: (val) async {
                                      if (val != null) {
                                        await AppSettings.setAutoHideSeconds(
                                            val);
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: AppSettings.autoHideSeconds < 60
                                      ? Colors.white60
                                      : Colors.white24,
                                  size: 22,
                                ),
                                onPressed: AppSettings.autoHideSeconds < 60
                                    ? () async {
                                        await AppSettings.setAutoHideSeconds(
                                            AppSettings.autoHideSeconds + 1);
                                        setState(() {});
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Smart Tracking
              _buildSmartTrackingCard(),
              const SizedBox(height: 16),

              // 2. Data & Backups (Middle)
              _buildSettingsGroup(
                title: strings.settingsDataAndBackups,
                icon: Icons.sync_rounded,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload_rounded,
                          color: Color(0xFF6366F1), size: 20),
                    ),
                    title: Text(strings.settingsExportDataBackup,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        strings.settingsExportSubtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                    onTap: _showExportFormatSheet,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download_rounded,
                          color: Color(0xFF10B981), size: 20),
                    ),
                    title: Text(strings.settingsImportDataRestore,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        strings.settingsImportSubtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white38),
                    onTap: _handleImportWorkflow,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Advanced Settings (Bottom)
              _buildAdvancedSettingsCard(),

              const SizedBox(height: 16),

              // 4. Developer Options (Bottom)
              _buildDeveloperOptionsCard(),
            ],
          ),
        ],
      ),
    );
  }

  // --- SHEET & GROUP BUILDERS ---

  void _showManageAccountsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final strings = AppLocalizations.of(context)!;
            IconData getIcon(String type) {
              switch (type) {
                case 'bank':
                  return Icons.account_balance;
                case 'credit_card':
                  return Icons.credit_card;
                case 'wallet':
                  return Icons.account_balance_wallet;
                default:
                  return Icons.money;
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.settingsManageAccountsTitle,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFF10B981), size: 28),
                            onPressed: () async {
                              await _openAccountFormDialog(null);
                              final dbService = DatabaseService.instance;
                              final accountsList =
                                  await dbService.getAllAccounts();
                              setState(() {
                                _accounts = accountsList;
                              });
                              setSheetState(() {});
                            },
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _accounts.isEmpty
                        ? Center(
                            child: Text(
                              strings.settingsNoAccountsYet,
                              style: const TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final acc = _accounts[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(getIcon(acc.type),
                                          color: const Color(0xFF6366F1),
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(acc.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: acc.keywords
                                                .split(',')
                                                .map((kw) {
                                              final clean = kw.trim();
                                              if (clean.isEmpty)
                                                return const SizedBox.shrink();
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  clean,
                                                  style: const TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.white60,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 18, color: Colors.white60),
                                      onPressed: () async {
                                        await _openAccountFormDialog(acc);
                                        final dbService =
                                            DatabaseService.instance;
                                        final accountsList =
                                            await dbService.getAllAccounts();
                                        setState(() {
                                          _accounts = accountsList;
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Color(0xFFEF4444)),
                                      onPressed: () async {
                                        final confirm =
                                            await _showConfirmDeleteDialog(
                                                acc.name);
                                        if (confirm == true) {
                                          await DatabaseService.instance
                                              .deleteAccount(acc.id!);
                                          final dbService =
                                              DatabaseService.instance;
                                          final accountsList =
                                              await dbService.getAllAccounts();
                                          setState(() {
                                            _accounts = accountsList;
                                          });
                                          setSheetState(() {});
                                          _loadSettingsData();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManageCategoriesSheet() {
    showManageCategoriesSheet(
      context: context,
      onCategoriesChanged: _loadSettingsData,
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 20, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 16),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF64748B), // Slate 500
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Card(
          color: const Color(0xFF1E293B),
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  // Reusable reliability recommendation block
  Widget _buildReliabilityAction({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_rounded,
                    size: 16, color: Color(0xFF818CF8)),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartTrackingCard() {
    final strings = AppLocalizations.of(context)!;
    return _buildSettingsGroup(
      title: strings.settingsSmartTracking,
      icon: Icons.notifications_active_rounded,
      children: [
        // Smart Tracking Toggle
        SwitchListTile(
          title: Text(strings.settingsSmartTracking,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              strings.settingsSmartTrackingSubtitle,
              style: const TextStyle(fontSize: 11)),
          activeColor: const Color(0xFF6366F1),
          value: _isServiceEnabled,
          onChanged: _toggleService,
          secondary:
              const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1)),
        ),

        // Reliability Recommendations - always shown when toggle is present
        if (_isServiceEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: Color(0xFF6366F1), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        strings.settingsReliabilityRecommendations,
                        style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.settingsReliabilityRecommendationsSubtitle,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _buildReliabilityAction(
                    icon: Icons.rocket_launch_rounded,
                    title: strings.settingsEnableAutoStartTitle,
                    description:
                        strings.settingsEnableAutoStartDescription,
                    buttonText: strings.settingsEnableAutoStartBtn,
                    onTap: () => NotificationHandler.openAutoStartSettings(),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildReliabilityAction(
                    icon: Icons.battery_saver_rounded,
                    title: strings.settingsEnableUnrestrictedRunTitle,
                    description:
                        strings.settingsEnableUnrestrictedRunDescription,
                    buttonText: strings.settingsEnableUnrestrictedRunBtn,
                    onTap: () => NotificationHandler.requestBatteryExemption(),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildReliabilityAction(
                    icon: Icons.notifications_active_rounded,
                    title: strings.settingsKeepNotificationAccessTitle,
                    description:
                        strings.settingsKeepNotificationAccessDescription,
                    buttonText: strings.settingsOpenNotificationAccessBtn,
                    onTap: () => NotificationHandler.openPermissionSettings(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10),
        ] else
          const Divider(color: Colors.white10),

        // Auto-Delete Archived Alerts
        Opacity(
          opacity: _isServiceEnabled ? 1.0 : 0.4,
          child: AbsorbPointer(
            absorbing: !_isServiceEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  title: Text(strings.settingsAutoDeleteArchivedAlerts,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    _isServiceEnabled
                        ? strings.settingsAutoDeleteSubtitle
                        : strings.settingsAutoDeleteRequiresSmartTracking,
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: AppSettings.autoDeleteArchive,
                  activeColor: const Color(0xFF6366F1),
                  secondary: const Icon(Icons.auto_delete_rounded,
                      color: Color(0xFF6366F1)),
                  onChanged: (val) async {
                    if (!val) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          icon: const Icon(Icons.auto_delete_rounded,
                              color: Color(0xFFF59E0B), size: 36),
                          title: Text(strings.settingsDisableAutoDeleteTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          content: Text(
                            strings.settingsDisableAutoDeleteDescription,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(strings.settingsKeepEnabled,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(strings.settingsDisable,
                                  style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                    }
                    await AppSettings.setAutoDeleteArchive(val);
                    if (val) {
                      await AppSettings.setAutoDeleteValue(1);
                      await AppSettings.setAutoDeleteUnit('months');
                    }
                    setState(() {});
                  },
                ),
                if (_isServiceEnabled && AppSettings.autoDeleteArchive)
                  Container(
                    margin: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.black.withOpacity(0.15),
                      title: Text(strings.settingsDeleteOlderThan,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.25)),
                            ),
                            child: Text(
                              '${AppSettings.autoDeleteValue} ${AppSettings.autoDeleteUnit}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF818CF8),
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: Colors.white30),
                        ],
                      ),
                      onTap: _showDurationPickerSheet,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const Divider(color: Colors.white10),

        // View Archived Alerts
        Opacity(
          opacity: _isServiceEnabled ? 1.0 : 0.4,
          child: AbsorbPointer(
            absorbing: !_isServiceEnabled,
            child: ListTile(
              leading:
                  const Icon(Icons.archive_rounded, color: Color(0xFF6366F1)),
              title: Text(strings.settingsViewArchivedAlerts,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                _isServiceEnabled
                    ? strings.settingsViewArchivedAlertsSubtitle
                    : strings.settingsAutoDeleteRequiresSmartTracking,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.white54),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ArchivedAlertsScreen()));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsCard() {
    final strings = AppLocalizations.of(context)!;
    return _buildSettingsGroup(
      title: strings.settingsAdvancedSettings,
      icon: Icons.construction_rounded,
      children: [
        // Train Your Model
        ListTile(
          leading:
              const Icon(Icons.psychology_rounded, color: Color(0xFF818CF8)),
          title: Text(strings.settingsTrainYourModel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              strings.settingsTrainYourModelSubtitle,
              style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.white54),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ModelTrainingScreen()),
            );
          },
        ),

        const Divider(color: Colors.white10),

        // SnackBar Display Duration
        ListTile(
          leading: const Icon(Icons.timer_rounded, color: Color(0xFF6366F1)),
          title: Text(strings.settingsSnackBarDuration,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              strings.settingsSnackBarDurationSubtitle((AppSettings.snackBarDurationMs / 1000).toStringAsFixed(1)),
              style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: AppSettings.snackBarDurationMs,
                dropdownColor: const Color(0xFF1E293B),
                isDense: true,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                  fontSize: 13,
                ),
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.arrow_drop_down,
                      color: Color(0xFF6366F1), size: 18),
                ),
                items: const [
                  DropdownMenuItem(value: 1000, child: Text('1.0s')),
                  DropdownMenuItem(value: 1500, child: Text('1.5s')),
                  DropdownMenuItem(value: 2000, child: Text('2.0s')),
                  DropdownMenuItem(value: 3000, child: Text('3.0s')),
                  DropdownMenuItem(value: 4000, child: Text('4.0s')),
                ],
                onChanged: (val) async {
                  if (val != null) {
                    await AppSettings.setSnackBarDuration(val);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperOptionsCard() {
    final strings = AppLocalizations.of(context)!;
    return _buildSettingsGroup(
      title: strings.settingsDeveloperOptions,
      icon: Icons.bug_report_rounded,
      children: [
        ListTile(
          leading: const Icon(Icons.terminal_rounded, color: Color(0xFF818CF8)),
          title: Text(strings.settingsLogInspector,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(strings.settingsLogInspectorSubtitle,
              style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.white54),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LogInspectorScreen()),
            );
          },
        ),
        ListTile(
          leading:
              const Icon(Icons.playlist_add_rounded, color: Color(0xFF10B981)),
          title: Text(strings.settingsSimulateNotification,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
              strings.settingsSimulateNotificationSubtitle,
              style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.white54),
          onTap: () => _showSimulateNotificationBottomSheet(),
        ),
      ],
    );
  }

  void _showSimulateNotificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _SimulateNotificationSheet();
      },
    );
  }

  void _showModelAuditLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final strings = AppLocalizations.of(context)!;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFF818CF8), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      strings.settingsModelAuditLogTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  strings.settingsModelAuditLogSubtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseService.instance.getModelAuditLogs(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Color(0xFF6366F1))));
                      }
                      final logs = snapshot.data!;
                      if (logs.isEmpty) {
                        return Center(
                          child: Text(strings.settingsNoAutomatedActionsYet,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        );
                      }
                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final action = log['action_type'] as String;
                          final appName = log['app_name'] as String? ?? 'App';
                          final title = log['title'] as String? ?? '';
                          final body = log['body'] as String? ?? '';
                          final confidence =
                              (log['confidence'] as num? ?? 0.85).toDouble();
                          final isDrafted = action == 'auto_drafted';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDrafted
                                    ? const Color(0xFF10B981)
                                        .withValues(alpha: 0.3)
                                    : const Color(0xFF6366F1)
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDrafted
                                            ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.15)
                                            : const Color(0xFF6366F1)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isDrafted
                                            ? strings.settingsAutoDraftedBadge
                                            : strings.settingsAutoDismissedBadge,
                                        style: TextStyle(
                                          color: isDrafted
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF818CF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(appName,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text(
                                      strings.settingsConfidencePct((confidence * 100).toInt()),
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title.isNotEmpty ? '$title: $body' : body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _undoAuditAction(log);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            Border.all(color: Colors.white12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.undo_rounded,
                                              size: 14,
                                              color: Color(0xFF818CF8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            isDrafted
                                                ? strings.settingsUndoAutoDraft
                                                : strings.settingsUndoAutoDismiss,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _undoAuditAction(Map<String, dynamic> auditLog) async {
    final auditId = auditLog['id'] as int;
    final logId = auditLog['log_id'] as int?;
    final actionType = auditLog['action_type'] as String;
    final body = auditLog['body'] as String? ?? '';
    final dbService = DatabaseService.instance;
    final parser = TransactionParser();

    if (actionType == 'auto_archived' || actionType == 'auto_dismissed') {
      if (logId != null) {
        await dbService.updateNotificationLogStatus(logId, 'unclassified');
      }
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.settingsRestoredToCapturedAlerts,
            type: SnackBarType.success);
      }
    } else if (actionType == 'auto_drafted') {
      if (logId != null) {
        await dbService.updateNotificationLogStatus(logId, 'unclassified');
      }
      if (body.isNotEmpty) {
        await parser.trainType(body, 'ignore');
        await PerceptronStorageService.instance.saveWeights();
      }
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context,
            strings.settingsUndoDraftLearnedIgnore,
            type: SnackBarType.neutral);
      }
    }

    final db = await dbService.database;
    await db.delete('model_audit_log', where: 'id = ?', whereArgs: [auditId]);

    if (mounted) {
      _loadSettingsData();
    }
  }

  // --- DIALOGS FOR FORMS ---

  Future<bool?> _showConfirmDeleteDialog(String name) {
    final strings = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(strings.settingsDeleteConfigTitle),
        content: Text(strings.settingsDeleteConfigConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(strings.settingsCancel, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.settingsDelete,
                style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccountFormDialog(AccountModel? editAcc) async {
    final strings = AppLocalizations.of(context)!;
    final isEdit = editAcc != null;
    final nameController =
        TextEditingController(text: isEdit ? editAcc.name : '');
    final kwController =
        TextEditingController(text: isEdit ? editAcc.keywords : '');
    final balController = TextEditingController(
        text: isEdit ? editAcc.balance.toString() : '0.0');
    String type = isEdit ? editAcc.type : 'bank';

    final types = [
      {'value': 'bank', 'label': strings.settingsAccountTypeBank, 'icon': Icons.account_balance},
      {'value': 'credit_card', 'label': strings.settingsAccountTypeCard, 'icon': Icons.credit_card},
      {
        'value': 'wallet',
        'label': strings.settingsAccountTypeWallet,
        'icon': Icons.account_balance_wallet
      },
      {'value': 'cash', 'label': strings.settingsAccountTypeCash, 'icon': Icons.money},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? strings.settingsEditAccount : strings.settingsAddAccount,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(strings.settingsAccountType,
                        style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: types.map((t) {
                        final isSel = type == t['value'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => type = t['value'] as String),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF6366F1).withOpacity(0.15)
                                    : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF6366F1)
                                      : Colors.white.withOpacity(0.05),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(t['icon'] as IconData,
                                      color: isSel
                                          ? const Color(0xFF6366F1)
                                          : Colors.white38,
                                      size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['label'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color:
                                          isSel ? Colors.white : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: strings.settingsAccountName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kwController,
                      decoration: InputDecoration(
                        labelText: strings.settingsMatchingKeywords,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        helperText:
                            strings.settingsMatchingKeywordsHelper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            strings.settingsStartingBalance(AppSettings.currencySymbol),
                        border: const OutlineInputBorder(),
                        prefixText: '${AppSettings.currencySymbol} ',
                        prefixStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(strings.settingsCancel,
                                style: const TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final kw = kwController.text.trim();
                              final bal =
                                  double.tryParse(balController.text) ?? 0.0;
                              if (name.isEmpty) return;

                              final acc = AccountModel(
                                id: isEdit ? editAcc.id : null,
                                name: name,
                                type: type,
                                keywords: kw.isEmpty ? name : kw,
                                balance: bal,
                              );

                              if (isEdit) {
                                await DatabaseService.instance
                                    .updateAccount(acc);
                              } else {
                                await DatabaseService.instance
                                    .insertAccount(acc);
                              }

                              Navigator.pop(context);
                              _loadSettingsData();
                            },
                            child: Text(isEdit ? strings.settingsSave : strings.settingsAdd,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoryFormDialog(CategoryModel? editCat) async {
    final strings = AppLocalizations.of(context)!;
    final isEdit = editCat != null;
    final nameController =
        TextEditingController(text: isEdit ? editCat.name : '');
    final nameFocusNode = FocusNode();
    int colorValue = isEdit ? editCat.color : 0xFF6366F1;
    String icon = isEdit ? editCat.icon : 'more_horiz';

    final colors = [
      0xFF6366F1, // Indigo
      0xFF3B82F6, // Blue
      0xFF06B6D4, // Cyan
      0xFF14B8A6, // Teal
      0xFF10B981, // Emerald
      0xFF84CC16, // Lime
      0xFFF59E0B, // Amber
      0xFFF97316, // Orange
      0xFFEF4444, // Red
      0xFFE11D48, // Rose
      0xFFEC4899, // Pink
      0xFFD946EF, // Fuchsia
      0xFF8B5CF6, // Violet
      0xFF7C3AED, // Purple
      0xFF78716C, // Stone
      0xFF94A3B8, // Slate
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEdit ? strings.settingsEditCategory : strings.settingsAddCategory,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        decoration: InputDecoration(
                          labelText: strings.settingsCategoryName,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(strings.settingsThemeColor,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 8),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ...colors.map((colVal) {
                              final isSel = colorValue == colVal;
                              return GestureDetector(
                                onTap: () {
                                  nameFocusNode.unfocus();
                                  setDialogState(() => colorValue = colVal);
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(colVal),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSel
                                      ? const Icon(Icons.check,
                                          size: 16, color: Colors.white)
                                      : null,
                                ),
                              );
                            }),
                            // Custom color picker button
                            GestureDetector(
                              onTap: () {
                                nameFocusNode.unfocus();
                                _showColorSpectrumPicker(context, colorValue,
                                    (selectedColor) {
                                  setDialogState(() {
                                    colorValue = selectedColor;
                                  });
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.orange,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.cyan,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.red,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: !colors.contains(colorValue)
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: !colors.contains(colorValue)
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : const Icon(Icons.colorize_rounded,
                                        size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(strings.settingsCategoryIcon,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(colorValue).withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Color(colorValue).withOpacity(0.25),
                                  width: 1.5),
                            ),
                            child: Icon(IconHelper.getIcon(icon),
                                color: Color(colorValue), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.settingsIconLabel(icon.replaceAll('_', ' ')),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.settingsBrowseIconsSubtitle,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.05)),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.search_rounded,
                                size: 14, color: Color(0xFF6366F1)),
                            label: Text(strings.settingsBrowse,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              nameFocusNode.unfocus();
                              _showSearchableIconPicker(context, colorValue,
                                  (selectedIcon) {
                                setDialogState(() {
                                  icon = selectedIcon;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(strings.settingsCancel,
                                  style: const TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) return;

                                final cat = CategoryModel(
                                  id: isEdit ? editCat.id : null,
                                  name: name,
                                  color: colorValue,
                                  icon: icon,
                                );

                                if (isEdit) {
                                  await DatabaseService.instance
                                      .updateCategory(cat);
                                } else {
                                  await DatabaseService.instance
                                      .insertCategory(cat);
                                }

                                Navigator.pop(context);
                                _loadSettingsData();
                              },
                              child: Text(isEdit ? strings.settingsSave : strings.settingsAdd,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSearchableIconPicker(
      BuildContext context, int colorValue, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SearchableIconPicker(
          colorValue: colorValue,
          onSelected: onSelected,
        );
      },
    );
  }

  void _showColorSpectrumPicker(
      BuildContext context, int currentColor, Function(int) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ColorSpectrumPicker(
          initialColor: currentColor,
          onSelected: onSelected,
        );
      },
    );
  }
}

class SearchableIconPicker extends StatefulWidget {
  final int colorValue;
  final Function(String) onSelected;

  const SearchableIconPicker({
    super.key,
    required this.colorValue,
    required this.onSelected,
  });

  @override
  State<SearchableIconPicker> createState() => _SearchableIconPickerState();
}

class _SearchableIconPickerState extends State<SearchableIconPicker> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredKeys = IconHelper.searchIcons(_query);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final strings = AppLocalizations.of(context)!;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.settingsSearchCategoryIcons,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: strings.settingsSearchIconsHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF6366F1)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredKeys.isEmpty
                      ? Center(
                          child: Text(
                            strings.settingsNoIconsFound,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white38),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredKeys.length,
                          itemBuilder: (context, index) {
                            final key = filteredKeys[index];
                            final iconData = IconHelper.getIcon(key);
                            return InkWell(
                              onTap: () {
                                widget.onSelected(key);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(iconData,
                                        color: Color(widget.colorValue),
                                        size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      key.replaceAll('_', ' '),
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.white60),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ColorSpectrumPicker extends StatefulWidget {
  final int initialColor;
  final Function(int) onSelected;

  const ColorSpectrumPicker({
    super.key,
    required this.initialColor,
    required this.onSelected,
  });

  @override
  State<ColorSpectrumPicker> createState() => _ColorSpectrumPickerState();
}

class _ColorSpectrumPickerState extends State<ColorSpectrumPicker> {
  late double _hue;
  late double _saturation;
  late double _lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(Color(widget.initialColor));
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.settingsPickCustomColor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Color preview
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'H: ${_hue.round()}°  S: ${(_saturation * 100).round()}%  L: ${(_lightness * 100).round()}%',
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Saturation x Lightness grid
          Align(
            alignment: Alignment.centerLeft,
            child: Text(strings.settingsShade,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (d) =>
                      _updateSatLight(d.localPosition, constraints),
                  onPanUpdate: (d) =>
                      _updateSatLight(d.localPosition, constraints),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 160),
                    painter: _SatLightPainter(_hue, _saturation, _lightness),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Hue slider
          Align(
            alignment: Alignment.centerLeft,
            child: Text(strings.settingsHue,
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (d) =>
                      _updateHue(d.localPosition.dx, constraints.maxWidth),
                  onPanUpdate: (d) =>
                      _updateHue(d.localPosition.dx, constraints.maxWidth),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 28),
                    painter: _HueBarPainter(_hue),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentColor,
                foregroundColor: _lightness > 0.5 ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onSelected(_currentColor.value);
                Navigator.pop(context);
              },
              child: Text(strings.settingsSelectColor,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _updateHue(double dx, double maxWidth) {
    setState(() {
      _hue = (dx / maxWidth).clamp(0.0, 1.0) * 360.0;
    });
  }

  void _updateSatLight(Offset pos, BoxConstraints constraints) {
    setState(() {
      _saturation = (pos.dx / constraints.maxWidth).clamp(0.0, 1.0);
      _lightness = 1.0 - (pos.dy / 160.0).clamp(0.0, 1.0);
    });
  }
}

class _HueBarPainter extends CustomPainter {
  final double hue;
  _HueBarPainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final colors = List.generate(
      7,
      (i) => HSLColor.fromAHSL(1.0, i * 60.0, 1.0, 0.5).toColor(),
    );

    final gradient = LinearGradient(colors: colors);
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Thumb
    final thumbX = (hue / 360.0) * size.width;
    canvas.drawCircle(
      Offset(thumbX.clamp(8, size.width - 8), size.height / 2),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _HueBarPainter old) => old.hue != hue;
}

class _SatLightPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double lightness;
  _SatLightPainter(this.hue, this.saturation, this.lightness);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.clipRRect(rrect);

    // Draw cells
    const cols = 20;
    const rows = 10;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final s = c / (cols - 1);
        final l = 1.0 - r / (rows - 1);
        final color = HSLColor.fromAHSL(1.0, hue, s, l).toColor();
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW + 1, cellH + 1),
          Paint()..color = color,
        );
      }
    }

    // Thumb
    final thumbX = saturation * size.width;
    final thumbY = (1.0 - lightness) * size.height;
    canvas.drawCircle(
      Offset(thumbX.clamp(8, size.width - 8), thumbY.clamp(8, size.height - 8)),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SatLightPainter old) =>
      old.hue != hue ||
      old.saturation != saturation ||
      old.lightness != lightness;
}

class _SimulateNotificationSheet extends StatefulWidget {
  const _SimulateNotificationSheet();

  @override
  State<_SimulateNotificationSheet> createState() =>
      _SimulateNotificationSheetState();
}

class _SimulateNotificationSheetState
    extends State<_SimulateNotificationSheet> {
  final _packageNameController =
      TextEditingController(text: 'com.android.messaging');
  final _titleController = TextEditingController(text: 'HDFC Bank');
  final _bodyController = TextEditingController(
      text:
          'Alert: Rs 2,500.00 spent on Debit Card XX4321 at STARBUCKS. Bal: Rs 15,432.00.');

  final List<Map<String, String>> _templates = [
    {
      'name': 'HDFC Debit',
      'package': 'com.android.messaging',
      'title': 'HDFC Bank',
      'body':
          'Alert: Rs 2,500.00 spent on Debit Card XX4321 at STARBUCKS. Bal: Rs 15,432.00.'
    },
    {
      'name': 'ICICI Credit',
      'package': 'com.android.messaging',
      'title': 'ICICI Bank',
      'body':
          'Your ICICI Bank Credit Card XX9999 has been charged Rs 8,450.00 at AMAZON INDIA. Available Limit: Rs 92,300.00.'
    },
    {
      'name': 'SBI UPI SMS',
      'package': 'com.android.messaging',
      'title': 'SBI UPI',
      'body':
          'Dear SBI User, Rs 1,500.00 debited from A/c XX8888 on 22-07-2026 for UPI Ref: 629381029472.'
    },
    {
      'name': 'Google Pay',
      'package': 'com.google.android.apps.nbu.paisa',
      'title': 'Google Pay',
      'body': 'You paid Rs 250 to Reliance Retail via UPI.'
    },
    {
      'name': 'WhatsApp (Ignore)',
      'package': 'com.whatsapp',
      'title': 'John Doe',
      'body': 'Hey, can you transfer Rs 500 to my account?'
    },
    {
      'name': 'Promo (Ignore)',
      'package': 'com.zomato.android',
      'title': 'Zomato',
      'body':
          'Hungry? Grab 50% discount up to Rs 120 on your next order! Use code CRRAVE50.'
    },
  ];

  @override
  void dispose() {
    _packageNameController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _packageNameController.text = template['package'] ?? '';
      _titleController.text = template['title'] ?? '';
      _bodyController.text = template['body'] ?? '';
    });
  }

  Future<void> _simulate() async {
    final pkg = _packageNameController.text.trim();
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (pkg.isEmpty || body.isEmpty) {
      final strings = AppLocalizations.of(context)!;
      AppSnackBar.show(
          context, strings.settingsSimulateRequiredError,
          type: SnackBarType.warning);
      return;
    }

    final mockEvent = NotificationEvent(
      packageName: pkg,
      title: title,
      text: body,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    Navigator.pop(context);

    try {
      await NotificationHandler.handleNotificationEvent(mockEvent);
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context,
            strings.settingsSimulateSuccess,
            type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.settingsSimulateFailure(e.toString()),
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.playlist_add_rounded,
                      color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    strings.settingsSimulateNotificationTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.settingsSimulateNotificationDescription,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Horizontal Templates List
              Text(
                strings.settingsQuickTemplates,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(t['name'] ?? ''),
                        labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        onPressed: () => _applyTemplate(t),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Package Name Input
              Text(
                strings.settingsAppPackageName,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _packageNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. com.android.messaging',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title Input
              Text(
                strings.settingsNotificationTitleLabel,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. HDFC Bank',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Body Input
              Text(
                strings.settingsNotificationBodyLabel,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _bodyController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: strings.settingsNotificationBodyHint,
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Simulate Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _simulate,
                  child: Text(
                    strings.settingsSimulateAndProcess,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
