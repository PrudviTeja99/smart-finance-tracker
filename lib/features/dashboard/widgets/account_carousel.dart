import 'package:flutter/material.dart';
import '../../../models/account_model.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_formatters.dart';

class AccountCarousel extends StatelessWidget {
  final List<AccountModel> accounts;
  final int? selectedAccountId;
  final Function(AccountModel) onAccountTapped;
  final VoidCallback? onClearAccountFilter;
  final bool shouldHideAmounts;

  const AccountCarousel({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountTapped,
    this.onClearAccountFilter,
    required this.shouldHideAmounts,
  });

  IconData _getIcon(String type) {
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

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final totalBalance = accounts.fold(0.0, (sum, a) => sum + a.balance);
    final formattedTotal = AppFormatters.formatAmount(totalBalance, shouldHide: shouldHideAmounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accounts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Balance: $formattedTotal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              if (selectedAccountId != null && onClearAccountFilter != null)
                TextButton(
                  onPressed: onClearAccountFilter,
                  child: const Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isSelected = selectedAccountId == account.id;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () => onAccountTapped(account),
                  child: Container(
                    width: 145,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.white.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(_getIcon(account.type),
                                color: const Color(0xFF6366F1), size: 20),
                            Text(
                              account.type.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatAmount(account.balance, shouldHide: shouldHideAmounts),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: account.balance >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
