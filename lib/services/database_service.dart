import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        keywords TEXT NOT NULL,
        balance REAL NOT NULL
      )
    ''');

    // 2. Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    // 3. Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_name TEXT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        to_account_id INTEGER,
        category_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (to_account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Create Index on date for range filtering performance
    await db
        .execute('CREATE INDEX idx_transactions_date ON transactions (date);');
    await db.execute(
        'CREATE INDEX idx_transactions_status ON transactions (status);');

    // 4. Create classifier_state table to store model training weights
    await db.execute('''
      CREATE TABLE classifier_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 5. Create notification_logs table to store all intercepted notifications
    await _createNotificationLogsTable(db);

    // 6. Create raw_notification_queue table for zero-battery background ingestion
    await db.execute('''
      CREATE TABLE IF NOT EXISTS raw_notification_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        title TEXT,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // 7. Create model_audit_log table for transparent automation tracking
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        app_name TEXT,
        package_name TEXT NOT NULL,
        title TEXT,
        body TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        log_id INTEGER
      )
    ''');

    // 8. Pre-seed default data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    // Seed default accounts
    final defaultAccounts = [
      AccountModel(
          name: 'Cash', type: 'cash', keywords: 'cash, physical', balance: 0.0),
      AccountModel(
          name: 'Bank Account',
          type: 'bank',
          keywords: 'a/c, bank, transfer, deposited, xx',
          balance: 0.0),
      AccountModel(
          name: 'Credit Card',
          type: 'credit_card',
          keywords: 'card, visa, mastercard, ending, spent on',
          balance: 0.0),
    ];

    for (var account in defaultAccounts) {
      await db.insert('accounts', account.toMap());
    }

    // Seed default categories
    final defaultCategories = [
      CategoryModel(
          name: 'Food', color: 0xFFFF8A80, icon: 'restaurant'), // Light red
      CategoryModel(
          name: 'Shopping',
          color: 0xFFFFD180,
          icon: 'shopping_bag'), // Light orange
      CategoryModel(
          name: 'Travel',
          color: 0xFF80D8FF,
          icon: 'directions_car'), // Light blue
      CategoryModel(
          name: 'Bills & Utilities',
          color: 0xFFEA80FC,
          icon: 'receipt'), // Light purple
      CategoryModel(
          name: 'Salary',
          color: 0xFFB9F6CA,
          icon: 'attach_money'), // Light green
      CategoryModel(
          name: 'Sent Money',
          color: 0xFFF87171,
          icon: 'credit_card'), // Soft Red
      CategoryModel(
          name: 'Received Money',
          color: 0xFF34D399,
          icon: 'monetization_on'), // Soft Emerald
      CategoryModel(
          name: 'Others', color: 0xFFCFD8DC, icon: 'more_horiz'), // Grey
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }

    // Seed default Naive Bayes classifier vocabulary maps
    final typeVocabulary = {
      'debited': {'debit': 10, 'credit': 0, 'transfer': 1},
      'spent': {'debit': 10, 'credit': 0, 'transfer': 0},
      'purchased': {'debit': 8, 'credit': 0, 'transfer': 0},
      'withdrawn': {'debit': 5, 'credit': 0, 'transfer': 5},
      'credited': {'debit': 0, 'credit': 10, 'transfer': 0},
      'received': {'debit': 0, 'credit': 10, 'transfer': 0},
      'deposited': {'debit': 0, 'credit': 8, 'transfer': 1},
      'salary': {'debit': 0, 'credit': 10, 'transfer': 0},
      'added': {'debit': 0, 'credit': 5, 'transfer': 3},
      'sent': {'debit': 6, 'credit': 0, 'transfer': 2},
      'paid': {'debit': 8, 'credit': 0, 'transfer': 0},
      'transfer': {'debit': 1, 'credit': 1, 'transfer': 10},
      'self': {'debit': 0, 'credit': 0, 'transfer': 10},
    };

    final categoryVocabulary = {
      'swiggy': {'Food': 10},
      'zomato': {'Food': 10},
      'restaurant': {'Food': 8},
      'eat': {'Food': 5},
      'uber': {'Travel': 10},
      'ola': {'Travel': 10},
      'rapido': {'Travel': 8},
      'fuel': {'Travel': 8},
      'petrol': {'Travel': 10},
      'railway': {'Travel': 7},
      'metro': {'Travel': 8},
      'amazon': {'Shopping': 10},
      'flipkart': {'Shopping': 10},
      'myntra': {'Shopping': 8},
      'decathlon': {'Shopping': 8},
      'mall': {'Shopping': 6},
      'electricity': {'Bills & Utilities': 10},
      'water': {'Bills & Utilities': 10},
      'gas': {'Bills & Utilities': 10},
      'jio': {'Bills & Utilities': 8},
      'airtel': {'Bills & Utilities': 8},
      'recharge': {'Bills & Utilities': 10},
      'bill': {'Bills & Utilities': 10},
      'salary': {'Salary': 10},
      'bonus': {'Salary': 8},
      'paycheck': {'Salary': 10},
    };

    await db.insert('classifier_state', {
      'key': 'type_vocabulary',
      'value': jsonEncode(typeVocabulary),
    });

    await db.insert('classifier_state', {
      'key': 'category_vocabulary',
      'value': jsonEncode(categoryVocabulary),
    });
  }

  // --- DATABASE MIGRATION ---

  static Future<void> _createNotificationLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE notification_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_name TEXT,
        package_name TEXT,
        title TEXT,
        body TEXT,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'unclassified'
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_notification_logs_status ON notification_logs (status);');
    await db.execute(
        'CREATE INDEX idx_notification_logs_date ON notification_logs (date);');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNotificationLogsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS raw_notification_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          package_name TEXT NOT NULL,
          title TEXT,
          body TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          status TEXT DEFAULT 'pending'
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS model_audit_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          app_name TEXT,
          package_name TEXT NOT NULL,
          title TEXT,
          body TEXT NOT NULL,
          confidence REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          log_id INTEGER
        )
      ''');
    }
    try {
      await db.execute('ALTER TABLE model_audit_log ADD COLUMN log_id INTEGER');
    } catch (_) {}
  }

  // --- CLASSIFIER STATE METHODS ---

  Future<Map<String, dynamic>?> getClassifierState(String key) async {
    final db = await database;
    final maps = await db.query(
      'classifier_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return jsonDecode(maps.first['value'] as String) as Map<String, dynamic>;
  }

  Future<void> saveClassifierState(
      String key, Map<String, dynamic> state) async {
    final db = await database;
    await db.insert(
      'classifier_state',
      {
        'key': key,
        'value': jsonEncode(state),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- NOTIFICATION LOGS CRUD ---

  Future<int> insertNotificationLog({
    required String appName,
    required String packageName,
    required String title,
    required String body,
    required DateTime date,
    String status = 'unclassified',
  }) async {
    final db = await database;
    return await db.insert('notification_logs', {
      'app_name': appName,
      'package_name': packageName,
      'title': title,
      'body': body,
      'date': date.toIso8601String(),
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getNotificationLogs(String status) async {
    final db = await database;
    return await db.query(
      'notification_logs',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllNotificationLogs() async {
    final db = await database;
    return await db.query(
      'notification_logs',
      orderBy: 'date DESC',
    );
  }

  Future<int> updateNotificationLogStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'notification_logs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotificationLog(int id) async {
    final db = await database;
    return await db.delete(
      'notification_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearNotificationLogs({String? status}) async {
    final db = await database;
    if (status != null) {
      await db.delete('notification_logs',
          where: 'status = ?', whereArgs: [status]);
    } else {
      await db.delete('notification_logs');
    }
  }

  // --- ACCOUNTS CRUD ---

  Future<int> insertAccount(AccountModel account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts', orderBy: 'id ASC');
    return result.map((json) => AccountModel.fromMap(json)).toList();
  }

  Future<int> updateAccount(AccountModel account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Calculate account balances dynamically based on confirmed transactions
  Future<double> getAccountBalance(int accountId) async {
    final db = await database;

    // Fetch starting balance
    final accountMap = await db.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [accountId],
    );
    if (accountMap.isEmpty) return 0.0;
    double balance = (accountMap.first['balance'] as num).toDouble();

    // 1. Add credits where account is destination
    final creditResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE account_id = ? AND type = 'credit' AND status = 'confirmed'
    ''', [accountId]);
    double credits = (creditResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Subtract debits where account is source
    final debitResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE account_id = ? AND type = 'debit' AND status = 'confirmed'
    ''', [accountId]);
    double debits = (debitResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Add incoming transfers (to_account_id = accountId)
    final transferInResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE to_account_id = ? AND type = 'transfer' AND status = 'confirmed'
    ''', [accountId]);
    double transferIn =
        (transferInResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // 4. Subtract outgoing transfers (account_id = accountId)
    final transferOutResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE account_id = ? AND type = 'transfer' AND status = 'confirmed'
    ''', [accountId]);
    double transferOut =
        (transferOutResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return balance + credits - debits + transferIn - transferOut;
  }

  // --- CATEGORIES CRUD ---

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Remap transactions of deleted category to 'Others' (usually id 6)
    await db.update(
      'transactions',
      {'category_id': 6},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- TRANSACTIONS CRUD ---

  // Inserts a transaction with deduplication filter.
  // Returns transaction ID, or -1 if it was rejected as a duplicate.
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;

    // Deduplication filter: check for identical amount, type, account within a 2-minute window
    final dateIso = tx.date.toIso8601String();
    final twoMinBefore =
        tx.date.subtract(const Duration(minutes: 2)).toIso8601String();
    final twoMinAfter =
        tx.date.add(const Duration(minutes: 2)).toIso8601String();

    final duplicateCount = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM transactions
        WHERE amount = ? 
          AND type = ? 
          AND account_id = ? 
          AND date BETWEEN ? AND ?
      ''', [tx.amount, tx.type, tx.accountId, twoMinBefore, twoMinAfter]));

    if (duplicateCount != null && duplicateCount > 0) {
      // Duplicate detected! Skip insertion.
      return -1;
    }

    return await db.insert('transactions', tx.toMap());
  }

  // Retrieve pending transactions
  Future<List<TransactionModel>> getPendingTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'date DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Retrieve confirmed transactions for a specific date range
  Future<List<TransactionModel>> getConfirmedTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = "status = 'confirmed'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += " AND date >= ?";
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += " AND date <= ?";
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getUniqueDescriptions() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT DISTINCT description FROM transactions WHERE status = 'confirmed' AND description != ''");
    return result.map((row) => row['description'] as String).toList();
  }

  Future<int> runArchiveAutoDelete(int value, String unit) async {
    final db = await database;
    DateTime cutoff;
    final now = DateTime.now();
    switch (unit) {
      case 'years':
        cutoff = DateTime(now.year - value, now.month, now.day);
        break;
      case 'months':
        cutoff = DateTime(now.year, now.month - value, now.day);
        break;
      case 'days':
      default:
        cutoff = now.subtract(Duration(days: value));
        break;
    }
    final cutoffIso = cutoff.toIso8601String();
    return await db.delete(
      'notification_logs',
      where: "status = 'archived' AND date < ?",
      whereArgs: [cutoffIso],
    );
  }

  /// Delete ALL archived notification logs (used when disabling Smart Tracking)
  Future<int> deleteAllArchivedAlerts() async {
    final db = await database;
    return await db.delete(
      'notification_logs',
      where: "status = 'archived'",
    );
  }

  /// Delete ALL model audit logs (used when disabling Smart Tracking)
  Future<int> deleteAllModelAuditLogs() async {
    final db = await database;
    return await db.delete('model_audit_log');
  }

  /// Delete ALL processed raw notifications from the queue
  Future<int> deleteProcessedRawNotifications() async {
    final db = await database;
    return await db.delete(
      'raw_notification_queue',
      where: "status = 'processed'",
    );
  }

  // --- RAW NOTIFICATION QUEUE (Zero-Battery Background Ingestion) ---

  Future<int> insertRawNotification({
    required String packageName,
    required String title,
    required String body,
    required int timestamp,
  }) async {
    final db = await database;

    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveSecondsAgo = now - const Duration(seconds: 5).inMilliseconds;
    // Or use 10 seconds if you prefer:
    // final tenSecondsAgo = now - const Duration(seconds: 10).inMilliseconds;

    // Look for an identical pending notification received recently.
    final duplicateCount = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM raw_notification_queue
        WHERE package_name = ?
          AND title = ?
          AND body = ?
          AND status = 'pending'
          AND timestamp >= ?
        ''',
        [
          packageName,
          title,
          body,
          fiveSecondsAgo,
        ],
      ),
    );

    if (duplicateCount != null && duplicateCount > 0) {
      // Duplicate detected.
      return -1;
    }

    return await db.insert('raw_notification_queue', {
      'package_name': packageName,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingRawNotifications() async {
    final db = await database;
    return await db.query(
      'raw_notification_queue',
      where: "status = 'pending'",
      orderBy: 'id ASC',
    );
  }

  Future<void> markRawNotificationsProcessed(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final idList = ids.join(',');
    await db.rawUpdate(
      "UPDATE raw_notification_queue SET status = 'processed' WHERE id IN ($idList)",
    );
  }

  // --- MODEL AUTOMATION AUDIT LOG ---

  Future<int> insertModelAuditLog({
    required String actionType,
    required String appName,
    required String packageName,
    required String title,
    required String body,
    required double confidence,
    int? logId,
  }) async {
    final db = await database;
    return await db.insert('model_audit_log', {
      'action_type': actionType,
      'app_name': appName,
      'package_name': packageName,
      'title': title,
      'body': body,
      'confidence': confidence,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (logId != null) 'log_id': logId,
    });
  }

  Future<List<Map<String, dynamic>>> getModelAuditLogs({int limit = 50}) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        app_name TEXT,
        package_name TEXT NOT NULL,
        title TEXT,
        body TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        log_id INTEGER
      )
    ''');
    return await db.query(
      'model_audit_log',
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  Future<Map<String, int>> getDailyAuditCounts() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        app_name TEXT,
        package_name TEXT NOT NULL,
        title TEXT,
        body TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        log_id INTEGER
      )
    ''');
    final startOfDay =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .millisecondsSinceEpoch;
    final result = await db.rawQuery('''
      SELECT action_type, COUNT(*) as cnt
      FROM model_audit_log
      WHERE timestamp >= ?
      GROUP BY action_type
    ''', [startOfDay]);

    int autoDrafted = 0;
    int autoArchived = 0;

    for (var row in result) {
      final action = row['action_type'] as String;
      final count = row['cnt'] as int;
      if (action == 'auto_drafted') autoDrafted = count;
      if (action == 'auto_archived') autoArchived = count;
    }

    return {'auto_drafted': autoDrafted, 'auto_archived': autoArchived};
  }

  Future<bool> hasTodayModelActivity() async {
    final counts = await getDailyAuditCounts();

    return counts.values.any((count) => count > 0);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
