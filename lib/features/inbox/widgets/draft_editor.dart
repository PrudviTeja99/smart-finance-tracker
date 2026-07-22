import 'package:finance_tracker/models/account_model.dart';
import 'package:finance_tracker/models/category_model.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/screens/dashboard_screen.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/utils/app_settings.dart';
import 'package:finance_tracker/utils/app_snackbar.dart';
import 'package:finance_tracker/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DraftEditor extends StatefulWidget {
  final TransactionModel tx;
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final Future<bool> Function(TransactionModel, String) onConfirm;
  final Function(int) onDiscard;
  final Function(int, String) onOnlineLookup;
  final bool isLookupLoading;
  final List<String> suggestions;

  const DraftEditor({
    super.key,
    required this.tx,
    required this.accounts,
    required this.categories,
    required this.onConfirm,
    required this.onDiscard,
    required this.onOnlineLookup,
    required this.isLookupLoading,
    required this.suggestions,
  });

  @override
  State<DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<DraftEditor> {
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late String _type;
  late int _accountId;
  int? _toAccountId;
  late int _categoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.tx.amount.toString());
    _descController = TextEditingController(text: widget.tx.description);
    _type = widget.tx.type;
    _accountId = widget.tx.accountId;
    _toAccountId = widget.tx.toAccountId;
    _categoryId = widget.tx.categoryId;
    _selectedDate = widget.tx.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere(
        (c) => c.id == _categoryId,
        orElse: () => widget.categories.last);
    final selectedAcc = widget.accounts.firstWhere((a) => a.id == _accountId,
        orElse: () => widget.accounts.first);
    final selectedToAcc = _type == 'transfer' && _toAccountId != null
        ? widget.accounts.firstWhere((a) => a.id == _toAccountId,
            orElse: () => widget.accounts.first)
        : null;

    IconData getAccountIcon(String t) {
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.tx.body,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Amount (${AppSettings.currencySymbol})',
                      labelStyle:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      prefixText: '${AppSettings.currencySymbol} ',
                      prefixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF0F172A),
                    ),
                    child: Row(
                      children: [
                        _buildMiniTypePill(
                          label: 'Dr',
                          isActive: _type == 'debit',
                          onTap: () => setState(() {
                            _type = 'debit';
                            _toAccountId = null;
                          }),
                        ),
                        _buildMiniTypePill(
                          label: 'Cr',
                          isActive: _type == 'credit',
                          onTap: () => setState(() {
                            _type = 'credit';
                            _toAccountId = null;
                          }),
                        ),
                        _buildMiniTypePill(
                          label: 'Tr',
                          isActive: _type == 'transfer',
                          onTap: () => setState(() {
                            _type = 'transfer';
                            if (_toAccountId == null &&
                                widget.accounts.length > 1) {
                              _toAccountId = widget.accounts
                                  .firstWhere((a) => a.id != _accountId)
                                  .id;
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomSelectField(
              label: _type == 'transfer' ? 'From Account' : 'Account',
              value: selectedAcc.name,
              icon: getAccountIcon(selectedAcc.type),
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
                icon: getAccountIcon(selectedToAcc.type),
                onTap: () {
                  _showAccountPicker(
                    'Select Destination Account',
                    _toAccountId ?? _accountId,
                    (selectedId) => setState(() => _toAccountId = selectedId),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            CustomSelectField(
              label: 'Category',
              value: selectedCategory.name,
              icon: IconHelper.getIcon(selectedCategory.icon),
              iconColor: Color(selectedCategory.color),
              onTap: () {
                _showCategoryPicker(
                  _categoryId,
                  (selectedId) => setState(() => _categoryId = selectedId),
                );
              },
            ),
            if (widget.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.suggestions.map((suggestName) {
                  final isNew = !widget.categories.any(
                      (c) => c.name.toLowerCase() == suggestName.toLowerCase());
                  final label = isNew
                      ? '✨ Suggest New Category: $suggestName'
                      : '✨ $suggestName';

                  return InkWell(
                    onTap: () async {
                      if (isNew) {
                        final dbService = DatabaseService.instance;
                        final colorList = [
                          0xFFFF8A80,
                          0xFFFFD180,
                          0xFF80D8FF,
                          0xFFEA80FC,
                          0xFFB9F6CA,
                          0xFFCFD8DC
                        ];
                        final randCol =
                            colorList[widget.tx.id! % colorList.length];
                        final newCatId = await dbService.insertCategory(
                          CategoryModel(
                              name: suggestName,
                              color: randCol,
                              icon: 'more_horiz'),
                        );

                        if (mounted) {
                          AppSnackBar.show(context,
                              'Created & assigned category "$suggestName"!',
                              type: SnackBarType.success);
                        }
                        setState(() {
                          _categoryId = newCatId;
                        });
                      } else {
                        final match = widget.categories.firstWhere((c) =>
                            c.name.toLowerCase() == suggestName.toLowerCase());
                        setState(() {
                          _categoryId = match.id!;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNew
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNew
                              ? const Color(0xFF34D399).withValues(alpha: 0.4)
                              : const Color(0xFF818CF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNew
                                ? Icons.add_circle_outline_rounded
                                : Icons.auto_awesome_rounded,
                            size: 13,
                            color: isNew
                                ? const Color(0xFF34D399)
                                : const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isNew
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: InkWell(
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
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF0F172A),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF6366F1), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM, hh:mm').format(_selectedDate),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                final finalDesc = desc.isEmpty ? widget.tx.description : desc;

                final updatedTx = widget.tx.copyWith(
                  amount: amt,
                  type: _type,
                  accountId: _accountId,
                  toAccountId: _toAccountId,
                  categoryId: _categoryId,
                  description: finalDesc,
                  date: _selectedDate,
                );

                final success =
                    await widget.onConfirm(updatedTx, selectedCategory.name);

                if (!mounted) return;

                if (success) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Verify & Confirm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.categories.length <= 4 ? 0.55 : 0.75;
    final double minFraction = 0.40;

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(cat.color).withOpacity(0.15),
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

  void _showAccountPicker(
      String pickerTitle, int currentSelected, Function(int) onSelected) {
    FocusManager.instance.primaryFocus?.unfocus();
    final double maxFraction = 0.85;
    final double initialFraction = widget.accounts.length <= 3 ? 0.55 : 0.75;
    final double minFraction = 0.40;

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
                        IconData getIcon(String t) {
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
                                  ? const Color(0xFF6366F1).withOpacity(0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6366F1).withOpacity(0.4)
                                    : Colors.white.withOpacity(0.05),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    getIcon(acc.type),
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

  Widget _buildMiniTypePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
