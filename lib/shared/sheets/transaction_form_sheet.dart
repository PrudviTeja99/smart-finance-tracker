import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_settings.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/icon_helper.dart';
import '../../features/dashboard/utils/custom_select_field.dart';

Future<void> showTransactionFormSheet({
  required BuildContext context,
  required TransactionModel? editTx,
  required List<AccountModel> accounts,
  required List<CategoryModel> categories,
  required VoidCallback onSaved,
  required VoidCallback onDeleted,
  bool isDraft = false,
  Function(TransactionModel tx, String categoryName)? onConfirmDraft,
  Function(int id, String text)? onOnlineLookup,
  bool isLookupLoading = false,
  List<String> suggestions = const [],
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    builder: (context) {
      return _TransactionFormContent(
        editTx: editTx,
        accounts: accounts,
        categories: categories,
        onSaved: onSaved,
        onDeleted: onDeleted,
        isDraft: isDraft,
        onConfirmDraft: onConfirmDraft,
        onOnlineLookup: onOnlineLookup,
        isLookupLoading: isLookupLoading,
        suggestions: suggestions,
      );
    },
  );
}

class _TransactionFormContent extends StatefulWidget {
  final TransactionModel? editTx;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;
  final bool isDraft;
  final Function(TransactionModel tx, String categoryName)? onConfirmDraft;
  final Function(int id, String text)? onOnlineLookup;
  final bool isLookupLoading;
  final List<String> suggestions;

  const _TransactionFormContent({
    required this.editTx,
    required this.accounts,
    required this.categories,
    required this.onSaved,
    required this.onDeleted,
    this.isDraft = false,
    this.onConfirmDraft,
    this.onOnlineLookup,
    this.isLookupLoading = false,
    this.suggestions = const [],
  });

  @override
  State<_TransactionFormContent> createState() =>
      __TransactionFormContentState();
}

