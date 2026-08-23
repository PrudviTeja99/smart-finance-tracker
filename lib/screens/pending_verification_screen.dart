import 'package:finance_tracker/features/inbox/widgets/audit_log_bottom_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/batch_progress_banner.dart';
import 'package:finance_tracker/features/inbox/widgets/captured_app_group_tile.dart';
import 'package:finance_tracker/shared/sheets/transaction_form_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/model_activity_banner.dart';
import 'package:finance_tracker/features/inbox/widgets/pending_transaction_card.dart';
import 'package:finance_tracker/features/inbox/widgets/app_selection_bottom_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/inbox_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/app_icon_cache_service.dart';
import '../services/merchant_search_service.dart';
import '../services/notification_handler.dart';
import '../services/perceptron_storage_service.dart';
import '../utils/transaction_parser.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_formatters.dart';
import '../l10n/app_localizations.dart';

class PendingVerificationScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback onConfirmedOrDiscarded;
  final ValueNotifier<int>? refreshSignal;

  const PendingVerificationScreen({
    super.key,
    required this.isActive,
    required this.onConfirmedOrDiscarded,
    this.refreshSignal,
  });

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<TransactionModel> _pendingTransactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  final TransactionParser _parser = TransactionParser();
  bool _isServiceEnabled = false;
  bool _hasModelActivity = false;
  bool _hasLoadedPrimaryData = false;
  bool _hasLoadedSecondaryData = false;
  Future<void>? _primaryLoad;
  Future<void>? _secondaryLoad;
  int _supportingDataVersion = -1;

  // Pagination state
  final ScrollController _draftsScrollController = ScrollController();
  static const int _batchSize = 30;
  int _draftsMaxDisplay = 30;

  // Dual-tab controller
  late TabController _tabController;

  // Captured Alerts state
  List<Map<String, dynamic>> _capturedAlerts = [];
  bool _isAppCategorySelectionMode = false;
  final Set<String> _selectedAppPackages = {};

  // Drafts Multi-Selection state
  bool _isDraftSelectionMode = false;
  final Set<int> _selectedDraftIds = {};

  Widget _buildAppIconWidget(String packageName, String fallbackName,
      {double size = 24}) {
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
    _tabController.addListener(_onTabChanged);
    _draftsScrollController.addListener(_onDraftsScroll);

    PerceptronStorageService.instance.loadWeights();
    _scheduleInitialLoad();

    // Listen for foreground refresh signals (new notifications while app is open)
    widget.refreshSignal?.addListener(_onForegroundRefresh);
  }

  @override
  void didUpdateWidget(PendingVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (_hasLoadedPrimaryData) {
        _refreshAll();
      } else {
        _scheduleInitialLoad();
      }
    }

    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onForegroundRefresh);
      widget.refreshSignal?.addListener(_onForegroundRefresh);
    }
  }

  void _onDraftsScroll() {
    if (_draftsScrollController.position.pixels >=
        _draftsScrollController.position.maxScrollExtent - 300) {
      if (_draftsMaxDisplay < _pendingTransactions.length) {
        setState(() {
          _draftsMaxDisplay += _batchSize;
        });
      }
    }
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _isDraftSelectionMode = false;
        _selectedDraftIds.clear();
        _isAppCategorySelectionMode = false;
        _selectedAppPackages.clear();
      });
    }
  }

  void _onForegroundRefresh() {
    if (mounted && widget.isActive) {
      _refreshAll();
    }
  }

  void _scheduleInitialLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let the navigation transition complete before database and platform
      // work competes with the first Inbox frame.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted && widget.isActive && !_hasLoadedPrimaryData) {
        await _refreshAll();
      }
    });
  }

  @override
  void dispose() {
    _draftsScrollController.removeListener(_onDraftsScroll);
    _draftsScrollController.dispose();
    widget.refreshSignal?.removeListener(_onForegroundRefresh);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCapturedAlerts() async {
    final logs =
        await DatabaseService.instance.getNotificationLogs('unclassified');
    if (mounted) {
      setState(() {
        _capturedAlerts = logs;
      });
    }
  }

  Future<void> _loadPrimaryInboxData() async {
    final dbService = DatabaseService.instance;
    final pending = await dbService.getPendingTransactions();
    final running = await NotificationHandler.isServiceRunning();
    final permission = await NotificationHandler.hasPermission();
    final serviceEnabled = running && permission;

    final currentVersion = dbService.dashboardDataVersion.value;
    final shouldReloadSupportingData =
        _supportingDataVersion != currentVersion ||
            _accounts.isEmpty ||
            _categories.isEmpty;
    final accountsList = shouldReloadSupportingData
        ? await dbService.getAllAccounts()
        : _accounts;
    final categoriesList = shouldReloadSupportingData
        ? await dbService.getAllCategories()
        : _categories;

    if (!mounted) return;

    final pendingIds = pending.map((t) => t.id).toSet();
    final currentIds = _pendingTransactions.map((t) => t.id).toSet();

    final hasAccountsChanged = _accounts.length != accountsList.length;
    final hasCategoriesChanged = _categories.length != categoriesList.length;
    final hasServiceChanged = _isServiceEnabled != serviceEnabled;

    if (pendingIds.difference(currentIds).isNotEmpty ||
        currentIds.difference(pendingIds).isNotEmpty ||
        hasAccountsChanged ||
        hasCategoriesChanged ||
        hasServiceChanged ||
        shouldReloadSupportingData ||
        !_hasLoadedPrimaryData) {
      setState(() {
        _pendingTransactions = pending;
        _accounts = accountsList;
        _categories = categoriesList;
        _isServiceEnabled = serviceEnabled;
        _hasLoadedPrimaryData = true;
        if (shouldReloadSupportingData) {
          _supportingDataVersion = currentVersion;
        }
      });
    }
  }

  Future<void> _enableService() async {
    final hasPerm = await NotificationHandler.hasPermission();
    if (!hasPerm) {
      await NotificationHandler.openPermissionSettings();
    } else {
      await NotificationHandler.startService();
    }
    await _refreshAll();
  }

  // Confirm and train Naive Bayes models with user verified data
  Future<void> _confirmTransaction(
      TransactionModel tx, String categoryName) async {
    final dbService = DatabaseService.instance;

    // Update status to confirmed and save edits
    final confirmedTx = tx.copyWith(status: 'confirmed');
    final rowsUpdated = await dbService.updateTransaction(confirmedTx);

    // Requirement 3: Permanently delete the corresponding notification log after confirmation
    if (rowsUpdated > 0) {
      if (confirmedTx.notificationLogId != null) {
        await dbService.deleteNotificationLog(confirmedTx.notificationLogId!);
      }
      if (confirmedTx.body.isNotEmpty &&
          confirmedTx.body != 'Manual transaction entry') {
        await dbService.deleteNotificationLogByBody(confirmedTx.body);
      }
    }

    // Look up the name of the selected account
    final account = _accounts.firstWhere((a) => a.id == tx.accountId,
        orElse: () => _accounts.first);

    // Self-Learning: Train type, category, account, and description classifiers on-device
    await _parser.trainConfirm(
      body: tx.body,
      categoryName: categoryName,
      accountName: account.name,
      accountKeywords: account.keywords,
      description: tx.description,
      amount: tx.amount,
      type: tx.type,
    );

    widget.onConfirmedOrDiscarded();
  }

  // Delete pending transaction and train model to ignore similar patterns
  Future<void> _discardTransaction(int id, [String? bodyText]) async {
    final dbService = DatabaseService.instance;
    final body = bodyText ??
        (_pendingTransactions.any((t) => t.id == id)
            ? _pendingTransactions.firstWhere((t) => t.id == id).body
            : '');

    if (body.isNotEmpty) {
      // Active Learning: Train model that this pattern should be ignored
      await _parser.trainType(body, 'ignore');
      await PerceptronStorageService.instance.saveWeights();
    }

    await dbService.deleteTransaction(id);
    widget.onConfirmedOrDiscarded();
    _refreshAll();

    if (mounted) {
      AppSnackBar.show(context,
          'Discarded notification. AI learned to ignore similar alerts.',
          type: SnackBarType.neutral);
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;

    if (_primaryLoad != null) return _primaryLoad!;

    final load = _loadPrimaryInboxData();
    _primaryLoad = load;

    try {
      await load;
      _loadSecondaryInboxData();
    } catch (e) {
      debugPrint('Refresh failed: $e');
    } finally {
      _primaryLoad = null;
    }
  }

  Future<void> _loadSecondaryInboxData() async {
    if (_secondaryLoad != null) return _secondaryLoad!;

    final load = () async {
      try {
        final activity = await DatabaseService.instance.hasTodayModelActivity();
        await _loadCapturedAlerts();
        if (mounted) {
          setState(() {
            _hasModelActivity = activity;
            _hasLoadedSecondaryData = true;
          });
        }
      } catch (e) {
        debugPrint('Secondary Inbox refresh failed: $e');
      }
    }();
    _secondaryLoad = load;
    try {
      await load;
    } finally {
      _secondaryLoad = null;
    }
  }

  // --- BATCH CLEARING & SELECTIVE APP CATEGORY MANAGEMENT ---

  void _toggleDraftSelection(int id) {
    setState(() {
      if (_selectedDraftIds.contains(id)) {
        _selectedDraftIds.remove(id);
        if (_selectedDraftIds.isEmpty) {
          _isDraftSelectionMode = false;
        }
      } else {
        _selectedDraftIds.add(id);
      }
    });
  }

  void _enterDraftSelectionMode(int initialId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDraftSelectionMode = true;
      _selectedDraftIds.clear();
      _selectedDraftIds.add(initialId);
    });
  }

  Future<void> _confirmSelectedDrafts(int? bulkCategoryId) async {
    if (_selectedDraftIds.isEmpty) return;

    final selectedTxs = _pendingTransactions
        .where((t) => t.id != null && _selectedDraftIds.contains(t.id))
        .toList();
    if (selectedTxs.isEmpty) return;

    final dbService = DatabaseService.instance;
    final db = await dbService.database;

    final accountMap = {for (var a in _accounts) a.id: a};
    final categoryMap = {for (var c in _categories) c.id: c.name};

    // 1. Perform database updates inside transaction block
    await db.transaction((txn) async {
      for (var tx in selectedTxs) {
        final targetCatId = bulkCategoryId ?? tx.categoryId;

        final confirmedTx = tx.copyWith(
          status: 'confirmed',
          categoryId: targetCatId,
        );

        // Update in DB
        await txn.update(
          'transactions',
          confirmedTx.toMap(),
          where: 'id = ?',
          whereArgs: [confirmedTx.id],
        );

        // Clean corresponding notification log
        if (confirmedTx.notificationLogId != null) {
          await txn.delete('notification_logs',
              where: 'id = ?', whereArgs: [confirmedTx.notificationLogId]);
        }
        if (confirmedTx.body.isNotEmpty &&
            confirmedTx.body != 'Manual transaction entry') {
          await txn.delete('notification_logs',
              where: 'body = ?', whereArgs: [confirmedTx.body]);
        }
      }
    });

    // 2. Train AI Classifier on-device AFTER the database transaction finishes
    for (var tx in selectedTxs) {
      final targetCatId = bulkCategoryId ?? tx.categoryId;
      final categoryName = categoryMap[targetCatId] ?? 'Others';
      final account = accountMap[tx.accountId] ??
          (_accounts.isNotEmpty
              ? _accounts.first
              : AccountModel(
                  id: 1,
                  name: 'Bank Account',
                  type: 'bank',
                  keywords: '',
                  balance: 0.0));

      await _parser.trainConfirm(
        body: tx.body,
        categoryName: categoryName,
        accountName: account.name,
        accountKeywords: account.keywords,
        description: tx.description,
        amount: tx.amount,
        type: tx.type,
      );
    }

    final count = selectedTxs.length;
    if (mounted) {
      AppSnackBar.show(
        context,
        'Confirmed $count draft ${count == 1 ? "transaction" : "transactions"}!',
        type: SnackBarType.success,
      );
      setState(() {
        _isDraftSelectionMode = false;
        _selectedDraftIds.clear();
      });
    }

    widget.onConfirmedOrDiscarded();
    await _refreshAll();
  }

  void _showBatchDraftConfirmSheet() {
    if (_selectedDraftIds.isEmpty) return;

    final selectedTxs = _pendingTransactions
        .where((t) => t.id != null && _selectedDraftIds.contains(t.id))
        .toList();
    if (selectedTxs.isEmpty) return;

    final totalSum = selectedTxs.fold(0.0, (sum, t) => sum + t.amount);
    int? selectedBulkCatId;

    final categoryMap = {for (var c in _categories) c.id: c.name};
    final accountMap = {for (var a in _accounts) a.id: a.name};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final strings = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.inboxConfirmDrafts,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedTxs.length} ${selectedTxs.length == 1 ? strings.inboxTransactionSingle : strings.inboxTransactionPlural} • Total ${AppFormatters.formatAmount(totalSum)}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.inboxBulkCategoryAssignment,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(strings.inboxKeepAiIndividual),
                          selected: selectedBulkCatId == null,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: selectedBulkCatId == null
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedBulkCatId = null);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map((cat) {
                          final isSelected = selectedBulkCatId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: Color(cat.color),
                              backgroundColor: const Color(0xFF1E293B),
                              labelStyle: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                setSheetState(() {
                                  selectedBulkCatId = selected ? cat.id : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedTxs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tx = selectedTxs[i];
                        final catName = selectedBulkCatId != null
                            ? (categoryMap[selectedBulkCatId] ?? 'Others')
                            : (categoryMap[tx.categoryId] ?? 'Others');
                        final accName =
                            accountMap[tx.accountId] ?? 'Bank Account';

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description.isNotEmpty
                                          ? tx.description
                                          : tx.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$accName • $catName',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppFormatters.formatAmount(tx.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        '${strings.inboxConfirm} ${selectedTxs.length} ${selectedTxs.length == 1 ? strings.inboxDraftSingle : strings.inboxDraftPlural}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmSelectedDrafts(selectedBulkCatId);
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

  Future<void> _discardSelectedDrafts() async {
    if (_selectedDraftIds.isEmpty) return;

    final count = _selectedDraftIds.length;
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.inboxDiscardSelectedDraftsTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          strings.inboxDiscardSelectedDraftsConfirm(count),
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(strings.inboxCancel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.inboxDiscard,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var id in _selectedDraftIds) {
        final matching = _pendingTransactions.where((t) => t.id == id).toList();
        if (matching.isNotEmpty && matching.first.body.isNotEmpty) {
          await _parser.trainType(matching.first.body, 'ignore');
        }
        await DatabaseService.instance.deleteTransaction(id);
      }
      await PerceptronStorageService.instance.saveWeights();

      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.inboxDiscardedBatchSuccess(count),
            type: SnackBarType.neutral);
        setState(() {
          _isDraftSelectionMode = false;
          _selectedDraftIds.clear();
        });
      }
      widget.onConfirmedOrDiscarded();
      _refreshAll();
    }
  }

  Future<void> _discardAllDrafts() async {
    if (_pendingTransactions.isEmpty) return;

    final count = _pendingTransactions.length;
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.inboxDiscardAllDraftsTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          strings.inboxDiscardAllDraftsConfirm(count),
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(strings.inboxCancel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.inboxDiscardAll,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
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
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.inboxDiscardedBatchSuccess(count),
            type: SnackBarType.neutral);
      }
      widget.onConfirmedOrDiscarded();
      _refreshAll();
    }
  }

  Future<void> _archiveAllCapturedAlerts() async {
    if (_capturedAlerts.isEmpty) return;

    final count = _capturedAlerts.length;
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.inboxClearAllAlertsTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          strings.inboxClearAllAlertsConfirm(count),
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(strings.inboxCancel, style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.inboxClearAll,
                style: const TextStyle(
                    color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var alert in _capturedAlerts) {
        final logId = alert['id'] as int;
        final body = alert['body'] as String? ?? '';
        await DatabaseService.instance
            .updateNotificationLogStatus(logId, 'archived');
        await _parser.trainType(body, 'ignore');
      }
      if (mounted) {
        final strings = AppLocalizations.of(context)!;
        AppSnackBar.show(context, strings.inboxClearedAlertsSuccess(count),
            type: SnackBarType.neutral);
      }
      _refreshAll();
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
      final alertsForPkg =
          _capturedAlerts.where((a) => a['package_name'] == pkg).toList();
      totalAlertsCount += alertsForPkg.length;
      for (var alert in alertsForPkg) {
        final logId = alert['id'] as int;
        final body = alert['body'] as String? ?? '';
        await DatabaseService.instance
            .updateNotificationLogStatus(logId, 'archived');
        await _parser.trainType(body, 'ignore');
      }
    }

    if (mounted) {
      AppSnackBar.show(context,
          'Archived $totalAlertsCount alerts from ${selectedPkgs.length} app categories.',
          type: SnackBarType.neutral);
      setState(() {
        _isAppCategorySelectionMode = false;
        _selectedAppPackages.clear();
      });
    }

    _refreshAll();
  }

  Future<void> _handleFeedback(int logId, String appName, String title,
      String body, bool isFinancial, bool isRelevant) async {
    final dbService = DatabaseService.instance;

    if (!isFinancial || !isRelevant) {
      // 1. Train model to ignore this pattern
      await _parser.trainType(body, 'ignore');

      // 2. Archive the log
      await dbService.updateNotificationLogStatus(logId, 'archived');

      if (mounted) {
        AppSnackBar.show(
            context, 'Captured alert archived. Model trained to ignore.',
            type: SnackBarType.neutral);
      }
    } else {
      // Find original notification log date from _capturedAlerts
      final alertLog = _capturedAlerts.firstWhere(
        (a) => a['id'] == logId,
        orElse: () => <String, dynamic>{},
      );
      final notificationDate = alertLog['date'] != null
          ? (DateTime.tryParse(alertLog['date'] as String) ?? DateTime.now())
          : DateTime.now();

      // 1. Parse details with original notification date & notificationLogId
      final tx = await _parser.parseNotification(
        appName: appName,
        title: title,
        body: body,
        date: notificationDate,
        notificationLogId: logId,
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
            AppSnackBar.show(context, 'Promoted alert to Transaction Drafts!',
                type: SnackBarType.success);
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
          date: notificationDate,
          status: 'pending',
          notificationLogId: logId,
        );
        await dbService.insertTransaction(manualTx);
        await dbService.updateNotificationLogStatus(logId, 'drafted');

        if (mounted) {
          AppSnackBar.show(context, 'Promoted alert to Transaction Drafts!',
              type: SnackBarType.success);
        }
      }
    }

    _refreshAll();
    widget.onConfirmedOrDiscarded();
  }

  // Trigger user-clicked online search category lookup
  Future<void> _triggerOnlineCategoryLookup(
      int txId, String merchantName) async {
    setState(() {
      _lookupLoading[txId] = true;
    });

    final suggestions =
        await MerchantSearchService.searchMerchantCategory(merchantName);

    setState(() {
      _lookupLoading[txId] = false;
      _categorySuggestions[txId] = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppLocalizations.of(context)!;
    final currentBottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardNowOpen = currentBottomInset > 0;
    if (_isKeyboardOpen && !isKeyboardNowOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
    _isKeyboardOpen = isKeyboardNowOpen;

    final bool isSelecting =
        _isDraftSelectionMode || _isAppCategorySelectionMode;

    return PopScope(
      canPop: !isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSelecting) {
          setState(() {
            _isDraftSelectionMode = false;
            _selectedDraftIds.clear();
            _isAppCategorySelectionMode = false;
            _selectedAppPackages.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor:
              (_isDraftSelectionMode || _isAppCategorySelectionMode)
                  ? const Color(0xFF1E293B)
                  : Colors.transparent,
          elevation: 0,
          leading: (_isDraftSelectionMode || _isAppCategorySelectionMode)
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isDraftSelectionMode = false;
                      _selectedDraftIds.clear();
                      _isAppCategorySelectionMode = false;
                      _selectedAppPackages.clear();
                    });
                  },
                )
              : null,
          title: Text(
            _isDraftSelectionMode
                ? '${_selectedDraftIds.length} ${_selectedDraftIds.length == 1 ? "Draft Selected" : "Drafts Selected"}'
                : (_isAppCategorySelectionMode
                    ? '${_selectedAppPackages.length} ${_selectedAppPackages.length == 1 ? "App Selected" : "Apps Selected"}'
                    : strings.inboxTitle),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: _isDraftSelectionMode
              ? [
                  IconButton(
                    icon: Icon(
                      _selectedDraftIds.length == _pendingTransactions.length
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: Colors.white70,
                    ),
                    tooltip:
                        _selectedDraftIds.length == _pendingTransactions.length
                            ? 'Deselect All'
                            : 'Select All',
                    onPressed: () {
                      setState(() {
                        if (_selectedDraftIds.length ==
                            _pendingTransactions.length) {
                          _selectedDraftIds.clear();
                          _isDraftSelectionMode = false;
                        } else {
                          _selectedDraftIds.clear();
                          _selectedDraftIds.addAll(_pendingTransactions
                              .where((t) => t.id != null)
                              .map((t) => t.id!));
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981)),
                    tooltip: 'Confirm Selected Drafts',
                    onPressed: _showBatchDraftConfirmSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Color(0xFFEF4444)),
                    tooltip: 'Discard Selected Drafts',
                    onPressed: _discardSelectedDrafts,
                  ),
                ]
              : (_isAppCategorySelectionMode
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined,
                            color: Color(0xFFEF4444)),
                        tooltip: 'Clear Selected Apps',
                        onPressed: _archiveSelectedAppCategories,
                      ),
                    ]
                  : [
                      if (_tabController.index == 0 &&
                          _pendingTransactions.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.checklist_rounded,
                              color: Colors.white70),
                          tooltip: 'Select Drafts',
                          onPressed: () {
                            setState(() {
                              _isDraftSelectionMode = true;
                              _selectedDraftIds.clear();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Discard All Drafts',
                          onPressed: _discardAllDrafts,
                        ),
                      ],
                      if (_tabController.index == 1) ...[
                        IconButton(
                          icon: const Icon(Icons.app_settings_alt_rounded,
                              color: Color(0xFF818CF8)),
                          tooltip: 'Track App Notifications',
                          onPressed: _showAppSelectionBottomSheet,
                        ),
                        if (_capturedAlerts.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.checklist_rounded,
                                color: Colors.white70),
                            tooltip: 'Select Apps to Clear',
                            onPressed: () {
                              setState(() {
                                _isAppCategorySelectionMode = true;
                                _selectedAppPackages.clear();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Clear All Alerts',
                            onPressed: _archiveAllCapturedAlerts,
                          ),
                        ],
                      ],
                    ]),
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
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
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
                              _buildTabItem(0, Icons.edit_note_rounded,
                                  strings.inboxDrafts, _pendingTransactions.length, value),
                              _buildTabItem(
                                  1,
                                  Icons.receipt_long_rounded,
                                  strings.inboxCapturedAlerts,
                                  _capturedAlerts.length,
                                  value),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const BatchProgressBanner(),
              if (_hasModelActivity)
                ModelActivityBanner(
                  onViewLogPressed: () async {
                    await showAuditLogBottomSheet(
                      context: context,
                      onUndo: _undoAuditAction,
                      onCleared: () {
                        if (mounted) {
                          setState(() {
                            _hasModelActivity = false;
                          });
                          _refreshAll();
                        }
                      },
                    );
                    if (mounted) _refreshAll();
                  },
                ),
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
  Widget _buildTabItem(
      int index, IconData icon, String label, int count, double animValue) {
    final double percent = index == 0
        ? (1 - animValue).clamp(0.0, 1.0)
        : animValue.clamp(0.0, 1.0);
    final color =
        Color.lerp(Colors.white.withOpacity(0.4), Colors.white, percent)!;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tabController.animateTo(index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5, // Slightly smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.25), percent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color.lerp(
                          Colors.white.withOpacity(0.7), Colors.white, percent),
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

  Future<void> _undoAuditAction(Map<String, dynamic> auditLog) async {
    final auditId = auditLog['id'] as int;
    final logId = auditLog['log_id'] as int?;
    final actionType = auditLog['action_type'] as String;
    final body = auditLog['body'] as String? ?? '';
    final dbService = DatabaseService.instance;

    if (actionType == 'auto_archived' || actionType == 'auto_dismissed') {
      if (logId != null) {
        await dbService.updateNotificationLogStatus(logId, 'unclassified');
      }
      if (mounted) {
        AppSnackBar.show(context, 'Restored to Captured Alerts!',
            type: SnackBarType.success);
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
        AppSnackBar.show(context,
            'Moved back to Captured Alerts. AI learned to ignore similar alerts.',
            type: SnackBarType.neutral);
      }
    }

    final db = await dbService.database;
    await db.delete('model_audit_log', where: 'id = ?', whereArgs: [auditId]);

    if (mounted) {
      _refreshAll();
    }
  }

  // --- DRAFTS TAB ---
  Widget _buildDraftsTab() {
    final strings = AppLocalizations.of(context)!;
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
        !_hasLoadedPrimaryData
            ? const InboxSkeleton()
            : _pendingTransactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isServiceEnabled) ...[
                            const Icon(Icons.mark_email_read_outlined,
                                size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                        Text(
                          strings.inboxAllCaughtUp,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                        Text(
                          strings.inboxEmpty,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF6366F1).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 56,
                                color: Color(0xFFEA80FC),
                              ),
                            ),
                            const SizedBox(height: 24),
                        Text(
                          strings.inboxTrackingDisabled,
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                        Text(
                          strings.inboxTrackingDisabledDescription,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _enableService,
                              icon: const Icon(Icons.bolt_rounded, size: 20),
                          label: Text(
                            strings.inboxEnableTracking,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _draftsScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: (_pendingTransactions.length < _draftsMaxDisplay
                            ? _pendingTransactions.length
                            : _draftsMaxDisplay) +
                        (_pendingTransactions.length > _draftsMaxDisplay
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      final visibleCount =
                          _pendingTransactions.length < _draftsMaxDisplay
                              ? _pendingTransactions.length
                              : _draftsMaxDisplay;

                      if (index == visibleCount) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        );
                      }

                      final tx = _pendingTransactions[index];
                      return PendingTransactionCard(
                        key: ValueKey(tx.id),
                        tx: tx,
                        accounts: _accounts,
                        categories: _categories,
                        onConfirm: _confirmTransaction,
                        onDiscard: _discardTransaction,
                        onOnlineLookup: _triggerOnlineCategoryLookup,
                        isLookupLoading: _lookupLoading[tx.id] ?? false,
                        suggestions: _categorySuggestions[tx.id] ?? [],
                        isSelectionMode: _isDraftSelectionMode,
                        isSelected: _selectedDraftIds.contains(tx.id),
                        onTap: () {
                          if (_isDraftSelectionMode && tx.id != null) {
                            _toggleDraftSelection(tx.id!);
                            return;
                          }
                          _showDraftEditor(tx);
                        },
                        onLongPress: () {
                          if (tx.id != null) {
                            if (!_isDraftSelectionMode) {
                              _enterDraftSelectionMode(tx.id!);
                            } else {
                              _toggleDraftSelection(tx.id!);
                            }
                          }
                        },
                      );
                    },
                  ),
      ],
    );
  }

  // --- CAPTURED ALERTS TAB ---
  Widget _buildCapturedAlertsTab() {
    final strings = AppLocalizations.of(context)!;
    if (!_hasLoadedSecondaryData) {
      return const InboxSkeleton(cardCount: 3);
    }

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
              Text(
                strings.inboxNoCapturedAlerts,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _isServiceEnabled
                    ? strings.inboxCapturedAlertsEnabledDescription
                    : strings.inboxCapturedAlertsDisabledDescription,
                style: const TextStyle(
                    fontSize: 13, color: Colors.white54, height: 1.5),
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
        final fallbackAppName =
            alertsList.first['app_name'] as String? ?? 'Unknown';
        final resolvedAppName = AppIconCacheService.instance
            .getCachedAppName(pkg, defaultFallback: fallbackAppName);
        final isSelected = _selectedAppPackages.contains(pkg);

        return CapturedAppGroupTile(
          key: ValueKey(
              'captured_group_${pkg}_${_isAppCategorySelectionMode}_$isSelected'),
          pkg: pkg,
          fallbackAppName: resolvedAppName,
          alertsList: alertsList,
          leadingWidget: _buildAppIconWidget(pkg, resolvedAppName, size: 24),
          isSelectionMode: _isAppCategorySelectionMode,
          isSelected: isSelected,
          onTapHeader: () => _toggleAppPackageSelection(pkg),
          onLongPressHeader: () => _enterAppCategorySelectionMode(pkg),
          onFeedback: _handleFeedback,
        );
      },
    );
  }

  Future<void> _showDraftEditor(TransactionModel tx) async {
    await showTransactionFormSheet(
      context: context,
      editTx: tx,
      accounts: _accounts,
      categories: _categories,
      isDraft: true,
      onConfirmDraft: (updatedTx, categoryName) async {
        await _confirmTransaction(updatedTx, categoryName);
        await _refreshAll();
        widget.onConfirmedOrDiscarded();
      },
      onDeleted: () async {
        if (tx.id != null) {
          await _discardTransaction(tx.id!);
          await _refreshAll();
          widget.onConfirmedOrDiscarded();
        }
      },
      onSaved: () async {
        await _refreshAll();
        widget.onConfirmedOrDiscarded();
      },
      onOnlineLookup: _triggerOnlineCategoryLookup,
      isLookupLoading: _lookupLoading[tx.id] ?? false,
      suggestions: _categorySuggestions[tx.id] ?? [],
    );
  }

  void _showAppSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AppSelectionBottomSheet();
      },
    ).then((_) {
      _refreshAll();
    });
  }
}
