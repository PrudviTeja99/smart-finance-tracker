import 'package:finance_tracker/features/dashboard/logic/filter_logic.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel transaction({
  required int id,
  required DateTime date,
  required String type,
  required int accountId,
  int? toAccountId,
  required String description,
}) {
  return TransactionModel(
    id: id,
    title: description,
    body: description,
    amount: 100,
    type: type,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: 1,
    description: description,
    date: date,
    status: 'confirmed',
  );
}

void main() {
  final transactions = [
    transaction(
      id: 1,
      date: DateTime(2026, 8, 10),
      type: 'debit',
      accountId: 1,
      description: 'Coffee shop',
    ),
    transaction(
      id: 2,
      date: DateTime(2026, 8, 11),
      type: 'credit',
      accountId: 1,
      description: 'Salary',
    ),
    transaction(
      id: 3,
      date: DateTime(2026, 8, 12),
      type: 'transfer',
      accountId: 2,
      toAccountId: 1,
      description: 'Savings transfer',
    ),
  ];
  final august = DateRange(
    start: DateTime(2026, 8, 1),
    end: DateTime(2026, 8, 31, 23, 59, 59),
  );

  test('base date/account filter includes destination transfers', () {
    final base = FilterLogic.filterByDateAndAccount(
      allTransactions: transactions,
      dateRange: august,
      selectedAccountId: 1,
    );

    expect(base.map((tx) => tx.id), [1, 2, 3]);
  });

  test('type and search filters operate correctly on a cached base set', () {
    final base = FilterLogic.filterByDateAndAccount(
      allTransactions: transactions,
      dateRange: august,
      selectedAccountId: 1,
    );

    final debit = FilterLogic.filterByTypeAndSearch(
      transactions: base,
      typeFilter: 'debit',
      searchQuery: 'coffee',
    );
    final credit = FilterLogic.filterByTypeAndSearch(
      transactions: base,
      typeFilter: 'credit',
      searchQuery: '',
    );

    expect(debit.map((tx) => tx.id), [1]);
    expect(credit.map((tx) => tx.id), [2]);
  });

  test('composed filters retain the previous behavior', () {
    final composed = FilterLogic.applyFilters(
      allTransactions: transactions,
      dateRange: august,
      selectedAccountId: 1,
      typeFilter: 'debit',
      searchQuery: 'coffee',
    );
    final split = FilterLogic.filterByTypeAndSearch(
      transactions: FilterLogic.filterByDateAndAccount(
        allTransactions: transactions,
        dateRange: august,
        selectedAccountId: 1,
      ),
      typeFilter: 'debit',
      searchQuery: 'coffee',
    );

    expect(composed.map((tx) => tx.id), split.map((tx) => tx.id));
  });

  test('cached base totals retain income, expense, and transfer behavior', () {
    final base = FilterLogic.filterByDateAndAccount(
      allTransactions: transactions,
      dateRange: august,
      selectedAccountId: 1,
    );
    final totals = FilterLogic.calculateTotals(base);

    expect(totals.income, 100);
    expect(totals.expense, 100);
    expect(totals.netBalance, 0);
    expect(totals.savingsRate, 0);
  });
}
