import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class DateRange {
  final DateTime start;
  final DateTime end;
  final String customLabel;

  const DateRange({
    required this.start,
    required this.end,
    this.customLabel = '',
  });
}

class DashboardTotals {
  final double income;
  final double expense;
  final double netBalance;
  final double savingsRate; // Percentage (e.g. 38.5 for 38.5%)

  const DashboardTotals({
    required this.income,
    required this.expense,
    required this.netBalance,
    required this.savingsRate,
  });
}

class FilterLogic {
  static DateRange getDateRange(
    String timeframe,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    String customLabel = '';

    if (timeframe == 'Today') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (timeframe == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      start = DateTime(yest.year, yest.month, yest.day);
      end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
    } else if (timeframe == 'This Week') {
      final weekday = now.weekday;
      final startOffset = weekday - 1;
      final tempStart = now.subtract(Duration(days: startOffset));
      start = DateTime(tempStart.year, tempStart.month, tempStart.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (timeframe == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (timeframe == 'This Year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
    } else if (timeframe == 'Custom' && startDate != null && endDate != null) {
      start = startDate;
      end = endDate;
      final df = DateFormat('dd MMM');
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        customLabel = df.format(start);
      } else if (start.day == 1 &&
          end.day == DateTime(end.year, end.month + 1, 0).day &&
          start.month == end.month &&
          start.year == end.year) {
        customLabel = DateFormat('MMM yyyy').format(start);
      } else {
        customLabel = '${df.format(start)} - ${df.format(end)}';
      }
    }

    return DateRange(start: start, end: end, customLabel: customLabel);
  }

  static List<TransactionModel> applyFilters({
    required List<TransactionModel> allTransactions,
    required DateRange dateRange,
    required int? selectedAccountId,
    required String typeFilter, // 'all', 'debit', 'credit', 'transfer'
    required String searchQuery,
  }) {
    final filteredByDateAndAccount = filterByDateAndAccount(
      allTransactions: allTransactions,
      dateRange: dateRange,
      selectedAccountId: selectedAccountId,
    );

    return filterByTypeAndSearch(
      transactions: filteredByDateAndAccount,
      typeFilter: typeFilter,
      searchQuery: searchQuery,
    );
  }

  static List<TransactionModel> filterByDateAndAccount({
    required List<TransactionModel> allTransactions,
    required DateRange dateRange,
    required int? selectedAccountId,
  }) {
    return allTransactions.where((tx) {
      final isWithinDates =
          tx.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
              tx.date.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      final matchesAccount = selectedAccountId == null ||
          tx.accountId == selectedAccountId ||
          tx.toAccountId == selectedAccountId;
      return isWithinDates && matchesAccount;
    }).toList(growable: false);
  }

  static List<TransactionModel> filterByTypeAndSearch({
    required List<TransactionModel> transactions,
    required String typeFilter,
    required String searchQuery,
  }) {
    final filteredByType = transactions.where((tx) {
      if (typeFilter == 'debit') return tx.type == 'debit';
      if (typeFilter == 'credit') return tx.type == 'credit';
      if (typeFilter == 'transfer') return tx.type == 'transfer';
      return true; // 'all'
    }).toList(growable: false);

    // Search query
    final query = searchQuery.toLowerCase().trim();
    if (query.isEmpty) return filteredByType;

    return filteredByType.where((tx) {
      return tx.description.toLowerCase().contains(query) ||
          tx.body.toLowerCase().contains(query) ||
          tx.amount.toString().contains(query);
    }).toList();
  }

  static DashboardTotals calculateTotals(List<TransactionModel> transactions) {
    double inc = 0.0;
    double exp = 0.0;

    for (var tx in transactions) {
      if (tx.type == 'credit') {
        inc += tx.amount;
      } else if (tx.type == 'debit') {
        exp += tx.amount;
      }
    }

    final net = inc - exp;
    double savingsRate = 0.0;
    if (inc > 0) {
      savingsRate = ((inc - exp) / inc) * 100;
    }

    return DashboardTotals(
      income: inc,
      expense: exp,
      netBalance: net,
      savingsRate: savingsRate,
    );
  }
}
