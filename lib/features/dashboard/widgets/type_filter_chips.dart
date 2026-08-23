import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TypeFilterChips extends StatelessWidget {
  final String selectedType; // 'all', 'debit', 'credit', 'transfer'
  final ValueChanged<String> onTypeChanged;

  const TypeFilterChips({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final options = [
      {'key': 'debit', 'label': strings.transactionsExpensesType, 'activeColor': const Color(0xFFEF4444)},
      {'key': 'credit', 'label': strings.transactionsIncomeType, 'activeColor': const Color(0xFF10B981)},
      {'key': 'transfer', 'label': strings.transactionsTransfersType, 'activeColor': const Color(0xFF38BDF8)},
      {'key': 'all', 'label': strings.transactionsAllType, 'activeColor': const Color(0xFF6366F1)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: options.map((opt) {
          final key = opt['key'] as String;
          final label = opt['label'] as String;
          final activeColor = opt['activeColor'] as Color;
          final isSelected = selectedType == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onTypeChanged(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
