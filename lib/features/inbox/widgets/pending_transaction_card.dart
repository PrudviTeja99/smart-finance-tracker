import 'package:finance_tracker/models/account_model.dart';
import 'package:finance_tracker/models/category_model.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/utils/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingTransactionCard extends StatefulWidget {
  final TransactionModel tx;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final Function(TransactionModel, String) onConfirm;
  final Function(int) onDiscard;
  final Function(int, String) onOnlineLookup;
  final bool isLookupLoading;
  final List<String> suggestions;

  final VoidCallback? onTap;

  const PendingTransactionCard({
    super.key,
    required this.tx,
    required this.accounts,
    required this.categories,
    required this.onConfirm,
    required this.onDiscard,
    required this.onOnlineLookup,
    required this.isLookupLoading,
    required this.suggestions,
    this.onTap,
  });

  @override
  State<PendingTransactionCard> createState() => _PendingTransactionCardState();
}

class _PendingTransactionCardState extends State<PendingTransactionCard> {
  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere(
        (c) => c.id == widget.tx.categoryId,
        orElse: () => widget.categories.last);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.04)),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.tx.appName ?? 'INTERCEPTED',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tx.title.isNotEmpty
                                ? widget.tx.title
                                : 'SMS notification',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white38, size: 20),
                        onPressed: () => widget.onDiscard(widget.tx.id!),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.tx.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${AppSettings.currencySymbol}${widget.tx.amount}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.tx.type == 'debit'
                          ? const Color(0xFFEF4444).withOpacity(0.15)
                          : const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.tx.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: widget.tx.type == 'debit'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${widget.accounts.firstWhere((a) => a.id == widget.tx.accountId, orElse: () => widget.accounts.first).name}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${selectedCategory.name}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(widget.tx.date),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
