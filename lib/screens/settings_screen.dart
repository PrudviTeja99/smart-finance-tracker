import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:file_picker/file_picker.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/notification_handler.dart';
import '../utils/transaction_parser.dart';
import '../utils/bio_tagger.dart';
import '../utils/app_settings.dart';
import '../utils/icon_helper.dart';
import '../utils/app_snackbar.dart';
import '../services/perceptron_storage_service.dart';
import 'archived_alerts_screen.dart';
import 'model_training_screen.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
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

    if (!serviceEnabled && AppSettings.autoDeleteArchive) {
      await AppSettings.setAutoDeleteArchive(false);
    }

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
      await AppSettings.setAutoDeleteArchive(true);
      await AppSettings.setAutoDeleteValue(1);
      await AppSettings.setAutoDeleteUnit('months');
    } else {
      // Confirmation dialog before disabling
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 36),
          title: const Text('Disable Smart Tracking?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: const Text(
            'The app will stop listening to incoming notifications in the background. '
            'New transactions will not be captured automatically until you re-enable this.\n\n'
            'Archived alerts, automation logs, and processed queue data will be cleaned up in the background. '
            'Your confirmed transactions and learned AI model weights will be preserved.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Enabled', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Disable', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
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
        debugPrint('🧹 Background cleanup complete: archived alerts, audit logs, and processed queue cleared.');
      });
    }
    _loadSettingsData();
  }

  // Trigger JSON file restore picker
  Future<void> _importJSONBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonContent = await file.readAsString();
        final success = await BackupService.restoreBackupJSON(jsonContent);

        if (mounted) {
          AppSnackBar.show(
            context,
            success ? 'Database restored successfully!' : 'Invalid backup file.',
            type: success ? SnackBarType.success : SnackBarType.error,
          );
          if (success) {
            _loadSettingsData();
          }
        }
      }
    } catch (e) {
      debugPrint('Restore file picker error: $e');
    }
  }

  void _showDurationPickerSheet() {
    int tempValue = AppSettings.autoDeleteValue;
    String tempUnit = AppSettings.autoDeleteUnit;

    final units = ['days', 'months', 'years'];
    final unitIndex = units.indexOf(tempUnit).clamp(0, 2);

    final valueScrollController = FixedExtentScrollController(initialItem: tempValue - 1);
    final unitScrollController = FixedExtentScrollController(initialItem: unitIndex);
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
                      const Text(
                        'Auto-Delete Retention',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select or type the age of alerts to permanently remove.',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  const SizedBox(height: 20),

                  // Numeric input & Unit preview pill combined
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
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
                                contentPadding: EdgeInsets.symmetric(vertical: 6),
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
                              textController.selection = TextSelection.fromPosition(
                                TextPosition(offset: textController.text.length),
                              );
                              isUpdatingFromWheel = false;
                              setSheetState(() {});
                            },
                            children: List.generate(90, (index) => Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                            children: units.map((u) => Center(
                              child: Text(
                                u,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            )).toList(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final enteredValue = int.tryParse(textController.text) ?? tempValue;
                      await AppSettings.setAutoDeleteValue(enteredValue.clamp(1, 999));
                      await AppSettings.setAutoDeleteUnit(tempUnit);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      setState(() {});
                    },
                    child: const Text('Save Retention Period', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _loadSettingsData(); // Lazy refresh

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // padding for bottom navigation strap
            children: [
              // 1. Preferences Card (Top)
              _buildSettingsGroup(
                title: 'Preferences',
                icon: Icons.tune_rounded,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1)),
                    title: const Text('Manage Payment Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_accounts.length} active accounts', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
                    onTap: _showManageAccountsSheet,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.category_rounded, color: Color(0xFF6366F1)),
                    title: const Text('Manage Transaction Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_categories.length} active categories', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
                    onTap: _showManageCategoriesSheet,
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_rounded, color: Color(0xFF6366F1)),
                    title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Display currency across the app', style: TextStyle(fontSize: 11)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
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
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('INR (₹)')),
                            DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                            DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                            DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                            DropdownMenuItem(value: '¥', child: Text('JPY/CNY (¥)')),
                            DropdownMenuItem(value: '₩', child: Text('KRW (₩)')),
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
                  SwitchListTile(
                    title: const Text('Auto-Hide Balances on Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Masks Dashboard values when app opens', style: TextStyle(fontSize: 11)),
                    value: AppSettings.autoHideEnabled,
                    activeColor: const Color(0xFF6366F1),
                    secondary: const Icon(Icons.visibility_off_rounded, color: Color(0xFF6366F1)),
                    onChanged: (val) async {
                      await AppSettings.setAutoHideEnabled(val);
                      setState(() {});
                    },
                  ),
                  if (AppSettings.autoHideEnabled)
                    Container(
                      margin: const EdgeInsets.only(left: 56, right: 16, bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.02)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hide Duration',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: AppSettings.autoHideSeconds > 1 ? Colors.white60 : Colors.white24,
                                  size: 22,
                                ),
                                onPressed: AppSettings.autoHideSeconds > 1
                                    ? () async {
                                        await AppSettings.setAutoHideSeconds(AppSettings.autoHideSeconds - 1);
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: AppSettings.autoHideSeconds,
                                    dropdownColor: const Color(0xFF1E293B),
                                    icon: const SizedBox.shrink(),
                                    alignment: Alignment.center,
                                    isDense: true,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                      fontSize: 13,
                                    ),
                                    items: (() {
                                      final presets = [1, 2, 3, 5, 10, 15, 30, 45, 60];
                                      final currentVal = AppSettings.autoHideSeconds;
                                      final itemsList = presets.contains(currentVal)
                                          ? presets
                                          : (List<int>.from(presets)..add(currentVal)..sort());
                                      return itemsList.map((val) {
                                        return DropdownMenuItem<int>(
                                          value: val,
                                          child: Center(
                                            child: Text(
                                              '${val}s',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    })(),
                                    onChanged: (val) async {
                                      if (val != null) {
                                        await AppSettings.setAutoHideSeconds(val);
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
                                  color: AppSettings.autoHideSeconds < 60 ? Colors.white60 : Colors.white24,
                                  size: 22,
                                ),
                                onPressed: AppSettings.autoHideSeconds < 60
                                    ? () async {
                                        await AppSettings.setAutoHideSeconds(AppSettings.autoHideSeconds + 1);
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
                title: 'Data & Backups',
                icon: Icons.sync_rounded,
                children: [
                  ListTile(
                    leading: const Icon(Icons.table_rows_rounded, color: Color(0xFF10B981)),
                    title: const Text('Export Ledger to CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Share transactions as Excel-compatible file', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      await BackupService.exportToCSV();
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.download, color: Color(0xFF6366F1)),
                    title: const Text('Backup Data (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Generate database backup file to share', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      await BackupService.exportBackupJSON();
                    },
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.upload, color: Color(0xFFEA80FC)),
                    title: const Text('Restore Data (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Select JSON backup file to overwrite database', style: TextStyle(fontSize: 11)),
                    onTap: _importJSONBackup,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Advanced Settings (Bottom)
              _buildAdvancedSettingsCard(),
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
            IconData getIcon(String type) {
              switch (type) {
                case 'bank': return Icons.account_balance;
                case 'credit_card': return Icons.credit_card;
                case 'wallet': return Icons.account_balance_wallet;
                default: return Icons.money;
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
                      const Text(
                        'Manage Accounts',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 28),
                            onPressed: () async {
                              await _openAccountFormDialog(null);
                              final dbService = DatabaseService.instance;
                              final accountsList = await dbService.getAllAccounts();
                              setState(() {
                                _accounts = accountsList;
                              });
                              setSheetState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _accounts.isEmpty
                        ? const Center(
                            child: Text(
                              'No accounts yet. Tap + to add one.',
                              style: TextStyle(color: Colors.white38),
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
                                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(getIcon(acc.type), color: const Color(0xFF6366F1), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: acc.keywords.split(',').map((kw) {
                                              final clean = kw.trim();
                                              if (clean.isEmpty) return const SizedBox.shrink();
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  clean,
                                                  style: const TextStyle(fontSize: 8, color: Colors.white60, fontWeight: FontWeight.w500),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white60),
                                      onPressed: () async {
                                        await _openAccountFormDialog(acc);
                                        final dbService = DatabaseService.instance;
                                        final accountsList = await dbService.getAllAccounts();
                                        setState(() {
                                          _accounts = accountsList;
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                      onPressed: () async {
                                        final confirm = await _showConfirmDeleteDialog(acc.name);
                                        if (confirm == true) {
                                          await DatabaseService.instance.deleteAccount(acc.id!);
                                          final dbService = DatabaseService.instance;
                                          final accountsList = await dbService.getAllAccounts();
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
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manage Categories',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981), size: 28),
                            onPressed: () async {
                              await _openCategoryFormDialog(null);
                              final dbService = DatabaseService.instance;
                              final categoriesList = await dbService.getAllCategories();
                              setState(() {
                                _categories = categoriesList;
                              });
                              setSheetState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _categories.isEmpty
                        ? const Center(
                            child: Text(
                              'No categories yet. Tap + to add one.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Color(cat.color).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(IconHelper.getIcon(cat.icon), color: Color(cat.color), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white60),
                                      onPressed: () async {
                                        await _openCategoryFormDialog(cat);
                                        final dbService = DatabaseService.instance;
                                        final categoriesList = await dbService.getAllCategories();
                                        setState(() {
                                          _categories = categoriesList;
                                        });
                                        setSheetState(() {});
                                      },
                                    ),
                                    if (cat.name != 'Others')
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                        onPressed: () async {
                                          final confirm = await _showConfirmDeleteDialog(cat.name);
                                          if (confirm == true) {
                                            await DatabaseService.instance.deleteCategory(cat.id!);
                                            final dbService = DatabaseService.instance;
                                            final categoriesList = await dbService.getAllCategories();
                                            setState(() {
                                              _categories = categoriesList;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartTrackingCard() {
  return _buildSettingsGroup(
    title: 'Smart Tracking',
    icon: Icons.notifications_active_rounded,
    children: [
      // Smart Tracking Toggle
      SwitchListTile(
        title: const Text('Smart Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Read incoming transaction notifications in background', style: TextStyle(fontSize: 11)),
        activeColor: const Color(0xFF6366F1),
        value: _isServiceEnabled,
        onChanged: _toggleService,
        secondary: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1)),
      ),

      if (_isServiceEnabled) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.battery_saver_rounded, color: Color(0xFF6366F1), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Reliability Recommendation',
                      style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'To prevent Android from putting the background listener to sleep, please set this app to "Unrestricted" in battery settings. This will NOT drain your battery because the app only wakes up for 5-10ms when a notification is received.',
                  style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    NotificationHandler.requestBatteryExemption();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF818CF8)),
                        SizedBox(width: 6),
                        Text(
                          'Enable Unrestricted Run',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                        ),
                      ],
                    ),
                  ),
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
                title: const Text('Auto-Delete Archived Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  _isServiceEnabled ? 'Automatically purge old ignored notification logs' : 'Requires Smart Tracking to be enabled',
                  style: const TextStyle(fontSize: 11),
                ),
                value: AppSettings.autoDeleteArchive,
                activeColor: const Color(0xFF6366F1),
                secondary: const Icon(Icons.auto_delete_rounded, color: Color(0xFF6366F1)),
                onChanged: (val) async {
                  if (!val) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        icon: const Icon(Icons.auto_delete_rounded, color: Color(0xFFF59E0B), size: 36),
                        title: const Text('Disable Auto-Delete?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        content: const Text(
                          'Archived alerts will no longer be automatically cleaned up. '
                          'Over time, this may increase storage usage as old notification logs accumulate.\n\n'
                          'You can still manually delete alerts from the Archived Alerts screen.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Keep Enabled', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Disable', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.black.withOpacity(0.15),
                    title: const Text('Delete older than', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
                          ),
                          child: Text(
                            '${AppSettings.autoDeleteValue} ${AppSettings.autoDeleteUnit}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white30),
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
            leading: const Icon(Icons.archive_rounded, color: Color(0xFF6366F1)),
            title: const Text('View Archived Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              _isServiceEnabled ? 'View and restore ignored notifications' : 'Requires Smart Tracking to be enabled',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchivedAlertsScreen()));
            },
          ),
        ),
      ),

      const Divider(color: Colors.white10),

       // Model Automation Audit Log
        ListTile(
          leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8)),
          title: const Text('Model Automation Audit Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('View AI triage history and 1-tap undo automated actions', style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
          onTap: () => _showModelAuditLogSheet(context),
        ),
    ],
  );
}

  Widget _buildAdvancedSettingsCard() {
    return _buildSettingsGroup(
      title: 'Advanced Settings',
      icon: Icons.construction_rounded,
      children: [

        // Train Your Model
        ListTile(
          leading: const Icon(Icons.psychology_rounded, color: Color(0xFF818CF8)),
          title: const Text('Train Your Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Manually teach the AI using sample notifications', style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ModelTrainingScreen()),
            );
          },
        ),

        const Divider(color: Colors.white10),

        // SnackBar Display Duration
        ListTile(
          leading: const Icon(Icons.timer_rounded, color: Color(0xFF6366F1)),
          title: const Text('SnackBar Display Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('${(AppSettings.snackBarDurationMs / 1000).toStringAsFixed(1)} seconds', style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
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
                  child: Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 18),
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

  void _showModelAuditLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Model Automation Audit Log',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Full transparency into automatic actions performed by your on-device AI.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: DatabaseService.instance.getModelAuditLogs(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))));
                      }
                      final logs = snapshot.data!;
                      if (logs.isEmpty) {
                        return const Center(
                          child: Text('No automated actions logged yet today.', style: TextStyle(color: Colors.white38, fontSize: 13)),
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
                          final confidence = (log['confidence'] as num? ?? 0.85).toDouble();
                          final isDrafted = action == 'auto_drafted';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDrafted ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF6366F1).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDrafted ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF6366F1).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isDrafted ? 'AUTO-DRAFTED' : 'AUTO-ARCHIVED',
                                        style: TextStyle(
                                          color: isDrafted ? const Color(0xFF34D399) : const Color(0xFF818CF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(appName, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text(
                                      '${(confidence * 100).toInt()}% Conf.',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title.isNotEmpty ? '$title: $body' : body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.undo_rounded, size: 14, color: Color(0xFF818CF8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            isDrafted ? 'Undo Auto-Draft' : 'Undo Auto-Archive',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
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

    if (actionType == 'auto_archived') {
      if (logId != null) {
        await dbService.updateNotificationLogStatus(logId, 'unclassified');
      }
      if (mounted) {
        AppSnackBar.show(context, 'Restored to Captured Alerts!', type: SnackBarType.success);
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
        AppSnackBar.show(context, 'Moved back to Captured Alerts. AI learned to ignore similar alerts.', type: SnackBarType.neutral);
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
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete configuration?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccountFormDialog(AccountModel? editAcc) async {
    final isEdit = editAcc != null;
    final nameController = TextEditingController(text: isEdit ? editAcc.name : '');
    final kwController = TextEditingController(text: isEdit ? editAcc.keywords : '');
    final balController = TextEditingController(text: isEdit ? editAcc.balance.toString() : '0.0');
    String type = isEdit ? editAcc.type : 'bank';

    final types = [
      {'value': 'bank', 'label': 'Bank', 'icon': Icons.account_balance},
      {'value': 'credit_card', 'label': 'Card', 'icon': Icons.credit_card},
      {'value': 'wallet', 'label': 'Wallet', 'icon': Icons.account_balance_wallet},
      {'value': 'cash', 'label': 'Cash', 'icon': Icons.money},
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
                      isEdit ? 'Edit Account' : 'Add Account',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text('Account Type', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: types.map((t) {
                        final isSel = type == t['value'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => type = t['value'] as String),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(t['icon'] as IconData, color: isSel ? const Color(0xFF6366F1) : Colors.white38, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['label'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      color: isSel ? Colors.white : Colors.white54,
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
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kwController,
                      decoration: const InputDecoration(
                        labelText: 'Matching Keywords (comma separated)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        helperText: 'E.g. "5678, SBI" (used to auto-predict this account)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Starting Balance (${AppSettings.currencySymbol})',
                        border: const OutlineInputBorder(),
                        prefixText: '${AppSettings.currencySymbol} ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final kw = kwController.text.trim();
                              final bal = double.tryParse(balController.text) ?? 0.0;
                              if (name.isEmpty) return;

                              final acc = AccountModel(
                                id: isEdit ? editAcc.id : null,
                                name: name,
                                type: type,
                                keywords: kw.isEmpty ? name : kw,
                                balance: bal,
                              );

                              if (isEdit) {
                                await DatabaseService.instance.updateAccount(acc);
                              } else {
                                await DatabaseService.instance.insertAccount(acc);
                              }

                              Navigator.pop(context);
                              _loadSettingsData();
                            },
                            child: Text(isEdit ? 'Save' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final isEdit = editCat != null;
    final nameController = TextEditingController(text: isEdit ? editCat.name : '');
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
                      isEdit ? 'Edit Category' : 'Add Category',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Theme Color', style: TextStyle(fontSize: 12, color: Colors.white54)),
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
                                    color: isSel ? Colors.white : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: isSel
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            );
                          }),
                          // Custom color picker button
                          GestureDetector(
                            onTap: () {
                              nameFocusNode.unfocus();
                              _showColorSpectrumPicker(context, colorValue, (selectedColor) {
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
                                  color: !colors.contains(colorValue) ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: !colors.contains(colorValue)
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : const Icon(Icons.colorize_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Category Icon', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(colorValue).withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(colorValue).withOpacity(0.25), width: 1.5),
                          ),
                          child: Icon(IconHelper.getIcon(icon), color: Color(colorValue), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Icon: "${icon.replaceAll('_', ' ')}"',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Search from 60+ modern icons',
                                style: TextStyle(fontSize: 10, color: Colors.white38),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 14, color: Color(0xFF6366F1)),
                          label: const Text('Browse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            nameFocusNode.unfocus();
                            _showSearchableIconPicker(context, colorValue, (selectedIcon) {
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                await DatabaseService.instance.updateCategory(cat);
                              } else {
                                await DatabaseService.instance.insertCategory(cat);
                              }

                              Navigator.pop(context);
                              _loadSettingsData();
                            },
                            child: Text(isEdit ? 'Save' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showSearchableIconPicker(BuildContext context, int colorValue, Function(String) onSelected) {
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

  void _showColorSpectrumPicker(BuildContext context, int currentColor, Function(int) onSelected) {
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
                const Text(
                  'Search Category Icons',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by keyword (e.g. food, taxi, bill...)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white38),
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
                      ? const Center(
                          child: Text(
                            'No matching icons found.\nTry another keyword!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(iconData, color: Color(widget.colorValue), size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      key.replaceAll('_', ' '),
                                      style: const TextStyle(fontSize: 9, color: Colors.white60),
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

  Color get _currentColor => HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Pick a Custom Color',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Shade', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (d) => _updateSatLight(d.localPosition, constraints),
                  onPanUpdate: (d) => _updateSatLight(d.localPosition, constraints),
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Hue', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
                  onPanUpdate: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                widget.onSelected(_currentColor.value);
                Navigator.pop(context);
              },
              child: const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      old.hue != hue || old.saturation != saturation || old.lightness != lightness;
}
