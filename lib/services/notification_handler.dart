import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'database_service.dart';
import 'perceptron_storage_service.dart';
import '../services/developer/log_service.dart';
import '../utils/transaction_parser.dart';
import '../utils/app_settings.dart';

@pragma('vm:entry-point')
class NotificationHandler {
  static const String portName = 'notification_receiver_port';
  static ReceivePort? _receivePort;

  // Initialize the notification listener service in the foreground UI
  static Future<void> init(Function() onRefreshRequested) async {
    _receivePort = ReceivePort();

    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);

    _receivePort!.listen((message) {
      if (message == "refresh") {
        onRefreshRequested();
      }
    });

    // Request permissions and start
    await NotificationsListener.initialize(
      callbackHandle: _onNotificationCallback,
    );
  }

  static Future<bool> isServiceRunning() async {
    return await NotificationsListener.isRunning ?? false;
  }

  static Future<void> startService() async {
    await NotificationsListener.startService(
      foreground: false,
    );
  }

  static Future<void> stopService() async {
    await NotificationsListener.stopService();
  }

  static Future<bool> hasPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  static Future<void> openPermissionSettings() async {
    await NotificationsListener.openPermissionSettings();
  }

  static Future<void> openAppSystemSettings() async {
    try {
      await const MethodChannel('com.example.finance_tracker/app_info')
          .invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Failed to open app system settings: $e');
    }
  }

  static Future<void> requestBatteryExemption() async {
    try {
      await const MethodChannel('com.example.finance_tracker/app_info')
          .invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('Failed to request battery exemption: $e');
    }
  }

  // Background entry point for the notification service (runs in a separate isolate)
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCallback(NotificationEvent event) async {
    // Required for background isolates — without this, plugin channel calls
    // (like sqflite) can silently fail and the notification gets dropped.
    WidgetsFlutterBinding.ensureInitialized();

    if (event.packageName == null) return;

    final title = event.title ?? '';
    final text = event.text ?? '';
    final body = text.isNotEmpty ? text : title;

    if (body.trim().isEmpty) return;

    try {
      // Awaited now — the isolate must not be allowed to die before this completes.
      await DatabaseService.instance.insertRawNotification(
        packageName: event.packageName!,
        title: title,
        body: body,
        timestamp: event.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
      LogService.logFromAnyIsolate(
          '✅ Queued raw notification from ${event.packageName}');
    } catch (e, st) {
      LogService.logFromAnyIsolate(
          '⚠️ Failed to queue background notification: $e\n$st');
      return; // don't attempt to notify UI if the write itself failed
    }

    // Notify the foreground UI (if the app is open) so it can process immediately
    final sendPort = IsolateNameServer.lookupPortByName(portName);
    if (sendPort != null) {
      sendPort.send("refresh");
    }
  }

  // Public entry point to process a notification event from either the OS listener or UI simulator
  static Future<String> handleNotificationEvent(NotificationEvent event) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (event.packageName == null) return 'invalid';

    final title = event.title ?? '';
    final text = event.text ?? '';
    final body = text.isNotEmpty ? text : title;

    if (body.trim().isEmpty) {
      return 'invalid';
    }

    final dbService = DatabaseService.instance;
    final appName = _getAppNameFromPackage(event.packageName!);

    try {
      // 1. Log every incoming notification into notification_logs
      final logId = await dbService.insertNotificationLog(
        appName: appName,
        packageName: event.packageName!,
        title: title,
        body: body,
        date: DateTime.now(),
        status: 'unclassified',
      );

      // Load Settings and Perceptron weights in background isolate to get latest mutedApps & AI weights
      await AppSettings.load();
      await PerceptronStorageService.instance.loadWeights();

      // 2. Check if the App is Muted
      if (AppSettings.mutedApps.contains(event.packageName!)) {
        await dbService.updateNotificationLogStatus(logId, 'archived');
        return 'archived';
      }

      // 3. Rule-based Pre-filter for non-financial ignore-keywords & promotional marketing
      final cleanBody = body.toLowerCase();
      final ignoreKeywords = [
        'balance',
        'bal',
        'available limit',
        'otp',
        'verification code',
        'security code',
        'login'
      ];
      final promoKeywords = [
        '50% off',
        '% off',
        'discount',
        'cashback offer',
        'use code',
        'upgrade your',
        'subscription',
        'newsletter',
        'flash sale',
        'exclusive offer',
        'promo'
      ];

      bool isIgnore = false;
      String archiveReason = 'auto_archived';
      double archiveConfidence = 0.90;

      for (var kw in ignoreKeywords) {
        if (cleanBody.contains(kw)) {
          isIgnore = true;
          archiveConfidence = 0.95;
          break;
        }
      }

      if (!isIgnore) {
        for (var kw in promoKeywords) {
          if (cleanBody.contains(kw)) {
            isIgnore = true;
            archiveConfidence = 0.88;
            break;
          }
        }
      }

      // Tier 2: Auto-Archive (High Confidence Non-Transaction / Promo)
      if (isIgnore) {
        await dbService.updateNotificationLogStatus(logId, 'archived');
        await dbService.insertModelAuditLog(
          actionType: archiveReason,
          appName: appName,
          packageName: event.packageName!,
          title: title,
          body: body,
          confidence: archiveConfidence,
          logId: logId,
        );

        LogService.logFromAnyIsolate(
            '🗄️ Auto-archived ($archiveReason): $appName — "$body"');

        return 'archived';
      }

      // 4. Tier 1: Auto-Draft (High Confidence Transaction >= 85%)
      final parser = TransactionParser();
      final tx = await parser.parseNotification(
        appName: appName,
        title: title,
        body: body,
      );

      if (tx != null && tx.amount > 0.0) {
        final result = await dbService.insertTransaction(tx);

        if (result != -1) {
          // Mark notification log as drafted (auto-promoted to Inbox)
          await dbService.updateNotificationLogStatus(logId, 'drafted');
          await dbService.insertModelAuditLog(
            actionType: 'auto_drafted',
            appName: appName,
            packageName: event.packageName!,
            title: title,
            body: body,
            confidence: 0.92,
            logId: logId,
          );

          LogService.logFromAnyIsolate(
              '📝 Auto-drafted transaction: $appName — ₹${tx.amount} (${tx.type})');

          return 'drafted';
        } else {
          LogService.logFromAnyIsolate(
              '⚠️ Duplicate transaction detected, skipped: $appName — ₹${tx.amount}');
        }
      }

      // 5. Tier 3: Captured Alerts Review (Uncertain Score < 85%)
      // Notification remains as 'unclassified' in Captured Alerts for 1-tap user guidance
      LogService.logFromAnyIsolate(
          '❓ Left unclassified for review: $appName — "$body"');
      return 'unclassified';
    } catch (e) {
      LogService.logFromAnyIsolate(
          '❌ Background notification processing error: $e');
      return 'error';
    }
  }

  // Helper to map package names to readable display names
  static String _getAppNameFromPackage(String package) {
    if (package.contains('messaging') ||
        package.contains('android.apps.messaging') ||
        package.contains('samsung.android.messaging')) {
      return 'SMS';
    } else if (package.contains('phonepe')) {
      return 'PhonePe';
    } else if (package.contains('google.android.apps.nbu.paisa')) {
      return 'Google Pay';
    } else if (package.contains('paytm')) {
      return 'Paytm';
    } else if (package.contains('whatsapp')) {
      return 'WhatsApp';
    } else {
      return formatPackageNameFallback(package);
    }
  }

  /// Intelligently formats package names like 'com.instagram.android' -> 'Instagram'
  static String formatPackageNameFallback(String package) {
    final parts = package.split('.');
    final ignored = {
      'com',
      'org',
      'net',
      'gov',
      'edu',
      'android',
      'app',
      'apps',
      'mobile',
      'lite',
      'client',
      'main',
      'service',
      'ui',
      'in',
      'us',
      'uk'
    };

    // Find the first meaningful word from the end that isn't ignored
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].toLowerCase();
      if (!ignored.contains(part) && part.length > 1) {
        return part[0].toUpperCase() + part.substring(1);
      }
    }

    // Ultimate fallback
    final last = parts.last;
    return last.isNotEmpty
        ? last[0].toUpperCase() + last.substring(1)
        : package;
  }
}
