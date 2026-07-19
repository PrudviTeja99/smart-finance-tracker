import 'dart:math';

/// Category prediction result containing matched category or a suggested new category
class CategoryPrediction {
  final int? matchedCategoryId;
  final String categoryName;
  final double confidence;
  final bool isNewSuggestion;

  CategoryPrediction({
    this.matchedCategoryId,
    required this.categoryName,
    required this.confidence,
    this.isNewSuggestion = false,
  });
}

class AccountPrediction {
  final int? matchedAccountId;
  final String accountName;
  final double confidence;

  AccountPrediction({
    this.matchedAccountId,
    required this.accountName,
    required this.confidence,
  });
}

/// Online Linear Perceptron Classifier for Category & Type prediction
class CategoryClassifier {
  final Map<String, Map<String, double>> categoryWeights;
  final Map<String, Map<String, double>> typeWeights;
  final Map<String, Map<String, double>> accountWeights; // NEW

  CategoryClassifier({
    Map<String, Map<String, double>>? initialCategoryWeights,
    Map<String, Map<String, double>>? initialTypeWeights,
    Map<String, Map<String, double>>? initialAccountWeights, // NEW
  })  : categoryWeights = initialCategoryWeights ?? {},
        typeWeights = initialTypeWeights ?? {},
        accountWeights = initialAccountWeights ?? {}; // NEW

  /// Predicts Category with confidence score and smart "Suggest New Category" logic
  CategoryPrediction predictCategory({
    required String text,
    required String merchantName,
    required List<Map<String, dynamic>> existingCategories, // List of {id, name, icon}
  }) {
    final features = _extractFeatures(text, merchantName);
    final Map<String, double> scores = {};

    // 1. Calculate Perceptron linear sum scores for each existing category
    for (var cat in existingCategories) {
      final name = cat['name'] as String;
      double score = 0.0;

      for (var feat in features) {
        if (categoryWeights.containsKey(feat) && categoryWeights[feat]!.containsKey(name)) {
          score += categoryWeights[feat]![name]!;
        }
      }

      // Add cold-start heuristic boost for known merchant keywords
      score += _getColdStartCategoryBoost(text, merchantName, name);
      scores[name] = score;
    }

    // 2. Softmax-like Probability Normalization
    if (scores.isEmpty) {
      return CategoryPrediction(
        categoryName: 'Others',
        confidence: 0.0,
        isNewSuggestion: true,
      );
    }

    final double maxScore = scores.values.reduce(max);
    final Map<String, double> expScores = {};
    double sumExp = 0.0;

    scores.forEach((name, s) {
      final expVal = exp((s - maxScore).clamp(-20.0, 0.0));
      expScores[name] = expVal;
      sumExp += expVal;
    });

    String bestCatName = existingCategories.first['name'] as String;
    double maxProb = 0.0;

    expScores.forEach((name, expVal) {
      final prob = sumExp > 0 ? expVal / sumExp : 0.0;
      if (prob > maxProb) {
        maxProb = prob;
        bestCatName = name;
      }
    });

    final matchedCat = existingCategories.firstWhere(
      (c) => c['name'] == bestCatName,
      orElse: () => existingCategories.first,
    );

    // 3. High Confidence -> Auto-select existing category
    if (maxProb >= 0.50 || (scores[bestCatName] ?? 0) > 3.0) {
      return CategoryPrediction(
        matchedCategoryId: matchedCat['id'] as int,
        categoryName: bestCatName,
        confidence: maxProb,
        isNewSuggestion: false,
      );
    }

    // 4. Low Confidence / Unknown Merchant -> Generate a Smart Suggested Category Name
    final suggestedName = _generateSuggestedCategoryName(merchantName, text);
    return CategoryPrediction(
      matchedCategoryId: null,
      categoryName: suggestedName,
      confidence: maxProb,
      isNewSuggestion: true,
    );
  }

