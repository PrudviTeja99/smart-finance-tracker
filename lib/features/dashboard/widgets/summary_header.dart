import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SummaryHeader extends StatelessWidget {
  final bool obscureAmounts;
  final VoidCallback onTogglePrivacy;
  final bool isTimerActive;
  final int remainingSeconds;
  final VoidCallback onCancelTimer;

  const SummaryHeader({
    super.key,
    required this.obscureAmounts,
    required this.onTogglePrivacy,
    required this.isTimerActive,
    required this.remainingSeconds,
    required this.onCancelTimer,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            strings.dashboardOverviewTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (isTimerActive) ...[
          Tooltip(
            message: strings.dashboardLockClockTooltip,
            child: InkWell(
              onTap: onCancelTimer,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_clock, size: 14),
                    const SizedBox(width: 4),
                    Text('${remainingSeconds}s'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: onTogglePrivacy,
          icon: Icon(
            obscureAmounts
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
        ),
      ],
    );
  }
}
