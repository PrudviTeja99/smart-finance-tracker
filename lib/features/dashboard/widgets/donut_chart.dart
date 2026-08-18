import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../utils/app_settings.dart';

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

  @override
  Widget build(BuildContext context) {
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
                  ? 'No income transactions recorded for this period.'
                  : 'No expense transactions recorded for this period.',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    String centerTitle = typeFilter == 'credit'
        ? 'TOTAL INCOME'
        : (typeFilter == 'debit'
            ? 'TOTAL SPENT'
            : (typeFilter == 'transfer' ? 'TRANSFERS' : 'TOTAL VOLUME'));
    String centerAmountText = shouldHideAmounts
        ? '${AppSettings.currencySymbol}••••'
        : '${AppSettings.currencySymbol}${totalSum.toStringAsFixed(0)}';
    
    int totalTxCount = 0;
    if (categoryCounts != null && categoryCounts!.isNotEmpty) {
      totalTxCount = categoryCounts!.values.fold(0, (a, b) => a + b);
    }

    String centerSubtext = totalTxCount > 0
        ? '$totalTxCount ${totalTxCount == 1 ? "transaction" : "transactions"}'
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

      centerTitle = cat.name.toUpperCase();
      centerTitleColor = Color(cat.color);
      centerAmountText = shouldHideAmounts
          ? '${AppSettings.currencySymbol}••••'
          : '${AppSettings.currencySymbol}${catAmount.toStringAsFixed(0)}';
      
      centerSubtext = catTxCount > 0
          ? '${percentage.toStringAsFixed(0)}% ($catTxCount ${catTxCount == 1 ? "transaction" : "transactions"})'
          : '${percentage.toStringAsFixed(0)}% of total';
    }

    final sections = List.generate(entries.length, (i) {
      final entry = entries[i];
      final isTouched = i == touchedIndex;
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.firstWhere(
          (c) => c.name.toLowerCase() == 'others',
          orElse: () => categories.first,
        ),
      );
      final value = entry.value;

      final radius = isTouched ? 34.0 : 26.0;
      final color = isTouched
          ? Color(category.color)
          : (touchedIndex >= 0
              ? Color(category.color).withValues(alpha: 0.5)
              : Color(category.color));

      return PieChartSectionData(
        color: color,
        value: value,
        title: '',
        radius: radius,
      );
    });

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
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
              sectionsSpace: 2,
              centerSpaceRadius: 68,
              sections: sections,
            ),
          ),
          GestureDetector(
            onTap: () => onTouchChanged(-1), // Reset selection on center tap
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 125,
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
  }
}
