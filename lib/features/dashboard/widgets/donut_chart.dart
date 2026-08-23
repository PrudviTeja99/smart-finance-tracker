import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../utils/app_formatters.dart';
import '../../../l10n/app_localizations.dart';

class DonutChart extends StatelessWidget {
  final Map<int, double> categoryTotals;
  final Map<int, int>? categoryCounts;
  final List<CategoryModel> categories;
  final String typeFilter; // 'debit', 'credit', 'all', 'transfer'
  final int touchedIndex; // -1 if none selected
  final ValueChanged<int> onTouchChanged;
  final bool shouldHideAmounts;

  const DonutChart({
    super.key,
    required this.categoryTotals,
    this.categoryCounts,
    required this.categories,
    required this.typeFilter,
    required this.touchedIndex,
    required this.onTouchChanged,
    required this.shouldHideAmounts,
  });

  static String _formatPct(double pct) {
    if (pct == pct.roundToDouble() && pct == pct.round().toDouble()) {
      return pct.toStringAsFixed(0);
    }
    final s = pct.toStringAsFixed(2);
    if (s.contains('.')) {
      return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final totalSum = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (categoryTotals.isEmpty || totalSum == 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              typeFilter == 'credit'
                  ? Icons.monetization_on_outlined
                  : Icons.receipt_long_outlined,
              color: Colors.white24,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              typeFilter == 'credit'
                  ? strings.donutNoIncome
                  : strings.donutNoExpense,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    String centerTitle = typeFilter == 'credit'
        ? strings.donutTotalIncome
        : (typeFilter == 'debit'
            ? strings.donutTotalSpent
            : (typeFilter == 'transfer' ? strings.donutTransfers : strings.donutTotalVolume));
    String centerAmountText = AppFormatters.formatAmount(totalSum, shouldHide: shouldHideAmounts);
    
    int totalTxCount = 0;
    if (categoryCounts != null && categoryCounts!.isNotEmpty) {
      totalTxCount = categoryCounts!.values.fold(0, (a, b) => a + b);
    }

    String centerSubtext = totalTxCount > 0
        ? strings.donutTxCount(totalTxCount)
        : '';
    Color centerTitleColor = Colors.white38;

    if (touchedIndex >= 0 && touchedIndex < entries.length) {
      final selectedEntry = entries[touchedIndex];
      final cat = categories.firstWhere(
        (c) => c.id == selectedEntry.key,
        orElse: () => categories.firstWhere(
          (c) => c.name.toLowerCase() == 'others',
          orElse: () => categories.first,
        ),
      );
      final catAmount = selectedEntry.value;
      final percentage = (catAmount / totalSum) * 100;
      final catTxCount = categoryCounts?[selectedEntry.key] ?? 0;

      centerTitle = cat.getLocalizedName(strings).toUpperCase();
      centerTitleColor = Color(cat.color);
      centerAmountText = AppFormatters.formatAmount(catAmount, shouldHide: shouldHideAmounts);
      
      centerSubtext = catTxCount > 0
          ? '${_formatPct(percentage)}% (${strings.donutTxCount(catTxCount)})'
          : strings.donutPctOfTotal(_formatPct(percentage));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the smaller of available width and a reasonable height to
        // compute radii that always fit with margin.
        const double chartHeight = 210.0;
        final double availableWidth = constraints.maxWidth;
        final double availableDiameter =
            (availableWidth < chartHeight ? availableWidth : chartHeight);
        // Reserve 10% margin on each side so expanded sections never clip
        final double maxOuterRadius = (availableDiameter / 2) * 0.90;
        // Section ring thickness is ~30% of outer radius
        final double sectionRadius = (maxOuterRadius * 0.28).clamp(18.0, 30.0);
        final double touchedSectionRadius = sectionRadius + 8;
        final double centerRadius = maxOuterRadius - touchedSectionRadius;

        // Enforce minimum visual value so tiny sections don't get eaten
        // by sectionsSpace gaps. Use 1.5% of total as the minimum display value.
        final double minDisplayValue = totalSum * 0.015;
        final adjustedEntries = entries.map((e) {
          return MapEntry(e.key, e.value > 0 && e.value < minDisplayValue ? minDisplayValue : e.value);
        }).toList();

        // Reduce sectionsSpace when many categories to prevent gaps
        // from overwhelming small sections
        final double effectiveSectionsSpace = entries.length > 8
            ? 1.0
            : (entries.length > 5 ? 1.5 : 2.0);

        final sections = List.generate(adjustedEntries.length, (i) {
          final entry = adjustedEntries[i];
          final isTouched = i == touchedIndex;
          final category = categories.firstWhere(
            (c) => c.id == entry.key,
            orElse: () => categories.firstWhere(
              (c) => c.name.toLowerCase() == 'others',
              orElse: () => categories.first,
            ),
          );

          final radius = isTouched ? touchedSectionRadius : sectionRadius;
          final color = isTouched
              ? Color(category.color)
              : (touchedIndex >= 0
                  ? Color(category.color).withValues(alpha: 0.5)
                  : Color(category.color));

          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '',
            radius: radius,
          );
        });

        return SizedBox(
          height: chartHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        return;
                      }
                      final index =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                      if (index != touchedIndex) {
                        onTouchChanged(index);
                      }
                    },
                  ),
                  sectionsSpace: effectiveSectionsSpace,
                  centerSpaceRadius: centerRadius,
                  sections: sections,
                ),
              ),
              GestureDetector(
                onTap: () => onTouchChanged(-1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: centerRadius * 1.75,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerTitle,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: centerTitleColor,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          centerAmountText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (centerSubtext.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            centerSubtext,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
