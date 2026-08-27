import 'package:flutter/material.dart';

class MonthSwitcher extends StatelessWidget {
  final String timeframe;
  final String timeframeDisplay;
  final VoidCallback onOpenTimeframeSheet;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final String accountFilterDisplay;
  final bool isAccountFiltered;
  final VoidCallback onOpenAccountSheet;

  const MonthSwitcher({
    super.key,
    required this.timeframe,
    required this.timeframeDisplay,
    required this.onOpenTimeframeSheet,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.accountFilterDisplay,
    required this.isAccountFiltered,
    required this.onOpenAccountSheet,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Timeframe / Month Selector Chip
          GestureDetector(
            onTap: onOpenTimeframeSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: timeframe != 'This Month'
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF334155),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: timeframe != 'This Month'
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeframeDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: timeframe != 'This Month'
                          ? Colors.white
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: Colors.white54),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Account Filter Chip
          GestureDetector(
            onTap: onOpenAccountSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAccountFiltered
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 16,
                    color: isAccountFiltered
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    accountFilterDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isAccountFiltered ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: Colors.white54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
