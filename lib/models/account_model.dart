class AccountModel {
  final int? id;
  final String name;
  final String type; // bank, credit_card, wallet, cash
  final String keywords; // comma-separated keywords for prediction
  final double balance; // starting or current balance

  AccountModel({
    this.id,
    required this.name,
    required this.type,
    required this.keywords,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'keywords': keywords,
      'balance': balance,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      keywords: map['keywords'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? type,
    String? keywords,
    double? balance,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      keywords: keywords ?? this.keywords,
      balance: balance ?? this.balance,
    );
  }
}