  /// Predicts which account a notification belongs to, combining learned
  /// weights with a strong cold-start boost from the user's own keywords.
  AccountPrediction predictAccount({
    required String text,
    required String accountHintText, // BIO-tagged account tokens (masked digits, etc.)
    required List<Map<String, dynamic>> existingAccounts, // {id, name, keywords}
  }) {
    final features = _extractFeatures(text, accountHintText);
    final Map<String, double> scores = {};

    for (var acc in existingAccounts) {
      final name = acc['name'] as String;
      double score = 0.0;
      for (var feat in features) {
        if (accountWeights.containsKey(feat) && accountWeights[feat]!.containsKey(name)) {
          score += accountWeights[feat]![name]!;
        }
      }
      score += _getColdStartAccountBoost(text, accountHintText, acc);
      scores[name] = score;
    }

    if (scores.isEmpty) {
      return AccountPrediction(accountName: '', confidence: 0.0);
    }

    final double maxScore = scores.values.reduce(max);
    final Map<String, double> expScores = {};
    double sumExp = 0.0;
    scores.forEach((name, s) {
      final expVal = exp((s - maxScore).clamp(-20.0, 0.0));
      expScores[name] = expVal;
      sumExp += expVal;
    });

    String bestName = existingAccounts.first['name'] as String;
    double maxProb = 0.0;
    expScores.forEach((name, expVal) {
      final prob = sumExp > 0 ? expVal / sumExp : 0.0;
      if (prob > maxProb) {
        maxProb = prob;
        bestName = name;
      }
    });

    final matched = existingAccounts.firstWhere((a) => a['name'] == bestName, orElse: () => existingAccounts.first);
    return AccountPrediction(
      matchedAccountId: matched['id'] as int,
      accountName: bestName,
      confidence: maxProb,
    );
  }

  double _getColdStartAccountBoost(String text, String accountHintText, Map<String, dynamic> account) {
    final lower = ('$text $accountHintText').toLowerCase();
    final keywordsStr = account['keywords'] as String? ?? '';
    final keywords = keywordsStr.split(',').map((k) => k.trim().toLowerCase()).where((k) => k.isNotEmpty);
    for (var kw in keywords) {
      if (lower.contains(kw)) return 8.0; // user-provided keywords are a strong, explicit signal
    }
    return 0.0;
  }

  /// Predicts Transaction Type: debit, credit, or transfer
  String predictType(String text) {
    final features = _extractFeatures(text, '');
    final types = ['debit', 'credit', 'transfer', 'ignore'];
    String bestType = 'debit';
    double maxScore = -double.infinity;

    for (var type in types) {
      double score = 0.0;
      for (var feat in features) {
        if (typeWeights.containsKey(feat) && typeWeights[feat]!.containsKey(type)) {
          score += typeWeights[feat]![type]!;
        }
      }
      // Heuristic priors
      final lower = text.toLowerCase();
      if (type == 'debit' && (lower.contains('debited') || lower.contains('spent') || lower.contains('paid'))) score += 5.0;
      if (type == 'credit' && (lower.contains('credited') || lower.contains('received') || lower.contains('deposited'))) score += 5.0;
      if (type == 'transfer' && (lower.contains('transferred') || lower.contains('neft') || lower.contains('imps'))) score += 5.0;

      if (score > maxScore) {
        maxScore = score;
        bestType = type;
      }
    }
    return bestType;
  }

  /// Online weight update for Category & Type learning
  void trainCategory({
  required String text,
  required String merchantName,
  required String correctCategoryName,
  required List<Map<String, dynamic>> existingCategories,
  double learningRate = 1.0,
}) {
  final predictedCategoryName = predictCategory(
    text: text,
    merchantName: merchantName,
    existingCategories: existingCategories,
  ).categoryName;

  if (correctCategoryName == predictedCategoryName) return;

  final features = _extractFeatures(text, merchantName);
  for (var feat in features) {
    categoryWeights.putIfAbsent(feat, () => {});
    categoryWeights[feat]![correctCategoryName] = (categoryWeights[feat]![correctCategoryName] ?? 0.0) + learningRate;
    categoryWeights[feat]![predictedCategoryName] = (categoryWeights[feat]![predictedCategoryName] ?? 0.0) - learningRate;
  }
}

/// Online weight update for account learning, using the same
/// self-computed-prediction pattern as trainCategory.
void trainAccount({
  required String text,
  required String accountHintText,
  required String correctAccountName,
  required List<Map<String, dynamic>> existingAccounts,
  double learningRate = 1.0,
}) {
  final predictedAccountName = predictAccount(
    text: text,
    accountHintText: accountHintText,
    existingAccounts: existingAccounts,
  ).accountName;

  if (correctAccountName == predictedAccountName) return;

  final features = _extractFeatures(text, accountHintText);
  for (var feat in features) {
    accountWeights.putIfAbsent(feat, () => {});
    accountWeights[feat]![correctAccountName] = (accountWeights[feat]![correctAccountName] ?? 0.0) + learningRate;
    accountWeights[feat]![predictedAccountName] = (accountWeights[feat]![predictedAccountName] ?? 0.0) - learningRate;
  }
}

