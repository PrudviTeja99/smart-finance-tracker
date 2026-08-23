import 'package:flutter/material.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_formatters.dart';
import '../../../l10n/app_localizations.dart';

class HeroCard extends StatelessWidget {
  final double netBalance;
  final double totalIncome;
  final double totalExpense;
  final double savingsRate;
  final bool shouldHideAmounts;
  final String? timeframeDisplay;

  const HeroCard({
    super.key,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsRate,
    required this.shouldHideAmounts,
    this.timeframeDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final isPositive = netBalance >= 0;
    final badgeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final badgeLabel = isPositive
        ? '+${savingsRate.toStringAsFixed(0)}% saved'
        : '${savingsRate.toStringAsFixed(0)}% overspent';

    final String titleText = timeframeDisplay != null && timeframeDisplay!.isNotEmpty
        ? 'NET CASHFLOW • ${timeframeDisplay!.toUpperCase()}'
        : 'NET CASHFLOW';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormatters.formatAmount(netBalance, shouldHide: shouldHideAmounts),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.white : const Color(0xFFF87171),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_circle_outline_rounded,
                            color: Color(0xFF10B981), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.dashboardIncome,
                              style:
                                  TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatAmount(totalIncome, shouldHide: shouldHideAmounts),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_circle_outline_rounded,
                            color: Color(0xFFEF4444), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.dashboardExpenses,
                              style:
                                  TextStyle(fontSize: 11, color: Colors.white54)),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatAmount(totalExpense, shouldHide: shouldHideAmounts),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
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
