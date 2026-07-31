import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../utils/app_settings.dart';

class CategoryLegend extends StatelessWidget {
  final Map<int, double> categoryTotals;
  final List<CategoryModel> categories;
  final int touchedIndex;
  final ValueChanged<int> onCategoryTapped;
  final bool shouldHideAmounts;

  const CategoryLegend({
    super.key,
    required this.categoryTotals,
    required this.categories,
    required this.touchedIndex,
    required this.onCategoryTapped,
    required this.shouldHideAmounts,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final totalSum = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = categoryTotals.entries.toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isSelected = index == touchedIndex;
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => categories.firstWhere(
            (c) => c.name.toLowerCase() == 'others',
            orElse: () => categories.first,
          ),
        );
        final value = entry.value;
        final percentage = totalSum > 0 ? (value / totalSum) * 100 : 0.0;
        final catColor = Color(category.color);

        return GestureDetector(
          onTap: () {
            if (isSelected) {
              onCategoryTapped(-1); // Reset selection
            } else {
              onCategoryTapped(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? catColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? catColor : Colors.white.withValues(alpha: 0.03),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${category.name} (${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  shouldHideAmounts
                      ? '${AppSettings.currencySymbol}••••'
                      : '${AppSettings.currencySymbol}${entry.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? catColor : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
