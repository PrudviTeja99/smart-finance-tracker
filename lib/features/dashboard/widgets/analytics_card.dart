import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import 'donut_chart.dart';
import 'bar_chart.dart';
import 'category_legend.dart';

class AnalyticsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final String typeFilter; // 'all', 'debit', 'credit', 'transfer'
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
    required this.timeframe,
    required this.chartView,
    required this.onToggleChartView,
    required this.touchedIndex,
    required this.onTouchIndexChanged,
    required this.shouldHideAmounts,
  });

  @override
  Widget build(BuildContext context) {
    // If typeFilter is 'transfer', we don't render donut/bar breakdown
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryTotals = <int, double>{};
    for (var tx in transactions) {
      if (typeFilter == 'all' || tx.type == typeFilter) {
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0.0) + tx.amount;
      }
    }

    final String sectionTitle = typeFilter == 'credit'
        ? 'Income Analysis'
        : (typeFilter == 'debit'
            ? 'Expense Analysis'
            : (typeFilter == 'transfer' ? 'Transfer Analysis' : 'All Transactions Analysis'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Donut vs Bar View Toggle Buttons
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onToggleChartView('donut'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chartView == 'donut'
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        size: 16,
                        color: chartView == 'donut'
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onToggleChartView('bar'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chartView == 'bar'
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 16,
                        color: chartView == 'bar'
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chartView == 'donut') ...[
                DonutChart(
                  categoryTotals: categoryTotals,
                  categories: categories,
                  typeFilter: typeFilter,
                  touchedIndex: touchedIndex,
                  onTouchChanged: onTouchIndexChanged,
                  shouldHideAmounts: shouldHideAmounts,
                ),
                const SizedBox(height: 16),
                CategoryLegend(
                  categoryTotals: categoryTotals,
                  categories: categories,
                  touchedIndex: touchedIndex,
                  onCategoryTapped: onTouchIndexChanged,
                  shouldHideAmounts: shouldHideAmounts,
                ),
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
