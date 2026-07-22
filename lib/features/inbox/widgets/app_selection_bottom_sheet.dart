import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../../services/app_icon_cache_service.dart';
import '../../../utils/app_settings.dart';
import '../../../utils/app_snackbar.dart';

class AppSelectionBottomSheet extends StatefulWidget {
  const AppSelectionBottomSheet({super.key});

  @override
  State<AppSelectionBottomSheet> createState() => _AppSelectionBottomSheetState();
}

class _AppSelectionBottomSheetState extends State<AppSelectionBottomSheet> {
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  final Set<String> _selectedPackages = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPackages.addAll(AppSettings.allowedNotificationApps);
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: false,
      );

      // Sort alphabetically by app name
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Pre-populate App Names in the global cache so the list uses launcher names
      for (var app in apps) {
        AppIconCacheService.instance.cacheAppName(app.packageName, app.name);
      }

      if (mounted) {
        setState(() {
          _installedApps = apps;
          _filteredApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading apps: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredApps = _installedApps;
      } else {
        final lowercaseQuery = query.toLowerCase();
        _filteredApps = _installedApps
            .where((app) => app.name.toLowerCase().contains(lowercaseQuery))
            .toList();
      }
    });
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  Future<void> _saveSelection() async {
    await AppSettings.setAllowedNotificationApps(_selectedPackages.toList());
    if (mounted) {
      Navigator.pop(context);
      AppSnackBar.show(
        context,
        'Notification tracking preferences saved successfully.',
        type: SnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.settings_suggest_rounded, color: Color(0xFF818CF8), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Track App Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedPackages.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF818CF8),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedPackages.clear();
                        });
                      },
                      child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select which apps should be tracked for auto-drafting and transaction capture.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterApps,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search installed apps...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _filterApps('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Main content (App grid list or loader)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    )
                  : _filteredApps.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching applications found',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final isSelected = _selectedPackages.contains(app.packageName);

                            return InkWell(
                              onTap: () => _toggleSelection(app.packageName),
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // App info container
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF6366F1).withOpacity(0.12)
                                          : Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6366F1).withOpacity(0.5)
                                            : Colors.white.withOpacity(0.05),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AppIconCacheService.instance.buildAppIconWidget(
                                          app.packageName,
                                          app.name,
                                          size: 44,
                                          onLoaded: () {
                                            if (mounted) setState(() {});
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        // App Name
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            app.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.white70,
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Premium Selection Checkmark Badge
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF6366F1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _saveSelection,
                  child: const Text(
                    'Save Tracking Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
