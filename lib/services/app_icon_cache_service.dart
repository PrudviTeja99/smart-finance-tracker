import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Global Two-Tier (Memory + Disk Storage) Cache Service.
/// 
/// Tier 1: In-Memory Map (RAM) -> 0ms instant lookup during app session.
/// Tier 2: Local Disk File Storage -> Persists across app restarts.
/// Tier 3: Native IPC / Fallback fetcher -> Triggered on total cache miss.
///
/// Designed to be extensible: Support namespaces (e.g. 'app_icons', 'merchants', 'thumbnails')
/// so future features can easily reuse the same RAM + Disk caching infrastructure.
class AppIconCacheService {
  AppIconCacheService._privateConstructor();
  static final AppIconCacheService instance = AppIconCacheService._privateConstructor();

  // Tier 1: Memory Caches keyed by [namespace:key]
  final Map<String, Uint8List?> _memoryCache = {};
  final Map<String, String> _appNameCache = {};
  final Set<String> _pendingFetches = {};

  static const _appInfoChannel = MethodChannel('com.example.finance_tracker/app_info');
  Directory? _cacheDir;

  /// Initialize the cache directory (called on app startup or lazily)
  Future<void> init() async {
    if (_cacheDir != null) return;
    try {
      final baseDir = await getTemporaryDirectory();
      _cacheDir = Directory('${baseDir.path}/media_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Load cached app names from disk asynchronously in an isolate
      final namesFile = File('${_cacheDir!.path}/app_names.json');
      if (await namesFile.exists()) {
        final jsonStr = await namesFile.readAsString();
        final map = await Isolate.run(() {
          return json.decode(jsonStr) as Map<String, dynamic>;
        });
        map.forEach((k, v) {
          _appNameCache[k] = v.toString();
        });
      }
    } catch (e) {
      // Fallback if temp dir is unavailable
    }
  }

  // ---------------------------------------------------------------------------
  // GENERIC TIER 1 & TIER 2 DISK/RAM CACHE (Extensible for future features)
  // ---------------------------------------------------------------------------

  /// Get raw bytes from RAM or Disk storage for any namespace & key
  Future<Uint8List?> getBytes(String key, {String namespace = 'default'}) async {
    final cacheKey = '$namespace:$key';

    // 1. Tier 1: RAM Lookup
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Tier 2: Disk Lookup
    final file = await _getCacheFile(key, namespace);
    if (file != null && await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        _memoryCache[cacheKey] = bytes; // Populate RAM
        return bytes;
      } catch (_) {
        // Disk read error, fall through
      }
    }

    return null;
  }

  /// Store raw bytes in RAM & Disk storage for any namespace & key
  Future<void> putBytes(String key, Uint8List bytes, {String namespace = 'default'}) async {
    final cacheKey = '$namespace:$key';
    _memoryCache[cacheKey] = bytes;

    final file = await _getCacheFile(key, namespace);
    if (file != null) {
      try {
        await file.writeAsBytes(bytes, flush: true);
      } catch (_) {
        // Ignore disk write failure
      }
    }
  }

  /// Persists the app names map to disk.
  Future<void> _saveAppNamesToDisk() async {
    if (_cacheDir == null) return;
    try {
      final namesFile = File('${_cacheDir!.path}/app_names.json');
      await namesFile.writeAsString(json.encode(_appNameCache), flush: true);
    } catch (_) {}
  }

  /// Manually caches an app's friendly name and writes it to disk.
  Future<void> cacheAppName(String packageName, String name) async {
    if (name.isNotEmpty) {
      _appNameCache[packageName] = name;
      await _saveAppNamesToDisk();
    }
  }

