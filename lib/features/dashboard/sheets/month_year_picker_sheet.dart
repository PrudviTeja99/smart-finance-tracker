import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showMonthYearPickerSheet({
  required BuildContext context,
  required Function(DateTime start, DateTime end) onMonthSelected,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  final now = DateTime.now();
  final locale = Localizations.localeOf(context).toString();
  final months = List.generate(12, (index) {
    return DateFormat('MMMM', locale).format(DateTime(now.year, index + 1, 1));
  });
  final years = List.generate(11, (index) => 2020 + index);

  int tempSelectedMonth = now.month;
  int tempSelectedYear = now.year;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final strings = AppLocalizations.of(context)!;
      return StatefulBuilder(
        builder: (context, setPickerState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 420,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.pickerSelectMonthYear,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final start = DateTime(
                              tempSelectedYear, tempSelectedMonth, 1);
                          final end = DateTime(
                              tempSelectedYear,
                              tempSelectedMonth + 1,
                              0,
                              23,
                              59,
                              59);
                          onMonthSelected(start, end);
                          Navigator.pop(context);
                        },
                        child: Text(
                          strings.pickerApply,
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        // Month List
                        Expanded(
                          child: ListView.builder(
                            itemCount: months.length,
                            itemBuilder: (context, index) {
                              final monthNum = index + 1;
                              final isSelected =
                                  monthNum == tempSelectedMonth;
                              return InkWell(
                                onTap: () {
                                  setPickerState(() {
                                    tempSelectedMonth = monthNum;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    months[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(color: Colors.white10),
                        // Year List
                        Expanded(
                          child: ListView.builder(
                            itemCount: years.length,
                            itemBuilder: (context, index) {
                              final yearNum = years[index];
                              final isSelected = yearNum == tempSelectedYear;
                              return InkWell(
                                onTap: () {
                                  setPickerState(() {
                                    tempSelectedYear = yearNum;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 12),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    yearNum.toString(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
