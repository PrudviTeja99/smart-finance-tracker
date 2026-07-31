class TransactionModel {
  final int? id;
  final String? appName; // originating package or app name (e.g. PhonePe)
  final String title; // notification title
  final String body; // notification body
  final double amount; // transaction value
  final String type; // debit, credit, transfer
  final int accountId; // source account ID
  final int? toAccountId; // destination account ID (for transfers only)
  final int categoryId; // category ID
  final String description; // customizable description
  final DateTime date; // date and time
  final String status; // pending, confirmed
  final int? notificationLogId; // originating notification_logs ID

  TransactionModel({
    this.id,
    this.appName,
    required this.title,
    required this.body,
    required this.amount,
    required this.type,
    required this.accountId,
    this.toAccountId,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.status,
    this.notificationLogId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'title': title,
      'body': body,
      'amount': amount,
      'type': type,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'category_id': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
      'notification_log_id': notificationLogId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      appName: map['app_name'] as String?,
      title: map['title'] as String,
      body: map['body'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      accountId: map['account_id'] as int,
      toAccountId: map['to_account_id'] as int?,
      categoryId: map['category_id'] as int,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      notificationLogId: map['notification_log_id'] as int?,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? appName,
    String? title,
    String? body,
    double? amount,
    String? type,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    String? description,
    DateTime? date,
    String? status,
    int? notificationLogId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      notificationLogId: notificationLogId ?? this.notificationLogId,
    );
  }
}
