import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:finance_tracker/services/batch_processor_service.dart';
import 'package:flutter/material.dart';

class BatchProgressBanner extends StatelessWidget {
  const BatchProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ValueListenableBuilder<BatchProgressState>(
      valueListenable: BatchProcessorService.instance.progressNotifier,
      builder: (context, state, child) {
        if (!state.isProcessing) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '⚡ ${strings.inboxProcessingBatch(state.totalCount)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '${state.processedCount}/${state.totalCount}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
