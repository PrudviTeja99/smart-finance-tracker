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
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

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
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  State<PendingTransactionCard> createState() =>
      _PendingTransactionCardState();
}

class _PendingTransactionCardState extends State<PendingTransactionCard> {
  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere(
        (c) => c.id == widget.tx.categoryId,
        orElse: () => widget.categories.last);

    final selectedAccount = widget.accounts.firstWhere(
        (a) => a.id == widget.tx.accountId,
        orElse: () => widget.accounts.first);

    final typeColor = widget.tx.type == 'debit'
        ? const Color(0xFFEF4444)
        : (widget.tx.type == 'credit'
            ? const Color(0xFF10B981)
            : const Color(0xFF38BDF8));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      color: widget.isSelected
          ? const Color(0xFF6366F1).withValues(alpha: 0.12)
          : const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: widget.isSelected
              ? const Color(0xFF6366F1)
              : Colors.white.withValues(alpha: 0.06),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: App Pill + Title + Date + Selection Check / Discard Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.tx.appName ?? 'INTERCEPTED',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF818CF8),
                        fontWeight: FontWeight.bold,
                      ),
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
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(widget.tx.date),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                  const SizedBox(width: 6),
                  widget.isSelectionMode
                      ? Icon(
                          widget.isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: widget.isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.white38,
                        )
                      : InkWell(
                          onTap: () => widget.onDiscard(widget.tx.id!),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded,
                                color: Colors.white38, size: 18),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 10),
              // Body Message Text
              Text(
                widget.tx.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35),
              ),
              const SizedBox(height: 12),
              // Footer Row: Amount + Type Badge + Account Chip + Category Chip
              Row(
                children: [
                  Text(
                    '${AppSettings.currencySymbol}${widget.tx.amount.toStringAsFixed(widget.tx.amount % 1 == 0 ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.tx.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedAccount.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedCategory.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ),
                        ),
                      ],
                    ),
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
