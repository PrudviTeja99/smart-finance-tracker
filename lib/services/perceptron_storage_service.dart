import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/bio_tagger.dart';
import '../utils/category_classifier.dart';

/// Top-level isolate functions for CPU-heavy weight decoding/encoding.
/// Top-level functions have zero closure context and capture no instance fields (e.g. Futures).
Map<String, Map<String, double>> _decodeWeightsIsolateTask(String? jsonStr) {
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

String _encodeWeightsIsolateTask(Map<String, Map<String, double>> weightTable) {
  return jsonEncode(weightTable);
}

/// Service to persist Perceptron weights and Automation Audit Logs locally
class PerceptronStorageService {
  PerceptronStorageService._privateConstructor();
  static final PerceptronStorageService instance =
      PerceptronStorageService._privateConstructor();

  static const String _taggerWeightsKey = 'perceptron_tagger_weights_v1';
  static const String _categoryWeightsKey = 'perceptron_category_weights_v1';
  static const String _typeWeightsKey = 'perceptron_type_weights_v1';
  static const String _accountWeightsKey = 'perceptron_account_weights_v1';

  StructuredPerceptronTagger? _tagger;
  CategoryClassifier? _classifier;
  Future<void>? _loadingFuture;

  /// Load persisted weights from SharedPreferences in a background isolate
  Future<void> loadWeights() async {
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = () async {
      try {
        final prefs = await SharedPreferences.getInstance();

        final taggerJson = prefs.getString(_taggerWeightsKey);
        final catJson = prefs.getString(_categoryWeightsKey);
        final typeJson = prefs.getString(_typeWeightsKey);
        final accJson = prefs.getString(_accountWeightsKey);

        final taggerWeights =
            await Isolate.run(() => _decodeWeightsIsolateTask(taggerJson));
        final categoryWeights =
            await Isolate.run(() => _decodeWeightsIsolateTask(catJson));
        final typeWeights =
            await Isolate.run(() => _decodeWeightsIsolateTask(typeJson));
        final accountWeights =
            await Isolate.run(() => _decodeWeightsIsolateTask(accJson));

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
    }();

    return _loadingFuture!;
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

  /// Asynchronously save modified weights to local storage using background isolates
  Future<void> saveWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_tagger != null) {
        final weightTable = _tagger!.weightTable;
        final taggerJson =
            await Isolate.run(() => _encodeWeightsIsolateTask(weightTable));
        await prefs.setString(_taggerWeightsKey, taggerJson);
      }
      if (_classifier != null) {
        final catWeights = _classifier!.categoryWeights;
        final typeWeights = _classifier!.typeWeights;
        final accWeights = _classifier!.accountWeights;

        final catJson =
            await Isolate.run(() => _encodeWeightsIsolateTask(catWeights));
        final typeJson =
            await Isolate.run(() => _encodeWeightsIsolateTask(typeWeights));
        final accJson =
            await Isolate.run(() => _encodeWeightsIsolateTask(accWeights));

        await prefs.setString(_categoryWeightsKey, catJson);
        await prefs.setString(_typeWeightsKey, typeJson);
        await prefs.setString(_accountWeightsKey, accJson);
      }
    } catch (e) {
      debugPrint('Error saving Perceptron weights: $e');
    }
  }
}
