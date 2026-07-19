/// Sequence labels for field extraction
enum BioTag {
  bAmount,
  iAmount,
  bMerchant,
  iMerchant,
  bAccount,
  iAccount,
  bType,
  o,
}

extension BioTagExtension on BioTag {
  String get name {
    switch (this) {
      case BioTag.bAmount:
        return 'B-AMOUNT';
      case BioTag.iAmount:
        return 'I-AMOUNT';
      case BioTag.bMerchant:
        return 'B-MERCHANT';
      case BioTag.iMerchant:
        return 'I-MERCHANT';
      case BioTag.bAccount:
        return 'B-ACCOUNT';
      case BioTag.iAccount:
        return 'I-ACCOUNT';
      case BioTag.bType:
        return 'B-TYPE';
      case BioTag.o:
        return 'O';
    }
  }

  static BioTag fromString(String tagStr) {
    switch (tagStr.toUpperCase()) {
      case 'B-AMOUNT':
        return BioTag.bAmount;
      case 'I-AMOUNT':
        return BioTag.iAmount;
      case 'B-MERCHANT':
        return BioTag.bMerchant;
      case 'I-MERCHANT':
        return BioTag.iMerchant;
      case 'B-ACCOUNT':
        return BioTag.bAccount;
      case 'I-ACCOUNT':
        return BioTag.iAccount;
      case 'B-TYPE':
        return BioTag.bType;
      default:
        return BioTag.o;
    }
  }
}

/// Tokenizer & Feature Extractor for BIO Sequence Labeling
class TokenFeatureExtractor {
  static final RegExp _currencyRegex = RegExp(r'^(rs\.?|₹|inr|usd|\$)$', caseSensitive: false);
  static final RegExp _numericRegex = RegExp(r'^\d+([.,]\d+)?$');
  static final RegExp _accountRegex = RegExp(r'^(a/c|ac|account|card|ending|x+)\b', caseSensitive: false);

  /// Derives BIO true-tags from the user's CONFIRMED field values, by locating
/// them inside the tokenized notification text. This is weak/heuristic
/// supervision (we don't have exact character spans from the user), but it's
/// far more accurate than labeling every token the same tag.
static List<BioTag> buildTrueTagsFromConfirmation({
  required List<String> tokens,
  required double amount,
  required String description,
  required List<String> accountKeywords,
}) {
  final tags = List<BioTag>.filled(tokens.length, BioTag.o);

  // 1. Amount: tag any token whose numeric value matches the confirmed amount
  for (int i = 0; i < tokens.length; i++) {
    final cleaned = tokens[i].replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) continue;
    final parsed = double.tryParse(cleaned);
    if (parsed != null && parsed == amount) {
      tags[i] = BioTag.bAmount;
    }
  }

  // 2. Merchant/description: find the matching consecutive token span
  final descWords = description.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (descWords.isNotEmpty) {
    final lowerTokens = tokens.map((t) => t.toLowerCase()).toList();
    final lowerDescWords = descWords.map((w) => w.toLowerCase()).toList();

    for (int i = 0; i <= tokens.length - lowerDescWords.length; i++) {
      bool matches = true;
      for (int j = 0; j < lowerDescWords.length; j++) {
        if (!lowerTokens[i + j].contains(lowerDescWords[j])) {
          matches = false;
          break;
        }
      }
      if (matches) {
        tags[i] = BioTag.bMerchant;
        for (int j = 1; j < lowerDescWords.length; j++) {
          tags[i + j] = BioTag.iMerchant;
        }
        break;
      }
    }
  }

  // 3. Account: tag tokens matching the account's keywords or a masked-digit pattern
  for (int i = 0; i < tokens.length; i++) {
    if (tags[i] != BioTag.o) continue; // don't overwrite amount/merchant tags
    final lower = tokens[i].toLowerCase();
    final hasMask = tokens[i].contains('X') || tokens[i].contains('x') || tokens[i].contains('*');
    final matchesKeyword = accountKeywords.any((kw) => kw.trim().isNotEmpty && lower.contains(kw.trim().toLowerCase()));
    if (hasMask || matchesKeyword) {
      tags[i] = BioTag.bAccount;
    }
  }

