import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

enum ExportFormat { json, csv }

enum ExportDestination { saveLocally, share }

enum ImportMode { append, override }

class BackupService {
  /// Save text content to a local file path chosen by user or default downloads folder
  static Future<String?> saveContentLocally(
      String fileName, String content) async {
    try {
      // 1. Try file_picker saveFile first if supported
      String? savePath = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(content)),
      );

      if (savePath != null && savePath.isNotEmpty) {
        final file = File(savePath);
        await file.writeAsString(content);
        return savePath;
      }

      // 2. Fallback to Downloads or App Documents folder
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content);
        return file.path;
      }
    } catch (e) {
      debugPrint('Error saving content locally: $e');
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/$fileName');
        await file.writeAsString(content);
        return file.path;
      } catch (_) {}
    }
    return null;
  }

  /// Generate CSV string for confirmed transactions
  static Future<String> generateCSVString() async {
    final dbService = DatabaseService.instance;
    final transactions = await dbService.getConfirmedTransactions();
    final accounts = await dbService.getAllAccounts();
    final categories = await dbService.getAllCategories();

    final accountMap = {for (var a in accounts) a.id: a.name};
    final categoryMap = {for (var c in categories) c.id: c.name};

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
        'Date,Time,App,Amount,Type,Account,To Account,Category,Description,Original SMS Body');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (var tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final accName = accountMap[tx.accountId] ?? 'Unknown';
      final toAccName = tx.toAccountId != null
          ? (accountMap[tx.toAccountId] ?? 'Unknown')
          : '';
      final catName = categoryMap[tx.categoryId] ?? 'Others';

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

    return csvBuffer.toString();
  }

  /// Unified CSV Export: share via apps or save locally
  static Future<String?> exportToCSV(
      {ExportDestination destination = ExportDestination.share}) async {
    final csvContent = await generateCSVString();
    final dateSuffix = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'finance_tracker_export_$dateSuffix.csv';

    if (destination == ExportDestination.share) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvContent);
      await Share.shareXFiles([XFile(file.path)],
          text: 'My Smart Finance Tracker Export');
      return file.path;
    } else {
      return await saveContentLocally(fileName, csvContent);
    }
  }

  /// Generate full JSON backup string
  static Future<String> generateJSONString() async {
    final dbService = DatabaseService.instance;
    final db = await dbService.database;

    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final classifierState = await db.query('classifier_state');
    final notificationLogs = await db.query('notification_logs');

    final backupData = {
      'version': 2,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'classifier_state': classifierState,
      'notification_logs': notificationLogs,
    };

    return jsonEncode(backupData);
  }

  /// Unified JSON Export: share via apps or save locally
  static Future<String?> exportBackupJSON(
      {ExportDestination destination = ExportDestination.share}) async {
    final jsonContent = await generateJSONString();
    final dateSuffix = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'finance_tracker_backup_$dateSuffix.json';

    if (destination == ExportDestination.share) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonContent);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Smart Finance Tracker Backup');
      return file.path;
    } else {
      return await saveContentLocally(fileName, jsonContent);
    }
  }

  /// Restore database state from a backup JSON string (Supports Override and Append modes)
  static Future<bool> importBackupJSON(
    String jsonContent, {
    required ImportMode mode,
  }) async {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (decoded['version'] != 2 && !decoded.containsKey('transactions')) {
        return false;
      }

      final dbService = DatabaseService.instance;
      final db = await dbService.database;

      if (mode == ImportMode.override) {
        return await restoreBackupJSON(jsonContent);
      }

      // Append Mode: Merge missing categories/accounts, add new transactions with dedup
      await db.transaction((txn) async {
        // 1. Ensure accounts exist
        if (decoded.containsKey('accounts')) {
          final existingAccs = await txn.query('accounts');
          final existingAccNames = existingAccs
              .map((a) => a['name'].toString().toLowerCase())
              .toSet();

          for (var acc in (decoded['accounts'] as List)) {
            final accMap = Map<String, dynamic>.from(acc as Map);
            final name = accMap['name'].toString().toLowerCase();
            if (!existingAccNames.contains(name)) {
              accMap.remove('id'); // Allow DB to auto-generate new ID
              await txn.insert('accounts', accMap);
            }
          }
        }

        // 2. Ensure categories exist
        if (decoded.containsKey('categories')) {
          final existingCats = await txn.query('categories');
          final existingCatNames = existingCats
              .map((c) => c['name'].toString().toLowerCase())
              .toSet();

          for (var cat in (decoded['categories'] as List)) {
            final catMap = Map<String, dynamic>.from(cat as Map);
            final name = catMap['name'].toString().toLowerCase();
            if (!existingCatNames.contains(name)) {
              catMap.remove('id');
              await txn.insert('categories', catMap);
            }
          }
        }

        // Fetch fresh maps for foreign keys
        final currentAccounts = await txn.query('accounts');
        final currentCategories = await txn.query('categories');

        int defaultAccId = currentAccounts.isNotEmpty
            ? (currentAccounts.first['id'] as int)
            : 1;
        int defaultCatId = currentCategories.isNotEmpty
            ? (currentCategories.first['id'] as int)
            : 1;

        // 3. Append transactions
        if (decoded.containsKey('transactions')) {
          final txList = decoded['transactions'] as List;

          for (var txItem in txList) {
            final txMap = Map<String, dynamic>.from(txItem as Map);
            txMap.remove('id');

            final body = txMap['body']?.toString() ?? '';
            final amount = (txMap['amount'] as num?)?.toDouble() ?? 0.0;
            final type = txMap['type']?.toString() ?? 'debit';
            final accId = (txMap['account_id'] as int?) ?? defaultAccId;

            // Check if exact transaction already exists
            final dupCount = Sqflite.firstIntValue(await txn.rawQuery('''
              SELECT COUNT(*) FROM transactions
              WHERE TRIM(body) = TRIM(?)
                AND amount = ?
                AND type = ?
                AND account_id = ?
            ''', [body, amount, type, accId]));

            if (dupCount == null || dupCount == 0) {
              await txn.insert('transactions', txMap);
            }
          }
        }
      });

      dbService.notifyDashboardDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error during JSON import: $e');
      return false;
    }
  }

  /// Legacy method for backward compatibility
  static Future<bool> restoreBackupJSON(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (!decoded.containsKey('transactions') &&
          !decoded.containsKey('accounts')) {
        return false;
      }

      final dbService = DatabaseService.instance;
      final db = await dbService.database;

      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('accounts');
        await txn.delete('classifier_state');
        await txn.delete('notification_logs');

        if (decoded.containsKey('accounts')) {
          final accountsList = decoded['accounts'] as List;
          for (var account in accountsList) {
            await txn.insert(
                'accounts', Map<String, dynamic>.from(account as Map));
          }
        }

        if (decoded.containsKey('categories')) {
          final categoriesList = decoded['categories'] as List;
          for (var category in categoriesList) {
            await txn.insert(
                'categories', Map<String, dynamic>.from(category as Map));
          }
        }

        if (decoded.containsKey('transactions')) {
          final transactionsList = decoded['transactions'] as List;
          for (var tx in transactionsList) {
            await txn.insert(
                'transactions', Map<String, dynamic>.from(tx as Map));
          }
        }

        if (decoded.containsKey('classifier_state')) {
          final classifierStateList = decoded['classifier_state'] as List;
          for (var state in classifierStateList) {
            await txn.insert(
                'classifier_state', Map<String, dynamic>.from(state as Map));
          }
        }

        if (decoded.containsKey('notification_logs')) {
          final notificationLogsList = decoded['notification_logs'] as List;
          for (var log in notificationLogsList) {
            await txn.insert(
                'notification_logs', Map<String, dynamic>.from(log as Map));
          }
        }
      });

      dbService.notifyDashboardDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error during restore: $e');
      return false;
    }
  }

  /// Import transactions from CSV content (Supports Override and Append modes)
  static Future<bool> importFromCSV(
    String csvContent, {
    required ImportMode mode,
  }) async {
    try {
      final lines =
          csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return false;

      final dbService = DatabaseService.instance;
      final db = await dbService.database;
      final accounts = await dbService.getAllAccounts();
      final categories = await dbService.getAllCategories();

      final accountNameMap = {
        for (var a in accounts) a.name.toLowerCase(): a.id!
      };
      final categoryNameMap = {
        for (var c in categories) c.name.toLowerCase(): c.id!
      };

      int defaultAccId = accounts.isNotEmpty ? accounts.first.id! : 1;
      int defaultCatId = categories.isNotEmpty ? categories.first.id! : 1;

      // Identify header index
      int startIdx = 0;
      final firstLine = lines.first.toLowerCase();
      if (firstLine.contains('amount') || firstLine.contains('date')) {
        startIdx = 1;
      }

      final parsedTransactions = <TransactionModel>[];

      for (int i = startIdx; i < lines.length; i++) {
        final cells = _parseCsvLine(lines[i]);
        if (cells.length < 4) continue;

        // Column mapping: Date,Time,App,Amount,Type,Account,To Account,Category,Description,Original SMS Body
        String dateStr = cells[0];
        String timeStr = cells.length > 1 ? cells[1] : '00:00:00';
        String appName = cells.length > 2 ? cells[2] : 'Manual';
        double amount =
            double.tryParse(cells.length > 3 ? cells[3] : '0') ?? 0.0;
        String type = cells.length > 4 ? cells[4].toLowerCase() : 'debit';
        String accName = cells.length > 5 ? cells[5] : '';
        String toAccName = cells.length > 6 ? cells[6] : '';
        String catName = cells.length > 7 ? cells[7] : '';
        String description = cells.length > 8 ? cells[8] : 'CSV Import';
        String body = cells.length > 9 ? cells[9] : description;

        if (amount <= 0.0) continue;

        DateTime dateTime;
        try {
          dateTime = DateTime.parse('$dateStr $timeStr');
        } catch (_) {
          try {
            dateTime = DateTime.parse(dateStr);
          } catch (_) {
            dateTime = DateTime.now();
          }
        }

        int accId = accountNameMap[accName.toLowerCase()] ?? defaultAccId;
        int? toAccId = toAccName.isNotEmpty
            ? (accountNameMap[toAccName.toLowerCase()] ?? defaultAccId)
            : null;
        int catId = categoryNameMap[catName.toLowerCase()] ?? defaultCatId;

        parsedTransactions.add(
          TransactionModel(
            appName: appName,
            title: appName,
            body: body,
            amount: amount,
            type: type,
            accountId: accId,
            toAccountId: toAccId,
            categoryId: catId,
            description: description,
            date: dateTime,
            status: 'confirmed',
          ),
        );
      }

      if (parsedTransactions.isEmpty) return false;

      if (mode == ImportMode.override) {
        await db.transaction((txn) async {
          await txn.delete('transactions');
          for (var tx in parsedTransactions) {
            await txn.insert('transactions', tx.toMap());
          }
        });
      } else {
        // Append mode
        for (var tx in parsedTransactions) {
          await dbService.insertTransaction(tx);
        }
      }

      dbService.notifyDashboardDataChanged();
      return true;
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      return false;
    }
  }

  /// Robust CSV line parser handling quotes and escaped characters
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }
}
