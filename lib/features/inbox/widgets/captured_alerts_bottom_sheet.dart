import 'package:finance_tracker/features/inbox/widgets/captured_alert_action_bottom_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/captured_alert_card.dart';
import 'package:flutter/material.dart';

class CapturedAlertsBottomSheet extends StatefulWidget {
  final String packageName;
  final String appName;
  final Widget leadingWidget;
  final List<Map<String, dynamic>> alerts;

  final Future<void> Function(int, String, String, String, bool, bool) onFeedback;

  const CapturedAlertsBottomSheet({
    super.key,
    required this.packageName,
    required this.appName,
    required this.leadingWidget,
    required this.alerts,
    required this.onFeedback,
  });

  @override
  State<CapturedAlertsBottomSheet> createState() => _CapturedAlertsBottomSheetState();
}

class _CapturedAlertsBottomSheetState extends State<CapturedAlertsBottomSheet> {
  late List<Map<String, dynamic>> _localAlerts;

  @override
  void initState() {
    super.initState();
    _localAlerts = List.from(widget.alerts);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.90,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    widget.leadingWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.appName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${_localAlerts.length} ${_localAlerts.length == 1 ? "Alert" : "Alerts"}',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _localAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _localAlerts[index];

                    return CapturedAlertCard(
                      key: ValueKey(alert['id']),
                      alert: alert,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CapturedAlertActionBottomSheet(
                            alert: alert,
                            onFeedback: (logId, appName, title, body, isFinancial, isRelevant) async {
                              await widget.onFeedback(
                                logId,
                                appName,
                                title,
                                body,
                                isFinancial,
                                isRelevant,
                              );
                              if (mounted) {
                                setState(() {
                                  _localAlerts.removeWhere((item) => item['id'] == logId);
                                });
                                if (_localAlerts.isEmpty) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
