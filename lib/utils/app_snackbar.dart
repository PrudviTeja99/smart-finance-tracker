import 'package:flutter/material.dart';
import 'package:finance_tracker/utils/app_settings.dart';

enum SnackBarType { success, error, info, warning, neutral }

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFEF4444);
        icon = Icons.error_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF6366F1);
        icon = Icons.info_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.neutral:
        backgroundColor = const Color(0xFF334155);
        icon = Icons.notifications_off_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(milliseconds: AppSettings.snackBarDurationMs),
      ),
    );
  }
}
