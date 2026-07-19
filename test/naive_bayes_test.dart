import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/utils/naive_bayes_classifier.dart';

void main() {
  group('Naive Bayes Text Classifier Tests', () {
    late NaiveBayesClassifier mockTypeClassifier;

    setUp(() {
      // Create classifier with mock state mapping
      mockTypeClassifier = NaiveBayesClassifier(dbKey: 'test_key');
    });

    test('Tokenization and text cleaning', () {
      final text = "Dear Customer, Rs. 1,500.00 spent on Card! (XX5678) I paid ₹ 10 for a pen";
      final tokens = mockTypeClassifier.cleanAndTokenize(text);

      expect(tokens, contains('dear'));
      expect(tokens, contains('customer'));
      expect(tokens, contains('spent'));
      expect(tokens, contains('card'));
      expect(tokens, contains('xx5678'));
      expect(tokens, contains('rs')); // Kept because length >= 2
      expect(tokens, isNot(contains('i'))); // Filtered out (len < 2)
      expect(tokens, isNot(contains('a'))); // Filtered out (len < 2)
    });

    test('Basic training and prediction calculations', () async {
      // Setup mock local memory to bypass SQLite query for testing
      final mockState = <String, Map<String, int>>{
        'debited': {'debit': 5, 'credit': 0},
        'spent': {'debit': 4, 'credit': 0},
        'paid': {'debit': 3, 'credit': 0},
        'received': {'debit': 0, 'credit': 5},
        'credited': {'debit': 0, 'credit': 4},
        'salary': {'debit': 0, 'credit': 3},
      };

      // Force load the mock vocabulary into the classifier memory
      final testClassifier = TestNaiveBayesClassifier(mockState);

      // Verify predictions
      final classes = ['debit', 'credit'];
      
      final debitPrediction = await testClassifier.predict('spent on shopping', classes, 'debit');
      expect(debitPrediction, equals('debit'));

      final creditPrediction = await testClassifier.predict('salary received', classes, 'debit');
      expect(creditPrediction, equals('credit'));

      // Check probabilities list
      final probs = await testClassifier.predictProbabilities('salary credited', classes);
      expect(probs.first.key, equals('credit'));
      expect(probs.first.value, greaterThan(0.7));
    });
  });

  group('Regex Amount Extraction Tests', () {
    double extractAmount(String body) {
      final amountPattern = RegExp(
        r'(?:rs|inr|amt|received|sent|paid|spent|debited|credited)\.?\s*(?:rs\.?|inr\.?)?\s*([0-9,]+(?:\.[0-9]{2})?)',
        caseSensitive: false,
      );
      var match = amountPattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0.0';
        return double.tryParse(amountStr) ?? 0.0;
      }
      
      // Fallback
      final fallbackPattern = RegExp(r'(?:₹|rs\.?|inr\.?)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false);
      match = fallbackPattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '0.0';
        return double.tryParse(amountStr) ?? 0.0;
      }
      return 0.0;
    }

    test('Parse standard HDFC Bank format', () {
      final text = "Dear Customer, Rs. 1,500.00 was debited from your A/c XX1234 on 16-07-26.";
      expect(extractAmount(text), equals(1500.00));
    });

    test('Parse UPI format with Indian Rupee symbol', () {
      final text = "Sent ₹450 to Starbucks on PhonePe.";
      expect(extractAmount(text), equals(450.00));
    });

    test('Parse credited income format with commas', () {
      final text = "Salary of INR 1,20,500.00 credited to account.";
      expect(extractAmount(text), equals(120500.00));
    });

    test('Parse short SMS debit notifications', () {
      final text = "Paid Rs 250 for food.";
      expect(extractAmount(text), equals(250.00));
    });
  });
}

// Subclass to bypass database dependency in unit tests
class TestNaiveBayesClassifier extends NaiveBayesClassifier {
  TestNaiveBayesClassifier(Map<String, Map<String, int>> initialVocab)
      : super(dbKey: 'test_key') {
    // Populate vocabulary directly (they are public properties now)
    initialVocab.forEach((token, classCounts) {
      final counts = Map<String, int>.from(classCounts);
      vocabulary[token] = counts;

      counts.forEach((className, count) {
        classDocCounts[className] = (classDocCounts[className] ?? 0) + count;
        totalDocs += count;
      });
    });
  }

  @override
  Future<void> load() async {
    // Override load to read from local test memory instead of SQLite
  }

  @override
  Future<void> save() async {
    // Override save
  }
}
