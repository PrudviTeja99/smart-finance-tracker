import 'dart:math';
import '../services/database_service.dart';

class NaiveBayesClassifier {
  final String dbKey; // The SQLite state key ('type_vocabulary' or 'category_vocabulary')
  Map<String, Map<String, int>> vocabulary = {};
  Map<String, int> classDocCounts = {};
  int totalDocs = 0;

  NaiveBayesClassifier({required this.dbKey});

  // Load the model vocabulary from the SQLite database
  Future<void> load() async {
    final state = await DatabaseService.instance.getClassifierState(dbKey);
    if (state != null) {
      vocabulary.clear();
      classDocCounts.clear();
      totalDocs = 0;

      state.forEach((token, classCounts) {
        final counts = Map<String, int>.from(classCounts as Map);
        vocabulary[token] = counts;

        counts.forEach((className, count) {
          classDocCounts[className] = (classDocCounts[className] ?? 0) + count;
          totalDocs += count;
        });
      });
    }
  }

  // Save the model vocabulary back to the SQLite database
  Future<void> save() async {
    await DatabaseService.instance.saveClassifierState(dbKey, vocabulary);
  }

  // Tokenize and clean raw text into clean word tokens
  List<String> cleanAndTokenize(String text) {
    // Regex splits by non-word characters (spaces, punctuation)
    final regex = RegExp(r'[^\w\s]+');
    final cleaned = text.replaceAll(regex, ' ').toLowerCase();
    
    return cleaned.split(RegExp(r'\s+'))
        .where((token) => token.length >= 2) // Skip tiny words/characters
        .toList();
  }

  // Trains the model on a document
  Future<void> train(String text, String className) async {
    await load(); // Ensure we have the latest state

    final tokens = cleanAndTokenize(text);
    if (tokens.isEmpty) return;

    for (var token in tokens) {
      if (!vocabulary.containsKey(token)) {
        vocabulary[token] = {};
      }
      final counts = vocabulary[token]!;
      counts[className] = (counts[className] ?? 0) + 1;
    }

    await save();
  }

  // Predicts the probabilities of classes for a given text.
  // Returns a list of Map entries sorted from highest probability to lowest.
  // Uses Laplace smoothing (+1) to handle unknown words.
  Future<List<MapEntry<String, double>>> predictProbabilities(
    String text,
    List<String> activeClasses,
  ) async {
    await load(); // Ensure latest state

    if (activeClasses.isEmpty) return [];

    final tokens = cleanAndTokenize(text);
    final results = <String, double>{};

    // Calculate vocabulary count for Laplace smoothing
    final vocabularySize = vocabulary.length;

    // Sum total words in each class
    final classWordTotals = <String, int>{};
    vocabulary.forEach((token, classCounts) {
      classCounts.forEach((className, count) {
        if (activeClasses.contains(className)) {
          classWordTotals[className] = (classWordTotals[className] ?? 0) + count;
        }
      });
    });

    for (var className in activeClasses) {
      // Prior probability P(Class)
      final classDocCount = classDocCounts[className] ?? 1;
      final totalDocCount = totalDocs > 0 ? totalDocs : activeClasses.length;
      double logProbability = log(classDocCount / totalDocCount);

      // Total words in this class + vocabulary size (smoothing divisor)
      final totalWordsInClass = classWordTotals[className] ?? 0;
      final divisor = totalWordsInClass + vocabularySize + 1;

      for (var token in tokens) {
        if (!vocabulary.containsKey(token)) continue;
        // Likelihood count of token in class
        final count = vocabulary[token]?[className] ?? 0;
        
        // P(token | Class) with Laplace smoothing
        final wordProbability = (count + 1) / divisor;
        logProbability += log(wordProbability);
      }

      results[className] = logProbability;
    }

    // Convert log-probabilities back to pseudo-probabilities for easy UI consumption (0.0 to 1.0 range)
    // Softmax-like scaling of log values to prevent underflow
    final maxLog = results.values.reduce(max);
    final exps = results.map((key, logVal) => MapEntry(key, exp(logVal - maxLog)));
    final sumExps = exps.values.reduce((a, b) => a + b);

    final probabilities = exps.map((key, expVal) => MapEntry(key, sumExps > 0 ? expVal / sumExps : 0.0));

    // Sort by probability desc
    final sortedList = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedList;
  }

  // Predicts the single most likely class
  Future<String> predict(String text, List<String> activeClasses, String defaultFallback) async {
    final probs = await predictProbabilities(text, activeClasses);
    if (probs.isEmpty) return defaultFallback;
    return probs.first.key;
  }
}
