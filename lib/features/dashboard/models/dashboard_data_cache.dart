import 'dashboard_data.dart';

/// Keeps one dashboard snapshot for the current database version.
///
/// The caller owns version changes. A new version always causes a fresh load,
/// while repeated requests for the same version reuse the existing snapshot.
class DashboardDataCache {
  DashboardData? _data;
  int? _version;
  Future<DashboardData>? _inFlightLoad;
  int? _inFlightVersion;

  Future<DashboardData> load({
    required int version,
    required Future<DashboardData> Function() loader,
  }) {
    if (_data != null && _version == version) {
      return Future.value(_data!);
    }

    if (_inFlightLoad != null && _inFlightVersion == version) {
      return _inFlightLoad!;
    }

    final load = Future.sync(loader).then((data) {
      // A newer database version may finish first. Never let an older load
      // replace that newer snapshot when it eventually completes.
      if (_inFlightVersion == version) {
        _data = data;
        _version = version;
      }
      return data;
    });
    _inFlightLoad = load;
    _inFlightVersion = version;

    return load.whenComplete(() {
      if (_inFlightVersion == version) {
        _inFlightLoad = null;
        _inFlightVersion = null;
      }
    });
  }

  void clear() {
    _data = null;
    _version = null;
  }
}
