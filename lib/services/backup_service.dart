import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class BackupService {
  // Export confirmed transactions as CSV and open system share dialog
  static Future<void> exportToCSV() async {
    final dbService = DatabaseService.instance;
    final transactions = await dbService.getConfirmedTransactions();
    final accounts = await dbService.getAllAccounts();
    final categories = await dbService.getAllCategories();

    // Map ID to Name for readable CSV output
    final accountMap = {for (var a in accounts) a.id: a.name};
    final categoryMap = {for (var c in categories) c.id: c.name};

    final csvBuffer = StringBuffer();
    // CSV Header
    csvBuffer.writeln('Date,Time,App,Amount,Type,Account,To Account,Category,Description,Original SMS Body');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (var tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final accName = accountMap[tx.accountId] ?? 'Unknown';
      final toAccName = tx.toAccountId != null ? (accountMap[tx.toAccountId] ?? 'Unknown') : '';
      final catName = categoryMap[tx.categoryId] ?? 'Others';

      // Safe CSV column formatter (handles quotes and commas)
      String csvCell(String val) {
        final escaped = val.replaceAll('"', '""');
        return '"$escaped"';
      }

      csvBuffer.writeln([
        dateStr,
        timeStr,
        csvCell(tx.appName ?? 'Manual'),
        tx.amount.toString(),
        tx.type,
        csvCell(accName),
        csvCell(toAccName),
        csvCell(catName),
        csvCell(tx.description),
        csvCell(tx.body),
      ].join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/finance_tracker_export.csv');
    await file.writeAsString(csvBuffer.toString());

    // Share the file
    await Share.shareXFiles([XFile(file.path)], text: 'My Smart Finance Tracker Export');
  }

  // Backup entire database state (Accounts, Categories, Confirmed/Pending Transactions) as a JSON string
  static Future<void> exportBackupJSON() async {
    final dbService = DatabaseService.instance;
    final db = await dbService.database;

    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final classifierState = await db.query('classifier_state');
    final notificationLogs = await db.query('notification_logs');

    final backupData = {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'classifier_state': classifierState,
      'notification_logs': notificationLogs,
    };

    final jsonString = jsonEncode(backupData);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/finance_tracker_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Smart Finance Tracker Backup');
  }

  // Restore database state from a backup JSON string
  static Future<bool> restoreBackupJSON(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (decoded['version'] != 2) return false;

      final dbService = DatabaseService.instance;
      final db = await dbService.database;

      await db.transaction((txn) async {
        // Clear current tables
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('accounts');
        await txn.delete('classifier_state');
        await txn.delete('notification_logs');

        // Restore Accounts
        final accountsList = decoded['accounts'] as List;
        for (var account in accountsList) {
          await txn.insert('accounts', account as Map<String, dynamic>);
        }

        // Restore Categories
        final categoriesList = decoded['categories'] as List;
        for (var category in categoriesList) {
          await txn.insert('categories', category as Map<String, dynamic>);
        }

        // Restore Transactions
        final transactionsList = decoded['transactions'] as List;
        for (var tx in transactionsList) {
          await txn.insert('transactions', tx as Map<String, dynamic>);
        }

        // Restore Classifier State
        final classifierStateList = decoded['classifier_state'] as List;
        for (var state in classifierStateList) {
          await txn.insert('classifier_state', state as Map<String, dynamic>);
        }

        // Restore Notification Logs
        final notificationLogsList = decoded['notification_logs'] as List;
        for (var log in notificationLogsList) {
          await txn.insert('notification_logs', log as Map<String, dynamic>);
        }
      });

      return true;
    } catch (e) {
      print('Error during restore: $e');
      return false;
    }
  }
}
