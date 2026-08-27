import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../features/dashboard/logic/filter_logic.dart';
import '../features/dashboard/widgets/ledger_list.dart';
import '../features/dashboard/sheets/month_year_picker_sheet.dart';
import '../shared/sheets/transaction_form_sheet.dart';

enum SortOption {
  dateDesc('Newest First', Icons.access_time_rounded),
  dateAsc('Oldest First', Icons.history_rounded),
  amountDesc('Highest Amount', Icons.arrow_downward_rounded),
  amountAsc('Lowest Amount', Icons.arrow_upward_rounded);

  final String label;
  final IconData icon;
  const SortOption(this.label, this.icon);
}

extension SortOptionL10n on SortOption {
  String getLocalizedLabel(AppLocalizations strings) {
    switch (this) {
      case SortOption.dateDesc:
        return strings.transactionsSortNewestFirst;
      case SortOption.dateAsc:
        return strings.transactionsSortOldestFirst;
      case SortOption.amountDesc:
        return strings.transactionsSortHighestAmount;
      case SortOption.amountAsc:
        return strings.transactionsSortLowestAmount;
    }
  }
}

class TransactionsScreen extends StatefulWidget {
  final int? initialAccountId;

  const TransactionsScreen({
    super.key,
    this.initialAccountId,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<TransactionModel> _allTransactions = [];
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  // Pagination state
  static const int _batchSize = 30;
  int _currentMaxDisplay = 30;

  // Filter & Sort state
  String _selectedTimeframe = 'This Month'; // Default to current month
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _customMonthLabel = '';
  String _selectedType = 'all'; // 'all', 'debit', 'credit', 'transfer'
  int? _selectedAccountId;
  int? _selectedCategoryId;
  SortOption _currentSort = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_currentMaxDisplay < _filteredAndSortedTransactions.length) {
        setState(() {
          _currentMaxDisplay += _batchSize;
        });
      }
    }
  }

  void _resetPagination() {
    if (_currentMaxDisplay != _batchSize) {
      setState(() {
        _currentMaxDisplay = _batchSize;
      });
    }
  }

  void _onSearchChanged() {
    _resetPagination();
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService.instance;
      final txs = await db.getConfirmedTransactions();
      final accs = await db.getAllAccounts();
      final cats = await db.getAllCategories();

      if (mounted) {
        setState(() {
          _allTransactions = txs;
          _accounts = accs;
          _categories = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions screen data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<TransactionModel> get _filteredAndSortedTransactions {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allTransactions.where((tx) {
      // 1. Timeframe filter (Default: Current Month, or Custom Month/Year)
      if (_selectedTimeframe == 'Custom' &&
          _customStartDate != null &&
          _customEndDate != null) {
        final isWithin = tx.date.isAfter(
                _customStartDate!.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(_customEndDate!.add(const Duration(seconds: 1)));
        if (!isWithin) return false;
      } else if (_selectedTimeframe != 'All Time') {
        final dateRange =
            FilterLogic.getDateRange(_selectedTimeframe, null, null);
        final isWithin = tx.date.isAfter(
                dateRange.start.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(dateRange.end.add(const Duration(seconds: 1)));
        if (!isWithin) return false;
      }

      // 2. Type filter
      if (_selectedType != 'all' && tx.type != _selectedType) {
        return false;
      }

      // 3. Account filter
      if (_selectedAccountId != null &&
          tx.accountId != _selectedAccountId &&
          tx.toAccountId != _selectedAccountId) {
        return false;
      }

      // 4. Category filter
      if (_selectedCategoryId != null && tx.categoryId != _selectedCategoryId) {
        return false;
      }

      // 5. Search query
      if (query.isNotEmpty) {
        final matchesDesc = tx.description.toLowerCase().contains(query);
        final matchesAmount = tx.amount.toString().contains(query);
        final matchesApp = tx.appName?.toLowerCase().contains(query) ?? false;
        if (!matchesDesc && !matchesAmount && !matchesApp) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting logic
    filtered.sort((a, b) {
      switch (_currentSort) {
        case SortOption.dateDesc:
          return b.date.compareTo(a.date);
        case SortOption.dateAsc:
          return a.date.compareTo(b.date);
        case SortOption.amountDesc:
          return b.amount.compareTo(a.amount);
        case SortOption.amountAsc:
          return a.amount.compareTo(b.amount);
      }
    });

    return filtered;
  }

  bool get _hasActiveFilters =>
      _selectedTimeframe != 'This Month' ||
      _selectedType != 'all' ||
      _selectedAccountId != null ||
      _selectedCategoryId != null ||
      _currentSort != SortOption.dateDesc ||
      _searchController.text.isNotEmpty;

  void _clearFilters() {
    _resetPagination();
    setState(() {
      _selectedTimeframe = 'This Month';
      _customStartDate = null;
      _customEndDate = null;
      _customMonthLabel = '';
      _selectedType = 'all';
      _selectedAccountId = null;
      _selectedCategoryId = null;
      _currentSort = SortOption.dateDesc;
      _searchController.clear();
    });
  }

  void _openSortSheet() {
    final strings = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    strings.transactionsSortBy,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...SortOption.values.map((opt) {
                  final isSelected = _currentSort == opt;
                  return ListTile(
                    leading: Icon(
                      opt.icon,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                    ),
                    title: Text(
                      opt.getLocalizedLabel(strings),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF6366F1))
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      _resetPagination();
                      setState(() => _currentSort = opt);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showYearPickerSheet(BuildContext context, StateSetter setSheetState) {
    final strings = AppLocalizations.of(context)!;
    final years = List.generate(11, (index) => 2020 + index);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.transactionsSelectSpecificYear,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: years.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final yr = years[index];
                      final isSel = _selectedTimeframe == 'Custom' &&
                          _customMonthLabel == 'Year $yr';
                      return ListTile(
                        title: Text(
                          '$yr',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? const Color(0xFF6366F1) : Colors.white70,
                          ),
                        ),
                        trailing: isSel
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF6366F1))
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTimeframe = 'Custom';
                            _customStartDate = DateTime(yr, 1, 1);
                            _customEndDate =
                                DateTime(yr, 12, 31, 23, 59, 59);
                            _customMonthLabel = 'Year $yr';
                          });
                          setSheetState(() {});
                          Navigator.pop(context);
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

  void _openFilterSheet() {
    final strings = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.transactionsFilterTitle,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      if (_selectedTimeframe != 'This Month' ||
                          _selectedAccountId != null ||
                          _selectedCategoryId != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTimeframe = 'This Month';
                              _selectedAccountId = null;
                              _selectedCategoryId = null;
                            });
                            setSheetState(() {});
                          },
                          child: Text(
                            strings.transactionsReset,
                            style: const TextStyle(color: Color(0xFF6366F1)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timeframe Filter
                  Text(strings.transactionsTimePeriod,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...[
                        strings.transactionsThisMonth,
                        strings.transactionsThisWeek,
                        strings.transactionsThisYear
                      ].map((tf) {
                        final isSel = _selectedTimeframe == tf;
                        return ChoiceChip(
                          label: Text(tf),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.white70),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedTimeframe = tf;
                                _customStartDate = null;
                                _customEndDate = null;
                                _customMonthLabel = '';
                              });
                              setSheetState(() {});
                            }
                          },
                        );
                      }),
                      ChoiceChip(
                        avatar: const Icon(Icons.calendar_month_rounded,
                            size: 16, color: Colors.white70),
                        label: Text(
                          _selectedTimeframe == 'Custom' &&
                                  !_customMonthLabel.startsWith('Year ') &&
                                  _customMonthLabel.isNotEmpty
                              ? _customMonthLabel
                              : strings.transactionsSelectMonth,
                        ),
                        selected: _selectedTimeframe == 'Custom' &&
                            !_customMonthLabel.startsWith('Year '),
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                            color: _selectedTimeframe == 'Custom' &&
                                    !_customMonthLabel.startsWith('Year ')
                                ? Colors.white
                                : Colors.white70),
                        onSelected: (val) {
                          showMonthYearPickerSheet(
                            context: context,
                            onMonthSelected: (start, end) {
                              setState(() {
                                _selectedTimeframe = 'Custom';
                                _customStartDate = start;
                                _customEndDate = end;
                                _customMonthLabel =
                                    DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(start);
                              });
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.calendar_today_rounded,
                            size: 16, color: Colors.white70),
                        label: Text(
                          _selectedTimeframe == 'Custom' &&
                                  _customMonthLabel.startsWith('Year ')
                              ? _customMonthLabel
                              : strings.transactionsSelectYear,
                        ),
                        selected: _selectedTimeframe == 'Custom' &&
                            _customMonthLabel.startsWith('Year '),
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                            color: _selectedTimeframe == 'Custom' &&
                                    _customMonthLabel.startsWith('Year ')
                                ? Colors.white
                                : Colors.white70),
                        onSelected: (val) {
                          _showYearPickerSheet(context, setSheetState);
                        },
                      ),
                      ChoiceChip(
                        label: Text(strings.transactionsAllTime),
                        selected: _selectedTimeframe == 'All Time',
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                            color: _selectedTimeframe == 'All Time'
                                ? Colors.white
                                : Colors.white70),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedTimeframe = 'All Time';
                              _customStartDate = null;
                              _customEndDate = null;
                              _customMonthLabel = '';
                            });
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Filter
                  Text(strings.transactionFormAccount,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(strings.transactionsAllAccounts),
                        selected: _selectedAccountId == null,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                            color: _selectedAccountId == null
                                ? Colors.white
                                : Colors.white70),
                        onSelected: (val) {
                          setState(() => _selectedAccountId = null);
                          setSheetState(() {});
                        },
                      ),
                      ..._accounts.map((acc) {
                        final isSel = _selectedAccountId == acc.id;
                        return ChoiceChip(
                          label: Text(acc.name),
                          selected: isSel,
                          selectedColor: const Color(0xFF6366F1),
                          backgroundColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.white70),
                          onSelected: (val) {
                            setState(() => _selectedAccountId = val ? acc.id : null);
                            setSheetState(() {});
                          },
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Category Filter
                  Text(strings.transactionFormCategory,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(strings.transactionsAllCategories),
                            selected: _selectedCategoryId == null,
                            selectedColor: const Color(0xFF6366F1),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                                color: _selectedCategoryId == null
                                    ? Colors.white
                                    : Colors.white70),
                            onSelected: (val) {
                              setState(() => _selectedCategoryId = null);
                              setSheetState(() {});
                            },
                          ),
                          ..._categories.map((cat) {
                            final isSel = _selectedCategoryId == cat.id;
                            return ChoiceChip(
                              label: Text(cat.name),
                              selected: isSel,
                              selectedColor: Color(cat.color).withValues(alpha: 0.8),
                              backgroundColor: const Color(0xFF0F172A),
                              labelStyle: TextStyle(
                                  color: isSel ? Colors.white : Colors.white70),
                              onSelected: (val) {
                                setState(() =>
                                    _selectedCategoryId = val ? cat.id : null);
                                setSheetState(() {});
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.transactionsApplyFilters,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
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

  void _openEditTransaction(TransactionModel tx) {
    showTransactionFormSheet(
      context: context,
      editTx: tx,
      accounts: _accounts,
      categories: _categories,
      onSaved: () => _loadData(),
      onDeleted: () => _loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final transactionsList = _filteredAndSortedTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          strings.transactionsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentSort != SortOption.dateDesc
                  ? _currentSort.icon
                  : Icons.swap_vert_rounded,
              color: _currentSort != SortOption.dateDesc
                  ? const Color(0xFF6366F1)
                  : Colors.white70,
            ),
            tooltip: strings.transactionsSortBy,
            onPressed: _openSortSheet,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedTimeframe != 'This Month' ||
                  _selectedAccountId != null ||
                  _selectedCategoryId != null,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.tune_rounded, color: Colors.white70),
            ),
            tooltip: strings.transactionsFilterTitle,
            onPressed: _openFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              children: [
                // Top Search Bar & Type Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      // Search Input
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: strings.transactionsSearchHint,
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon:
                              const Icon(Icons.search_rounded, color: Colors.white38),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      color: Colors.white38),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Type Filter Chips Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildTypeChip('all', strings.transactionsAllType),
                            const SizedBox(width: 8),
                            _buildTypeChip('debit', strings.transactionsExpensesType, color: const Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            _buildTypeChip('credit', strings.transactionsIncomeType, color: const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            _buildTypeChip('transfer', strings.transactionsTransfersType, color: const Color(0xFF38BDF8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Filter Bar (If any filters applied)
                if (_hasActiveFilters)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            strings.transactionsShowingCount(transactionsList.length, _allTransactions.length, _currentSort.getLocalizedLabel(strings)),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Text(
                            strings.transactionsResetAll,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Transactions List
                Expanded(
                  child: transactionsList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: Colors.white24),
                              const SizedBox(height: 12),
                              Text(
                                strings.transactionsNotFound,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.transactionsNotFoundSubtitle,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _clearFilters,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6366F1),
                                    side: const BorderSide(
                                        color: Color(0xFF6366F1)),
                                  ),
                                  child: Text(strings.transactionsClearFilters),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: (transactionsList.length < _currentMaxDisplay
                                  ? transactionsList.length
                                  : _currentMaxDisplay) +
                              (transactionsList.length > _currentMaxDisplay ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final visibleCount =
                                transactionsList.length < _currentMaxDisplay
                                    ? transactionsList.length
                                    : _currentMaxDisplay;

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

                            final tx = transactionsList[index];
                            return LedgerItem(
                              tx: tx,
                              accounts: _accounts,
                              categories: _categories,
                              shouldHideAmounts: false,
                              onTap: () => _openEditTransaction(tx),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTypeChip(String key, String label, {Color? color}) {
    final isSelected = _selectedType == key;
    final activeColor = color ?? const Color(0xFF6366F1);

    return GestureDetector(
      onTap: () {
        _resetPagination();
        setState(() => _selectedType = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