  /// Online weight update for Transaction Type learning (debit/credit/transfer)
  void trainType({
    required String text,
    required String correctType,
    double learningRate = 1.0,
  }) {
    final predictedType = predictType(text);
    if (correctType == predictedType) return;

    final features = _extractFeatures(text, '');
    for (var feat in features) {
      typeWeights.putIfAbsent(feat, () => {});
      typeWeights[feat]![correctType] = (typeWeights[feat]![correctType] ?? 0.0) + learningRate;
      typeWeights[feat]![predictedType] = (typeWeights[feat]![predictedType] ?? 0.0) - learningRate;
    }
  }

  List<String> _extractFeatures(String text, String merchantName) {
    final List<String> feats = [];
    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));

    for (var w in words) {
      if (w.length > 2) feats.add('word:$w');
    }
    if (merchantName.isNotEmpty) {
      feats.add('merchant:${merchantName.toLowerCase()}');
    }
    return feats;
  }

  double _getColdStartCategoryBoost(String text, String merchant, String categoryName) {
    final mLower = merchant.toLowerCase();
    final cLower = categoryName.toLowerCase();

    if ((cLower.contains('food') || cLower.contains('dining')) &&
        (mLower.contains('swiggy') || mLower.contains('zomato') || mLower.contains('kfc') || mLower.contains('mcdonald') || mLower.contains('starbucks'))) {
      return 6.0;
    }
    if ((cLower.contains('shopping') || cLower.contains('grocer')) &&
        (mLower.contains('amazon') || mLower.contains('flipkart') || mLower.contains('blinkit') || mLower.contains('zepto') || mLower.contains('mart'))) {
      return 6.0;
    }
    if ((cLower.contains('travel') || cLower.contains('transport')) &&
        (mLower.contains('uber') || mLower.contains('ola') || mLower.contains('rapido') || mLower.contains('irctc') || mLower.contains('indigo'))) {
      return 6.0;
    }
    if ((cLower.contains('bill') || cLower.contains('utilit')) &&
        (mLower.contains('bescom') || mLower.contains('airtel') || mLower.contains('jio') || mLower.contains('recharge'))) {
      return 6.0;
    }
    return 0.0;
  }

  String _generateSuggestedCategoryName(String merchantName, String text) {
    final lower = '$merchantName $text'.toLowerCase();

    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('kfc') || lower.contains('mcdonald') || lower.contains('starbucks') || lower.contains('restaurant') || lower.contains('food') || lower.contains('dine')) {
      return 'Food & Dining';
    }
    if (lower.contains('uber') || lower.contains('ola') || lower.contains('rapido') || lower.contains('irctc') || lower.contains('indigo') || lower.contains('fuel') || lower.contains('petrol')) {
      return 'Cab & Travel';
    }
    if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra') || lower.contains('blinkit') || lower.contains('zepto') || lower.contains('mart') || lower.contains('shopping')) {
      return 'Shopping & Groceries';
    }
    if (lower.contains('airtel') || lower.contains('jio') || lower.contains('recharge') || lower.contains('bill') || lower.contains('electricity') || lower.contains('water') || lower.contains('gas')) {
      return 'Bills & Utilities';
    }

    if (merchantName.isNotEmpty) {
      final cleanM = merchantName.trim();
      return '$cleanM Expenses';
    }
    return 'General Expenses';
  }
}
