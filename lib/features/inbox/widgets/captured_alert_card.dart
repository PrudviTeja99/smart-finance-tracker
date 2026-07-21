import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CapturedAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Function(int, String, String, String, bool, bool) onFeedback;
  final Function(String, int, String) onMute;

  const CapturedAlertCard({
    super.key,
    required this.alert,
    required this.onFeedback,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final logId = alert['id'] as int;
    final appName = alert['app_name'] as String? ?? 'Unknown';
    final title = alert['title'] as String? ?? '';
    final body = alert['body'] as String? ?? '';
    final dateStr = alert['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final formattedDate =
        date != null ? DateFormat('dd MMM, hh:mm a').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp & Badge Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Body
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            body,
            style: const TextStyle(
                fontSize: 12, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),

          // 1-Tap Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_chart_rounded, size: 15),
                  label: const Text('Track Transaction',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () {
                    onFeedback(logId, appName, title, body, true, true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.block_rounded, size: 15),
                  label: const Text('Ignore',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    onFeedback(logId, appName, title, body, false, false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