class __TransactionFormContentState extends State<_TransactionFormContent> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late String _type;
  late int _accountId;
  int? _toAccountId;
  late int _categoryId;
  late DateTime _selectedDate;
  bool _isKeyboardOpen = false;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.editTx != null;
    _amountController = TextEditingController(
        text: isEdit ? widget.editTx!.amount.toString() : '');
    _descController = TextEditingController(
        text: isEdit ? widget.editTx!.description : '');
    _type = isEdit ? widget.editTx!.type : 'debit';
    _accountId = isEdit
        ? widget.editTx!.accountId
        : (widget.accounts.isNotEmpty ? widget.accounts.first.id! : 1);
    _toAccountId = isEdit ? widget.editTx!.toAccountId : null;
    _categoryId = isEdit
        ? widget.editTx!.categoryId
        : (widget.categories.isNotEmpty ? widget.categories.first.id! : 1);
    _selectedDate = isEdit ? widget.editTx!.date : DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  IconData _getAccountIcon(String t) {
    switch (t) {
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.money;
    }
  }

  void _showAccountPicker(
      String pickerTitle, int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction;
    final double initialFraction;
    if (widget.accounts.length <= 3) {
      maxFraction = 0.35;
      initialFraction = 0.35;
    } else if (widget.accounts.length <= 6) {
      maxFraction = 0.6;
      initialFraction = 0.6;
    } else {
      maxFraction = 0.9;
      initialFraction = 0.5;
    }
    final minFraction = 0.25.clamp(0.1, initialFraction);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    pickerTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.accounts.length,
                      itemBuilder: (context, index) {
                        final acc = widget.accounts[index];
                        final isSelected = acc.id == currentSelected;
                        return InkWell(
                          onTap: () {
                            onSelected(acc.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getAccountIcon(acc.type),
                                    color: const Color(0xFF6366F1),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Balance: ${AppSettings.currencySymbol}${acc.balance.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryPicker(
      int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction;
    final double initialFraction;
    if (widget.categories.length <= 4) {
      maxFraction = 0.4;
      initialFraction = 0.4;
    } else if (widget.categories.length <= 8) {
      maxFraction = 0.65;
      initialFraction = 0.65;
    } else {
      maxFraction = 0.9;
      initialFraction = 0.5;
    }
    final minFraction = 0.25.clamp(0.1, initialFraction);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.categories.length,
                      itemBuilder: (context, index) {
                        final cat = widget.categories[index];
                        final isSelected = cat.id == currentSelected;
                        return InkWell(
                          onTap: () {
                            onSelected(cat.id!);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(cat.color).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    IconHelper.getIcon(cat.icon),
                                    color: Color(cat.color),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormTypePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editTx != null;
    final isDraftMode = widget.isDraft || (isEdit && widget.editTx!.status == 'draft');

    final currentBottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardNowOpen = currentBottomInset > 0;
    if (_isKeyboardOpen && !isKeyboardNowOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
    _isKeyboardOpen = isKeyboardNowOpen;

    final selectedAcc = widget.accounts.firstWhere((a) => a.id == _accountId,
        orElse: () => widget.accounts.first);
    final selectedToAcc = _type == 'transfer' && _toAccountId != null
        ? widget.accounts.firstWhere((a) => a.id == _toAccountId,
            orElse: () => widget.accounts.first)
        : null;
    final selectedCat = widget.categories.firstWhere(
        (c) => c.id == _categoryId,
        orElse: () => widget.categories.first);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 14,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDraftMode
                        ? 'Verify Draft Transaction'
                        : (isEdit ? 'Edit Transaction' : 'Add Transaction'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      tooltip: isDraftMode ? 'Discard Draft' : 'Delete Transaction',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(isDraftMode
                                ? 'Discard Draft?'
                                : 'Delete Transaction?'),
                            content: Text(isDraftMode
                                ? 'This will discard this transaction draft.'
                                : 'This will permanently delete this transaction.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Discard',
                                    style: TextStyle(color: Color(0xFFEF4444))),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          if (isDraftMode) {
                            await DatabaseService.instance
                                .deleteTransaction(widget.editTx!.id!);
                          } else {
                            await DatabaseService.instance
                                .deleteTransaction(widget.editTx!.id!);
                          }
                          if (context.mounted) Navigator.pop(context);
                          widget.onDeleted();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // --- ORIGINAL NOTIFICATION CARD (If editing a draft from Inbox) ---
              if (isDraftMode && widget.editTx?.body != null && widget.editTx!.body.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.editTx?.appName ?? 'INTERCEPTED',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF818CF8),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM, hh:mm a')
                                .format(widget.editTx?.date ?? DateTime.now()),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white38),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.editTx!.body,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.white70, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],

              // Type selector pills
              Row(
                children: [
                  _buildFormTypePill(
                    label: 'Expense',
                    isActive: _type == 'debit',
                    onTap: () => setState(() {
                      _type = 'debit';
                      _toAccountId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildFormTypePill(
                    label: 'Income',
                    isActive: _type == 'credit',
                    onTap: () => setState(() {
                      _type = 'credit';
                      _toAccountId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildFormTypePill(
                    label: 'Transfer',
                    isActive: _type == 'transfer',
                    onTap: () => setState(() {
                      _type = 'transfer';
                      if (_toAccountId == null && widget.accounts.length > 1) {
                        _toAccountId = widget.accounts
                            .firstWhere((a) => a.id != _accountId)
                            .id;
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Amount (${AppSettings.currencySymbol})',
                  labelStyle:
                      const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  prefixText: '${AppSettings.currencySymbol} ',
                  prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Account select field
              CustomSelectField(
                label: _type == 'transfer' ? 'From Account' : 'Account',
                value: selectedAcc.name,
                icon: _getAccountIcon(selectedAcc.type),
                onTap: () {
                  _showAccountPicker(
                    _type == 'transfer'
                        ? 'Select Source Account'
                        : 'Select Account',
                    _accountId,
                    (selectedId) => setState(() {
                      _accountId = selectedId;
                      if (_type == 'transfer' && _toAccountId == _accountId) {
                        _toAccountId = widget.accounts
                            .firstWhere((a) => a.id != _accountId)
                            .id;
                      }
                    }),
                  );
                },
              ),
              if (_type == 'transfer' && selectedToAcc != null) ...[
                CustomSelectField(
                  label: 'To Account',
                  value: selectedToAcc.name,
                  icon: _getAccountIcon(selectedToAcc.type),
                  onTap: () {
                    _showAccountPicker(
                      'Select Destination Account',
                      _toAccountId ?? _accountId,
                      (selectedId) =>
                          setState(() => _toAccountId = selectedId),
                    );
                  },
                ),
              ],

              // Category select field
              CustomSelectField(
                label: 'Category',
                value: selectedCat.name,
                icon: IconHelper.getIcon(selectedCat.icon),
                iconColor: Color(selectedCat.color),
                onTap: () {
                  _showCategoryPicker(
                    _categoryId,
                    (selectedId) => setState(() => _categoryId = selectedId),
                  );
                },
              ),
              const SizedBox(height: 8),

              // AI Category Suggestions (If in draft mode)
              if (isDraftMode && widget.suggestions.isNotEmpty) ...[
                const Text('AI Category Suggestions:',
                    style: TextStyle(fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.suggestions.map((sug) {
                    final isMatched = selectedCat.name.toLowerCase() == sug.toLowerCase();
                    return ChoiceChip(
                      label: Text(sug, style: const TextStyle(fontSize: 11)),
                      selected: isMatched,
                      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                          color: isMatched ? Colors.white : Colors.white70),
                      onSelected: (_) {
                        final catMatch = widget.categories.firstWhere(
                            (c) => c.name.toLowerCase() == sug.toLowerCase(),
                            orElse: () => selectedCat);
                        setState(() => _categoryId = catMatch.id!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Description / Remarks field
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Description / Remarks',
                  labelStyle:
                      const TextStyle(color: Colors.white54, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  prefixIcon: const Icon(Icons.description,
                      color: Color(0xFF6366F1), size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date picker field
              InkWell(
                onTap: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0F172A),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF6366F1), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date & Time',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('yyyy-MM-dd hh:mm a')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save / Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDraftMode
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amt = double.tryParse(_amountController.text) ?? 0.0;
                  if (amt <= 0) {
                    AppSnackBar.show(context, 'Please enter a valid amount',
                        type: SnackBarType.warning);
                    return;
                  }

                  final desc = _descController.text.trim();
                  final finalDesc = desc.isEmpty
                      ? (isEdit ? widget.editTx!.description : 'Manual Entry')
                      : desc;

                  final tx = TransactionModel(
                    id: isEdit ? widget.editTx!.id : null,
                    notificationLogId: isEdit ? widget.editTx!.notificationLogId : null,
                    appName: isEdit ? widget.editTx!.appName : 'Manual',
                    title: isEdit ? widget.editTx!.title : 'Manual',
                    body: isEdit
                        ? widget.editTx!.body
                        : 'Manual transaction entry',
                    amount: amt,
                    type: _type,
                    accountId: _accountId,
                    toAccountId: _toAccountId,
                    categoryId: _categoryId,
                    description: finalDesc,
                    date: _selectedDate,
                    status: 'confirmed',
                  );

                  if (isDraftMode && widget.onConfirmDraft != null) {
                    if (context.mounted) Navigator.pop(context);
                    widget.onConfirmDraft!(tx, selectedCat.name);
                    widget.onSaved();
                  } else {
                    if (isEdit) {
                      await DatabaseService.instance.updateTransaction(tx);
                    } else {
                      await DatabaseService.instance.insertTransaction(tx);
                    }
                    if (context.mounted) Navigator.pop(context);
                    widget.onSaved();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isDraftMode) ...[
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isDraftMode
                          ? 'Confirm & Verify'
                          : (isEdit ? 'Save Changes' : 'Confirm Transaction'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
