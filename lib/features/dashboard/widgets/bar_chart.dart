import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_formatters.dart';

class DashboardBarChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String typeFilter; // 'all', 'debit', 'credit', 'transfer'
  final String timeframe;
  final bool shouldHideAmounts;

  const DashboardBarChart({
    super.key,
    required this.transactions,
    required this.typeFilter,
    required this.timeframe,
    required this.shouldHideAmounts,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 36),
            SizedBox(height: 12),
            Text(
              'No transaction trend data available for this period.',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    // Group transactions by period (days for week/today, weeks for month/year)
    final bool isWeeklyGrouping = timeframe == 'This Month' || timeframe == 'This Year';
    final Map<String, _PeriodBarData> periodMap = {};

    if (!isWeeklyGrouping) {
      // Daily grouping (Mon-Sun)
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (var d in days) {
        periodMap[d] = _PeriodBarData(label: d);
      }

      for (var tx in transactions) {
        final dayName = DateFormat('E').format(tx.date); // e.g. Mon
        if (periodMap.containsKey(dayName)) {
          if (tx.type == 'credit') {
            periodMap[dayName]!.income += tx.amount;
          } else if (tx.type == 'debit') {
            periodMap[dayName]!.expense += tx.amount;
          } else if (tx.type == 'transfer') {
            periodMap[dayName]!.transfer += tx.amount;
          }
        }
      }
    } else {
      // Weekly grouping (Week 1, Week 2, Week 3, Week 4, Week 5)
      for (int i = 1; i <= 5; i++) {
        periodMap['Week $i'] = _PeriodBarData(label: 'Week $i');
      }

      for (var tx in transactions) {
        final weekNum = ((tx.date.day - 1) ~/ 7) + 1;
        final weekKey = 'Week ${weekNum > 5 ? 5 : weekNum}';
        if (periodMap.containsKey(weekKey)) {
          if (tx.type == 'credit') {
            periodMap[weekKey]!.income += tx.amount;
          } else if (tx.type == 'debit') {
            periodMap[weekKey]!.expense += tx.amount;
          } else if (tx.type == 'transfer') {
            periodMap[weekKey]!.transfer += tx.amount;
          }
        }
      }
    }

    final periodList = periodMap.values.toList();
    double maxVal = 0.0;
    double totalVal = 0.0;
    String peakPeriod = '';

    for (var p in periodList) {
      final periodTotal = typeFilter == 'credit'
          ? p.income
          : (typeFilter == 'debit'
              ? p.expense
              : (typeFilter == 'transfer' ? p.transfer : (p.expense + p.income)));
      if (periodTotal > maxVal) {
        maxVal = periodTotal;
        peakPeriod = p.label;
      }
      totalVal += periodTotal;
    }

    final avgVal = periodList.isNotEmpty ? totalVal / periodList.length : 0.0;
    if (maxVal == 0) maxVal = 100.0; // Avoid divide-by-zero

    final isGroupedAll = typeFilter == 'all';

    final barGroups = List.generate(periodList.length, (i) {
      final p = periodList[i];

      if (isGroupedAll) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: p.expense,
              color: const Color(0xFFEF4444),
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: p.income,
              color: const Color(0xFF10B981),
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }

      final rodVal = typeFilter == 'debit'
          ? p.expense
          : (typeFilter == 'credit' ? p.income : p.transfer);
      final rodColor = typeFilter == 'debit'
          ? const Color(0xFFEF4444)
          : (typeFilter == 'credit'
              ? const Color(0xFF10B981)
              : const Color(0xFF38BDF8));

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rodVal,
            color: rodColor,
            width: 14,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0F172A),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tooltipMargin: 6,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rod.toY == 0) return null;
                    return BarTooltipItem(
                      AppFormatters.formatAmount(rod.toY, shouldHide: shouldHideAmounts),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < periodList.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: -0.4, // Inclined ~23 degrees for sleek look
                            child: Text(
                              periodList[idx].label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            shouldHideAmounts
                ? 'Average: ${AppSettings.currencySymbol}•••• • Peak: ${peakPeriod.isEmpty ? "N/A" : peakPeriod}'
                : 'Avg: ${AppFormatters.formatAmount(avgVal)} • Peak: ${peakPeriod.isEmpty ? "N/A" : peakPeriod}',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ),
      ],
    );
  }
}

class _PeriodBarData {
  final String label;
  double income = 0.0;
  double expense = 0.0;
  double transfer = 0.0;

  _PeriodBarData({required this.label});
}
