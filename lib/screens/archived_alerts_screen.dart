import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_icon_cache_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_settings.dart';

class ArchivedAlertsScreen extends StatefulWidget {
  const ArchivedAlertsScreen({super.key});

  @override
  State<ArchivedAlertsScreen> createState() => _ArchivedAlertsScreenState();
}

class _ArchivedAlertsScreenState extends State<ArchivedAlertsScreen> {
  final ScrollController _scrollController = ScrollController();
  static const int _batchSize = 30;
  int _maxDisplay = 30;

  List<Map<String, dynamic>> _archivedLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSelectionMode = false;
  final Set<int> _selectedLogIds = {};

  // App Category Multi-Selection Mode
  bool _isAppCategorySelectionMode = false;
  final Set<String> _selectedAppPackages = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadArchivedLogs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_maxDisplay < _archivedLogs.length) {
        setState(() {
          _maxDisplay += _batchSize;
        });
      }
    }
  }

  Future<void> _loadArchivedLogs() async {
    setState(() {
      _isLoading = true;
    });

    final dbService = DatabaseService.instance;
    final logs = await dbService.getNotificationLogs('archived');

    if (mounted) {
      setState(() {
        _archivedLogs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreAlert(int logId) async {
    final strings = AppLocalizations.of(context)!;
    await DatabaseService.instance
        .updateNotificationLogStatus(logId, 'unclassified');
    if (!mounted) return;
    AppSnackBar.show(context, strings.archivedAlertsRestoredSuccess,
        type: SnackBarType.success);
    _loadArchivedLogs();
  }

  Future<void> _deleteAlert(int logId) async {
    final strings = AppLocalizations.of(context)!;
    await DatabaseService.instance.deleteNotificationLog(logId);
    if (!mounted) return;
    AppSnackBar.show(context, strings.archivedAlertsDeletedSuccess,
        type: SnackBarType.success);
    _loadArchivedLogs();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLogIds.clear();
    });
  }

  void _toggleSelection(int logId) {
    setState(() {
      if (_selectedLogIds.contains(logId)) {
        _selectedLogIds.remove(logId);
        if (_selectedLogIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedLogIds.add(logId);
      }
    });
  }

  void _enterSelectionMode(int logId) {
    setState(() {
      _isSelectionMode = true;
      _selectedLogIds.add(logId);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedLogIds.isEmpty) return;
    final strings = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.archivedAlertsDeleteSelectedTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            strings.archivedAlertsDeleteSelectedConfirm(_selectedLogIds.length),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.inboxCancel,
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.archivedAlertsDelete,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ids = _selectedLogIds.toList();
      for (var id in ids) {
        await DatabaseService.instance.deleteNotificationLog(id);
      }
      if (!mounted) return;
      AppSnackBar.show(
          context, strings.archivedAlertsBatchDeletedSuccess(ids.length),
          type: SnackBarType.success);
      setState(() {
        _isSelectionMode = false;
        _selectedLogIds.clear();
      });
      _loadArchivedLogs();
    }
  }

  Future<void> _restoreSelected() async {
    if (_selectedLogIds.isEmpty) return;
    final strings = AppLocalizations.of(context)!;

    final ids = _selectedLogIds.toList();
    for (var id in ids) {
      await DatabaseService.instance
          .updateNotificationLogStatus(id, 'unclassified');
    }
    if (!mounted) return;
    AppSnackBar.show(
        context, strings.archivedAlertsRestoredSelectedSuccess(ids.length),
        type: SnackBarType.success);
    setState(() {
      _isSelectionMode = false;
      _selectedLogIds.clear();
    });
    _loadArchivedLogs();
  }

  Future<void> _clearAllArchives() async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.archivedAlertsClearAllTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(strings.archivedAlertsClearAllConfirm,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.inboxCancel,
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.inboxClearAllAlerts,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.clearNotificationLogs(status: 'archived');
      if (mounted) {
        AppSnackBar.show(context, strings.archivedAlertsClearAllSuccess,
            type: SnackBarType.success);
      }
      _loadArchivedLogs();
    }
  }

  // --- APP CATEGORY BATCH MANAGEMENT ---

  void _toggleAppPackageSelection(String packageName) {
    setState(() {
      if (_selectedAppPackages.contains(packageName)) {
        _selectedAppPackages.remove(packageName);
        if (_selectedAppPackages.isEmpty) {
          _isAppCategorySelectionMode = false;
        }
      } else {
        _selectedAppPackages.add(packageName);
      }
    });
  }

  void _enterAppCategorySelectionMode(String initialPackage) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAppCategorySelectionMode = true;
      _selectedAppPackages.clear();
      _selectedAppPackages.add(initialPackage);
    });
  }

  Future<void> _restoreSelectedAppCategories() async {
    if (_selectedAppPackages.isEmpty) return;
    final strings = AppLocalizations.of(context)!;

    final selectedPkgs = _selectedAppPackages.toList();
    int totalCount = 0;

    for (var pkg in selectedPkgs) {
      final logsForPkg =
          _archivedLogs.where((l) => l['package_name'] == pkg).toList();
      totalCount += logsForPkg.length;
      for (var log in logsForPkg) {
        final id = log['id'] as int;
        await DatabaseService.instance
            .updateNotificationLogStatus(id, 'unclassified');
      }
    }

    if (mounted) {
      AppSnackBar.show(
        context,
        strings.archivedAlertsRestoredAppCategoriesSuccess(
            totalCount, selectedPkgs.length),
        type: SnackBarType.success,
      );
      setState(() {
        _isAppCategorySelectionMode = false;
        _selectedAppPackages.clear();
      });
    }
    _loadArchivedLogs();
  }

  Future<void> _deleteSelectedAppCategoriesPermanently() async {
    if (_selectedAppPackages.isEmpty) return;
    final strings = AppLocalizations.of(context)!;

    final selectedPkgs = _selectedAppPackages.toList();
    int totalCount = 0;
    for (var pkg in selectedPkgs) {
      totalCount += _archivedLogs.where((l) => l['package_name'] == pkg).length;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.archivedAlertsDeleteAppCategoriesTitle(totalCount),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          strings.archivedAlertsDeleteAppCategoriesConfirm(
              totalCount, selectedPkgs.length),
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.inboxCancel,
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.archivedAlertsDelete,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var pkg in selectedPkgs) {
        final logsForPkg =
            _archivedLogs.where((l) => l['package_name'] == pkg).toList();
        for (var log in logsForPkg) {
          final id = log['id'] as int;
          await DatabaseService.instance.deleteNotificationLog(id);
        }
      }

      if (mounted) {
        AppSnackBar.show(context,
            strings.archivedAlertsDeletedAppCategoriesSuccess(totalCount),
            type: SnackBarType.neutral);
        setState(() {
          _isAppCategorySelectionMode = false;
          _selectedAppPackages.clear();
        });
      }
      _loadArchivedLogs();
    }
  }

  void _showDetailsBottomSheet(
      Map<String, dynamic> log, String resolvedAppName) {
    final strings = AppLocalizations.of(context)!;
    final title = log['title'] as String? ?? '';
    final body = log['body'] as String? ?? '';
    final packageName = log['package_name'] as String? ?? '';
    final ts = log['timestamp'] as int?;
    final date = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    final formattedDate =
        date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildAppIconWidget(packageName, resolvedAppName, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedAppName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          Text(
                            packageName,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  body,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Received: $formattedDate',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteAlert(log['id'] as int);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(strings.archivedAlertsDelete,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _restoreAlert(log['id'] as int);
                        },
                        icon: const Icon(Icons.settings_backup_restore_rounded,
                            size: 18),
                        label: Text(strings.archivedAlertsRestore,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        _searchFocusNode.unfocus();
      }
    });
  }

  Widget _buildAppIconWidget(String packageName, String fallbackName,
      {double size = 20}) {
    return AppIconCacheService.instance.buildAppIconWidget(
      packageName,
      fallbackName,
      size: size,
      onLoaded: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final query = _searchQuery.toLowerCase().trim();
    final filteredLogs = _archivedLogs.where((log) {
      if (query.isEmpty) return true;
      final title = (log['title'] as String? ?? '').toLowerCase();
      final body = (log['body'] as String? ?? '').toLowerCase();
      final appName = (log['app_name'] as String? ?? '').toLowerCase();
      final packageName = (log['package_name'] as String? ?? '').toLowerCase();
      final cachedAppName = AppIconCacheService.instance
          .getCachedAppName(log['package_name'] as String? ?? '')
          .toLowerCase();

      return title.contains(query) ||
          body.contains(query) ||
          appName.contains(query) ||
          packageName.contains(query) ||
          cachedAppName.contains(query);
    }).toList();

    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var log in filteredLogs) {
      final pkg = log['package_name'] as String? ?? 'unknown';
      if (!groups.containsKey(pkg)) {
        groups[pkg] = [];
      }
      groups[pkg]!.add(log);
    }

    final sortedPackages = groups.keys.toList()
      ..sort((a, b) {
        final tsA = groups[a]!.first['timestamp'] as int? ?? 0;
        final tsB = groups[b]!.first['timestamp'] as int? ?? 0;
        return tsB.compareTo(tsA);
      });

    return PopScope(
      canPop: !_isSelectionMode && !_isAppCategorySelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        } else if (_isAppCategorySelectionMode) {
          setState(() {
            _isAppCategorySelectionMode = false;
            _selectedAppPackages.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: _exitSelectionMode,
                  tooltip: strings.archivedAlertsExitSelection,
                ),
                title: Text(
                  strings.inboxSelectedCount(_selectedLogIds.length),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                backgroundColor: const Color(0xFF1E293B),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_backup_restore_rounded,
                        color: Color(0xFF818CF8)),
                    onPressed: _restoreSelected,
                    tooltip: strings.archivedAlertsRestoreSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444)),
                    onPressed: _deleteSelected,
                    tooltip: strings.archivedAlertsDeleteSelected,
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : _isAppCategorySelectionMode
                ? AppBar(
                    leading: IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isAppCategorySelectionMode = false;
                          _selectedAppPackages.clear();
                        });
                      },
                    ),
                    title: Text(
                      strings.archivedAlertsAppsSelected(
                          _selectedAppPackages.length),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.restore_rounded,
                            color: Color(0xFF10B981)),
                        tooltip: strings.archivedAlertsRestoreSelectedApps,
                        onPressed: _restoreSelectedAppCategories,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: Color(0xFFEF4444)),
                        tooltip:
                            strings.archivedAlertsDeleteSelectedAppsPermanently,
                        onPressed: _deleteSelectedAppCategoriesPermanently,
                      ),
                    ],
                  )
                : AppBar(
                    title: Row(
                      children: [
                        Text(strings.archivedAlertsTitle,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (!_isLoading && _archivedLogs.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_archivedLogs.length}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      if (!_isLoading && _archivedLogs.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.checklist_rounded,
                              color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _isAppCategorySelectionMode = true;
                              _selectedAppPackages.clear();
                            });
                          },
                          tooltip: strings.archivedAlertsSelectApps,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_rounded,
                              color: Colors.white70),
                          onPressed: _clearAllArchives,
                          tooltip: strings.inboxClearAllAlerts,
                        ),
                      ],
                    ],
                  ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Dummy focus node to absorb automatic focus when modal bottom sheets are popped
              const Focus(
                autofocus: true,
                child: SizedBox.shrink(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: strings.archivedAlertsSearchHint,
                    hintStyle:
                        const TextStyle(color: Colors.white30, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white30, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.white10, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.white10, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(Color(0xFF6366F1))))
                    : sortedPackages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                            itemCount: (sortedPackages.length < _maxDisplay
                                    ? sortedPackages.length
                                    : _maxDisplay) +
                                (sortedPackages.length > _maxDisplay ? 1 : 0),
                            itemBuilder: (context, index) {
                              final visibleCount =
                                  sortedPackages.length < _maxDisplay
                                      ? sortedPackages.length
                                      : _maxDisplay;

                              if (index == visibleCount) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final pkg = sortedPackages[index];
                              final list = groups[pkg]!;
                              final fallbackAppName =
                                  list.first['app_name'] as String? ??
                                      'Unknown';
                              final resolvedAppName = AppIconCacheService
                                  .instance
                                  .getCachedAppName(pkg,
                                      defaultFallback: fallbackAppName);

                              final isSelected =
                                  _selectedAppPackages.contains(pkg);

                              return _ArchivedAppGroupTile(
                                key: ValueKey(
                                    'archive_group_${pkg}_${_isAppCategorySelectionMode}_$isSelected'),
                                pkg: pkg,
                                resolvedAppName: resolvedAppName,
                                list: list,
                                leadingWidget: _buildAppIconWidget(
                                    pkg, resolvedAppName,
                                    size: 24),
                                isSelectionMode: _isAppCategorySelectionMode,
                                isSelected: isSelected,
                                onTapHeader: () =>
                                    _toggleAppPackageSelection(pkg),
                                onLongPressHeader: () =>
                                    _enterAppCategorySelectionMode(pkg),
                                buildLogItem: (log) =>
                                    _buildArchivedLogItem(log, resolvedAppName),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final strings = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.archive_outlined,
                size: 56,
                color: Color(0xFF818CF8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? strings.archivedAlertsNoSearchResults
                  : strings.archivedAlertsNoAlerts,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? strings.archivedAlertsNoSearchResultsSubtitle
                  : strings.archivedAlertsEmptyStateSubtitle,
              style: const TextStyle(
                  fontSize: 12, color: Colors.white38, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedLogItem(
      Map<String, dynamic> log, String resolvedAppName) {
    final strings = AppLocalizations.of(context)!;
    final title = log['title'] as String? ?? '';
    final body = log['body'] as String? ?? '';
    final ts = log['timestamp'] as int?;
    final logId = log['id'] as int;
    final date = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    final formattedTime =
        date != null ? DateFormat('dd MMM, hh:mm a').format(date) : '';

    final isSelected = _selectedLogIds.contains(logId);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
            : const Color(0xFF0F172A).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.04),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(logId);
          } else {
            _showDetailsBottomSheet(log, resolvedAppName);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(logId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox on selection mode, otherwise mail icon
              _isSelectionMode
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        size: 16,
                        color: Colors.white38,
                      ),
                    ),
              const SizedBox(width: 14),

              // Alert Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right Metadata & Action Button (hidden in selection mode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                  const SizedBox(height: 2),
                  _isSelectionMode
                      ? const SizedBox(height: 22, width: 22)
                      : PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white38,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 150),
                          color: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: Color(0xFF334155), width: 1),
                          ),
                          onSelected: (val) {
                            if (val == 'restore') {
                              _restoreAlert(logId);
                            } else if (val == 'delete') {
                              _deleteAlert(logId);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restore',
                              height: 44,
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.settings_backup_restore_rounded,
                                      size: 18,
                                      color: Color(0xFF818CF8)),
                                  const SizedBox(width: 10),
                                  Text(strings.archivedAlertsRestoreAlert,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 44,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 10),
                                  Text(strings.archivedAlertsDeleteAlert,
                                      style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedAppGroupTile extends StatefulWidget {
  final String pkg;
  final String resolvedAppName;
  final List<Map<String, dynamic>> list;
  final Widget leadingWidget;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapHeader;
  final VoidCallback? onLongPressHeader;
  final Widget Function(Map<String, dynamic> log) buildLogItem;

  const _ArchivedAppGroupTile({
    super.key,
    required this.pkg,
    required this.resolvedAppName,
    required this.list,
    required this.leadingWidget,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTapHeader,
    this.onLongPressHeader,
    required this.buildLogItem,
  });

  @override
  State<_ArchivedAppGroupTile> createState() => _ArchivedAppGroupTileState();
}

class _ArchivedAppGroupTileState extends State<_ArchivedAppGroupTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? const Color(0xFF6366F1)
              : const Color(0xFF334155),
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: widget.onLongPressHeader,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          onExpansionChanged: (expanded) {
            if (widget.isSelectionMode) {
              if (widget.onTapHeader != null) widget.onTapHeader!();
            } else {
              setState(() {
                _isExpanded = expanded;
              });
            }
          },
          leading: widget.isSelectionMode
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.white30,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color:
                        widget.isSelected ? Colors.white : Colors.transparent,
                  ),
                )
              : widget.leadingWidget,
          title: Text(
            widget.resolvedAppName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.list.length}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (!widget.isSelectionMode) ...[
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: Colors.white30),
                ),
              ],
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: widget.list.map((log) => widget.buildLogItem(log)).toList(),
        ),
      ),
    );
  }
}
