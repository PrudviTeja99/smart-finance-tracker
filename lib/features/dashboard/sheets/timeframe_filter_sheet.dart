import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showTimeframeFilterSheet({
  required BuildContext context,
  required String timeframe,
  required DateTime? startDate,
  required DateTime? endDate,
  required Function(String timeframe, DateTime? start, DateTime? end) onSelectTimeframe,
  required VoidCallback onOpenMonthYearPicker,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

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
        builder: (context, setSheetState) {
          final isCustom = timeframe == 'Custom';
          bool isSpecificDate = false;
          bool isSpecificMonth = false;

          if (isCustom && startDate != null && endDate != null) {
            if (startDate.year == endDate.year &&
                startDate.month == endDate.month &&
                startDate.day == endDate.day) {
              isSpecificDate = true;
            } else if (startDate.day == 1 &&
                endDate.day ==
                    DateTime(endDate.year, endDate.month + 1, 0).day &&
                startDate.month == endDate.month &&
                startDate.year == endDate.year) {
              isSpecificMonth = true;
            }
          }

          final locale = Localizations.localeOf(context).toString();

          final dateLabel =
              isSpecificDate ? DateFormat('dd MMM yyyy', locale).format(startDate!) : '';
          final monthLabel =
              isSpecificMonth ? DateFormat('MMMM yyyy', locale).format(startDate!) : '';

          Widget buildRadioOption(String value) {
            final now = DateTime.now();
            final isSelected = timeframe == value;
            String displayLabel = value;

            if (value == 'Today') {
              displayLabel = '${strings.timeframeToday} (${now.day} ${DateFormat('MMM', locale).format(now)})';
            } else if (value == 'Yesterday') {
              final yest = now.subtract(const Duration(days: 1));
              displayLabel = '${strings.timeframeYesterday} (${yest.day} ${DateFormat('MMM', locale).format(yest)})';
            } else if (value == 'This Week') {
              final startOffset = now.weekday - 1;
              final tempStart = now.subtract(Duration(days: startOffset));
              displayLabel =
                  '${strings.transactionsThisWeek} (${tempStart.day} ${DateFormat('MMM', locale).format(tempStart)} - ${now.day} ${DateFormat('MMM', locale).format(now)})';
            } else if (value == 'This Month') {
              displayLabel = '${strings.transactionsThisMonth} (${DateFormat('MMMM yyyy', locale).format(now)})';
            } else if (value == 'This Year') {
              displayLabel = '${strings.transactionsThisYear} (${now.year})';
            }

            return InkWell(
              onTap: () {
                onSelectTimeframe(value, null, null);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Radio<String>(
                      value: value,
                      groupValue: timeframe,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          onSelectTimeframe(newValue, null, null);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildCustomRadioOption({
            required String title,
            required bool isSelected,
            required String subLabel,
            required VoidCallback onTap,
          }) {
            return InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (subLabel.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subLabel,
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (_) => onTap(),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      strings.timeframeFilterTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildRadioOption('Today'),
                  buildRadioOption('Yesterday'),
                  buildRadioOption('This Week'),
                  buildRadioOption('This Month'),
                  buildRadioOption('This Year'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(color: Colors.white10),
                  ),
                  buildCustomRadioOption(
                    title: strings.timeframeSpecificDate,
                    isSelected: isSpecificDate,
                    subLabel: dateLabel,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF6366F1),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1E293B),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        final s = DateTime(date.year, date.month, date.day);
                        final e = DateTime(date.year, date.month, date.day, 23, 59, 59);
                        onSelectTimeframe('Custom', s, e);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  buildCustomRadioOption(
                    title: strings.timeframeSpecificMonth,
                    isSelected: isSpecificMonth,
                    subLabel: monthLabel,
                    onTap: () async {
                      Navigator.pop(context);
                      onOpenMonthYearPicker();
                    },
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
