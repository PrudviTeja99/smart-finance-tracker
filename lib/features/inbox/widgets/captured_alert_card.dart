import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CapturedAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  const CapturedAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = alert['title'] as String? ?? '';
    final body = alert['body'] as String? ?? '';
    final dateStr = alert['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final formattedDate =
        date != null ? DateFormat('dd MMM, hh:mm a').format(date) : '';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.white10,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp & Chevron
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white38,
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (title.isNotEmpty) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],

            Text(
              body,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
