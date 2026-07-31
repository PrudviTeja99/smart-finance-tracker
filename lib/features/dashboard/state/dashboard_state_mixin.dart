import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/transaction_model.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../services/database_service.dart';
import '../models/dashboard_data.dart';
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
      final data = await fetchDashboardData();
      if (!mounted) return;
      setState(() {
        allTransactions = data.allTransactions;
        accounts = data.accounts;
        categories = data.categories;
      });
      applyFilters();
    } catch (e) {
      debugPrint('Error refreshing dashboard data: $e');
    }
  }

  void applyFilters() {
    final dateRange = FilterLogic.getDateRange(timeframe, startDate, endDate);
    customFilterLabel = dateRange.customLabel;

    // 1. Calculate overall totals for Hero Card (unfiltered by type/search)
    final dateAndAccountMatched = FilterLogic.applyFilters(
      allTransactions: allTransactions,
      dateRange: dateRange,
      selectedAccountId: selectedAccountFilterId,
      typeFilter: 'all',
      searchQuery: '',
    );
    final totals = FilterLogic.calculateTotals(dateAndAccountMatched);

    // 2. Filter transactions for Analytics Chart & Ledger List
    final matched = FilterLogic.applyFilters(
      allTransactions: allTransactions,
      dateRange: dateRange,
      selectedAccountId: selectedAccountFilterId,
      typeFilter: selectedTypeFilter,
      searchQuery: searchController.text,
    );

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

  String getTimeframeDisplay() {
    if (timeframe == 'Custom' && customFilterLabel.isNotEmpty) {
      return customFilterLabel;
    }
    return timeframe;
  }

  String getAccountFilterDisplay() {
    if (selectedAccountFilterId == null) return 'All Accounts';
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
