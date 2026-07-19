import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../utils/transaction_parser.dart';
import '../utils/app_settings.dart';
import '../utils/app_snackbar.dart';
import '../utils/icon_helper.dart';
import '../services/perceptron_storage_service.dart';
import '../utils/bio_tagger.dart';

class ModelTrainingScreen extends StatefulWidget {
  const ModelTrainingScreen({super.key});

  @override
  State<ModelTrainingScreen> createState() => _ModelTrainingScreenState();
}

class _ModelTrainingScreenState extends State<ModelTrainingScreen> {
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TransactionParser _parser = TransactionParser();
  final TextEditingController _accountHintController = TextEditingController(); // NEW

  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  int? _accountId;
  int? _categoryId;
  String _type = 'debit';

  bool _isPredicting = false;
  bool _isSaving = false;
  bool _hasPredicted = false;
  bool _wasDetectedAsTransaction = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _accountHintController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final accounts = await DatabaseService.instance.getAllAccounts();
    final categories = await DatabaseService.instance.getAllCategories();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categories = categories;
      });
    }
  }

  // Step 1: Ask the current model what it thinks this notification means
  Future<void> _runPrediction() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
        AppSnackBar.show(context, 'Paste a notification message first', type: SnackBarType.warning);
        return;
    }

    setState(() => _isPredicting = true);

    final TransactionModel? tx = await _parser.parseNotification(
        appName: 'Manual Training',
        title: '',
        body: body,
    );

    // Also pull the raw account-span guess directly from the tagger for display
    final tokens = TokenFeatureExtractor.tokenize(body);
    final tagger = PerceptronStorageService.instance.tagger;
    final bioTags = tagger.predictSequence(tokens);
    final accountHintTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
        if (bioTags[i] == BioTag.bAccount || bioTags[i] == BioTag.iAccount) {
        accountHintTokens.add(tokens[i]);
        }
    }

    if (!mounted) return;

    setState(() {
        _isPredicting = false;
        _hasPredicted = true;

        if (tx != null) {
        _wasDetectedAsTransaction = true;
        _amountController.text = tx.amount > 0 ? tx.amount.toString() : '';
        _descController.text = tx.description;
        _type = tx.type;
        _accountId = tx.accountId;
        _categoryId = tx.categoryId;
        } else {
        _wasDetectedAsTransaction = false;
        _amountController.clear();
        _descController.clear();
        _type = 'debit';
        _accountId = _accounts.isNotEmpty ? _accounts.first.id : null;
        _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
        }
        _accountHintController.text = accountHintTokens.join(' '); // NEW — user can correct this
    });
  }

  // Step 2a: The prediction (or corrected fields) was right — reinforce it
  Future<void> _confirmAndTrain() async {
    final body = _bodyController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descController.text.trim();

    if (amount == null || amount <= 0) {
      AppSnackBar.show(context, 'Enter a valid amount', type: SnackBarType.warning);
      return;
    }
    if (description.isEmpty) {
      AppSnackBar.show(context, 'Enter the merchant/description', type: SnackBarType.warning);
      return;
    }
    if (_accountId == null || _categoryId == null) {
      AppSnackBar.show(context, 'Add an account and category first', type: SnackBarType.warning);
      return;
    }

    setState(() => _isSaving = true);

    final account = _accounts.firstWhere((a) => a.id == _accountId);
    final category = _categories.firstWhere((c) => c.id == _categoryId);

    await _parser.trainConfirm(
        body: body,
        categoryName: category.name,
        accountName: account.name,
        accountKeywords: account.keywords,
        description: description,
        amount: amount,
        type: _type,
        accountHintOverride: _accountHintController.text.trim(), // NEW
    );

    if (mounted) {
      setState(() => _isSaving = false);
      AppSnackBar.show(context, 'Model trained on this example!', type: SnackBarType.success);
      _resetToInput();
    }
  }

  // Step 2b: This was never a transaction — reinforce the ignore path instead
  Future<void> _trainAsIgnore() async {
    final body = _bodyController.text.trim();
    setState(() => _isSaving = true);

    await _parser.trainType(body, 'ignore');

    if (mounted) {
      setState(() => _isSaving = false);
      AppSnackBar.show(context, 'Model trained: this pattern will be ignored.', type: SnackBarType.neutral);
      _resetToInput();
    }
  }

  void _resetToInput() {
    setState(() {
      _hasPredicted = false;
      _wasDetectedAsTransaction = false;
      _bodyController.clear();
      _amountController.clear();
      _descController.clear();
      _accountHintController.clear();
      _type = 'debit';
    });
  }

  Widget _buildTypePill(String label, String value) {
    final isActive = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Your Model', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_hasPredicted)
            TextButton(
              onPressed: _isSaving ? null : _resetToInput,
              child: const Text('Start Over', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF818CF8), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Paste a notification, see what the model predicts, correct any mistakes, then confirm to reinforce the learning.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Notification Text', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                maxLines: 3,
                enabled: !_isSaving,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Rs. 500 debited from A/c XX1234 to Swiggy on 18-Jul-26',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!_hasPredicted)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isPredicting ? null : _runPrediction,
                  icon: _isPredicting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Icon(Icons.psychology_rounded, size: 18),
                  label: Text(_isPredicting ? 'Analyzing...' : 'Predict', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),

              if (_hasPredicted) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _runPrediction,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Re-run Prediction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_wasDetectedAsTransaction ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_wasDetectedAsTransaction ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _wasDetectedAsTransaction ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: _wasDetectedAsTransaction ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wasDetectedAsTransaction
                              ? 'Detected as a transaction — review the fields below'
                              : 'Not detected as a transaction — fill in the correct fields, or confirm it should be ignored',
                          style: TextStyle(
                            color: _wasDetectedAsTransaction ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Correct Answers', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: !_isSaving,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Amount (${AppSettings.currencySymbol})',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0F172A),
                        ),
                        child: Row(
                          children: [
                            _buildTypePill('Dr', 'debit'),
                            _buildTypePill('Cr', 'credit'),
                            _buildTypePill('Tr', 'transfer'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _descController,
                  enabled: !_isSaving,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Merchant / Description',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text('Account Identifier in Message', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                'The exact text (e.g. "XX1234" or "SBI") that tells the model which account this is',
                style: TextStyle(fontSize: 10, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                TextField(
                controller: _accountHintController,
                enabled: !_isSaving,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'e.g. XX1234',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                ),
                ),


                const SizedBox(height: 12),

                if (_accounts.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: _accountId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Account',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                    items: _accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                    onChanged: _isSaving ? null : (val) => setState(() => _accountId = val),
                  ),
                const SizedBox(height: 12),

                if (_categories.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: _categoryId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IconHelper.getIcon(c.icon), color: Color(c.color), size: 16),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: _isSaving ? null : (val) => setState(() => _categoryId = val),
                  ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _trainAsIgnore,
                        child: const Text('Not a Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _confirmAndTrain,
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Text('Confirm & Train', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}