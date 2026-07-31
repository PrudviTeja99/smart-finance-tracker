import 'package:finance_tracker/features/inbox/widgets/captured_alert_action_bottom_sheet.dart';
import 'package:finance_tracker/features/inbox/widgets/captured_alert_card.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/utils/transaction_parser.dart';
import 'package:finance_tracker/utils/app_snackbar.dart';
import 'package:flutter/material.dart';

class CapturedAlertsBottomSheet extends StatefulWidget {
  final String packageName;
  final String appName;
  final Widget leadingWidget;
  final List<Map<String, dynamic>> alerts;

  final Future<void> Function(int, String, String, String, bool, bool)
      onFeedback;

  const CapturedAlertsBottomSheet({
    super.key,
    required this.packageName,
    required this.appName,
    required this.leadingWidget,
    required this.alerts,
    required this.onFeedback,
  });

  @override
  State<CapturedAlertsBottomSheet> createState() =>
      _CapturedAlertsBottomSheetState();
}

class _CapturedAlertsBottomSheetState extends State<CapturedAlertsBottomSheet> {
  late List<Map<String, dynamic>> _localAlerts;
  bool _isSelectionMode = false;
  final Set<int> _selectedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _localAlerts = List.from(widget.alerts);
  }

  Future<void> _archiveSelectedAlerts() async {
    if (_selectedAlertIds.isEmpty) return;

    final count = _selectedAlertIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Selected Alerts?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to clear $count selected alerts? They will be moved to your Archived Alerts feed.',
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(
                    color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dbService = DatabaseService.instance;
      final parser = TransactionParser();
      final alertsToArchive = List<int>.from(_selectedAlertIds);

      for (var id in alertsToArchive) {
        final alert = _localAlerts.firstWhere((item) => item['id'] == id);
        final body = alert['body'] as String? ?? '';
        await dbService.updateNotificationLogStatus(id, 'archived');
        await parser.trainType(body, 'ignore');
      }

      if (mounted) {
        setState(() {
          _localAlerts
              .removeWhere((item) => alertsToArchive.contains(item['id']));
          _isSelectionMode = false;
          _selectedAlertIds.clear();
        });

        if (alertsToArchive.isNotEmpty) {
          final lastAlert = _localAlerts.isEmpty
              ? {'title': '', 'body': ''}
              : _localAlerts.first;
          await widget.onFeedback(
            alertsToArchive.last,
            widget.appName,
            lastAlert['title'] ?? '',
            lastAlert['body'] ?? '',
            false,
            false,
          );
        }

        if (_localAlerts.isEmpty) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _reviewSelectedAlertsAsTransactions() async {
    if (_selectedAlertIds.isEmpty) return;

    final count = _selectedAlertIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Review Selected Alerts?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to promote $count selected alerts into draft transactions?',
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Review',
                style: TextStyle(
                    color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final alertsToReview = List<int>.from(_selectedAlertIds);
    int createdCount = 0;

    for (var id in alertsToReview) {
      final matching = _localAlerts.where((item) => item['id'] == id).toList();
      if (matching.isNotEmpty) {
        final alert = matching.first;
        final body = alert['body'] as String? ?? '';
        final title = alert['title'] as String? ?? '';

        await widget.onFeedback(
          id,
          widget.appName,
          title,
          body,
          true, // isFinancial
          true, // isRelevant
        );
        createdCount++;
      }
    }

    if (mounted) {
      setState(() {
        _localAlerts
            .removeWhere((item) => alertsToReview.contains(item['id']));
        _isSelectionMode = false;
        _selectedAlertIds.clear();
      });

      AppSnackBar.show(
        context,
        'Promoted $createdCount alerts to draft transactions!',
        type: SnackBarType.success,
      );

      if (_localAlerts.isEmpty) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _archiveAllAlerts() async {
    if (_localAlerts.isEmpty) return;

    final count = _localAlerts.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Alerts?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to clear all $count alerts for "${widget.appName}"? They will be moved to your Archived Alerts feed.',
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All',
                style: TextStyle(
                    color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dbService = DatabaseService.instance;
      final parser = TransactionParser();
      final alertsToArchive =
          _localAlerts.map((item) => item['id'] as int).toList();

      for (var id in alertsToArchive) {
        final alert = _localAlerts.firstWhere((item) => item['id'] == id);
        final body = alert['body'] as String? ?? '';
        await dbService.updateNotificationLogStatus(id, 'archived');
        await parser.trainType(body, 'ignore');
      }

      if (mounted) {
        setState(() {
          _localAlerts.clear();
          _isSelectionMode = false;
          _selectedAlertIds.clear();
        });

        if (alertsToArchive.isNotEmpty) {
          await widget.onFeedback(
            alertsToArchive.last,
            widget.appName,
            '',
            '',
            false,
            false,
          );
        }

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedAlertIds.clear();
          });
        }
      },
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border:
                  Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isSelectionMode
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedAlertIds.clear();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedAlertIds.length} Selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded,
                                  color: Color(0xFF818CF8)),
                              tooltip: 'Promote Selected to Drafts',
                              onPressed: _reviewSelectedAlertsAsTransactions,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  color: Color(0xFFEF4444)),
                              tooltip: 'Clear Selected Alerts',
                              onPressed: _archiveSelectedAlerts,
                            ),
                          ],
                        )
                      : Row(
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
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.3),
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
                            IconButton(
                              icon: const Icon(Icons.checklist_rounded,
                                  color: Colors.white70),
                              tooltip: 'Select Alerts to Clear',
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedAlertIds.clear();
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Clear All Alerts',
                              onPressed: _archiveAllAlerts,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _localAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _localAlerts[index];
                      final alertId = alert['id'] as int;
                      final isSelected = _selectedAlertIds.contains(alertId);

                      return CapturedAlertCard(
                        key: ValueKey(alertId),
                        alert: alert,
                        isSelectionMode: _isSelectionMode,
                        isSelected: isSelected,
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedAlertIds.remove(alertId);
                              } else {
                                _selectedAlertIds.add(alertId);
                              }
                            });
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CapturedAlertActionBottomSheet(
                                alert: alert,
                                onFeedback: (logId, appName, title, body,
                                    isFinancial, isRelevant) async {
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
                                      _localAlerts.removeWhere(
                                          (item) => item['id'] == logId);
                                    });
                                    if (_localAlerts.isEmpty) {
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedAlertIds.clear();
                              _selectedAlertIds.add(alertId);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
