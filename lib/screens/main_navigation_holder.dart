import 'dart:ui';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'pending_verification_screen.dart';
import 'settings_screen.dart';
import '../services/database_service.dart';
import '../services/notification_handler.dart';
import '../services/batch_processor_service.dart';
import '../utils/app_settings.dart';

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  int _pendingCount = 0;
  bool _isInitPort = false;
  final ValueNotifier<int> _foregroundRefreshSignal = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _updatePendingCount();
    _initNotificationListener();
  }

  // Update badge count from the database
  Future<void> _updatePendingCount() async {
    final pendingList = await DatabaseService.instance.getPendingTransactions();
    if (mounted) {
      setState(() {
        _pendingCount = pendingList.length;
      });
    }
  }

  // Initialize notification listener and register foreground port
  Future<void> _initNotificationListener() async {
    if (_isInitPort) return;
    _isInitPort = true;

    await NotificationHandler.init(() {
      BatchProcessorService.instance.processQueue(
        onCompleted: () {
          if (mounted) {
            _updatePendingCount();
            _foregroundRefreshSignal.value++;
          }
        },
      );
    });

    // Auto-start the background listener service ONLY if user enabled Smart Tracking
    final hasPerm = await NotificationHandler.hasPermission();
    final isRunning = await NotificationHandler.isServiceRunning();
    if (hasPerm && !isRunning && AppSettings.smartTrackingEnabled) {
      await NotificationHandler.startService();
    } else if (isRunning && !AppSettings.smartTrackingEnabled) {
      await NotificationHandler.stopService();
    }


    // Process any notifications that were queued while the app wasn't running.
    await BatchProcessorService.instance.processQueue(
      onCompleted: () {
        if (mounted) {
          _updatePendingCount();
          _foregroundRefreshSignal.value++;
        }
      },
    );
  }

  @override
  void dispose() {
    
    IsolateNameServer.removePortNameMapping(NotificationHandler.portName);

    _pageController.dispose();
    _foregroundRefreshSignal.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
              if (index == 1) {
                _updatePendingCount(); // Refresh count on viewing pending list
              }
            },
            children: [
              DashboardScreen(
                isActive: _selectedIndex == 0,
                onRefreshPendingCount: _updatePendingCount,
              ),
              PendingVerificationScreen(
                onConfirmedOrDiscarded: _updatePendingCount,
                refreshSignal: _foregroundRefreshSignal,
              ),
              const SettingsScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationStrap(),
          ),
        ],
      ),
    );
  }

  // Floating frosted-glass navigation bar ("Strap" UI)
  Widget _buildBottomNavigationStrap() {
    final theme = Theme.of(context);
    
    return Theme(
      data: theme.copyWith(canvasColor: Colors.transparent),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStrapItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                  ),
                  _buildStrapItem(
                    index: 1,
                    icon: Icons.mark_email_unread_outlined,
                    activeIcon: Icons.mark_email_unread,
                    label: 'Inbox',
                    badgeCount: _pendingCount,
                  ),
                  _buildStrapItem(
                    index: 2,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStrapItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = Colors.white.withOpacity(0.5);

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(16.0),
      child: SizedBox(
        width: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
