import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../utils/icon_helper.dart';

Future<void> showManageCategoriesSheet({
  required BuildContext context,
  VoidCallback? onCategoriesChanged,
}) async {
  List<CategoryModel> categories =
      await DatabaseService.instance.getAllCategories();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Categories',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF10B981), size: 28),
                          onPressed: () async {
                            await showCategoryFormDialog(context, null);
                            categories =
                                await DatabaseService.instance.getAllCategories();
                            setSheetState(() {});
                            onCategoriesChanged?.call();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: categories.isEmpty
                      ? const Center(
                          child: Text(
                            'No categories yet. Tap + to add one.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.03)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Color(cat.color).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(IconHelper.getIcon(cat.icon),
                                        color: Color(cat.color), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 18, color: Colors.white60),
                                    onPressed: () async {
                                      await showCategoryFormDialog(context, cat);
                                      categories = await DatabaseService
                                          .instance
                                          .getAllCategories();
                                      setSheetState(() {});
                                      onCategoriesChanged?.call();
                                    },
                                  ),
                                  if (cat.name != 'Others')
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Color(0xFFEF4444)),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor:
                                                const Color(0xFF1E293B),
                                            title: const Text('Delete Category?'),
                                            content: Text(
                                                'Are you sure you want to delete "${cat.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Color(0xFFEF4444))),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await DatabaseService.instance
                                              .deleteCategory(cat.id!);
                                          categories = await DatabaseService
                                              .instance
                                              .getAllCategories();
                                          setSheetState(() {});
                                          onCategoriesChanged?.call();
                                        }
                                      },
                                    ),
                                ],
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

Future<void> showCategoryFormDialog(
    BuildContext context, CategoryModel? editCat) async {
  final isEdit = editCat != null;
  final nameController =
      TextEditingController(text: isEdit ? editCat.name : '');
  final nameFocusNode = FocusNode();
  int colorValue = isEdit ? editCat.color : 0xFF6366F1;
  String icon = isEdit ? editCat.icon : 'shopping_bag';

  final colors = [
    0xFF6366F1,
    0xFF3B82F6,
    0xFF06B6D4,
    0xFF14B8A6,
    0xFF10B981,
    0xFF84CC16,
    0xFFF59E0B,
    0xFFF97316,
    0xFFEF4444,
    0xFFE11D48,
    0xFFEC4899,
    0xFFD946EF,
    0xFF8B5CF6,
    0xFF7C3AED,
    0xFF78716C,
    0xFF94A3B8,
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Category' : 'Add Category',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Theme Color',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ...colors.map((colVal) {
                            final isSel = colorValue == colVal;
                            return GestureDetector(
                              onTap: () {
                                nameFocusNode.unfocus();
                                setDialogState(() => colorValue = colVal);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(colVal),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: isSel
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Category Icon',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        nameFocusNode.unfocus();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return SearchableIconPicker(
                              colorValue: colorValue,
                              onSelected: (selectedIcon) {
                                setDialogState(() {
                                  icon = selectedIcon;
                                });
                              },
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(colorValue).withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Color(colorValue).withOpacity(0.25),
                                    width: 1.5),
                              ),
                              child: Icon(IconHelper.getIcon(icon),
                                  color: Color(colorValue), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Icon: "${icon.replaceAll('_', ' ')}"',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Search from 60+ modern icons',
                                    style: TextStyle(
                                        fontSize: 10, color: Color(0xFF818CF8)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.05)),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.search_rounded,
                                  size: 14, color: Color(0xFF6366F1)),
                              label: const Text('Browse',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () {
                                nameFocusNode.unfocus();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return SearchableIconPicker(
                                      colorValue: colorValue,
                                      onSelected: (selectedIcon) {
                                        setDialogState(() {
                                          icon = selectedIcon;
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;

                              final cat = CategoryModel(
                                id: isEdit ? editCat.id : null,
                                name: name,
                                color: colorValue,
                                icon: icon,
                              );

                              if (isEdit) {
                                await DatabaseService.instance
                                    .updateCategory(cat);
                              } else {
                                await DatabaseService.instance
                                    .insertCategory(cat);
                              }

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(isEdit ? 'Save' : 'Add',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class SearchableIconPicker extends StatefulWidget {
  final int colorValue;
  final Function(String) onSelected;

  const SearchableIconPicker({
    super.key,
    required this.colorValue,
    required this.onSelected,
  });

  @override
  State<SearchableIconPicker> createState() => _SearchableIconPickerState();
}

class _SearchableIconPickerState extends State<SearchableIconPicker> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredKeys = IconHelper.searchIcons(_query);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search Category Icons',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by keyword (e.g. food, taxi, bill...)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF6366F1)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white38),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredKeys.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching icons found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredKeys.length,
                          itemBuilder: (context, index) {
                            final key = filteredKeys[index];
                            final iconData = IconHelper.getIcon(key);
                            return InkWell(
                              onTap: () {
                                widget.onSelected(key);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(iconData,
                                        color: Color(widget.colorValue),
                                        size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      key.replaceAll('_', ' '),
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.white60),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
