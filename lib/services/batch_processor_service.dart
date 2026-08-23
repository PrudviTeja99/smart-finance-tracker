import 'package:flutter/foundation.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'database_service.dart';
import 'notification_handler.dart';

class BatchProgressState {
  final bool isProcessing;
  final int totalCount;
  final int processedCount;

  BatchProgressState({
    required this.isProcessing,
    required this.totalCount,
    required this.processedCount,
  });

  double get progress => totalCount > 0 ? (processedCount / totalCount).clamp(0.0, 1.0) : 0.0;
}

/// Service to batch-process queued background notifications on app launch/resume
class BatchProcessorService {
  BatchProcessorService._privateConstructor();
  static final BatchProcessorService instance = BatchProcessorService._privateConstructor();

  final ValueNotifier<BatchProgressState> progressNotifier = ValueNotifier(
    BatchProgressState(isProcessing: false, totalCount: 0, processedCount: 0),
  );

  bool _isBatchRunning = false;
  bool _rerunRequested = false;

  /// Triggered on App Startup or Resume to process buffered raw notifications
  Future<void> processQueue({Function()? onCompleted}) async {
    // A notification can arrive while an existing batch is running.  Do not
    // lose that refresh request: drain the queue once more after the current
    // snapshot has completed.
    if (_isBatchRunning) {
      _rerunRequested = true;
      return;
    }
    _isBatchRunning = true;

    try {
      final dbService = DatabaseService.instance;
      do {
        _rerunRequested = false;
        final pendingRaw = await dbService.getPendingRawNotifications();

        if (pendingRaw.isEmpty) {
          continue;
        }

        final total = pendingRaw.length;
        progressNotifier.value = BatchProgressState(
          isProcessing: true,
          totalCount: total,
          processedCount: 0,
        );

        for (int i = 0; i < total; i++) {
          final rawItem = pendingRaw[i];
          final rawId = rawItem['id'] as int;
          final pkg = rawItem['package_name'] as String;
          final title = rawItem['title'] as String? ?? '';
          final body = rawItem['body'] as String;

          // Mark as processed immediately to claim the raw item and prevent duplicate processing
          await dbService.markRawNotificationsProcessed([rawId]);

          // Process notification via full 7-field prefill & Perceptron engine
          final mockEvent = NotificationEvent(
            packageName: pkg,
            title: title,
            text: body,
            timestamp: rawItem['timestamp'] as int?,
          );

          try {
            final result =
                await NotificationHandler.handleNotificationEvent(mockEvent);

            if (result == "error") {
              // Revert status to pending so it can be retried on next batch
              await dbService.markRawNotificationPending(rawId);
            }
          } catch (e, st) {
            debugPrint("Failed processing raw notification $rawId");
            debugPrint("$e");
            debugPrintStack(stackTrace: st);

            // Revert status to pending for retry
            await dbService.markRawNotificationPending(rawId);
          }

          progressNotifier.value = BatchProgressState(
            isProcessing: true,
            totalCount: total,
            processedCount: i + 1,
          );

          // Yield execution briefly to keep UI responsive
          if ((i + 1) % 5 == 0) {
            await Future.delayed(
              const Duration(milliseconds: 5),
            );
          }
        }

        progressNotifier.value = BatchProgressState(
          isProcessing: false,
          totalCount: total,
          processedCount: total,
        );
      } while (_rerunRequested);

      onCompleted?.call();
    } catch (e) {
      debugPrint('Batch processing error: $e');
    } finally {
      _isBatchRunning = false;
      progressNotifier.value = BatchProgressState(isProcessing: false, totalCount: 0, processedCount: 0);
    }
  }
}
