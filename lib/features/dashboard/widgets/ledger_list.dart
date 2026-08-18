import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/icon_helper.dart';

class LedgerItem extends StatelessWidget {
  final TransactionModel tx;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final bool shouldHideAmounts;
  final VoidCallback onTap;

  const LedgerItem({
    super.key,
    required this.tx,
    required this.accounts,
    required this.categories,
    required this.shouldHideAmounts,
    required this.onTap,
  });

  String _getAccountTypeDisplay(String type) {
    switch (type) {
      case 'bank':
        return 'Bank';
      case 'credit_card':
        return 'Card';
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Cash';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => categories.firstWhere(
        (c) => c.name.toLowerCase() == 'others',
        orElse: () => categories.first,
      ),
    );
    final account = accounts.firstWhere((a) => a.id == tx.accountId,
        orElse: () => accounts.first);

    Color textCol = const Color(0xFFEF4444); // Red for debit
    String sign = '-';
    if (tx.type == 'credit') {
      textCol = const Color(0xFF10B981); // Green for credit
      sign = '+';
    } else if (tx.type == 'transfer') {
      textCol = const Color(0xFF38BDF8); // Blue for transfer
      sign = '';
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(category.color).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconHelper.getIcon(category.icon),
                    color: Color(category.color), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          tx.type == 'transfer'
                              ? '${account.name} ➔ ${accounts.firstWhere((a) => a.id == tx.toAccountId, orElse: () => accounts.first).name}'
                              : account.name,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white38),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getAccountTypeDisplay(account.type),
                            style: const TextStyle(
                                fontSize: 8, color: Colors.white38),
                          ),
                        ),
                        if (tx.appName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tx.appName!,
                                style: const TextStyle(
                                    fontSize: 8, color: Colors.white38)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    shouldHideAmounts
                        ? '${AppSettings.currencySymbol}••••'
                        : '$sign${AppFormatters.formatAmount(tx.amount)}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(tx.date),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
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

class LedgerList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final bool shouldHideAmounts;
  final Function(TransactionModel) onTransactionTapped;

  const LedgerList({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.shouldHideAmounts,
    required this.onTransactionTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No transactions found for this period.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          return LedgerItem(
            tx: tx,
            accounts: accounts,
            categories: categories,
            shouldHideAmounts: shouldHideAmounts,
            onTap: () => onTransactionTapped(tx),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}
