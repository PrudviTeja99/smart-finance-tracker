import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_formatters.dart';
import '../../../l10n/app_localizations.dart';

class DashboardBarChart extends StatefulWidget {
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
  State<DashboardBarChart> createState() => _DashboardBarChartState();
}

class _DashboardBarChartState extends State<DashboardBarChart> {
  int? _selectedMonthIndex; // 0 = Jan, 1 = Feb, ... 11 = Dec
  int? _selectedWeekIndex; // 0 = W1, 1 = W2, 2 = W3, 3 = W4, 4 = W5
  int? _selectedSubWeekIndex; // 0 = W1..W5 selected inside month sub-chart

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    if (widget.transactions.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 36),
            const SizedBox(height: 12),
            Text(
              strings.barChartNoData,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final bool isYearlyGrouping = widget.timeframe == 'This Year';
    final bool isMonthlyGrouping =
        widget.timeframe == 'This Month' || widget.timeframe == 'Custom';
    final Map<String, _PeriodBarData> periodMap = {};

    if (isYearlyGrouping) {
      final sampleYear = widget.transactions.isNotEmpty ? widget.transactions.first.date.year : DateTime.now().year;
      final months = List.generate(12, (index) {
        return DateFormat('MMM', locale).format(DateTime(sampleYear, index + 1, 1));
      });
      for (var m in months) {
        periodMap[m] = _PeriodBarData(label: m);
      }

      for (var tx in widget.transactions) {
        final monthName = DateFormat('MMM', locale).format(tx.date);
        if (periodMap.containsKey(monthName)) {
          if (tx.type == 'credit') {
            periodMap[monthName]!.income += tx.amount;
          } else if (tx.type == 'debit') {
            periodMap[monthName]!.expense += tx.amount;
          } else if (tx.type == 'transfer') {
            periodMap[monthName]!.transfer += tx.amount;
          }
        }
      }
    } else if (isMonthlyGrouping) {
      final sampleDate = widget.transactions.isNotEmpty ? widget.transactions.first.date : DateTime.now();
      final monthName = DateFormat('MMM', locale).format(sampleDate);
      final daysInMonth = DateUtils.getDaysInMonth(sampleDate.year, sampleDate.month);

      for (int i = 1; i <= 5; i++) {
        final start = (i - 1) * 7 + 1;
        if (start > daysInMonth) break;
        int end = i * 7;
        if (end > daysInMonth) end = daysInMonth;

        final label = '$start $monthName - $end $monthName';
        periodMap['W$i'] = _PeriodBarData(label: label);
      }

      for (var tx in widget.transactions) {
        final weekNum = ((tx.date.day - 1) ~/ 7) + 1;
        final weekKey = 'W${weekNum > 5 ? 5 : weekNum}';
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
    } else {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final days = List.generate(7, (index) {
        return DateFormat('E', locale).format(monday.add(Duration(days: index)));
      });
      for (var d in days) {
        periodMap[d] = _PeriodBarData(label: d);
      }

      for (var tx in widget.transactions) {
        final dayName = DateFormat('E', locale).format(tx.date);
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
    }

    final periodList = periodMap.values.toList();
    double maxVal = 0.0;
    double totalVal = 0.0;
    String peakPeriod = '';

    for (var p in periodList) {
      final double periodMaxVal = (p.expense > p.income)
          ? (p.expense > p.transfer ? p.expense : p.transfer)
          : (p.income > p.transfer ? p.income : p.transfer);
      final periodMaxRod = widget.typeFilter == 'credit'
          ? p.income
          : (widget.typeFilter == 'debit'
              ? p.expense
              : (widget.typeFilter == 'transfer' ? p.transfer : periodMaxVal));
      if (periodMaxRod > maxVal) {
        maxVal = periodMaxRod;
        peakPeriod = p.label;
      }
      totalVal += widget.typeFilter == 'credit'
          ? p.income
          : (widget.typeFilter == 'debit'
              ? p.expense
              : (widget.typeFilter == 'transfer' ? p.transfer : (p.expense + p.income + p.transfer)));
    }

    final avgVal = periodList.isNotEmpty ? totalVal / periodList.length : 0.0;
    if (maxVal == 0) maxVal = 100.0;
    final ceilingMaxY = maxVal * 1.02;

    final isGroupedAll = widget.typeFilter == 'all';
    final double rodWidth = isYearlyGrouping ? (isGroupedAll ? 4.0 : 5.0) : (isGroupedAll ? 5.5 : 7.0);
    final double mainBottomReserved = isMonthlyGrouping ? 34.0 : 28.0;

    final barGroups = List.generate(periodList.length, (i) {
      final p = periodList[i];
      final isSelectedGroup = (isMonthlyGrouping && _selectedWeekIndex == i) ||
          (isYearlyGrouping && _selectedMonthIndex == i);

      if (isGroupedAll) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: p.expense,
              color: isSelectedGroup ? const Color(0xFFF87171) : const Color(0xFFEF4444),
              width: rodWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: isSelectedGroup
                    ? [const Color(0xFFFCA5A5), const Color(0xFFEF4444)]
                    : [const Color(0xFFF87171), const Color(0xFFEF4444)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: ceilingMaxY,
                color: isSelectedGroup
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: p.income,
              color: isSelectedGroup ? const Color(0xFF34D399) : const Color(0xFF10B981),
              width: rodWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: isSelectedGroup
                    ? [const Color(0xFF6EE7B7), const Color(0xFF10B981)]
                    : [const Color(0xFF34D399), const Color(0xFF10B981)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: ceilingMaxY,
                color: isSelectedGroup
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: p.transfer,
              color: isSelectedGroup ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8),
              width: rodWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: isSelectedGroup
                    ? [const Color(0xFFBAE6FD), const Color(0xFF38BDF8)]
                    : [const Color(0xFF7DD3FC), const Color(0xFF0284C7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: ceilingMaxY,
                color: isSelectedGroup
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }

      final rodVal = widget.typeFilter == 'debit'
          ? p.expense
          : (widget.typeFilter == 'credit' ? p.income : p.transfer);
      final Color baseColor = widget.typeFilter == 'debit'
          ? const Color(0xFFEF4444)
          : (widget.typeFilter == 'credit'
              ? const Color(0xFF10B981)
              : const Color(0xFF38BDF8));
      final List<Color> rodGradient = widget.typeFilter == 'debit'
          ? [const Color(0xFFF87171), const Color(0xFFEF4444)]
          : (widget.typeFilter == 'credit'
              ? [const Color(0xFF34D399), const Color(0xFF10B981)]
              : [const Color(0xFF38BDF8), const Color(0xFF0284C7)]);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rodVal,
            color: baseColor,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(
              colors: rodGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: ceilingMaxY,
              color: isSelectedGroup
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : const Color(0xFF1E293B).withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 195,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerUp: (event) {
                  if ((isMonthlyGrouping || isYearlyGrouping) && periodList.isNotEmpty) {
                    final chartWidth = constraints.maxWidth;
                    if (chartWidth > 0) {
                      final groupWidth = chartWidth / periodList.length;
                      final touchedGroup = (event.localPosition.dx / groupWidth)
                          .floor()
                          .clamp(0, periodList.length - 1);
                      setState(() {
                        if (isMonthlyGrouping) {
                          _selectedWeekIndex = (_selectedWeekIndex == touchedGroup) ? null : touchedGroup;
                        } else if (isYearlyGrouping) {
                          _selectedMonthIndex = (_selectedMonthIndex == touchedGroup) ? null : touchedGroup;
                          _selectedSubWeekIndex = null;
                        }
                      });
                    }
                  }
                },
                child: Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: ceilingMaxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: ceilingMaxY / 4,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withValues(alpha: 0.06),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < periodList.length) {
                                  final p = periodList[idx];
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: _buildTopAmountWidget(
                                      income: p.income,
                                      expense: p.expense,
                                      transfer: p.transfer,
                                      typeFilter: widget.typeFilter,
                                      shouldHideAmounts: widget.shouldHideAmounts,
                                      isYearlyGrouping: isYearlyGrouping,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: mainBottomReserved,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < periodList.length) {
                                  final isSelectedGroup = (isMonthlyGrouping && _selectedWeekIndex == idx) ||
                                      (isYearlyGrouping && _selectedMonthIndex == idx);
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        if (isMonthlyGrouping) {
                                          _selectedWeekIndex = (_selectedWeekIndex == idx) ? null : idx;
                                        } else if (isYearlyGrouping) {
                                          _selectedMonthIndex = (_selectedMonthIndex == idx) ? null : idx;
                                          _selectedSubWeekIndex = null;
                                        }
                                      });
                                    },
                                    child: SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Transform.rotate(
                                        angle: isMonthlyGrouping ? -0.45 : -0.3,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: isSelectedGroup
                                              ? BoxDecoration(
                                                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(6),
                                                )
                                              : null,
                                          child: Text(
                                            periodList[idx].label,
                                            style: TextStyle(
                                              fontSize: isYearlyGrouping ? 9 : (isMonthlyGrouping ? 8.5 : 10),
                                              color: isSelectedGroup ? const Color(0xFF818CF8) : Colors.white60,
                                              fontWeight: isSelectedGroup ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
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
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LineChart(
                          _buildTrendLineChartData(
                            periodList: periodList,
                            typeFilter: widget.typeFilter,
                            ceilingMaxY: ceilingMaxY,
                            isYearlyGrouping: isYearlyGrouping,
                            topReservedSize: 32,
                            bottomReservedSize: mainBottomReserved,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.4)),
            ),
            child: Text(
              '${strings.barChartAvg(widget.shouldHideAmounts ? "${AppSettings.currencySymbol}••••" : AppFormatters.formatAmount(avgVal))} • ${strings.barChartPeak(peakPeriod.isEmpty ? "N/A" : peakPeriod)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        if (isMonthlyGrouping || isYearlyGrouping) ...[
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (isMonthlyGrouping ? _selectedWeekIndex != null : _selectedMonthIndex != null)
                        ? Icons.close_rounded
                        : Icons.touch_app_rounded,
                    size: 13,
                    color: const Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isMonthlyGrouping
                        ? (_selectedWeekIndex != null ? strings.barChartTapToClose : strings.barChartTapForDays)
                        : (_selectedMonthIndex != null ? strings.barChartTapToClose : strings.barChartTapMonthForWeeks),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA5B4FC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Interactive Week Drill-Down Sub-Chart (7 Days breakdown for selected week)
        if (isMonthlyGrouping && _selectedWeekIndex != null) ...[
          const SizedBox(height: 14),
          _buildDailyDrillDownSubChart(_selectedWeekIndex!),
        ],

        // Interactive Month Drill-Down Sub-Chart (5 Weeks breakdown for selected month in Yearly mode)
        if (isYearlyGrouping && _selectedMonthIndex != null) ...[
          const SizedBox(height: 14),
          _buildMonthlyWeeksSubChart(_selectedMonthIndex!),
        ],
      ],
    );
  }

  LineChartData _buildTrendLineChartData({
    required List<_PeriodBarData> periodList,
    required String typeFilter,
    required double ceilingMaxY,
    required bool isYearlyGrouping,
    required double topReservedSize,
    required double bottomReservedSize,
  }) {
    if (periodList.isEmpty) return LineChartData();

    final isGroupedAll = typeFilter == 'all';
    final List<LineChartBarData> lineBarsData = [];
    const double minX = -0.5;
    final double maxX = periodList.length - 0.5;

    if (isGroupedAll) {
      final List<FlSpot> expenseSpots = [];
      final List<FlSpot> incomeSpots = [];
      final List<FlSpot> transferSpots = [];
      final double xOffset = isYearlyGrouping ? 0.08 : 0.12;

      for (int i = 0; i < periodList.length; i++) {
        final p = periodList[i];
        expenseSpots.add(FlSpot(i.toDouble() - xOffset, p.expense));
        incomeSpots.add(FlSpot(i.toDouble(), p.income));
        transferSpots.add(FlSpot(i.toDouble() + xOffset, p.transfer));
      }

      if (AppSettings.showExpenseTrendLine && expenseSpots.length >= 2) {
        lineBarsData.add(
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFFF87171).withValues(alpha: 0.85),
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: const Color(0xFFEF4444),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        );
      }

      if (AppSettings.showIncomeTrendLine && incomeSpots.length >= 2) {
        lineBarsData.add(
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFF34D399).withValues(alpha: 0.85),
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: const Color(0xFF10B981),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        );
      }

      if (AppSettings.showTransferTrendLine && transferSpots.length >= 2) {
        lineBarsData.add(
          LineChartBarData(
            spots: transferSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: const Color(0xFF0284C7),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        );
      }
    } else {
      final bool isEnabled = (typeFilter == 'debit' && AppSettings.showExpenseTrendLine) ||
          (typeFilter == 'credit' && AppSettings.showIncomeTrendLine) ||
          (typeFilter == 'transfer' && AppSettings.showTransferTrendLine);

      if (isEnabled) {
        final List<FlSpot> spots = [];
        final Color lineColor = typeFilter == 'debit'
            ? const Color(0xFFF87171)
            : (typeFilter == 'credit' ? const Color(0xFF34D399) : const Color(0xFF38BDF8));
        final Color dotColor = typeFilter == 'debit'
            ? const Color(0xFFEF4444)
            : (typeFilter == 'credit' ? const Color(0xFF10B981) : const Color(0xFF0284C7));

        for (int i = 0; i < periodList.length; i++) {
          final p = periodList[i];
          final val = typeFilter == 'debit'
              ? p.expense
              : (typeFilter == 'credit' ? p.income : p.transfer);
          spots.add(FlSpot(i.toDouble(), val));
        }

        if (spots.length >= 2) {
          lineBarsData.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: lineColor.withValues(alpha: 0.85),
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 2.5,
                    color: dotColor,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          );
        }
      }
    }

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: ceilingMaxY,
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: topReservedSize,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReservedSize,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: lineBarsData,
    );
  }

  Widget _buildTopAmountWidget({
    required double income,
    required double expense,
    required double transfer,
    required String typeFilter,
    required bool shouldHideAmounts,
    required bool isYearlyGrouping,
  }) {
    const double tiltAngle = -0.6; // ~-34 degrees tilt
    final double fontSize = isYearlyGrouping ? 7.0 : 7.5;

    if (typeFilter == 'all') {
      if (income == 0 && expense == 0 && transfer == 0) return const SizedBox.shrink();

      return Transform.rotate(
        angle: tiltAngle,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (expense > 0)
                Text(
                  AppFormatters.formatAmount(expense, shouldHide: shouldHideAmounts),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF87171),
                    height: 1.1,
                  ),
                ),
              if (income > 0)
                Text(
                  AppFormatters.formatAmount(income, shouldHide: shouldHideAmounts),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF34D399),
                    height: 1.1,
                  ),
                ),
              if (transfer > 0)
                Text(
                  AppFormatters.formatAmount(transfer, shouldHide: shouldHideAmounts),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7DD3FC),
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final double amount = typeFilter == 'debit'
        ? expense
        : (typeFilter == 'credit' ? income : transfer);
    if (amount == 0) return const SizedBox.shrink();

    final Color textColor = typeFilter == 'debit'
        ? const Color(0xFFF87171)
        : (typeFilter == 'credit' ? const Color(0xFF34D399) : const Color(0xFF7DD3FC));

    return Transform.rotate(
      angle: tiltAngle,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AppFormatters.formatAmount(amount, shouldHide: shouldHideAmounts),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyDrillDownSubChart(int weekIndex) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final sampleDate = widget.transactions.isNotEmpty ? widget.transactions.first.date : DateTime.now();
    final sampleYear = sampleDate.year;
    final sampleMonth = sampleDate.month;
    final monthName = DateFormat('MMM', locale).format(sampleDate);
    final daysInMonth = DateUtils.getDaysInMonth(sampleYear, sampleMonth);

    final startDay = (weekIndex * 7) + 1;
    int endDay = (weekIndex + 1) * 7;
    if (endDay > daysInMonth) endDay = daysInMonth;

    final dateRangeTitle = '$startDay $monthName – $endDay $monthName';

    final weekTxList = widget.transactions.where((tx) {
      return tx.date.year == sampleYear &&
          tx.date.month == sampleMonth &&
          tx.date.day >= startDay &&
          tx.date.day <= endDay;
    }).toList();

    final Map<int, String> dayLabelMap = {};
    final Map<String, _PeriodBarData> dailyMap = {};

    for (int day = startDay; day <= endDay; day++) {
      final label = '$day $monthName';
      dayLabelMap[day] = label;
      dailyMap[label] = _PeriodBarData(label: label);
    }

    for (var tx in weekTxList) {
      final day = tx.date.day;
      if (dayLabelMap.containsKey(day)) {
        final label = dayLabelMap[day]!;
        if (tx.type == 'credit') {
          dailyMap[label]!.income += tx.amount;
        } else if (tx.type == 'debit') {
          dailyMap[label]!.expense += tx.amount;
        } else if (tx.type == 'transfer') {
          dailyMap[label]!.transfer += tx.amount;
        }
      }
    }

    final dailyList = dailyMap.values.toList();
    double subMaxVal = 0.0;
    for (var d in dailyList) {
      final double dailyMaxVal = (d.expense > d.income)
          ? (d.expense > d.transfer ? d.expense : d.transfer)
          : (d.income > d.transfer ? d.income : d.transfer);
      final subMaxRod = widget.typeFilter == 'credit'
          ? d.income
          : (widget.typeFilter == 'debit'
              ? d.expense
              : (widget.typeFilter == 'transfer' ? d.transfer : dailyMaxVal));
      if (subMaxRod > subMaxVal) subMaxVal = subMaxRod;
    }
    if (subMaxVal == 0) subMaxVal = 100.0;
    final subCeilingMaxY = subMaxVal * 1.02;
    final isGroupedAll = widget.typeFilter == 'all';

    final subBarGroups = List.generate(dailyList.length, (i) {
      final d = dailyList[i];
      if (isGroupedAll) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.expense,
              color: const Color(0xFFEF4444),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: d.income,
              color: const Color(0xFF10B981),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: d.transfer,
              color: const Color(0xFF38BDF8),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }

      final rodVal = widget.typeFilter == 'debit'
          ? d.expense
          : (widget.typeFilter == 'credit' ? d.income : d.transfer);
      final Color baseColor = widget.typeFilter == 'debit'
          ? const Color(0xFFEF4444)
          : (widget.typeFilter == 'credit'
              ? const Color(0xFF10B981)
              : const Color(0xFF38BDF8));

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rodVal,
            color: baseColor,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: subCeilingMaxY,
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF818CF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.barChartWeekBreakdown(weekIndex + 1, dateRangeTitle),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedWeekIndex = null),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 155,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: subCeilingMaxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dailyList.length) {
                              final d = dailyList[idx];
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: _buildTopAmountWidget(
                                  income: d.income,
                                  expense: d.expense,
                                  transfer: d.transfer,
                                  typeFilter: widget.typeFilter,
                                  shouldHideAmounts: widget.shouldHideAmounts,
                                  isYearlyGrouping: false,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dailyList.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Transform.rotate(
                                  angle: -0.45,
                                  child: Text(
                                    dailyList[idx].label,
                                    style: const TextStyle(
                                      fontSize: 8.5,
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
                    barGroups: subBarGroups,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LineChart(
                      _buildTrendLineChartData(
                        periodList: dailyList,
                        typeFilter: widget.typeFilter,
                        ceilingMaxY: subCeilingMaxY,
                        isYearlyGrouping: false,
                        topReservedSize: 30,
                        bottomReservedSize: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyWeeksSubChart(int monthIndex) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final sampleYear = widget.transactions.isNotEmpty
        ? widget.transactions.first.date.year
        : DateTime.now().year;
    final targetMonth = monthIndex + 1;
    final monthDate = DateTime(sampleYear, targetMonth, 1);
    final monthName = DateFormat('MMMM', locale).format(monthDate);
    final shortMonthName = DateFormat('MMM', locale).format(monthDate);
    final daysInMonth = DateUtils.getDaysInMonth(sampleYear, targetMonth);

    final monthTxList = widget.transactions.where((tx) {
      return tx.date.year == sampleYear && tx.date.month == targetMonth;
    }).toList();

    final Map<String, _PeriodBarData> weekMap = {};
    for (int i = 1; i <= 5; i++) {
      final start = (i - 1) * 7 + 1;
      if (start > daysInMonth) break;
      int end = i * 7;
      if (end > daysInMonth) end = daysInMonth;

      final label = '$start $shortMonthName - $end $shortMonthName';
      weekMap['W$i'] = _PeriodBarData(label: label);
    }

    for (var tx in monthTxList) {
      final weekNum = ((tx.date.day - 1) ~/ 7) + 1;
      final weekKey = 'W${weekNum > 5 ? 5 : weekNum}';
      if (weekMap.containsKey(weekKey)) {
        if (tx.type == 'credit') {
          weekMap[weekKey]!.income += tx.amount;
        } else if (tx.type == 'debit') {
          weekMap[weekKey]!.expense += tx.amount;
        } else if (tx.type == 'transfer') {
          weekMap[weekKey]!.transfer += tx.amount;
        }
      }
    }

    final weekList = weekMap.values.toList();
    double subMaxVal = 0.0;
    for (var w in weekList) {
      final double weekMaxVal = (w.expense > w.income)
          ? (w.expense > w.transfer ? w.expense : w.transfer)
          : (w.income > w.transfer ? w.income : w.transfer);
      final subMaxRod = widget.typeFilter == 'credit'
          ? w.income
          : (widget.typeFilter == 'debit'
              ? w.expense
              : (widget.typeFilter == 'transfer' ? w.transfer : weekMaxVal));
      if (subMaxRod > subMaxVal) subMaxVal = subMaxRod;
    }
    if (subMaxVal == 0) subMaxVal = 100.0;
    final subCeilingMaxY = subMaxVal * 1.02;
    final isGroupedAll = widget.typeFilter == 'all';

    final subBarGroups = List.generate(weekList.length, (i) {
      final w = weekList[i];
      final isSelectedSubWeek = _selectedSubWeekIndex == i;

      if (isGroupedAll) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: w.expense,
              color: isSelectedSubWeek ? const Color(0xFFF87171) : const Color(0xFFEF4444),
              width: 5.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: isSelectedSubWeek
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: w.income,
              color: isSelectedSubWeek ? const Color(0xFF34D399) : const Color(0xFF10B981),
              width: 5.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: isSelectedSubWeek
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: w.transfer,
              color: isSelectedSubWeek ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8),
              width: 5.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: isSelectedSubWeek
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }

      final rodVal = widget.typeFilter == 'debit'
          ? w.expense
          : (widget.typeFilter == 'credit' ? w.income : w.transfer);
      final Color baseColor = widget.typeFilter == 'debit'
          ? const Color(0xFFEF4444)
          : (widget.typeFilter == 'credit'
              ? const Color(0xFF10B981)
              : const Color(0xFF38BDF8));

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rodVal,
            color: baseColor,
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: subCeilingMaxY,
              color: isSelectedSubWeek
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : const Color(0xFF1E293B).withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF818CF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.barChartMonthBreakdown(monthName),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() {
                  _selectedMonthIndex = null;
                  _selectedSubWeekIndex = null;
                }),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 155,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerUp: (event) {
                    final chartWidth = constraints.maxWidth;
                    if (chartWidth > 0 && weekList.isNotEmpty) {
                      final groupWidth = chartWidth / weekList.length;
                      final touchedGroup = (event.localPosition.dx / groupWidth)
                          .floor()
                          .clamp(0, weekList.length - 1);
                      setState(() {
                        _selectedSubWeekIndex = (_selectedSubWeekIndex == touchedGroup) ? null : touchedGroup;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: subCeilingMaxY,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < weekList.length) {
                                    final w = weekList[idx];
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: _buildTopAmountWidget(
                                        income: w.income,
                                        expense: w.expense,
                                        transfer: w.transfer,
                                        typeFilter: widget.typeFilter,
                                        shouldHideAmounts: widget.shouldHideAmounts,
                                        isYearlyGrouping: false,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < weekList.length) {
                                    final isSelectedSubWeek = _selectedSubWeekIndex == idx;
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _selectedSubWeekIndex = (_selectedSubWeekIndex == idx) ? null : idx;
                                        });
                                      },
                                      child: SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Transform.rotate(
                                          angle: -0.45,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: isSelectedSubWeek
                                                ? BoxDecoration(
                                                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  )
                                                : null,
                                            child: Text(
                                              weekList[idx].label,
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                color: isSelectedSubWeek ? const Color(0xFF818CF8) : Colors.white60,
                                                fontWeight: isSelectedSubWeek ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
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
                          barGroups: subBarGroups,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: LineChart(
                            _buildTrendLineChartData(
                              periodList: weekList,
                              typeFilter: widget.typeFilter,
                              ceilingMaxY: subCeilingMaxY,
                              isYearlyGrouping: false,
                              topReservedSize: 30,
                              bottomReservedSize: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_selectedSubWeekIndex != null) ...[
            const SizedBox(height: 12),
            _buildDailyDrillDownSubChartForMonth(_selectedSubWeekIndex!, targetMonth, sampleYear),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyDrillDownSubChartForMonth(int weekIndex, int targetMonth, int sampleYear) {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat('MMM', locale).format(DateTime(sampleYear, targetMonth, 1));
    final daysInMonth = DateUtils.getDaysInMonth(sampleYear, targetMonth);

    final startDay = (weekIndex * 7) + 1;
    int endDay = (weekIndex + 1) * 7;
    if (endDay > daysInMonth) endDay = daysInMonth;

    final dateRangeTitle = '$startDay $monthName – $endDay $monthName';

    final weekTxList = widget.transactions.where((tx) {
      return tx.date.year == sampleYear &&
          tx.date.month == targetMonth &&
          tx.date.day >= startDay &&
          tx.date.day <= endDay;
    }).toList();

    final Map<int, String> dayLabelMap = {};
    final Map<String, _PeriodBarData> dailyMap = {};

    for (int day = startDay; day <= endDay; day++) {
      final label = '$day $monthName';
      dayLabelMap[day] = label;
      dailyMap[label] = _PeriodBarData(label: label);
    }

    for (var tx in weekTxList) {
      final day = tx.date.day;
      if (dayLabelMap.containsKey(day)) {
        final label = dayLabelMap[day]!;
        if (tx.type == 'credit') {
          dailyMap[label]!.income += tx.amount;
        } else if (tx.type == 'debit') {
          dailyMap[label]!.expense += tx.amount;
        } else if (tx.type == 'transfer') {
          dailyMap[label]!.transfer += tx.amount;
        }
      }
    }

    final dailyList = dailyMap.values.toList();
    double subMaxVal = 0.0;
    for (var d in dailyList) {
      final double dailyMaxVal = (d.expense > d.income)
          ? (d.expense > d.transfer ? d.expense : d.transfer)
          : (d.income > d.transfer ? d.income : d.transfer);
      final subMaxRod = widget.typeFilter == 'credit'
          ? d.income
          : (widget.typeFilter == 'debit'
              ? d.expense
              : (widget.typeFilter == 'transfer' ? d.transfer : dailyMaxVal));
      if (subMaxRod > subMaxVal) subMaxVal = subMaxRod;
    }
    if (subMaxVal == 0) subMaxVal = 100.0;
    final subCeilingMaxY = subMaxVal * 1.02;
    final isGroupedAll = widget.typeFilter == 'all';

    final subBarGroups = List.generate(dailyList.length, (i) {
      final d = dailyList[i];
      if (isGroupedAll) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.expense,
              color: const Color(0xFFEF4444),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: d.income,
              color: const Color(0xFF10B981),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
            BarChartRodData(
              toY: d.transfer,
              color: const Color(0xFF38BDF8),
              width: 4.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: subCeilingMaxY,
                color: const Color(0xFF1E293B).withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }

      final rodVal = widget.typeFilter == 'debit'
          ? d.expense
          : (widget.typeFilter == 'credit' ? d.income : d.transfer);
      final Color baseColor = widget.typeFilter == 'debit'
          ? const Color(0xFFEF4444)
          : (widget.typeFilter == 'credit'
              ? const Color(0xFF10B981)
              : const Color(0xFF38BDF8));

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: rodVal,
            color: baseColor,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: subCeilingMaxY,
              color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            ),
          ),
        ],
      );
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF818CF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.barChartWeekBreakdown(weekIndex + 1, dateRangeTitle),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedSubWeekIndex = null),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 155,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: subCeilingMaxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dailyList.length) {
                              final d = dailyList[idx];
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: _buildTopAmountWidget(
                                  income: d.income,
                                  expense: d.expense,
                                  transfer: d.transfer,
                                  typeFilter: widget.typeFilter,
                                  shouldHideAmounts: widget.shouldHideAmounts,
                                  isYearlyGrouping: false,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < dailyList.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Transform.rotate(
                                  angle: -0.45,
                                  child: Text(
                                    dailyList[idx].label,
                                    style: const TextStyle(
                                      fontSize: 8.5,
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
                    barGroups: subBarGroups,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LineChart(
                      _buildTrendLineChartData(
                        periodList: dailyList,
                        typeFilter: widget.typeFilter,
                        ceilingMaxY: subCeilingMaxY,
                        isYearlyGrouping: false,
                        topReservedSize: 30,
                        bottomReservedSize: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
