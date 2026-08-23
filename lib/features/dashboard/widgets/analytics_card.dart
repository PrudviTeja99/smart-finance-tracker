import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../l10n/app_localizations.dart';
import 'donut_chart.dart';
import 'bar_chart.dart';
import 'category_legend.dart';
import 'type_filter_chips.dart';

class AnalyticsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final String typeFilter; // 'all', 'debit', 'credit', 'transfer'
  final ValueChanged<String> onTypeChanged;
  final String timeframe;
  final String chartView; // 'donut', 'bar'
  final ValueChanged<String> onToggleChartView;
  final int touchedIndex;
  final ValueChanged<int> onTouchIndexChanged;
  final bool shouldHideAmounts;

  const AnalyticsCard({
    super.key,
    required this.transactions,
    required this.categories,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.timeframe,
    required this.chartView,
    required this.onToggleChartView,
    required this.touchedIndex,
    required this.onTouchIndexChanged,
    required this.shouldHideAmounts,
  });

  Widget _buildChartSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unsortedTotals = <int, double>{};
    final categoryCounts = <int, int>{};
    for (var tx in transactions) {
      if (typeFilter == 'all' || tx.type == typeFilter) {
        unsortedTotals[tx.categoryId] =
            (unsortedTotals[tx.categoryId] ?? 0.0) + tx.amount;
        categoryCounts[tx.categoryId] =
            (categoryCounts[tx.categoryId] ?? 0) + 1;
      }
    }

    final sortedEntries = unsortedTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryTotals = Map<int, double>.fromEntries(sortedEntries);

    final strings = AppLocalizations.of(context)!;
    final String sectionTitle = typeFilter == 'credit'
        ? strings.dashboardIncomeAnalysis
        : (typeFilter == 'debit'
            ? strings.dashboardExpenseAnalysis
            : (typeFilter == 'transfer' ? strings.dashboardTransferAnalysis : strings.dashboardAllTransactionsAnalysis));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            // Donut vs Bar View Segmented Switcher
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  _buildChartSegment(
                    label: 'Donut',
                    icon: Icons.pie_chart_rounded,
                    isSelected: chartView == 'donut',
                    onTap: () => onToggleChartView('donut'),
                  ),
                  _buildChartSegment(
                    label: 'Bar',
                    icon: Icons.bar_chart_rounded,
                    isSelected: chartView == 'bar',
                    onTap: () => onToggleChartView('bar'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TypeFilterChips(
          selectedType: typeFilter,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chartView == 'donut') ...[
                DonutChart(
                  categoryTotals: categoryTotals,
                  categoryCounts: categoryCounts,
                  categories: categories,
                  typeFilter: typeFilter,
                  touchedIndex: touchedIndex,
                  onTouchChanged: onTouchIndexChanged,
                  shouldHideAmounts: shouldHideAmounts,
                ),
                const SizedBox(height: 16),
                CategoryLegend(
                  categoryTotals: categoryTotals,
                  categoryCounts: categoryCounts,
                  categories: categories,
                  touchedIndex: touchedIndex,
                  onCategoryTapped: onTouchIndexChanged,
                  shouldHideAmounts: shouldHideAmounts,
                ),
                const SizedBox(height: 4),
              ] else ...[
                DashboardBarChart(
                  transactions: transactions,
                  typeFilter: typeFilter,
                  timeframe: timeframe,
                  shouldHideAmounts: shouldHideAmounts,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
