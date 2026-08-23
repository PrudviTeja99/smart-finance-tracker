import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int color; // ARGB color value for rendering
  final String icon; // Icon identifier key

  CategoryModel({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      icon: map['icon'] as String,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? color,
    String? icon,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

extension CategoryL10nExtension on CategoryModel {
  String getLocalizedName(dynamic stringsOrContext) {
    String n = name.trim().toLowerCase();
    if (stringsOrContext is BuildContext) {
      final strings = AppLocalizations.of(stringsOrContext)!;
      return _getLocalizedNameWithStrings(strings, n);
    } else if (stringsOrContext is AppLocalizations) {
      return _getLocalizedNameWithStrings(stringsOrContext, n);
    }
    return name;
  }

  String _getLocalizedNameWithStrings(AppLocalizations strings, String n) {
    if (n == 'food') return strings.catFood;
    if (n == 'shopping') return strings.catShopping;
    if (n == 'travel') return strings.catTravel;
    if (n == 'bills & utilities' || n == 'bills') return strings.catBills;
    if (n == 'salary') return strings.catSalary;
    if (n == 'sent money') return strings.catSentMoney;
    if (n == 'received money') return strings.catReceivedMoney;
    if (n == 'others') return strings.catOthers;
    if (n == 'transfer') return strings.catTransfer;
    return name;
  }
}
