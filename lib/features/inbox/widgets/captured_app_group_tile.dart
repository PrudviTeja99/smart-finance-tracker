import 'package:finance_tracker/features/inbox/widgets/captured_alert_card.dart';
import 'package:flutter/material.dart';

class CapturedAppGroupTile extends StatefulWidget {
  final String pkg;
  final String fallbackAppName;
  final List<Map<String, dynamic>> alertsList;
  final Widget leadingWidget;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapHeader;
  final VoidCallback? onLongPressHeader;
  final Function(int, String, String, String, bool, bool) onFeedback;
  final Function(String, int, String) onMute;
  final Function(String, String, List<Map<String, dynamic>>) onMuteEntireApp;

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
    required this.onMute,
    required this.onMuteEntireApp,
  });

  @override
  State<CapturedAppGroupTile> createState() => _CapturedAppGroupTileState();
}

class _CapturedAppGroupTileState extends State<CapturedAppGroupTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? const Color(0xFF6366F1)
              : const Color(0xFF334155),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: widget.onLongPressHeader,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: false,
          onExpansionChanged: (expanded) {
            if (widget.isSelectionMode) {
              if (widget.onTapHeader != null) widget.onTapHeader!();
            } else {
              setState(() {
                _isExpanded = expanded;
              });
            }
          },
          leading: widget.isSelectionMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(2),
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
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color:
                        widget.isSelected ? Colors.white : Colors.transparent,
                  ),
                )
              : widget.leadingWidget,
          title: Text(
            widget.fallbackAppName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.alertsList.length} ${widget.alertsList.length == 1 ? "Alert" : "Alerts"}',
                  style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (!widget.isSelectionMode) ...[
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.volume_off_rounded,
                      color: Colors.white38, size: 18),
                  tooltip: 'Mute ${widget.fallbackAppName}',
                  onPressed: () => widget.onMuteEntireApp(
                      widget.pkg, widget.fallbackAppName, widget.alertsList),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: Colors.white30),
                ),
              ],
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: widget.alertsList.map((alert) {
            return CapturedAlertCard(
              key: ValueKey(alert['id']),
              alert: alert,
              onFeedback: widget.onFeedback,
              onMute: widget.onMute,
            );
          }).toList(),
        ),
      ),
    );
  }
}
