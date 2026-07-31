import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/perceptron_storage_service.dart';
import 'bio_tagger.dart';
import 'category_classifier.dart';

class TransactionParser {
  // Parses raw notification and returns a TransactionModel configured as 'pending'.
  Future<TransactionModel?> parseNotification({
    required String? appName,
    required String title,
    required String body,
    DateTime? date,
    int? notificationLogId,
  }) async {
    final cleanBody = body.toLowerCase();

    // 1. Rule-based Pre-filter for non-financial ignore-keywords
    final ignoreKeywords = ['balance', 'bal', 'available limit', 'otp', 'verification code', 'security code', 'login'];
    for (var kw in ignoreKeywords) {
      if (cleanBody.contains(kw)) {
        return null;
      }
    }

    final dbService = DatabaseService.instance;
    final accounts = await dbService.getAllAccounts();
    final categories = await dbService.getAllCategories();

    // Build user account keyword set
    final Set<String> userAccountKeywords = {};
    for (var acc in accounts) {
      for (var kw in acc.keywords.split(',')) {
        if (kw.trim().isNotEmpty) userAccountKeywords.add(kw.trim());
      }
    }

    // 2. Tokenize & Predict BIO Sequence Tags
    final tokens = TokenFeatureExtractor.tokenize(body);
    final tagger = PerceptronStorageService.instance.tagger;
    final bioTags = tagger.predictSequence(tokens, userAccountKeywords: userAccountKeywords);

    // 3. Extract Amount from BIO tags (or fallback regex)
    double amount = 0.0;
    final amountTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (bioTags[i] == BioTag.bAmount || bioTags[i] == BioTag.iAmount) {
        amountTokens.add(tokens[i]);
      }
    }

    if (amountTokens.isNotEmpty) {
      final amountStr = amountTokens.join('').replaceAll(RegExp(r'[^0-9.]'), '');
      amount = double.tryParse(amountStr) ?? 0.0;
    }

    if (amount <= 0.0) {
      final amountPattern = RegExp(r'(?:rs|inr|amt|received|sent|paid|spent|debited|credited|₹)\.?\s*(?:rs\.?|inr\.?|₹)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false);
      final match = amountPattern.firstMatch(body);
      if (match != null) {
        amount = double.tryParse(match.group(1)?.replaceAll(',', '') ?? '0.0') ?? 0.0;
      }
    }

    if (amount <= 0.0) return null; // Non-financial notification

    // 4. Predict Transaction Type using active learning classifier
    final classifier = PerceptronStorageService.instance.classifier;
    final predictedType = classifier.predictType(body);

    // Active Learning Guard: If the model learned that this pattern is 'ignore', do not auto-draft!
    if (predictedType == 'ignore') {
      return null;
    }

    // Chat App Filter: WhatsApp/chat messages without explicit bank keywords should not be auto-drafted
    final lowerApp = (appName ?? '').toLowerCase();
    final isChatApp = lowerApp.contains('whatsapp') || lowerApp.contains('chat') || lowerApp.contains('telegram');
    final hasBankKeyword = cleanBody.contains('debited') ||
        cleanBody.contains('credited') ||
        cleanBody.contains('paid to') ||
        cleanBody.contains('received') ||
        cleanBody.contains('spent') ||
        cleanBody.contains('transferred') ||
        cleanBody.contains('vpa') ||
        cleanBody.contains('upi') ||
        cleanBody.contains('a/c') ||
        cleanBody.contains('acct') ||
        cleanBody.contains('bank');

    if (isChatApp && !hasBankKeyword && predictedType != 'debit' && predictedType != 'credit') {
      return null;
    }

    // 5. Extract & Match Account (learned + keyword cold-start)
    int accountId = accounts.isNotEmpty ? accounts.first.id! : 1;
    final accountTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (bioTags[i] == BioTag.bAccount || bioTags[i] == BioTag.iAccount) {
        accountTokens.add(tokens[i]);
      }
    }
    final accountHintText = accountTokens.join(' ');

    if (accounts.isNotEmpty) {
      final accountPrediction = classifier.predictAccount(
        text: body,
        accountHintText: accountHintText,
        existingAccounts: accounts.map((a) => a.toMap()).toList(),
      );
      if (accountPrediction.matchedAccountId != null) {
        accountId = accountPrediction.matchedAccountId!;
      }
    }

