import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/transaction_model.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../services/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_data_cache.dart';
import '../logic/filter_logic.dart';
import '../logic/privacy_logic.dart';

mixin DashboardStateMixin<T extends StatefulWidget> on State<T> {
  // Filter states
  String timeframe = 'This Month';
  DateTime? startDate;
  DateTime? endDate;
  String customFilterLabel = '';
  int? selectedAccountFilterId;
  String selectedTypeFilter = 'debit'; // 'debit' (Expenses), 'credit' (Income), 'transfer' (Transfers)
  String chartView = 'donut'; // 'donut', 'bar'
  int touchedChartIndex = -1;
  bool showAllDashboardTransactions = false;

  // Data lists
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  List<AccountModel> accounts = [];
  List<CategoryModel> categories = [];

  // Computed totals
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double netBalance = 0.0;
  double savingsRate = 0.0;

  final DashboardDataCache _dataCache = DashboardDataCache();
  int _loadedDataVersion = -1;
  String? _baseFilterKey;
  List<TransactionModel> _baseFilteredTransactions = const [];
  DashboardTotals? _baseTotals;

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  bool showFab = true;
  double lastScrollOffset = 0.0;

  // Privacy controller
  late final PrivacyController privacyController;

  void initDashboardState() {
    privacyController = PrivacyController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    privacyController.loadSavedPrivacyMode();
    loadSavedTimeframe();
    scrollController.addListener(scrollListener);
  }

  void disposeDashboardState() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    privacyController.dispose();
  }

  void unfocusSearch() {
    searchFocusNode.unfocus(disposition: UnfocusDisposition.scope);
    FocusManager.instance.primaryFocus
        ?.unfocus(disposition: UnfocusDisposition.scope);
  }

  void scrollListener() {
    final currentOffset = scrollController.offset;
    if (currentOffset > lastScrollOffset && currentOffset > 50) {
      if (showFab) {
        setState(() {
          showFab = false;
        });
      }
    } else if (currentOffset < lastScrollOffset) {
      if (!showFab) {
        setState(() {
          showFab = true;
        });
      }
    }
    lastScrollOffset = currentOffset;
  }

  Future<void> loadSavedTimeframe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTf = prefs.getString('dashboard_timeframe');
    if (savedTf != null) {
      timeframe = savedTf;
    }
    applyFilters();
  }

  Future<void> saveTimeframe(String tf) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dashboard_timeframe', tf);
  }

  Future<DashboardData> fetchDashboardData() async {
    final dbService = DatabaseService.instance;
    final txs = await dbService.getConfirmedTransactions();
    final accs = await dbService.getAllAccounts();
    final cats = await dbService.getAllCategories();

    return DashboardData(
      allTransactions: txs,
      accounts: accs,
      categories: cats,
    );
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    try {
      final dbService = DatabaseService.instance;
      final version = dbService.dashboardDataVersion.value;
      final data = await _dataCache.load(
        version: version,
        loader: fetchDashboardData,
      );
      if (!mounted) return;
      setState(() {
        allTransactions = data.allTransactions;
        accounts = data.accounts;
        categories = data.categories;
        _loadedDataVersion = version;
      });
      applyFilters();
    } catch (e) {
      debugPrint('Error refreshing dashboard data: $e');
    }
  }

  void applyFilters() {
    final dateRange = FilterLogic.getDateRange(timeframe, startDate, endDate);
    customFilterLabel = dateRange.customLabel;

    final baseFilterKey = [
      _loadedDataVersion,
      dateRange.start.microsecondsSinceEpoch,
      dateRange.end.microsecondsSinceEpoch,
      selectedAccountFilterId,
    ].join('|');

    if (_baseFilterKey != baseFilterKey) {
      _baseFilteredTransactions = FilterLogic.filterByDateAndAccount(
        allTransactions: allTransactions,
        dateRange: dateRange,
        selectedAccountId: selectedAccountFilterId,
      );
      _baseTotals = FilterLogic.calculateTotals(_baseFilteredTransactions);
      _baseFilterKey = baseFilterKey;
    }

    // Only type/search changes need to filter the already-matched base set.
    final matched = FilterLogic.filterByTypeAndSearch(
      transactions: _baseFilteredTransactions,
      typeFilter: selectedTypeFilter,
      searchQuery: searchController.text,
    );
    final totals = _baseTotals!;

    setState(() {
      filteredTransactions = matched;
      totalIncome = totals.income;
      totalExpense = totals.expense;
      netBalance = totals.netBalance;
      savingsRate = totals.savingsRate;
      touchedChartIndex = -1; // Reset touched chart slice on filter change
    });
  }

  void previousMonth() {
    final dateRange = FilterLogic.getDateRange(timeframe, startDate, endDate);
    final currentStart = dateRange.start;
    final prevMonthStart = DateTime(currentStart.year, currentStart.month - 1, 1);
    final prevMonthEnd = DateTime(currentStart.year, currentStart.month, 0, 23, 59, 59);

    setState(() {
      timeframe = 'Custom';
      startDate = prevMonthStart;
      endDate = prevMonthEnd;
    });
    saveTimeframe('Custom');
    applyFilters();
  }

  void nextMonth() {
    final dateRange = FilterLogic.getDateRange(timeframe, startDate, endDate);
    final currentStart = dateRange.start;
    final nextMonthStart = DateTime(currentStart.year, currentStart.month + 1, 1);
    final nextMonthEnd = DateTime(currentStart.year, currentStart.month + 2, 0, 23, 59, 59);

    setState(() {
      timeframe = 'Custom';
      startDate = nextMonthStart;
      endDate = nextMonthEnd;
    });
    saveTimeframe('Custom');
    applyFilters();
  }

  String getTimeframeDisplay(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    if (timeframe == 'This Month') {
      return '${strings.transactionsThisMonth} (${DateFormat('MMMM yyyy', locale).format(now)})';
    } else if (timeframe == 'This Year') {
      return '${strings.transactionsThisYear} (${now.year})';
    } else if (timeframe == 'Today') {
      return '${strings.timeframeToday} (${now.day} ${DateFormat('MMM', locale).format(now)})';
    } else if (timeframe == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      return '${strings.timeframeYesterday} (${yest.day} ${DateFormat('MMM', locale).format(yest)})';
    } else if (timeframe == 'This Week') {
      final startOffset = now.weekday - 1;
      final tempStart = now.subtract(Duration(days: startOffset));
      return '${strings.transactionsThisWeek} (${tempStart.day} ${DateFormat('MMM', locale).format(tempStart)} - ${now.day} ${DateFormat('MMM', locale).format(now)})';
    } else if (timeframe == 'Custom') {
      if (startDate != null && endDate != null) {
        final df = DateFormat('dd MMM', locale);
        if (startDate!.year == endDate!.year &&
            startDate!.month == endDate!.month &&
            startDate!.day == endDate!.day) {
          return df.format(startDate!);
        } else if (startDate!.day == 1 &&
            endDate!.day == DateTime(endDate!.year, endDate!.month + 1, 0).day &&
            startDate!.month == endDate!.month &&
            startDate!.year == endDate!.year) {
          return DateFormat('MMMM yyyy', locale).format(startDate!);
        } else {
          return '${df.format(startDate!)} - ${df.format(endDate!)}';
        }
      }
      if (customFilterLabel.isNotEmpty) return customFilterLabel;
    }
    return timeframe;
  }

  String getAccountFilterDisplay(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (selectedAccountFilterId == null) return strings.transactionsAllAccounts;
    final acc = accounts.firstWhere(
      (a) => a.id == selectedAccountFilterId,
      orElse: () => AccountModel(
        name: 'Account',
        type: 'bank',
        balance: 0.0,
        keywords: '',
      ),
    );
    return acc.name;
  }
}
