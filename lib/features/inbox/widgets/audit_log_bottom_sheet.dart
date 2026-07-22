import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showAuditLogBottomSheet({
  required BuildContext context,
  required Future<void> Function(Map<String, dynamic>) onUndo,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Header
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFF818CF8), size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'On-Device Learning Algorithm Decisions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: Color(0xFFEF4444), size: 24),
                    tooltip: 'Clear All',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear Audit Log?',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'This will clear the history of automatic decisions made by your learning algorithm.\n\n'
                            'Your learning progress and confirmed transactions will not be affected.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear All',
                                  style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await DatabaseService.instance
                            .deleteAllModelAuditLogs();
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppSnackBar.show(
                              context, 'Automatic decision log cleared.',
                              type: SnackBarType.neutral);
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Text(
                'Full transparency into automatic actions performed by your on-device learning algorithm.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseService.instance.getModelAuditLogs(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(Color(0xFF6366F1))));
                    }
                    final logs = snapshot.data!;
                    if (logs.isEmpty) {
                      return const Center(
                        child: Text('No automated decisions logged yet today.',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 13)),
                      );
                    }
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final action = log['action_type'] as String;
                        final appName = log['app_name'] as String? ?? 'App';
                        final title = log['title'] as String? ?? '';
                        final body = log['body'] as String? ?? '';
                        final confidence =
                            (log['confidence'] as num? ?? 0.85).toDouble();
                        final isDrafted = action == 'auto_drafted';

                        // Safely handle String, int (millis), or null values for date
                        final rawDate = log['date'] ??
                            log['created_at'] ??
                            log['timestamp'];
                        DateTime? date;

                        if (rawDate is int) {
                          date = DateTime.fromMillisecondsSinceEpoch(rawDate);
                        } else if (rawDate is String) {
                          date = DateTime.tryParse(rawDate) ??
                              (int.tryParse(rawDate) != null
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(rawDate))
                                  : null);
                        }

                        final formattedTime = date != null
                            ? DateFormat('dd MMM, hh:mm a').format(date)
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDrafted
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.3)
                                  : const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDrafted
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.15)
                                          : const Color(0xFF6366F1)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isDrafted
                                          ? 'AUTO-DRAFTED'
                                          : 'AUTO-DISMISSED',
                                      style: TextStyle(
                                        color: isDrafted
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF818CF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(appName,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Text(
                                    formattedTime.isNotEmpty
                                        ? formattedTime
                                        : 'Recent',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title.isNotEmpty ? '$title: $body' : body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(confidence * 100).toInt()}% Conf.',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      onUndo(log);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border:
                                            Border.all(color: Colors.white12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.undo_rounded,
                                              size: 14,
                                              color: Color(0xFF818CF8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            isDrafted
                                                ? 'Undo Auto-Draft'
                                                : 'Undo Auto-Dismiss',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      );
    },
  );
}

void showModelAuditLogSheet(BuildContext context) {}
