import 'package:finance_tracker/features/inbox/widgets/captured_alert_action_bottom_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/captured_alert_card.dart';
import 'captured_alerts_bottom_sheet.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CapturedAppGroupTile extends StatefulWidget {
  final String pkg;
  final String fallbackAppName;
  final List<Map<String, dynamic>> alertsList;
  final Widget leadingWidget;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapHeader;
  final VoidCallback? onLongPressHeader;
  final Future<void> Function(int, String, String, String, bool, bool) onFeedback;

  const CapturedAppGroupTile({
    super.key,
    required this.pkg,
    required this.fallbackAppName,
    required this.alertsList,
    required this.leadingWidget,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTapHeader,
    this.onLongPressHeader,
    required this.onFeedback,
  });

  @override
  State<CapturedAppGroupTile> createState() => _CapturedAppGroupTileState();
}

class _CapturedAppGroupTileState extends State<CapturedAppGroupTile> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withValues(alpha: 0.05),
            width: widget.isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.isSelectionMode) {
              widget.onTapHeader?.call();
              return;
            }

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CapturedAlertsBottomSheet(
                packageName: widget.pkg,
                appName: widget.fallbackAppName,
                leadingWidget: widget.leadingWidget,
                alerts: widget.alertsList,
                onFeedback: widget.onFeedback,
              ),
            );
          },
          onLongPress: widget.onLongPressHeader,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                widget.isSelectionMode
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isSelected
                                ? const Color(0xFF6366F1)
                                : Colors.white30,
                            width: 1.5,
                          ),
                        ),
                        child: widget.isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      )
                    : widget.leadingWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.fallbackAppName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    strings.inboxAlertCount(widget.alertsList.length),
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!widget.isSelectionMode) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                  ),
                ],
              ],
            ),
          ),
        ));
  }
}
