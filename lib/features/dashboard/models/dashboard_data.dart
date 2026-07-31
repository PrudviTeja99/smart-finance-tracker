import '../../../models/transaction_model.dart';
import '../../../models/account_model.dart';
import '../../../models/category_model.dart';

class DashboardData {
  final List<TransactionModel> allTransactions;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;

  const DashboardData({
    required this.allTransactions,
    required this.accounts,
    required this.categories,
  });
}