  /// Clear memory and disk cache for a given namespace (or all)
  Future<void> clear({String? namespace}) async {
    if (namespace == null) {
      _memoryCache.clear();
      _appNameCache.clear();
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
    } else {
      _memoryCache.removeWhere((k, _) => k.startsWith('$namespace:'));
      if (namespace == 'app_icons') {
        _appNameCache.clear();
        try {
          final namesFile = File('${_cacheDir!.path}/app_names.json');
          if (await namesFile.exists()) {
            await namesFile.delete();
          }
        } catch (_) {}
      }
      final nsDir = await _getNamespaceDirectory(namespace);
      if (nsDir != null && await nsDir.exists()) {
        await nsDir.delete(recursive: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // APP ICON SPECIFIC HELPER API
  // ---------------------------------------------------------------------------

  /// Returns cached app icon bytes, or fetches natively via MethodChannel.
  /// Result is automatically saved to RAM & Disk.
  Future<Uint8List?> loadAppIcon(String packageName, String fallbackName) async {
    // 1. Tier 1 & 2: Check RAM & Disk Cache
    final cachedBytes = await getBytes(packageName, namespace: 'app_icons');
    if (cachedBytes != null) {
      return cachedBytes;
    }

    // Prevent duplicate concurrent fetches for the same app
    if (_pendingFetches.contains(packageName)) return null;
    _pendingFetches.add(packageName);

    try {
      // 3. Tier 3: Fetch natively from Android PackageManager
      final result = await _appInfoChannel.invokeMapMethod<String, dynamic>(
        'getAppInfo',
        {'packageName': packageName},
      );

      if (result != null) {
        final appName = result['appName'] as String? ?? fallbackName;
        final iconBytes = result['iconBytes'] as Uint8List?;

        _appNameCache[packageName] = appName;
        await _saveAppNamesToDisk();

        if (iconBytes != null && iconBytes.isNotEmpty) {
          await putBytes(packageName, iconBytes, namespace: 'app_icons');
          return iconBytes;
        }
      }
    } catch (_) {
      // App uninstalled or unavailable, cache empty result in RAM to avoid re-querying
      _memoryCache['app_icons:$packageName'] = null;
    } finally {
      _pendingFetches.remove(packageName);
    }

    return null;
  }

  /// Synchronously get cached App Name if available, or clean fallback
  String getCachedAppName(String packageName, {String? defaultFallback}) {
    if (_appNameCache.containsKey(packageName) && _appNameCache[packageName]!.isNotEmpty) {
      return _appNameCache[packageName]!;
    }
    if (defaultFallback != null &&
        defaultFallback.isNotEmpty &&
        defaultFallback.toLowerCase() != 'android' &&
        defaultFallback.toLowerCase() != 'app') {
      return defaultFallback;
    }
    return formatPackageName(packageName);
  }

  /// Intelligently formats package names like 'com.instagram.android' -> 'Instagram'
  static String formatPackageName(String package) {
    if (package.contains('messaging') ||
        package.contains('android.apps.messaging') ||
        package.contains('samsung.android.messaging')) {
      return 'SMS';
    } else if (package.contains('phonepe')) {
      return 'PhonePe';
    } else if (package.contains('google.android.apps.nbu.paisa')) {
      return 'Google Pay';
    } else if (package.contains('paytm')) {
      return 'Paytm';
    } else if (package.contains('whatsapp')) {
      return 'WhatsApp';
    }

    final parts = package.split('.');
    final ignored = {
      'com',
      'org',
      'net',
      'gov',
      'edu',
      'android',
      'app',
      'apps',
      'mobile',
      'lite',
      'client',
      'main',
      'service',
      'ui',
      'in',
      'us',
      'uk'
    };

    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].toLowerCase();
      if (!ignored.contains(part) && part.length > 1) {
        return part[0].toUpperCase() + part.substring(1);
      }
    }

    final last = parts.last;
    return last.isNotEmpty ? last[0].toUpperCase() + last.substring(1) : package;
  }

  /// Helper to build a cached app icon widget or fallback letter badge
  Widget buildAppIconWidget(String packageName, String fallbackName, {double size = 24, VoidCallback? onLoaded}) {
    final cacheKey = 'app_icons:$packageName';

    // If present in RAM
    if (_memoryCache.containsKey(cacheKey)) {
      final bytes = _memoryCache[cacheKey];
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) => buildFallbackIcon(fallbackName, size),
          ),
        );
      } else {
        return buildFallbackIcon(fallbackName, size);
      }
    }

    // Trigger async load from Disk / Native
    loadAppIcon(packageName, fallbackName).then((bytes) {
      if (bytes != null && onLoaded != null) {
        onLoaded();
      }
    });

    return buildFallbackIcon(fallbackName, size);
  }

  /// Renders fallback circular initial letter avatar
  Widget buildFallbackIcon(String name, double size) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: const Color(0xFF818CF8),
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER DIRECTORY UTILS
  // ---------------------------------------------------------------------------

  Future<File?> _getCacheFile(String key, String namespace) async {
    final dir = await _getNamespaceDirectory(namespace);
    if (dir == null) return null;
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${dir.path}/$safeKey.bin');
  }

  Future<Directory?> _getNamespaceDirectory(String namespace) async {
    await init();
    if (_cacheDir == null) return null;
    final nsDir = Directory('${_cacheDir!.path}/$namespace');
    if (!await nsDir.exists()) {
      await nsDir.create(recursive: true);
    }
    return nsDir;
  }
}
