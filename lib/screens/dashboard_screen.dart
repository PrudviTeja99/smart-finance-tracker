import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../utils/app_settings.dart';
import '../utils/icon_helper.dart';
import '../utils/app_snackbar.dart';

class _DashboardData {
  final List<TransactionModel> allTransactions;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;

  const _DashboardData({
    required this.allTransactions,
    required this.accounts,
    required this.categories,
  });
}

class DashboardScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback onRefreshPendingCount;
  final ValueNotifier<int>? refreshSignal;

  const DashboardScreen({
    super.key,
    required this.isActive,
    required this.onRefreshPendingCount,
    this.refreshSignal,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _timeframe = 'This Month'; // Default timeframe
  DateTime? _startDate;
  DateTime? _endDate;
  String _customFilterLabel = '';

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];

  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _netBalance = 0.0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int? _selectedAccountFilterId;
  int? _touchedChartIndex;
  String _analyticsTab = 'debit'; // 'debit' for Expenses, 'credit' for Income
  bool _obscureAmounts = false;
  bool _showFab = true;
  double _lastScrollOffset = 0.0;

  bool _isAutoHideTimerActive = false;
  Timer? _autoHideTimer;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _wasPaused = false;

  bool get _shouldHideAmounts => _obscureAmounts || _isAutoHideTimerActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedTimeframe();
    _loadSavedPrivacyMode();
    _startAutoHideTimerIfNeeded();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
    widget.refreshSignal?.addListener(_onRefreshSignal);
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    _countdownTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    _searchFocusNode.unfocus(disposition: UnfocusDisposition.scope);
    FocusManager.instance.primaryFocus?.unfocus(disposition: UnfocusDisposition.scope);
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      _unfocusSearch();
    }
    if (widget.isActive && !oldWidget.isActive) {
      _refreshData();
    }
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshSignal);
      widget.refreshSignal?.addListener(_onRefreshSignal);
    }
  }

  void _onRefreshSignal() {
    if (mounted) {
      _refreshData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPaused) {
        _wasPaused = false;
        _startAutoHideTimerIfNeeded();
      }
    }
  }

  String _getTimeframeDisplay() {
    final now = DateTime.now();

    switch (_timeframe) {
      case 'Today':
        return 'Today (${DateFormat('d MMM').format(now)})';

      case 'Yesterday':
        return 'Yesterday (${DateFormat('d MMM').format(
          now.subtract(const Duration(days: 1)),
        )})';

      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));

        return 'This Week (${DateFormat('d').format(start)}–${DateFormat('d MMM').format(end)})';

      case 'This Month':
        return 'This Month (${DateFormat('MMMM').format(now)})';

      case 'This Year':
        return 'This Year (${now.year})';

      case 'Custom':
        return _customFilterLabel;

      default:
        return _timeframe;
    }
  }

  void _startAutoHideTimerIfNeeded() {
    _countdownTimer?.cancel();
    if (AppSettings.autoHideEnabled) {
      setState(() {
        _isAutoHideTimerActive = true;
        _remainingSeconds = AppSettings.autoHideSeconds;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_remainingSeconds > 1) {
              _remainingSeconds--;
            } else {
              _isAutoHideTimerActive = false;
              _remainingSeconds = 0;
              _countdownTimer?.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });
    } else {
      _isAutoHideTimerActive = false;
      _remainingSeconds = 0;
    }
  }

  void _cancelAutoHideTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isAutoHideTimerActive = false;
      _remainingSeconds = 0;
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;

    // Hide FAB when scrolling down past a small threshold, show it when scrolling up
    if (currentOffset > _lastScrollOffset && currentOffset > 50) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    }
    _lastScrollOffset = currentOffset;
  }

  // Load persistent privacy setting
  Future<void> _loadSavedPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrivacy = prefs.getBool('obscure_amounts') ?? false;
    if (mounted) {
      setState(() {
        _obscureAmounts = savedPrivacy;
      });
    }
  }

  // Load persistent timeframe filter from SharedPreferences
  void _loadSavedTimeframe() {
    // Always default to 'This Month' on dashboard startup as requested
    const savedTimeframe = 'This Month';
    if (mounted) {
      setState(() {
        _timeframe = savedTimeframe;
      });
      _applyTimeframeFilter();
    }
  }

  // Save selected timeframe to SharedPreferences
  Future<void> _saveTimeframe(String timeframe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_timeframe', timeframe);
  }

  /// Performs all asynchronous database operations to fetch dashboard data.
  /// Does NOT invoke setState() or mutate UI state directly.
  Future<_DashboardData> _loadDashboardData() async {
    final dbService = DatabaseService.instance;
    final allTx = await dbService.getConfirmedTransactions();

    // Compute current balances for all accounts
    final rawAccounts = await dbService.getAllAccounts();
    final updatedAccounts = <AccountModel>[];
    for (var acc in rawAccounts) {
      final bal = await dbService.getAccountBalance(acc.id!);
      updatedAccounts.add(acc.copyWith(balance: bal));
    }

    final rawCategories = await dbService.getAllCategories();

    return _DashboardData(
      allTransactions: allTx,
      accounts: updatedAccounts,
      categories: rawCategories,
    );
  }

  /// Event-driven method to reload dashboard data and apply single-batch UI updates.
  Future<void> _refreshData() async {
    final data = await _loadDashboardData();

    if (mounted) {
      setState(() {
        _allTransactions = data.allTransactions;
        _accounts = data.accounts;
        _categories = data.categories;
      });
      _applyTimeframeFilter();
    }
  }

  // Apply chosen date parameters and filter confirmed transactions
  void _applyTimeframeFilter() {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _customFilterLabel = '';

    if (_timeframe == 'Today') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_timeframe == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      start = DateTime(yest.year, yest.month, yest.day);
      end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
    } else if (_timeframe == 'This Week') {
      final weekday = now.weekday;
      final startOffset = weekday - 1;
      final tempStart = now.subtract(Duration(days: startOffset));
      start = DateTime(tempStart.year, tempStart.month, tempStart.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_timeframe == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (_timeframe == 'This Year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
    } else if (_timeframe == 'Custom' &&
        _startDate != null &&
        _endDate != null) {
      start = _startDate!;
      end = _endDate!;
      final df = DateFormat('dd MMM');
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        _customFilterLabel = df.format(start);
      } else if (start.day == 1 &&
          end.day == DateTime(end.year, end.month + 1, 0).day &&
          start.month == end.month &&
          start.year == end.year) {
        _customFilterLabel = DateFormat('MMM yyyy').format(start);
      } else {
        _customFilterLabel = '${df.format(start)} - ${df.format(end)}';
      }
    }

    final matchedTx = _allTransactions.where((tx) {
      final isWithinDates =
          tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              tx.date.isBefore(end.add(const Duration(seconds: 1)));
      final matchesAccount = _selectedAccountFilterId == null ||
          tx.accountId == _selectedAccountFilterId ||
          tx.toAccountId == _selectedAccountFilterId;
      return isWithinDates && matchesAccount;
    }).toList();

    // Calculate totals
    double inc = 0.0;
    double exp = 0.0;
    for (var tx in matchedTx) {
      if (tx.type == 'credit') {
        inc += tx.amount;
      } else if (tx.type == 'debit') {
        exp += tx.amount;
      }
      // Note: Transfers are excluded from net income/expense because net worth stays constant
    }

    setState(() {
      _filteredTransactions = matchedTx;
      _totalIncome = inc;
      _totalExpense = exp;
      _netBalance = inc - exp;
    });

    _onSearchChanged(); // Apply search filters over date filters
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredTransactions = _allTransactions.where((tx) {
          // Re-apply date and account filters
          final now = DateTime.now();
          DateTime start = DateTime(now.year, now.month, 1);
          DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

          if (_timeframe == 'Today') {
            start = DateTime(now.year, now.month, now.day);
            end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          } else if (_timeframe == 'Yesterday') {
            final yest = now.subtract(const Duration(days: 1));
            start = DateTime(yest.year, yest.month, yest.day);
            end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
          } else if (_timeframe == 'This Week') {
            final tempStart = now.subtract(Duration(days: now.weekday - 1));
            start = DateTime(tempStart.year, tempStart.month, tempStart.day);
            end = DateTime(now.year, now.month, now.day, 23, 59, 59);
          } else if (_timeframe == 'This Month') {
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          } else if (_timeframe == 'This Year') {
            start = DateTime(now.year, 1, 1);
            end = DateTime(now.year, 12, 31, 23, 59, 59);
          } else if (_timeframe == 'Custom' &&
              _startDate != null &&
              _endDate != null) {
            start = _startDate!;
            end = _endDate!;
          }

          final isWithinDates =
              tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                  tx.date.isBefore(end.add(const Duration(seconds: 1)));
          final matchesAccount = _selectedAccountFilterId == null ||
              tx.accountId == _selectedAccountFilterId ||
              tx.toAccountId == _selectedAccountFilterId;
          return isWithinDates && matchesAccount;
        }).toList();
      });
      return;
    }

    setState(() {
      _filteredTransactions = _filteredTransactions.where((tx) {
        return tx.description.toLowerCase().contains(query) ||
            tx.body.toLowerCase().contains(query) ||
            tx.amount.toString().contains(query);
      }).toList();
    });
  }

  void _showTimeframeFilterSheet() {
    _unfocusSearch();
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
            final isCustom = _timeframe == 'Custom';
            bool isSpecificDate = false;
            bool isSpecificMonth = false;
            bool isDateRange = false;

            if (isCustom && _startDate != null && _endDate != null) {
              if (_startDate!.year == _endDate!.year &&
                  _startDate!.month == _endDate!.month &&
                  _startDate!.day == _endDate!.day) {
                isSpecificDate = true;
              } else if (_startDate!.day == 1 &&
                  _endDate!.day ==
                      DateTime(_endDate!.year, _endDate!.month + 1, 0).day &&
                  _startDate!.month == _endDate!.month &&
                  _startDate!.year == _endDate!.year) {
                isSpecificMonth = true;
              } else {
                isDateRange = true;
              }
            }

            final dateLabel = isSpecificDate
                ? DateFormat('dd MMM yyyy').format(_startDate!)
                : '';
            final monthLabel = isSpecificMonth
                ? DateFormat('MMMM yyyy').format(_startDate!)
                : '';
            final rangeLabel = isDateRange
                ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                : '';

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Select Date Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(context, setSheetState, 'Today'),
                    _buildRadioOption(context, setSheetState, 'Yesterday'),
                    _buildRadioOption(context, setSheetState, 'This Week'),
                    _buildRadioOption(context, setSheetState, 'This Month'),
                    _buildRadioOption(context, setSheetState, 'This Year'),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Divider(color: Colors.white10),
                    ),
                    _buildCustomRadioOption(
                      context,
                      setSheetState,
                      title: 'Specific Date...',
                      isSelected: isSpecificDate,
                      subLabel: dateLabel,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF6366F1),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _timeframe = 'Custom';
                            _startDate =
                                DateTime(date.year, date.month, date.day);
                            _endDate = DateTime(
                                date.year, date.month, date.day, 23, 59, 59);
                          });
                          _saveTimeframe('Custom');
                          _applyTimeframeFilter();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                    _buildCustomRadioOption(
                      context,
                      setSheetState,
                      title: 'Specific Month...',
                      isSelected: isSpecificMonth,
                      subLabel: monthLabel,
                      onTap: () async {
                        Navigator.pop(context);
                        _openMonthYearPicker();
                      },
                    ),
                    _buildCustomRadioOption(
                      context,
                      setSheetState,
                      title: 'Custom Date Range...',
                      isSelected: isDateRange,
                      subLabel: rangeLabel,
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: _startDate != null &&
                                  _endDate != null &&
                                  isDateRange
                              ? DateTimeRange(
                                  start: _startDate!, end: _endDate!)
                              : null,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF6366F1),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E293B),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (range != null) {
                          setState(() {
                            _timeframe = 'Custom';
                            _startDate = DateTime(range.start.year,
                                range.start.month, range.start.day);
                            _endDate = DateTime(range.end.year, range.end.month,
                                range.end.day, 23, 59, 59);
                          });
                          _saveTimeframe('Custom');
                          _applyTimeframeFilter();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getAccountFilterDisplay() {
    if (_selectedAccountFilterId == null) {
      return 'All Accounts';
    }
    final matched = _accounts.firstWhere(
      (acc) => acc.id == _selectedAccountFilterId,
      orElse: () => AccountModel(
        name: 'Account',
        type: 'bank',
        keywords: '',
        balance: 0.0,
      ),
    );
    return matched.name;
  }

  void _showAccountFilterSheet() {
    _unfocusSearch();
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
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Select Account Filter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAccountRadioOption(
                      context,
                      setSheetState,
                      id: null,
                      name: 'All Accounts',
                      balance: null,
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Divider(color: Colors.white10),
                    ),
                    ..._accounts.map((acc) {
                      return _buildAccountRadioOption(
                        context,
                        setSheetState,
                        id: acc.id,
                        name: acc.name,
                        balance: acc.balance,
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAccountRadioOption(
    BuildContext context,
    StateSetter setSheetState, {
    required int? id,
    required String name,
    required double? balance,
  }) {
    final isSelected = _selectedAccountFilterId == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountFilterId = id;
        });
        _applyTimeframeFilter();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (balance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF10B981) : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            Radio<int?>(
              value: id,
              groupValue: _selectedAccountFilterId,
              activeColor: const Color(0xFF10B981),
              onChanged: (newValue) {
                setState(() {
                  _selectedAccountFilterId = newValue;
                });
                _applyTimeframeFilter();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(
      BuildContext context, StateSetter setSheetState, String value) {
    final isSelected = _timeframe == value;
    final now = DateTime.now();
    String displayLabel = value;

    if (value == 'Today') {
      displayLabel = 'Today (${DateFormat('d MMMM').format(now)})';
    } else if (value == 'Yesterday') {
      displayLabel =
          'Yesterday (${DateFormat('d MMMM').format(now.subtract(const Duration(days: 1)))})';
    } else if (value == 'This Week') {
      final weekday = now.weekday;
      final startOffset = weekday - 1;
      final start = now.subtract(Duration(days: startOffset));
      final end = start.add(const Duration(days: 6));
      displayLabel =
          'This Week (${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)})';
    } else if (value == 'This Month') {
      displayLabel = 'This Month (${DateFormat('MMMM').format(now)})';
    } else if (value == 'This Year') {
      displayLabel = 'This Year (${now.year})';
    }

    return InkWell(
      onTap: () {
        setState(() {
          _timeframe = value;
          _startDate = null;
          _endDate = null;
        });
        _saveTimeframe(value);
        _applyTimeframeFilter();
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _timeframe,
              activeColor: const Color(0xFF6366F1),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _timeframe = newValue;
                    _startDate = null;
                    _endDate = null;
                  });
                  _saveTimeframe(newValue);
                  _applyTimeframeFilter();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRadioOption(
    BuildContext context,
    StateSetter setSheetState, {
    required String title,
    required bool isSelected,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected && subLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: const Color(0xFF6366F1),
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  // Opens month and year lists
  void _openMonthYearPicker() {
    _unfocusSearch();
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Select Month & Year'),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedMonth,
                      dropdownColor: const Color(0xFF1E293B),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(months[index]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMonth = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      dropdownColor: const Color(0xFF1E293B),
                      items: List.generate(11, (index) {
                        final y = now.year - 5 + index;
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedYear = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _timeframe = 'Custom';
                      _startDate = DateTime(selectedYear, selectedMonth, 1);
                      _endDate = DateTime(
                          selectedYear, selectedMonth + 1, 0, 23, 59, 59);
                    });
                    _saveTimeframe('Custom');
                    _applyTimeframeFilter();
                  },
                  child: const Text('Select',
                      style: TextStyle(color: Color(0xFF6366F1))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _unfocusSearch,
        child: Stack(
          children: [
            // Background soft circles for premium dark UI
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 250,
              right: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Top Header with Title and Custom Picker
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (_isAutoHideTimerActive) ...[
                                Tooltip(
                                  message: 'Tap to reveal amounts',
                                  child: InkWell(
                                    onTap: _cancelAutoHideTimer,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF6366F1)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.lock_clock,
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text('${_remainingSeconds}s'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                onPressed: () async {
                                  setState(() {
                                    _obscureAmounts = !_obscureAmounts;
                                  });

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'obscure_amounts', _obscureAmounts);
                                },
                                icon: Icon(
                                  _obscureAmounts
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _showTimeframeFilterSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _timeframe != 'This Month'
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF334155),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: _timeframe != 'This Month'
                                              ? const Color(0xFF6366F1)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getTimeframeDisplay(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _timeframe != 'This Month'
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: Colors.white54),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _showAccountFilterSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedAccountFilterId != null
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF334155),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 16,
                                          color:
                                              _selectedAccountFilterId != null
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getAccountFilterDisplay(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _selectedAccountFilterId != null
                                                    ? Colors.white
                                                    : Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: Colors.white54),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Summary Metric Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSummaryCard(),
                    ),
                  ),

                  // Accounts Carousel
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'Accounts',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 105,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              return _buildAccountCard(_accounts[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chart and ledger headers
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_filteredTransactions.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Breakdown Analysis',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _analyticsTab = 'debit';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _analyticsTab == 'debit'
                                                ? const Color(0xFF6366F1)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'Expense',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _analyticsTab == 'debit'
                                                  ? Colors.white
                                                  : Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _analyticsTab = 'credit';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _analyticsTab == 'credit'
                                                ? const Color(0xFF10B981)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'Income',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _analyticsTab == 'credit'
                                                  ? Colors.white
                                                  : Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPieChart(),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (_selectedAccountFilterId != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedAccountFilterId = null;
                                    });
                                    _applyTimeframeFilter();
                                  },
                                  child: const Text('Clear Account Filter',
                                      style:
                                          TextStyle(color: Color(0xFF6366F1))),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search merchant or amount...',
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.white54),
                              suffixIcon:
                                  ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _searchController,
                                builder: (context, value, child) {
                                  return value.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded,
                                              color: Colors.white54, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            _unfocusSearch();
                                          },
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ledger list
                  if (_filteredTransactions.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No transactions found for this period.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildLedgerItem(_filteredTransactions[index]);
                        },
                        childCount: _filteredTransactions.length,
                      ),
                    ),

                  // Spacer at bottom so elements don't get covered by nav strap
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !_showFab,
        child: AnimatedScale(
          scale: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: 74), // Floating just above bottom navigation strap
            child: FloatingActionButton(
              onPressed: _openManualAddBottomSheet,
              backgroundColor: const Color(0xFF6366F1),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)], // Indigo Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET SAVINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _shouldHideAmounts
                ? '${AppSettings.currencySymbol}••••'
                : '${AppSettings.currencySymbol}${_netBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward,
                          color: Color(0xFFB9F6CA), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Income',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                        Text(
                          _shouldHideAmounts
                              ? '${AppSettings.currencySymbol}••••'
                              : '${AppSettings.currencySymbol}${_totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 35, color: Colors.white24),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward,
                          color: Color(0xFFFF8A80), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expense',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                        Text(
                          _shouldHideAmounts
                              ? '${AppSettings.currencySymbol}••••'
                              : '${AppSettings.currencySymbol}${_totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account) {
    final isSelected = _selectedAccountFilterId == account.id;

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

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAccountFilterId = isSelected ? null : account.id;
          });
          _applyTimeframeFilter();
        },
        child: Container(
          width: 145,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.15)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(getIcon(account.type),
                      color: const Color(0xFF6366F1), size: 20),
                  Text(
                    account.type.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shouldHideAmounts
                        ? '${AppSettings.currencySymbol}••••'
                        : '${AppSettings.currencySymbol}${account.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final categoryTotals = <int, double>{};
    for (var tx in _filteredTransactions) {
      if (tx.type == _analyticsTab) {
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _analyticsTab == 'debit'
                  ? Icons.receipt_long_outlined
                  : Icons.monetization_on_outlined,
              color: Colors.white24,
              size: 36,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _analyticsTab == 'debit'
                    ? 'No expense transactions recorded for this period.'
                    : 'No income transactions recorded for this period.',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final totalDeductions = categoryTotals.values.fold(0.0, (a, b) => a + b);

    final sections = categoryTotals.entries.map((entry) {
      final category = _categories.firstWhere((c) => c.id == entry.key,
          orElse: () => _categories.last);
      final value = entry.value;

      return PieChartSectionData(
        color: Color(category.color),
        value: value,
        title: '', // Hiding text inside slices to prevent overlaps
        radius: 32,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Donut Chart Container
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: sections,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _analyticsTab == 'debit' ? 'TOTAL SPENT' : 'TOTAL INCOME',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shouldHideAmounts
                          ? '${AppSettings.currencySymbol}••••'
                          : '${AppSettings.currencySymbol}${totalDeductions.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Wrapping grid of category chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categoryTotals.entries.map((entry) {
              final category = _categories.firstWhere((c) => c.id == entry.key,
                  orElse: () => _categories.last);
              final value = entry.value;
              final percentage =
                  totalDeductions > 0 ? (value / totalDeductions) * 100 : 0.0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${category.name} (${percentage.toStringAsFixed(0)}%)',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _shouldHideAmounts
                          ? '${AppSettings.currencySymbol}••••'
                          : '${AppSettings.currencySymbol}${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(TransactionModel tx) {
    final category = _categories.firstWhere((c) => c.id == tx.categoryId,
        orElse: () => _categories.last);
    final account = _accounts.firstWhere((a) => a.id == tx.accountId,
        orElse: () => _accounts.first);

    String getAccountTypeDisplay(String type) {
      switch (type) {
        case 'bank':
          return 'Bank';
        case 'credit_card':
          return 'Card';
        case 'wallet':
          return 'Wallet';
        case 'cash':
          return 'Cash';
        default:
          return type.replaceAll('_', ' ').toUpperCase();
      }
    }

    Color textCol = const Color(0xFFEF4444); // Red
    String sign = '-';
    if (tx.type == 'credit') {
      textCol = const Color(0xFF10B981); // Green
      sign = '+';
    } else if (tx.type == 'transfer') {
      textCol = const Color(0xFF94A3B8); // Slate 400
      sign = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () => _openEditTransactionBottomSheet(tx),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(category.color).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconHelper.getIcon(category.icon),
                    color: Color(category.color), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          tx.type == 'transfer'
                              ? '${account.name} ➔ ${_accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => _accounts.first).name}'
                              : account.name,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            getAccountTypeDisplay(account.type),
                            style: const TextStyle(
                                fontSize: 8, color: Colors.white38),
                          ),
                        ),
                        if (tx.appName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tx.appName!,
                                style: const TextStyle(
                                    fontSize: 8, color: Colors.white38)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _shouldHideAmounts
                        ? '${AppSettings.currencySymbol}••••'
                        : '$sign${AppSettings.currencySymbol}${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(tx.date),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FORM & BOTTOM SHEET LOGIC ---

  // Opens bottom sheet to add manual transaction
  void _openManualAddBottomSheet() {
    _openTransactionFormBottomSheet(null);
  }

  // Opens bottom sheet to edit existing transaction
  void _openEditTransactionBottomSheet(TransactionModel tx) {
    _openTransactionFormBottomSheet(tx);
  }

  void _openTransactionFormBottomSheet(TransactionModel? editTx) {
    _unfocusSearch();
    final isEdit = editTx != null;

    // Form fields
    final amountController =
        TextEditingController(text: isEdit ? editTx.amount.toString() : '');
    final descController =
        TextEditingController(text: isEdit ? editTx.description : '');
    String type = isEdit ? editTx.type : 'debit';
    int accountId = isEdit
        ? editTx.accountId
        : (_accounts.isNotEmpty ? _accounts.first.id! : 1);
    int? toAccountId = isEdit ? editTx.toAccountId : null;
    int categoryId = isEdit
        ? editTx.categoryId
        : (_categories.isNotEmpty ? _categories.first.id! : 1);
    DateTime selectedDate = isEdit ? editTx.date : DateTime.now();
    bool isKeyboardOpen = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setFormState) {
            final currentBottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardNowOpen = currentBottomInset > 0;
            if (isKeyboardOpen && !isKeyboardNowOpen) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FocusManager.instance.primaryFocus?.unfocus();
              });
            }
            isKeyboardOpen = isKeyboardNowOpen;

            final selectedAcc = _accounts.firstWhere((a) => a.id == accountId,
                orElse: () => _accounts.first);
            final selectedToAcc = type == 'transfer' && toAccountId != null
                ? _accounts.firstWhere((a) => a.id == toAccountId,
                    orElse: () => _accounts.first)
                : null;
            final selectedCat = _categories.firstWhere(
                (c) => c.id == categoryId,
                orElse: () => _categories.first);

            IconData getAccountIcon(String t) {
              switch (t) {
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

            void showAccountPicker(String pickerTitle, int currentSelected,
                Function(int) onSelected) {
              FocusManager.instance.primaryFocus?.unfocus();
              final double maxFraction;
              final double initialFraction;
              if (_accounts.length <= 3) {
                // Short list: Fit exactly to 35% without expansion
                maxFraction = 0.35;
                initialFraction = 0.35;
              } else if (_accounts.length <= 6) {
                // Medium list: Fit exactly to 60% without expansion
                maxFraction = 0.6;
                initialFraction = 0.6;
              } else {
                // Long list: Start at 50%, expand up to 90%
                maxFraction = 0.9;
                initialFraction = 0.5;
              }
              final minFraction = 0.25.clamp(0.1, initialFraction);

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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
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
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: _accounts.length,
                                itemBuilder: (context, index) {
                                  final acc = _accounts[index];
                                  final isSelected = acc.id == currentSelected;
                                  return InkWell(
                                    onTap: () {
                                      onSelected(acc.id!);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                                .withOpacity(0.15)
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                                  .withOpacity(0.4)
                                              : Colors.white.withOpacity(0.05),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1)
                                                  .withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              getAccountIcon(acc.type),
                                              color: const Color(0xFF6366F1),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  acc.name,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
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
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF10B981),
                                                size: 20),
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

            void showCategoryPicker(
                int currentSelected, Function(int) onSelected) {
              FocusManager.instance.primaryFocus?.unfocus();
              final double maxFraction;
              final double initialFraction;
              if (_categories.length <= 4) {
                // Short list: Fit exactly to 40% without expansion
                maxFraction = 0.4;
                initialFraction = 0.4;
              } else if (_categories.length <= 8) {
                // Medium list: Fit exactly to 65% without expansion
                maxFraction = 0.65;
                initialFraction = 0.65;
              } else {
                // Long list: Start at 50%, expand up to 90%
                maxFraction = 0.9;
                initialFraction = 0.5;
              }
              final minFraction = 0.25.clamp(0.1, initialFraction);

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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
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
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isSelected = cat.id == currentSelected;
                                  return InkWell(
                                    onTap: () {
                                      onSelected(cat.id!);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                                .withOpacity(0.15)
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                                  .withOpacity(0.4)
                                              : Colors.white.withOpacity(0.05),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Color(cat.color)
                                                  .withOpacity(0.15),
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
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF10B981),
                                                size: 20),
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

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Transaction' : 'Add Transaction',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (isEdit)
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Color(0xFFEF4444)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: const Text('Delete Transaction?'),
                                    content: const Text(
                                        'This will permanently delete this transaction.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel',
                                            style: TextStyle(
                                                color: Colors.white70)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete',
                                            style: TextStyle(
                                                color: Color(0xFFEF4444))),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await DatabaseService.instance
                                      .deleteTransaction(editTx.id!);
                                  Navigator.pop(context); // Close bottom sheet
                                  _refreshData();
                                  widget.onRefreshPendingCount();
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Type selector pills
                      Row(
                        children: [
                          _buildFormTypePill(
                            label: 'Expense',
                            isActive: type == 'debit',
                            onTap: () => setFormState(() {
                              type = 'debit';
                              toAccountId = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildFormTypePill(
                            label: 'Income',
                            isActive: type == 'credit',
                            onTap: () => setFormState(() {
                              type = 'credit';
                              toAccountId = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildFormTypePill(
                            label: 'Transfer',
                            isActive: type == 'transfer',
                            onTap: () => setFormState(() {
                              type = 'transfer';
                              if (toAccountId == null && _accounts.length > 1) {
                                toAccountId = _accounts
                                    .firstWhere((a) => a.id != accountId)
                                    .id;
                              }
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Amount field
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Amount (${AppSettings.currencySymbol})',
                          labelStyle: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixText: '${AppSettings.currencySymbol} ',
                          prefixStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Account select field
                      CustomSelectField(
                        label: type == 'transfer' ? 'From Account' : 'Account',
                        value: selectedAcc.name,
                        icon: getAccountIcon(selectedAcc.type),
                        onTap: () {
                          showAccountPicker(
                            type == 'transfer'
                                ? 'Select Source Account'
                                : 'Select Account',
                            accountId,
                            (selectedId) => setFormState(() {
                              accountId = selectedId;
                              if (type == 'transfer' &&
                                  toAccountId == accountId) {
                                toAccountId = _accounts
                                    .firstWhere((a) => a.id != accountId)
                                    .id;
                              }
                            }),
                          );
                        },
                      ),
                      if (type == 'transfer' && selectedToAcc != null) ...[
                        // To Account select field
                        CustomSelectField(
                          label: 'To Account',
                          value: selectedToAcc.name,
                          icon: getAccountIcon(selectedToAcc.type),
                          onTap: () {
                            showAccountPicker(
                              'Select Destination Account',
                              toAccountId ?? accountId,
                              (selectedId) =>
                                  setFormState(() => toAccountId = selectedId),
                            );
                          },
                        ),
                      ],
                      // Category select field
                      CustomSelectField(
                        label: 'Category',
                        value: selectedCat.name,
                        icon: IconHelper.getIcon(selectedCat.icon),
                        iconColor: Color(selectedCat.color),
                        onTap: () {
                          showCategoryPicker(
                            categoryId,
                            (selectedId) =>
                                setFormState(() => categoryId = selectedId),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Description
                      TextField(
                        controller: descController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Description / Remarks',
                          labelStyle: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.description,
                              color: Color(0xFF6366F1), size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date picker field
                      InkWell(
                        onTap: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (time != null) {
                              setFormState(() {
                                selectedDate = DateTime(
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
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF0F172A),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF6366F1), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date & Time',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white54),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('yyyy-MM-dd hh:mm a')
                                          .format(selectedDate),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final amt =
                              double.tryParse(amountController.text) ?? 0.0;
                          if (amt <= 0) {
                            AppSnackBar.show(
                                context, 'Please enter a valid amount',
                                type: SnackBarType.warning);
                            return;
                          }

                          final desc = descController.text.trim();
                          final finalDesc = desc.isEmpty
                              ? (isEdit ? editTx.description : 'Manual Entry')
                              : desc;

                          final tx = TransactionModel(
                            id: isEdit ? editTx.id : null,
                            appName: isEdit ? editTx.appName : 'Manual',
                            title: isEdit ? editTx.title : 'Manual',
                            body: isEdit
                                ? editTx.body
                                : 'Manual transaction entry',
                            amount: amt,
                            type: type,
                            accountId: accountId,
                            toAccountId: toAccountId,
                            categoryId: categoryId,
                            description: finalDesc,
                            date: selectedDate,
                            status:
                                'confirmed', // Manual or edited transactions are confirmed immediately
                          );

                          if (isEdit) {
                            await DatabaseService.instance
                                .updateTransaction(tx);
                          } else {
                            await DatabaseService.instance
                                .insertTransaction(tx);
                          }

                          Navigator.pop(context); // Close bottom sheet
                          _refreshData();
                          widget.onRefreshPendingCount();
                        },
                        child: Text(
                          isEdit ? 'Save Changes' : 'Confirm Transaction',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildFormTypePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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
