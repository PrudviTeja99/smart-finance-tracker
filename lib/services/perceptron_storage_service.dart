import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/bio_tagger.dart';
import '../utils/category_classifier.dart';

/// Service to persist Perceptron weights and Automation Audit Logs locally
class PerceptronStorageService {
  PerceptronStorageService._privateConstructor();
  static final PerceptronStorageService instance = PerceptronStorageService._privateConstructor();

  static const String _taggerWeightsKey = 'perceptron_tagger_weights_v1';
  static const String _categoryWeightsKey = 'perceptron_category_weights_v1';
  static const String _typeWeightsKey = 'perceptron_type_weights_v1';
  static const String _accountWeightsKey = 'perceptron_account_weights_v1'; // NEW

  StructuredPerceptronTagger? _tagger;
  CategoryClassifier? _classifier;

  /// Load persisted weights from SharedPreferences
  Future<void> loadWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final taggerJson = prefs.getString(_taggerWeightsKey);
      final catJson = prefs.getString(_categoryWeightsKey);
      final typeJson = prefs.getString(_typeWeightsKey);
      final accJson = prefs.getString(_accountWeightsKey);

      final taggerWeights = _decodeWeightTable(taggerJson);
      final categoryWeights = _decodeWeightTable(catJson);
      final typeWeights = _decodeWeightTable(typeJson);
      final accountWeights = _decodeWeightTable(accJson);

      _tagger = StructuredPerceptronTagger(initialWeights: taggerWeights);
      _classifier = CategoryClassifier(
        initialCategoryWeights: categoryWeights,
        initialTypeWeights: typeWeights,
        initialAccountWeights: accountWeights,
      );
    } catch (e) {
      debugPrint('Error loading Perceptron weights: $e');
      _tagger = StructuredPerceptronTagger();
      _classifier = CategoryClassifier();
    }
  }

  /// Get the single global Perceptron Tagger instance
  StructuredPerceptronTagger get tagger {
    _tagger ??= StructuredPerceptronTagger();
    return _tagger!;
  }

  /// Get the single global Category Classifier instance
  CategoryClassifier get classifier {
    _classifier ??= CategoryClassifier();
    return _classifier!;
  }

  /// Asynchronously save modified weights to local storage
  Future<void> saveWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_tagger != null) {
        await prefs.setString(_taggerWeightsKey, jsonEncode(_tagger!.weightTable));
      }
      if (_classifier != null) {
        await prefs.setString(_categoryWeightsKey, jsonEncode(_classifier!.categoryWeights));
        await prefs.setString(_typeWeightsKey, jsonEncode(_classifier!.typeWeights));
        await prefs.setString(_accountWeightsKey, jsonEncode(_classifier!.accountWeights));
      }
    } catch (e) {
      debugPrint('Error saving Perceptron weights: $e');
    }
  }

  Map<String, Map<String, double>> _decodeWeightTable(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final Map<String, Map<String, double>> result = {};

      decoded.forEach((feat, tagMap) {
        if (tagMap is Map<String, dynamic>) {
          result[feat] = {};
          tagMap.forEach((tag, weight) {
            result[feat]![tag] = (weight as num).toDouble();
          });
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }
}
