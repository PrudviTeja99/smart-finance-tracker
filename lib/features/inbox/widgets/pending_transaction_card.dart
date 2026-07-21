import 'package:finance_tracker/models/account_model.dart';
import 'package:finance_tracker/models/category_model.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/screens/dashboard_screen.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/utils/app_settings.dart';
import 'package:finance_tracker/utils/app_snackbar.dart';
import 'package:finance_tracker/utils/icon_helper.dart';
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
    final selectedAcc = widget.accounts.firstWhere(
        (a) => a.id == widget.tx.accountId,
        orElse: () => widget.accounts.first);
    final selectedToAcc =
        widget.tx.type == 'transfer' && widget.tx.accountId != null
            ? widget.accounts.firstWhere((a) => a.id == widget.tx.accountId,
                orElse: () => widget.accounts.first)
            : null;

    IconData getAccountIcon(String t) {
      switch (t) {
        case 'bank':
          return Icons.account_balance;
        case 'credit_card':
          return Icons.credit_card;
        case 'wallet':
          return Icons.account_balance_wallet;
        default:
          return Icons.money;
      }
    }

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

  void _showCategoryPicker(int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.categories.length <= 4 ? 0.55 : 0.75;
    final double minFraction = 0.40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final cat = widget.categories[index];
                        final isSelected = cat.id == currentSelected;
                        return InkWell(
                          onTap: () {
                            onSelected(cat.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(cat.color).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconHelper.getIcon(cat.icon),
                                    color: Color(cat.color),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccountPicker(
      String pickerTitle, int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.accounts.length <= 3 ? 0.55 : 0.75;
    final double minFraction = 0.40;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    pickerTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.accounts.length,
                      itemBuilder: (context, index) {
                        final acc = widget.accounts[index];
                        final isSelected = acc.id == currentSelected;
                        IconData getIcon(String t) {
                          switch (t) {
                            case 'bank':
                              return Icons.account_balance;
                            case 'credit_card':
                              return Icons.credit_card;
                            case 'wallet':
                              return Icons.account_balance_wallet;
                            default:
                              return Icons.money;
                          }
                        }

                        return InkWell(
                          onTap: () {
                            onSelected(acc.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    getIcon(acc.type),
                                    color: const Color(0xFF6366F1),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Balance: ${AppSettings.currencySymbol}${acc.balance.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniTypePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