  return tags;
}

  /// Splits free-text notification into individual tokens
  static List<String> tokenize(String text) {
    if (text.trim().isEmpty) return [];
    // Tokenize by space and common punctuation while keeping amounts intact
    final rawTokens = text.trim().split(RegExp(r'\s+'));
    final List<String> result = [];

    for (var token in rawTokens) {
      if (token.isEmpty) continue;
      // Strip trailing periods or commas if not part of a float
      String cleaned = token;
      if (cleaned.length > 1 && (cleaned.endsWith('.') || cleaned.endsWith(',')) && !_numericRegex.hasMatch(cleaned)) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      result.add(cleaned);
    }
    return result;
  }

  /// Extracts contextual features for a token at position [index] in [tokens]
  static List<String> extractFeatures({
    required List<String> tokens,
    required int index,
    Set<String>? userAccountKeywords,
  }) {
    final String current = tokens[index];
    final String lower = current.toLowerCase();
    final List<String> features = [];

    // 1. Current token features
    features.add('word:$lower');
    features.add('len:${current.length}');

    final isNumeric = _numericRegex.hasMatch(current);
    if (isNumeric) features.add('is_numeric');

    final isCurrency = _currencyRegex.hasMatch(lower);
    if (isCurrency) features.add('is_currency');

    final isAllCaps = current.length > 1 && current == current.toUpperCase() && RegExp(r'[A-Z]').hasMatch(current);
    if (isAllCaps) features.add('is_all_caps');

    final isTitleCase = current.length > 1 && current[0] == current[0].toUpperCase() && current.substring(1) == current.substring(1).toLowerCase();
    if (isTitleCase) features.add('is_title_case');

    if (current.contains('X') || current.contains('x') || current.contains('*')) {
      features.add('has_mask_char');
    }

    // 2. User Account Keyword Match
    if (userAccountKeywords != null && userAccountKeywords.isNotEmpty) {
      for (var kw in userAccountKeywords) {
        if (kw.trim().isNotEmpty && lower.contains(kw.toLowerCase())) {
          features.add('matches_user_account_kw');
          break;
        }
      }
    }

    // 3. Previous Token Context (i - 1)
    if (index > 0) {
      final prev = tokens[index - 1];
      final prevLower = prev.toLowerCase();
      features.add('prev_word:$prevLower');

      if (_currencyRegex.hasMatch(prevLower)) {
        features.add('prev_is_currency');
      }
      if (_accountRegex.hasMatch(prevLower) || prevLower == 'from' || prevLower == 'at') {
        features.add('prev_is_acct_prefix:$prevLower');
      }
      if (prevLower == 'to' || prevLower == 'at' || prevLower == 'vpa' || prevLower == 'info' || prevLower == 'for') {
        features.add('prev_is_merchant_prefix:$prevLower');
      }
    } else {
      features.add('BOS'); // Beginning of sentence
    }

    // 4. Next Token Context (i + 1)
    if (index < tokens.length - 1) {
      final next = tokens[index + 1];
      final nextLower = next.toLowerCase();
      features.add('next_word:$nextLower');

      if (nextLower == 'debited' || nextLower == 'credited' || nextLower == 'spent' || nextLower == 'received') {
        features.add('next_is_tx_type:$nextLower');
      }
    } else {
      features.add('EOS'); // End of sentence
    }

    return features;
  }
}

/// On-Device Structured Averaged Perceptron Sequence Tagger
class StructuredPerceptronTagger {
  // Feature weights map: [FeatureName -> [TagString -> WeightDouble]]
  final Map<String, Map<String, double>> weightTable;

  StructuredPerceptronTagger({Map<String, Map<String, double>>? initialWeights})
      : weightTable = initialWeights ?? {};

  /// Predicts the optimal BIO tag sequence for a given list of tokens
  List<BioTag> predictSequence(List<String> tokens, {Set<String>? userAccountKeywords}) {
    if (tokens.isEmpty) return [];

    final List<BioTag> predicted = [];

    for (int i = 0; i < tokens.length; i++) {
      final features = TokenFeatureExtractor.extractFeatures(
        tokens: tokens,
        index: i,
        userAccountKeywords: userAccountKeywords,
      );

      BioTag bestTag = BioTag.o;
      double maxScore = -double.infinity;

      for (var tag in BioTag.values) {
        final tagStr = tag.name;
        double score = 0.0;

        for (var feat in features) {
          if (weightTable.containsKey(feat) && weightTable[feat]!.containsKey(tagStr)) {
            score += weightTable[feat]![tagStr]!;
          }
        }

        // Rule-assisted prior heuristics when model is untrained/cold
        score += _getColdStartHeuristicScore(tokens, i, tag, features);

        if (score > maxScore) {
          maxScore = score;
          bestTag = tag;
        }
      }

      predicted.add(bestTag);
    }

    return predicted;
  }

  /// Online single-step Perceptron weight update (Incremental Learning)
  void trainSequence({
    required List<String> tokens,
    required List<BioTag> trueTags,
    required List<BioTag> predictedTags,
    Set<String>? userAccountKeywords,
    double learningRate = 1.0,
  }) {
    if (tokens.length != trueTags.length || tokens.length != predictedTags.length) return;

    for (int i = 0; i < tokens.length; i++) {
      final trueTagStr = trueTags[i].name;
      final predTagStr = predictedTags[i].name;

      if (trueTagStr == predTagStr) continue; // No error

      final features = TokenFeatureExtractor.extractFeatures(
        tokens: tokens,
        index: i,
        userAccountKeywords: userAccountKeywords,
      );

      for (var feat in features) {
        weightTable.putIfAbsent(feat, () => {});

        // Reward true tag features
        weightTable[feat]![trueTagStr] = (weightTable[feat]![trueTagStr] ?? 0.0) + learningRate;

        // Penalize false predicted tag features
        weightTable[feat]![predTagStr] = (weightTable[feat]![predTagStr] ?? 0.0) - learningRate;
      }
    }
  }

  /// Rule-assisted prior heuristics for cold start before user training
  double _getColdStartHeuristicScore(List<String> tokens, int i, BioTag tag, List<String> features) {
    final lower = tokens[i].toLowerCase();
    double bonus = 0.0;

    switch (tag) {
      case BioTag.bAmount:
        if (features.contains('is_numeric') && features.contains('prev_is_currency')) bonus += 5.0;
        if (features.contains('is_numeric') && (lower.contains('.') || lower.contains(','))) bonus += 2.0;
        break;
      case BioTag.bAccount:
        if (features.contains('matches_user_account_kw')) bonus += 10.0;
        if (features.contains('has_mask_char')) bonus += 6.0;
        break;
      case BioTag.bMerchant:
        if (features.contains('is_title_case') && features.contains('prev_is_merchant_prefix:to')) bonus += 4.0;
        if (features.contains('is_all_caps') && features.contains('prev_is_merchant_prefix:at')) bonus += 4.0;
        break;
      case BioTag.bType:
        if (lower == 'debited' || lower == 'credited' || lower == 'spent' || lower == 'received' || lower == 'paid') bonus += 5.0;
        break;
      default:
        break;
    }
    return bonus;
  }
}
