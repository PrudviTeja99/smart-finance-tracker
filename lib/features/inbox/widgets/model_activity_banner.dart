import 'package:finance_tracker/services/database_service.dart';
import 'package:flutter/material.dart';

class ModelActivityBanner extends StatelessWidget {
  const ModelActivityBanner({
    super.key,
    required this.onViewLogPressed,
  });

  final VoidCallback onViewLogPressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: DatabaseService.instance.getDailyAuditCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};
        final drafted = counts['auto_drafted'] ?? 0;
        final archived = counts['auto_archived'] ?? 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s Automated Decisions: Auto-drafted $drafted, Auto-dismissed $archived',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              GestureDetector(
                onTap: onViewLogPressed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'View Log',
                    style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