    // 6. Extract Merchant / Description from BIO tags
    String description = title;
    final merchantTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (bioTags[i] == BioTag.bMerchant || bioTags[i] == BioTag.iMerchant) {
        merchantTokens.add(tokens[i]);
      }
    }

    if (merchantTokens.isNotEmpty) {
      description = merchantTokens.join(' ');
    } else {
      final merchantPattern = RegExp(r'(?:paid to|spent on|at|to|sent to|transfer to)\s+([a-zA-Z0-9\s\.\*]+?)(?:\s+from|\s+on|\s+via|\.|\d|\n|$)', caseSensitive: false);
      final mMatch = merchantPattern.firstMatch(body);
      if (mMatch != null) {
        final name = mMatch.group(1)?.trim() ?? '';
        if (name.isNotEmpty && name.length < 30) {
          description = name;
        }
      }
    }

    // 7. Predict Category using CategoryClassifier
    final categoryListMaps = categories.map((c) => c.toMap()).toList();
    final catPrediction = classifier.predictCategory(
      text: body,
      merchantName: description,
      existingCategories: categoryListMaps,
    );

    int categoryId = categories.isNotEmpty ? categories.last.id! : 1;
    if (catPrediction.matchedCategoryId != null) {
      categoryId = catPrediction.matchedCategoryId!;
    } else {
      // Find category matching categoryName or default to Others
      final matchedCat = categories.firstWhere(
        (c) => c.name.toLowerCase() == catPrediction.categoryName.toLowerCase(),
        orElse: () => categories.firstWhere((c) => c.name == 'Others', orElse: () => categories.last),
      );
      categoryId = matchedCat.id!;
    }

    return TransactionModel(
      appName: appName,
      title: title,
      body: body,
      amount: amount,
      type: predictedType,
      accountId: accountId,
      categoryId: categoryId,
      description: description,
      date: date ?? DateTime.now(),
      status: 'pending',
      notificationLogId: notificationLogId,
    );
  }

  // Trains the type classifier with a specific label (debit, credit, transfer, ignore)
  Future<void> trainType(String text, String type) async {
  final storage = PerceptronStorageService.instance;
  storage.classifier.trainType(text: text, correctType: type);
  await storage.saveWeights();
}

  // Trains BIO sequence tagger and category/type/account classifier using confirmed user inputs
Future<void> trainConfirm({
  required String body,
  required String categoryName,
  required String accountName,
  required String accountKeywords,
  required String description,
  required double amount,
  String? type,
  String? accountHintOverride, // NEW
}) async {
  final storage = PerceptronStorageService.instance;
  final classifier = storage.classifier;

  final categories = await DatabaseService.instance.getAllCategories();
  classifier.trainCategory(
    text: body,
    merchantName: description,
    correctCategoryName: categoryName,
    existingCategories: categories.map((c) => c.toMap()).toList(),
  );

  if (type != null && type.isNotEmpty) {
    classifier.trainType(text: body, correctType: type);
  }

  final tokens = TokenFeatureExtractor.tokenize(body);
  List<BioTag>? trueTags;
  if (tokens.isNotEmpty) {
    trueTags = TokenFeatureExtractor.buildTrueTagsFromConfirmation(
      tokens: tokens,
      amount: amount,
      description: description,
      accountKeywords: accountKeywords.split(','),
      accountHintOverride: accountHintOverride, // NEW
    );
    final predictedTags = storage.tagger.predictSequence(tokens);
    storage.tagger.trainSequence(tokens: tokens, trueTags: trueTags, predictedTags: predictedTags);
  }

  final accounts = await DatabaseService.instance.getAllAccounts();
  final accountHintTokens = <String>[];
  if (trueTags != null) {
    for (int i = 0; i < tokens.length; i++) {
      if (trueTags[i] == BioTag.bAccount || trueTags[i] == BioTag.iAccount) accountHintTokens.add(tokens[i]);
    }
  }
  classifier.trainAccount(
    text: body,
    accountHintText: accountHintTokens.join(' '),
    correctAccountName: accountName,
    existingAccounts: accounts.map((a) => a.toMap()).toList(),
  );

  await storage.saveWeights();
}
}
