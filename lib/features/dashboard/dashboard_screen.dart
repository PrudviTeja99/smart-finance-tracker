import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../models/account_model.dart';
import 'state/dashboard_state_mixin.dart';
import 'widgets/summary_header.dart';
import 'widgets/hero_card.dart';
import 'widgets/account_carousel.dart';
import 'widgets/month_switcher.dart';
import 'widgets/type_filter_chips.dart';
import 'widgets/analytics_card.dart';
import 'widgets/search_bar.dart';
import 'widgets/ledger_list.dart';
import 'sheets/timeframe_filter_sheet.dart';
import 'sheets/account_filter_sheet.dart';
import 'sheets/month_year_picker_sheet.dart';
import 'sheets/transaction_form_sheet.dart';

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
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin, DashboardStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initDashboardState();
    refreshData();
    widget.refreshSignal?.addListener(_onRefreshSignal);
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      unfocusSearch();
    }
    if (widget.isActive && !oldWidget.isActive) {
      refreshData();
    }
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshSignal);
      widget.refreshSignal?.addListener(_onRefreshSignal);
    }
  }

  void _onRefreshSignal() {
    if (mounted) {
      refreshData();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    WidgetsBinding.instance.removeObserver(this);
    disposeDashboardState();
    super.dispose();
  }

  void _openTimeframeSheet() {
    showTimeframeFilterSheet(
      context: context,
      timeframe: timeframe,
      startDate: startDate,
      endDate: endDate,
      onSelectTimeframe: (tf, start, end) {
        setState(() {
          timeframe = tf;
          startDate = start;
          endDate = end;
        });
        saveTimeframe(tf);
        applyFilters();
      },
      onOpenMonthYearPicker: _openMonthYearPicker,
    );
  }

  void _openAccountSheet() {
    showAccountFilterSheet(
      context: context,
      accounts: accounts,
      selectedAccountId: selectedAccountFilterId,
      onSelectAccount: (accId) {
        setState(() {
          selectedAccountFilterId = accId;
        });
        applyFilters();
      },
    );
  }

  void _openMonthYearPicker() {
    showMonthYearPickerSheet(
      context: context,
      onMonthSelected: (start, end) {
        setState(() {
          timeframe = 'Custom';
          startDate = start;
          endDate = end;
        });
        saveTimeframe('Custom');
        applyFilters();
      },
    );
  }

  void _openTransactionForm(TransactionModel? editTx) {
    showTransactionFormSheet(
      context: context,
      editTx: editTx,
      accounts: accounts,
      categories: categories,
      onSaved: () {
        refreshData();
        widget.onRefreshPendingCount();
      },
      onDeleted: () {
        refreshData();
        widget.onRefreshPendingCount();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: unfocusSearch,
        child: Stack(
          children: [
            // Background ambient lighting circles
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                ),
              ),
            ),

            SafeArea(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Title + Privacy toggle header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SummaryHeader(
                            obscureAmounts: privacyController.obscureAmounts,
                            onTogglePrivacy: () {
                              privacyController.setObscureAmounts(
                                  !privacyController.obscureAmounts);
                            },
                            isTimerActive:
                                privacyController.isAutoHideTimerActive,
                            remainingSeconds:
                                privacyController.remainingSeconds,
                            onCancelTimer:
                                privacyController.cancelAutoHideTimer,
                          ),
                          const SizedBox(height: 12),
                          MonthSwitcher(
                            timeframe: timeframe,
                            timeframeDisplay: getTimeframeDisplay(),
                            onOpenTimeframeSheet: _openTimeframeSheet,
                            onPreviousMonth: previousMonth,
                            onNextMonth: nextMonth,
                            accountFilterDisplay: getAccountFilterDisplay(),
                            isAccountFiltered: selectedAccountFilterId != null,
                            onOpenAccountSheet: _openAccountSheet,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero Card (Net Cashflow + Savings Rate)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: HeroCard(
                        netBalance: netBalance,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense,
                        savingsRate: savingsRate,
                        shouldHideAmounts: privacyController.obscureAmounts,
                        timeframeDisplay: getTimeframeDisplay(),
                      ),
                    ),
                  ),

                  // Account Carousel
                  SliverToBoxAdapter(
                    child: AccountCarousel(
                      accounts: accounts,
                      selectedAccountId: selectedAccountFilterId,
                      onAccountTapped: (acc) {
                        setState(() {
                          selectedAccountFilterId =
                              selectedAccountFilterId == acc.id
                                  ? null
                                  : acc.id;
                        });
                        applyFilters();
                      },
                      onClearAccountFilter: () {
                        setState(() {
                          selectedAccountFilterId = null;
                        });
                        applyFilters();
                      },
                      shouldHideAmounts: privacyController.obscureAmounts,
                    ),
                  ),

                  // Analytics Card + Type Filter Chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TypeFilterChips(
                            selectedType: selectedTypeFilter,
                            onTypeChanged: (type) {
                              setState(() {
                                selectedTypeFilter = type;
                              });
                              applyFilters();
                            },
                          ),
                          const SizedBox(height: 16),
                          AnalyticsCard(
                            transactions: filteredTransactions,
                            categories: categories,
                            typeFilter: selectedTypeFilter,
                            timeframe: timeframe,
                            chartView: chartView,
                            onToggleChartView: (v) {
                              setState(() {
                                chartView = v;
                              });
                            },
                            touchedIndex: touchedChartIndex,
                            onTouchIndexChanged: (idx) {
                              setState(() {
                                touchedChartIndex = idx;
                              });
                            },
                            shouldHideAmounts: privacyController.obscureAmounts,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Transactions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DashboardSearchBar(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onClear: unfocusSearch,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transaction Ledger List
                  LedgerList(
                    transactions: filteredTransactions,
                    accounts: accounts,
                    categories: categories,
                    shouldHideAmounts: privacyController.obscureAmounts,
                    onTransactionTapped: (tx) => _openTransactionForm(tx),
                  ),

                  // Bottom padding for navigation bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !showFab,
        child: AnimatedScale(
          scale: showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 74),
            child: FloatingActionButton(
              onPressed: () => _openTransactionForm(null),
              backgroundColor: const Color(0xFF6366F1),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
