import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/app_icon_cache_service.dart';
import '../services/merchant_search_service.dart';
import '../services/notification_handler.dart';
import '../services/batch_processor_service.dart';
import '../services/perceptron_storage_service.dart';
import '../utils/bio_tagger.dart';
import '../utils/transaction_parser.dart';
import '../utils/app_settings.dart';
import '../utils/app_snackbar.dart';
import '../utils/icon_helper.dart';

class PendingVerificationScreen extends StatefulWidget {
  final VoidCallback onConfirmedOrDiscarded;
  final ValueNotifier<int>? refreshSignal;

  const PendingVerificationScreen({super.key, required this.onConfirmedOrDiscarded, this.refreshSignal});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> with TickerProviderStateMixin {
  List<TransactionModel> _pendingTransactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  final TransactionParser _parser = TransactionParser();
  bool _isServiceEnabled = false;

  // Dual-tab controller
  late TabController _tabController;

  // Captured Alerts state
  List<Map<String, dynamic>> _capturedAlerts = [];
  bool _isAppCategorySelectionMode = false;
  final Set<String> _selectedAppPackages = {};

  Widget _buildAppIconWidget(String packageName, String fallbackName, {double size = 24}) {
    return AppIconCacheService.instance.buildAppIconWidget(
      packageName,
      fallbackName,
      size: size,
      onLoaded: () {
        if (mounted) setState(() {});
      },
    );
  }

  // Map to track loading states of web lookups for each transaction card by ID
  final Map<int, bool> _lookupLoading = {};
  // Map to track dynamic category suggestion lists returned from search
  final Map<int, List<String>> _categorySuggestions = {};
  bool _isKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    PerceptronStorageService.instance.loadWeights();
    _loadPendingData();
    _loadCapturedAlerts();

    // Listen for foreground refresh signals (new notifications while app is open)
    widget.refreshSignal?.addListener(_onForegroundRefresh);

    // Trigger foreground batch processor for raw background notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatchProcessorService.instance.processQueue(onCompleted: () {
        if (mounted) {
          _loadPendingData();
          _loadCapturedAlerts();
        }
      });
    });
  }

  void _onForegroundRefresh() {
    if (mounted) {
      _loadPendingData();
      _loadCapturedAlerts();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onForegroundRefresh);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCapturedAlerts() async {
    final logs = await DatabaseService.instance.getNotificationLogs('unclassified');
    if (mounted) {
      setState(() {
        _capturedAlerts = logs;
      });
    }
  }

  Future<void> _loadPendingData() async {
    final dbService = DatabaseService.instance;
    final pending = await dbService.getPendingTransactions();
    final accountsList = await dbService.getAllAccounts();
    final categoriesList = await dbService.getAllCategories();
    final running = await NotificationHandler.isServiceRunning();
    final permission = await NotificationHandler.hasPermission();
    final serviceEnabled = running && permission;

    if (mounted) {
      // Check if we actually need to update the state to prevent infinite build loops
      final hasPendingChanged = _pendingTransactions.length != pending.length ||
          _pendingTransactions.any((tx) => !pending.any((p) => p.id == tx.id));
      final hasAccountsChanged = _accounts.length != accountsList.length;
      final hasCategoriesChanged = _categories.length != categoriesList.length;
      final hasServiceChanged = _isServiceEnabled != serviceEnabled;

      if (hasPendingChanged || hasAccountsChanged || hasCategoriesChanged || hasServiceChanged) {
        setState(() {
          _pendingTransactions = pending;
          _accounts = accountsList;
          _categories = categoriesList;
          _isServiceEnabled = serviceEnabled;
        });
      }
    }
  }

  Future<void> _enableService() async {
    final hasPerm = await NotificationHandler.hasPermission();
    if (!hasPerm) {
      await NotificationHandler.openPermissionSettings();
    } else {
      await NotificationHandler.startService();
    }
    await _loadPendingData();
  }

  // Confirm and train Naive Bayes models with user verified data
  Future<void> _confirmTransaction(TransactionModel tx, String categoryName) async {
    // Show SnackBar synchronously first to avoid queuing delays
    if (mounted) {
      AppSnackBar.show(context, 'Confirmed transaction under "$categoryName"! Learned this pattern.', type: SnackBarType.success);
    }

    final dbService = DatabaseService.instance;
    
    // Update status to confirmed and save edits
    final confirmedTx = tx.copyWith(status: 'confirmed');
    await dbService.updateTransaction(confirmedTx);

    // Look up the name of the selected account
    final account = _accounts.firstWhere((a) => a.id == tx.accountId, orElse: () => _accounts.first);
    final accountName = account.name;

    // Self-Learning: Train type, category, account, and description classifiers on-device
    await _parser.trainConfirm(
  body: tx.body,
  categoryName: categoryName,
  accountName: accountName,
  accountKeywords: account.keywords,
  description: tx.description,
  amount: tx.amount,
  type: tx.type,
);

    widget.onConfirmedOrDiscarded();
    _loadPendingData();
  }

  // Delete pending transaction and train model to ignore similar patterns
  Future<void> _discardTransaction(int id) async {
    final dbService = DatabaseService.instance;
    final pending = _pendingTransactions.where((t) => t.id == id).toList();
    
    if (pending.isNotEmpty && pending.first.body.isNotEmpty) {
      final bodyText = pending.first.body;
      // Active Learning: Train model that this pattern should be ignored
      await _parser.trainType(bodyText, 'ignore');
      await PerceptronStorageService.instance.saveWeights();
    }

    await dbService.deleteTransaction(id);
    widget.onConfirmedOrDiscarded();
    _loadPendingData();

    if (mounted) {
      AppSnackBar.show(context, 'Discarded notification. AI learned to ignore similar alerts.', type: SnackBarType.neutral);
    }
  }

  // Mute notifications from app and archive raw log
  Future<void> _muteAppForLog(String packageName, int logId, String body) async {
    await AppSettings.muteApp(packageName);
    await DatabaseService.instance.updateNotificationLogStatus(logId, 'archived');
    
    // Train classifier to ignore
    await _parser.trainType(body, 'ignore');

    if (mounted) {
      AppSnackBar.show(context, 'Muted notifications from $packageName.', type: SnackBarType.neutral);
    }

    _loadPendingData();
    _loadCapturedAlerts();
  }

  // Mute an entire app package and archive all its captured logs
  Future<void> _muteEntireApp(String packageName, String appName, List<Map<String, dynamic>> alertsList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mute $appName?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'All future notifications from $appName will be automatically ignored. Also archives ${alertsList.length} captured ${alertsList.length == 1 ? "alert" : "alerts"} from this app.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mute App', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppSettings.muteApp(packageName);
      for (var alert in alertsList) {
        final logId = alert['id'] as int;
        final body = alert['body'] as String? ?? '';
        await DatabaseService.instance.updateNotificationLogStatus(logId, 'archived');
        await _parser.trainType(body, 'ignore');
      }
      if (mounted) {
        AppSnackBar.show(context, 'Muted $appName and archived all alerts.', type: SnackBarType.neutral);
      }
      _loadPendingData();
      _loadCapturedAlerts();
    }
  }

  // --- BATCH CLEARING & SELECTIVE APP CATEGORY MANAGEMENT ---

  Future<void> _discardAllDrafts() async {
    if (_pendingTransactions.isEmpty) return;

    final count = _pendingTransactions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard All Drafts?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to discard all $count pending draft transactions? Unconfirmed drafts will be removed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard All', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var tx in _pendingTransactions) {
        if (tx.id != null) {
          await DatabaseService.instance.deleteTransaction(tx.id!);
        }
      }
      if (mounted) {
        AppSnackBar.show(context, '$count draft transactions discarded.', type: SnackBarType.neutral);
      }
      widget.onConfirmedOrDiscarded();
      _loadPendingData();
    }
  }

  Future<void> _archiveAllCapturedAlerts() async {
    if (_capturedAlerts.isEmpty) return;

    final count = _capturedAlerts.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Archive All Alerts?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to archive all $count captured alerts? They will be moved to your Archived Alerts feed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive All', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var alert in _capturedAlerts) {
        final logId = alert['id'] as int;
        final body = alert['body'] as String? ?? '';
        await DatabaseService.instance.updateNotificationLogStatus(logId, 'archived');
        await _parser.trainType(body, 'ignore');
      }
      if (mounted) {
        AppSnackBar.show(context, '$count captured alerts archived.', type: SnackBarType.neutral);
      }
      _loadCapturedAlerts();
    }
  }

  void _toggleAppPackageSelection(String packageName) {
    setState(() {
      if (_selectedAppPackages.contains(packageName)) {
        _selectedAppPackages.remove(packageName);
        if (_selectedAppPackages.isEmpty) {
          _isAppCategorySelectionMode = false;
        }
      } else {
        _selectedAppPackages.add(packageName);
      }
    });
  }

  void _enterAppCategorySelectionMode(String initialPackage) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAppCategorySelectionMode = true;
      _selectedAppPackages.clear();
      _selectedAppPackages.add(initialPackage);
    });
  }

  Future<void> _archiveSelectedAppCategories() async {
    if (_selectedAppPackages.isEmpty) return;

    final selectedPkgs = _selectedAppPackages.toList();
    int totalAlertsCount = 0;

    for (var pkg in selectedPkgs) {
      final alertsForPkg = _capturedAlerts.where((a) => a['package_name'] == pkg).toList();
      totalAlertsCount += alertsForPkg.length;
      for (var alert in alertsForPkg) {
        final logId = alert['id'] as int;
        final body = alert['body'] as String? ?? '';
        await DatabaseService.instance.updateNotificationLogStatus(logId, 'archived');
        await _parser.trainType(body, 'ignore');
      }
    }

    if (mounted) {
      AppSnackBar.show(context, 'Archived $totalAlertsCount alerts from ${selectedPkgs.length} app categories.', type: SnackBarType.neutral);
      setState(() {
        _isAppCategorySelectionMode = false;
        _selectedAppPackages.clear();
      });
    }
    _loadCapturedAlerts();
  }

  Future<void> _muteAndArchiveSelectedAppCategories() async {
    if (_selectedAppPackages.isEmpty) return;

    final selectedPkgs = _selectedAppPackages.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mute ${selectedPkgs.length} Apps?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Future notifications from these ${selectedPkgs.length} selected apps will be automatically ignored.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mute & Archive', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int totalAlertsCount = 0;
      for (var pkg in selectedPkgs) {
        await AppSettings.muteApp(pkg);
        final alertsForPkg = _capturedAlerts.where((a) => a['package_name'] == pkg).toList();
        totalAlertsCount += alertsForPkg.length;
        for (var alert in alertsForPkg) {
          final logId = alert['id'] as int;
          final body = alert['body'] as String? ?? '';
          await DatabaseService.instance.updateNotificationLogStatus(logId, 'archived');
          await _parser.trainType(body, 'ignore');
        }
      }

      if (mounted) {
        AppSnackBar.show(context, 'Muted ${selectedPkgs.length} apps and archived $totalAlertsCount alerts.', type: SnackBarType.neutral);
        setState(() {
          _isAppCategorySelectionMode = false;
          _selectedAppPackages.clear();
        });
      }
      _loadCapturedAlerts();
    }
  }
  Future<void> _handleFeedback(int logId, String appName, String title, String body, bool isFinancial, bool isRelevant) async {
    final dbService = DatabaseService.instance;

    if (!isFinancial || !isRelevant) {
      // 1. Train model to ignore this pattern
      await _parser.trainType(body, 'ignore');

      // 2. Archive the log
      await dbService.updateNotificationLogStatus(logId, 'archived');

      if (mounted) {
        AppSnackBar.show(context, 'Captured alert archived. Model trained to ignore.', type: SnackBarType.neutral);
      }
    } else {
      // 1. Parse details
      final tx = await _parser.parseNotification(
        appName: appName,
        title: title,
        body: body,
      );

      if (tx != null) {
        // 2. Insert as a transaction draft
        final txId = await dbService.insertTransaction(tx);
        if (txId != -1) {
          // Train model on parsed transaction type
          await _parser.trainType(body, tx.type);
          // Set log status to drafted
          await dbService.updateNotificationLogStatus(logId, 'drafted');

          if (mounted) {
            AppSnackBar.show(context, 'Promoted alert to Transaction Drafts!', type: SnackBarType.success);
          }
        } else {
          // Already exists or duplicate, archive it
          await dbService.updateNotificationLogStatus(logId, 'archived');
        }
      } else {
        // If parsing still returned null but user says it is a transaction, let's create a generic manual entry
        final manualTx = TransactionModel(
          appName: appName,
          title: title,
          body: body,
          amount: 0.0, // Let the user fill it out in Drafts
          type: 'debit', // Default
          accountId: 1, // Cash/Bank
          categoryId: 6, // Others
          description: title.isNotEmpty ? title : 'New Notification',
          date: DateTime.now(),
          status: 'pending',
        );
        await dbService.insertTransaction(manualTx);
        await dbService.updateNotificationLogStatus(logId, 'drafted');

        if (mounted) {
          AppSnackBar.show(context, 'Promoted alert to Transaction Drafts!', type: SnackBarType.success);
        }
      }
    }

    _loadPendingData();
    _loadCapturedAlerts();
    widget.onConfirmedOrDiscarded();
  }

  // Trigger user-clicked online search category lookup
  Future<void> _triggerOnlineCategoryLookup(int txId, String merchantName) async {
    setState(() {
      _lookupLoading[txId] = true;
    });

    final suggestions = await MerchantSearchService.searchMerchantCategory(merchantName);

    setState(() {
      _lookupLoading[txId] = false;
      _categorySuggestions[txId] = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadPendingData(); // Lazy refresh
    _loadCapturedAlerts(); // Lazy refresh alerts

    final currentBottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardNowOpen = currentBottomInset > 0;
    if (_isKeyboardOpen && !isKeyboardNowOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
    _isKeyboardOpen = isKeyboardNowOpen;

    return PopScope(
      canPop: !_isAppCategorySelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isAppCategorySelectionMode) {
          setState(() {
            _isAppCategorySelectionMode = false;
            _selectedAppPackages.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _isAppCategorySelectionMode ? const Color(0xFF1E293B) : Colors.transparent,
          elevation: 0,
          leading: _isAppCategorySelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isAppCategorySelectionMode = false;
                      _selectedAppPackages.clear();
                    });
                  },
                )
              : null,
          title: Text(
            _isAppCategorySelectionMode
                ? '${_selectedAppPackages.length} ${_selectedAppPackages.length == 1 ? "App Selected" : "Apps Selected"}'
                : 'Transaction Inbox',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: _isAppCategorySelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.archive_outlined, color: Color(0xFF818CF8)),
                    tooltip: 'Archive Selected Apps',
                    onPressed: _archiveSelectedAppCategories,
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_off_rounded, color: Color(0xFFEF4444)),
                    tooltip: 'Mute & Archive Selected',
                    onPressed: _muteAndArchiveSelectedAppCategories,
                  ),
                ]
              : [
                  if (_tabController.index == 0 && _pendingTransactions.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
                      tooltip: 'Discard All Drafts',
                      onPressed: _discardAllDrafts,
                    ),
                  if (_tabController.index == 1 && _capturedAlerts.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.checklist_rounded, color: Colors.white70),
                      tooltip: 'Select Apps to Clear',
                      onPressed: () {
                        setState(() {
                          _isAppCategorySelectionMode = true;
                          _selectedAppPackages.clear();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.white70),
                      tooltip: 'Archive All Alerts',
                      onPressed: _archiveAllCapturedAlerts,
                    ),
                  ],
                ],
        ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // --- CUSTOM PREMIUM SEGMENTED TAB SWITCHER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: AnimatedBuilder(
                  animation: _tabController.animation!,
                  builder: (context, child) {
                    final value = _tabController.animation!.value;
                    return Stack(
                      children: [
                        // Sliding indicator
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth / 2;
                            return Transform.translate(
                              offset: Offset(value * width, 0),
                              child: Container(
                                width: width,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1), // Indigo
                                      Color(0xFF818CF8), // Soft indigo
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Tab items
                        Row(
                          children: [
                            _buildTabItem(0, Icons.edit_note_rounded, 'Drafts', _pendingTransactions.length, value),
                            _buildTabItem(1, Icons.receipt_long_rounded, 'Captured Alerts', _capturedAlerts.length, value),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildBatchProgressBarWidget(),
            _buildModelActivityBannerWidget(),
            // --- TAB CONTENT ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDraftsTab(),
                  _buildCapturedAlertsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // --- TAB ITEM BUILDER ---
  Widget _buildTabItem(int index, IconData icon, String label, int count, double animValue) {
    // Calculate activation percentage for this tab index
    final double percent = index == 0 ? (1 - animValue).clamp(0.0, 1.0) : animValue.clamp(0.0, 1.0);
    final color = Color.lerp(Colors.white.withOpacity(0.4), Colors.white, percent)!;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.2),
                      percent,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: Color.lerp(
                        Colors.white.withOpacity(0.6),
                        Colors.white,
                        percent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchProgressBarWidget() {
    return ValueListenableBuilder<BatchProgressState>(
      valueListenable: BatchProcessorService.instance.progressNotifier,
      builder: (context, state, child) {
        if (!state.isProcessing) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '⚡ Processing ${state.totalCount} incoming alerts...',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '${state.processedCount}/${state.totalCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelActivityBannerWidget() {
    return FutureBuilder<Map<String, int>>(
      future: DatabaseService.instance.getDailyAuditCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};
        final drafted = counts['auto_drafted'] ?? 0;
        final archived = counts['auto_archived'] ?? 0;
        final hasActivity = drafted > 0 || archived > 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasActivity
                      ? 'Model Activity Today: Auto-drafted $drafted, Auto-archived $archived'
                      : 'Model Activity: AI Active & Learning',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              GestureDetector(
                onTap: () => _showModelAuditLogSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'View Log',
                    style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        await _parser.trainType(body, 'ignore');
        await PerceptronStorageService.instance.saveWeights();
      }
      if (mounted) {
        AppSnackBar.show(context, 'Moved back to Captured Alerts. AI learned to ignore similar alerts.', type: SnackBarType.neutral);
      }
    }

    final db = await dbService.database;
    await db.delete('model_audit_log', where: 'id = ?', whereArgs: [auditId]);

    if (mounted) {
      _loadPendingData();
      _loadCapturedAlerts();
      setState(() {});
    }
  }

  // --- DRAFTS TAB ---
  Widget _buildDraftsTab() {
    return Stack(
      children: [
        // Background soft design circle
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withOpacity(0.05),
            ),
          ),
        ),
        _pendingTransactions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isServiceEnabled) ...[
                        const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'All caught up!',
                          style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your transaction inbox is empty.',
                          style: TextStyle(fontSize: 13, color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 56,
                            color: Color(0xFFEA80FC),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Smart Tracking Disabled',
                          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enable Smart Tracking to automatically detect, parse, and review transaction notifications here.',
                          style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _enableService,
                          icon: const Icon(Icons.bolt_rounded, size: 20),
                          label: const Text(
                            'Enable Smart Tracking',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: _pendingTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _pendingTransactions[index];
                  return Dismissible(
                    key: Key(tx.id!.toString()),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) => _discardTransaction(tx.id!),
                    background: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text('Discard', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    child: PendingTransactionCard(
                      key: ValueKey(tx.id),
                      tx: tx,
                      accounts: _accounts,
                      categories: _categories,
                      onConfirm: _confirmTransaction,
                      onDiscard: _discardTransaction,
                      onOnlineLookup: _triggerOnlineCategoryLookup,
                      isLookupLoading: _lookupLoading[tx.id] ?? false,
                      suggestions: _categorySuggestions[tx.id] ?? [],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- CAPTURED ALERTS TAB ---
  Widget _buildCapturedAlertsTab() {
    if (_capturedAlerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Captured Alerts',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _isServiceEnabled
                    ? 'Notifications that aren\'t auto-classified will appear here for your review.'
                    : 'Enable Smart Tracking to capture and classify notifications.',
                style: const TextStyle(fontSize: 13, color: Colors.white54, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group captured alerts by package_name
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var alert in _capturedAlerts) {
      final pkg = alert['package_name'] as String? ?? 'unknown';
      if (!groups.containsKey(pkg)) {
        groups[pkg] = [];
      }
      groups[pkg]!.add(alert);
    }

    final sortedPackages = groups.keys.toList()
      ..sort((a, b) {
        final dateStrA = groups[a]!.first['date'] as String? ?? '';
        final dateStrB = groups[b]!.first['date'] as String? ?? '';
        final dateA = DateTime.tryParse(dateStrA) ?? DateTime(1970);
        final dateB = DateTime.tryParse(dateStrB) ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: sortedPackages.length,
      itemBuilder: (context, index) {
        final pkg = sortedPackages[index];
        final alertsList = groups[pkg]!;
        final fallbackAppName = alertsList.first['app_name'] as String? ?? 'Unknown';
        final resolvedAppName = AppIconCacheService.instance.getCachedAppName(pkg, defaultFallback: fallbackAppName);
        final isSelected = _selectedAppPackages.contains(pkg);

        return _CapturedAppGroupTile(
          key: ValueKey('captured_group_${pkg}_${_isAppCategorySelectionMode}_$isSelected'),
          pkg: pkg,
          fallbackAppName: resolvedAppName,
          alertsList: alertsList,
          leadingWidget: _buildAppIconWidget(pkg, resolvedAppName, size: 24),
          isSelectionMode: _isAppCategorySelectionMode,
          isSelected: isSelected,
          onTapHeader: () => _toggleAppPackageSelection(pkg),
          onLongPressHeader: () => _enterAppCategorySelectionMode(pkg),
          onFeedback: _handleFeedback,
          onMute: _muteAppForLog,
          onMuteEntireApp: _muteEntireApp,
        );
      },
    );
  }

  // --- CARD WIDGET BUILDER ---

}

class PendingTransactionCard extends StatefulWidget {
  final TransactionModel tx;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final Function(TransactionModel, String) onConfirm;
  final Function(int) onDiscard;
  final Function(int, String) onOnlineLookup;
  final bool isLookupLoading;
  final List<String> suggestions;

  const PendingTransactionCard({
    super.key,
    required this.tx,
    required this.accounts,
    required this.categories,
    required this.onConfirm,
    required this.onDiscard,
    required this.onOnlineLookup,
    required this.isLookupLoading,
    required this.suggestions,
  });

  @override
  State<PendingTransactionCard> createState() => _PendingTransactionCardState();
}

class _PendingTransactionCardState extends State<PendingTransactionCard> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late String _type;
  late int _accountId;
  int? _toAccountId;
  late int _categoryId;
  late DateTime _selectedDate;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.tx.amount.toString());
    _descController = TextEditingController(text: widget.tx.description);
    _type = widget.tx.type;
    _accountId = widget.tx.accountId;
    _toAccountId = widget.tx.toAccountId;
    _categoryId = widget.tx.categoryId;
    _selectedDate = widget.tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAccountPicker(String pickerTitle, int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.accounts.length <= 3 ? 0.55 : 0.75;
    final double minFraction = 0.40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    pickerTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.accounts.length,
                      itemBuilder: (context, index) {
                        final acc = widget.accounts[index];
                        final isSelected = acc.id == currentSelected;
                        IconData getIcon(String t) {
                          switch (t) {
                            case 'bank': return Icons.account_balance;
                            case 'credit_card': return Icons.credit_card;
                            case 'wallet': return Icons.account_balance_wallet;
                            default: return Icons.money;
                          }
                        }
                        return InkWell(
                          onTap: () {
                            onSelected(acc.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    getIcon(acc.type),
                                    color: const Color(0xFF6366F1),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Balance: ${AppSettings.currencySymbol}${acc.balance.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              ],
                            ),
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

  void _showCategoryPicker(int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.categories.length <= 4 ? 0.55 : 0.75;
    final double minFraction = 0.40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final cat = widget.categories[index];
                        final isSelected = cat.id == currentSelected;
                        return InkWell(
                          onTap: () {
                            onSelected(cat.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(cat.color).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconHelper.getIcon(cat.icon),
                                    color: Color(cat.color),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              ],
                            ),
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

  Widget _buildMiniTypePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere((c) => c.id == _categoryId, orElse: () => widget.categories.last);
    final selectedAcc = widget.accounts.firstWhere((a) => a.id == _accountId, orElse: () => widget.accounts.first);
    final selectedToAcc = _type == 'transfer' && _toAccountId != null
        ? widget.accounts.firstWhere((a) => a.id == _toAccountId, orElse: () => widget.accounts.first)
        : null;

    IconData getAccountIcon(String t) {
      switch (t) {
        case 'bank': return Icons.account_balance;
        case 'credit_card': return Icons.credit_card;
        case 'wallet': return Icons.account_balance_wallet;
        default: return Icons.money;
      }
    }

    if (!_isExpanded) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.tx.appName ?? 'INTERCEPTED',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.tx.title.isNotEmpty ? widget.tx.title : 'SMS notification',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.expand_more, color: Colors.white70),
                          onPressed: () => setState(() => _isExpanded = true),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                          onPressed: () => widget.onDiscard(widget.tx.id!),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tx.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${AppSettings.currencySymbol}${_amountController.text}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _type == 'debit' ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9, 
                          color: _type == 'debit' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${widget.accounts.firstWhere((a) => a.id == _accountId, orElse: () => widget.accounts.first).name}',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${selectedCategory.name}',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(widget.tx.date),
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = false),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.tx.appName ?? 'INTERCEPTED',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.tx.title.isNotEmpty ? widget.tx.title : 'SMS notification',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.expand_less, color: Colors.white70),
                          onPressed: () => setState(() => _isExpanded = false),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                          onPressed: () => widget.onDiscard(widget.tx.id!),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.tx.body,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Amount (${AppSettings.currencySymbol})',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      prefixText: '${AppSettings.currencySymbol} ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF0F172A),
                    ),
                    child: Row(
                      children: [
                        _buildMiniTypePill(
                          label: 'Dr',
                          isActive: _type == 'debit',
                          onTap: () => setState(() {
                            _type = 'debit';
                            _toAccountId = null;
                          }),
                        ),
                        _buildMiniTypePill(
                          label: 'Cr',
                          isActive: _type == 'credit',
                          onTap: () => setState(() {
                            _type = 'credit';
                            _toAccountId = null;
                          }),
                        ),
                        _buildMiniTypePill(
                          label: 'Tr',
                          isActive: _type == 'transfer',
                          onTap: () => setState(() {
                            _type = 'transfer';
                            if (_toAccountId == null && widget.accounts.length > 1) {
                              _toAccountId = widget.accounts.firstWhere((a) => a.id != _accountId).id;
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomSelectField(
              label: _type == 'transfer' ? 'From Account' : 'Account',
              value: selectedAcc.name,
              icon: getAccountIcon(selectedAcc.type),
              onTap: () {
                _showAccountPicker(
                  _type == 'transfer' ? 'Select Source Account' : 'Select Account',
                  _accountId,
                  (selectedId) => setState(() {
                    _accountId = selectedId;
                    if (_type == 'transfer' && _toAccountId == _accountId) {
                      _toAccountId = widget.accounts.firstWhere((a) => a.id != _accountId).id;
                    }
                  }),
                );
              },
            ),
            if (_type == 'transfer' && selectedToAcc != null) ...[
              CustomSelectField(
                label: 'To Account',
                value: selectedToAcc.name,
                icon: getAccountIcon(selectedToAcc.type),
                onTap: () {
                  _showAccountPicker(
                    'Select Destination Account',
                    _toAccountId ?? _accountId,
                    (selectedId) => setState(() => _toAccountId = selectedId),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            CustomSelectField(
              label: 'Category',
              value: selectedCategory.name,
              icon: IconHelper.getIcon(selectedCategory.icon),
              iconColor: Color(selectedCategory.color),
              onTap: () {
                _showCategoryPicker(
                  _categoryId,
                  (selectedId) => setState(() => _categoryId = selectedId),
                );
              },
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.suggestions.map((suggestName) {
                  final isNew = !widget.categories.any((c) => c.name.toLowerCase() == suggestName.toLowerCase());
                  final label = isNew ? '✨ Suggest New Category: $suggestName' : '✨ $suggestName';

                  return InkWell(
                    onTap: () async {
                      if (isNew) {
                        final dbService = DatabaseService.instance;
                        final colorList = [0xFFFF8A80, 0xFFFFD180, 0xFF80D8FF, 0xFFEA80FC, 0xFFB9F6CA, 0xFFCFD8DC];
                        final randCol = colorList[widget.tx.id! % colorList.length];
                        final newCatId = await dbService.insertCategory(
                          CategoryModel(name: suggestName, color: randCol, icon: 'more_horiz'),
                        );
                        
                        if (mounted) {
                          AppSnackBar.show(context, 'Created & assigned category "$suggestName"!', type: SnackBarType.success);
                        }
                        setState(() {
                          _categoryId = newCatId;
                        });
                      } else {
                        final match = widget.categories.firstWhere((c) => c.name.toLowerCase() == suggestName.toLowerCase());
                        setState(() {
                          _categoryId = match.id!;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNew 
                            ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                            : const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNew 
                              ? const Color(0xFF34D399).withValues(alpha: 0.4) 
                              : const Color(0xFF818CF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNew ? Icons.add_circle_outline_rounded : Icons.auto_awesome_rounded,
                            size: 13,
                            color: isNew ? const Color(0xFF34D399) : const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isNew ? const Color(0xFF34D399) : const Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: InkWell(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDate),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF0F172A),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF6366F1), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM, hh:mm').format(_selectedDate),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final amt = double.tryParse(_amountController.text) ?? 0.0;
                if (amt <= 0) {
                  AppSnackBar.show(context, 'Please enter a valid amount', type: SnackBarType.warning);
                  return;
                }

                final desc = _descController.text.trim();
                final finalDesc = desc.isEmpty ? widget.tx.description : desc;

                final updatedTx = widget.tx.copyWith(
                  amount: amt,
                  type: _type,
                  accountId: _accountId,
                  toAccountId: _toAccountId,
                  categoryId: _categoryId,
                  description: finalDesc,
                  date: _selectedDate,
                );

                widget.onConfirm(updatedTx, selectedCategory.name);
              },
              child: const Text('Verify & Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom selection field widget to replace native dropdowns and prevent keyboard/viewport conflicts
class CustomSelectField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const CustomSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF0F172A), // Dark contrast background
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapturedAppGroupTile extends StatefulWidget {
  final String pkg;
  final String fallbackAppName;
  final List<Map<String, dynamic>> alertsList;
  final Widget leadingWidget;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapHeader;
  final VoidCallback? onLongPressHeader;
  final Function(int, String, String, String, bool, bool) onFeedback;
  final Function(String, int, String) onMute;
  final Function(String, String, List<Map<String, dynamic>>) onMuteEntireApp;

  const _CapturedAppGroupTile({
    super.key,
    required this.pkg,
    required this.fallbackAppName,
    required this.alertsList,
    required this.leadingWidget,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTapHeader,
    this.onLongPressHeader,
    required this.onFeedback,
    required this.onMute,
    required this.onMuteEntireApp,
  });

  @override
  State<_CapturedAppGroupTile> createState() => _CapturedAppGroupTileState();
}

class _CapturedAppGroupTileState extends State<_CapturedAppGroupTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: widget.onLongPressHeader,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: false,
          onExpansionChanged: (expanded) {
            if (widget.isSelectionMode) {
              if (widget.onTapHeader != null) widget.onTapHeader!();
            } else {
              setState(() {
                _isExpanded = expanded;
              });
            }
          },
          leading: widget.isSelectionMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected ? const Color(0xFF6366F1) : Colors.white30,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: widget.isSelected ? Colors.white : Colors.transparent,
                  ),
                )
              : widget.leadingWidget,
          title: Text(
            widget.fallbackAppName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.alertsList.length} ${widget.alertsList.length == 1 ? "Alert" : "Alerts"}',
                  style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (!widget.isSelectionMode) ...[
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.volume_off_rounded, color: Colors.white38, size: 18),
                  tooltip: 'Mute ${widget.fallbackAppName}',
                  onPressed: () => widget.onMuteEntireApp(widget.pkg, widget.fallbackAppName, widget.alertsList),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.white30),
                ),
              ],
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: widget.alertsList.map((alert) {
            return CapturedAlertCard(
              key: ValueKey(alert['id']),
              alert: alert,
              onFeedback: widget.onFeedback,
              onMute: widget.onMute,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CapturedAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Function(int, String, String, String, bool, bool) onFeedback;
  final Function(String, int, String) onMute;

  const CapturedAlertCard({
    super.key,
    required this.alert,
    required this.onFeedback,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final logId = alert['id'] as int;
    final appName = alert['app_name'] as String? ?? 'Unknown';
    final title = alert['title'] as String? ?? '';
    final body = alert['body'] as String? ?? '';
    final dateStr = alert['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final formattedDate = date != null ? DateFormat('dd MMM, hh:mm a').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp & Badge Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Body
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            body,
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),

          // 1-Tap Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_chart_rounded, size: 15),
                  label: const Text('Track Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () {
                    onFeedback(logId, appName, title, body, true, true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.block_rounded, size: 15),
                  label: const Text('Ignore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    onFeedback(logId, appName, title, body, false, false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
