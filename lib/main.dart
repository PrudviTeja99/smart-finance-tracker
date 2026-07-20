import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation_holder.dart';
import 'services/database_service.dart';
import 'services/app_icon_cache_service.dart';
import 'services/developer/log_service.dart';
import 'utils/app_settings.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await LogService.instance.initIsolateListener(); // For logs

    // Enable true edge-to-edge mode so content flows behind transparent system navigation/status bars
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Initialize App Settings from SharedPreferences
    await AppSettings.load();

    // Initialize Two-Tier App Icon Cache
    await AppIconCacheService.instance.init();

    // Initialize the local SQLite database
    await DatabaseService.instance.database;

    // Run auto-delete cleanup on app launch if enabled
    if (AppSettings.autoDeleteArchive) {
      DatabaseService.instance
          .runArchiveAutoDelete(
        AppSettings.autoDeleteValue,
        AppSettings.autoDeleteUnit,
      )
          .catchError((e) {
        debugPrint('Auto-delete on launch error: $e');
        return 0;
      });
    }

    // Capture uncaught Flutter framework errors into the log inspector too
    FlutterError.onError = (details) {
      LogService.instance
          .addLog('❌ FlutterError: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };

    runApp(const FinanceTrackerApp());
  }, (error, stack) {
    LogService.instance.addLog('❌ Uncaught error: $error');
    debugPrint('Uncaught error: $error\n$stack');
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      LogService.instance.addLog(line);
      parent.print(zone, line); // still shows in the real debug console
    },
  ));
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        canvasColor: Colors
            .transparent, // Required to make custom bottom navigation bar background transparent
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // Premium Dark Theme Palette
        primaryColor: const Color(0xFF6366F1), // Vibrant Indigo
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        cardColor: const Color(0xFF1E293B), // Slate 800
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981), // Emerald Green (Credits)
          error: Color(0xFFEF4444), // Red (Debits)
          surface: Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge:
              TextStyle(fontSize: 16.0, color: Color(0xFFE2E8F0)), // Slate 200
          bodyMedium:
              TextStyle(fontSize: 14.0, color: Color(0xFF94A3B8)), // Slate 400
        ),
      ),
      home: const MainNavigationHolder(),
    );
  }
}
