import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../models/account_model.dart';
import '../../../utils/app_formatters.dart';

Future<void> showAccountFilterSheet({
  required BuildContext context,
  required List<AccountModel> accounts,
  required int? selectedAccountId,
  required Function(int? accountId) onSelectAccount,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final strings = AppLocalizations.of(context)!;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  strings.accountFilterTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // All Accounts Option
              InkWell(
                onTap: () {
                  onSelectAccount(null);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apps_rounded,
                              color: Color(0xFF6366F1), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            strings.transactionsAllAccounts,
                            style: TextStyle(
                              color: selectedAccountId == null
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 15,
                              fontWeight: selectedAccountId == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Radio<int?>(
                        value: null,
                        groupValue: selectedAccountId,
                        activeColor: const Color(0xFF6366F1),
                        onChanged: (_) {
                          onSelectAccount(null);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Divider(color: Colors.white10),
              ),

              // Individual Account Options
              ...accounts.map((account) {
                final isSelected = selectedAccountId == account.id;

                IconData getIcon(String type) {
                  switch (type) {
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
                    onSelectAccount(account.id);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(getIcon(account.type),
                                color: const Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.formatAmount(account.balance),
                                  style: TextStyle(
                                    color: account.balance >= 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Radio<int?>(
                          value: account.id,
                          groupValue: selectedAccountId,
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (_) {
                            onSelectAccount(account.id);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
