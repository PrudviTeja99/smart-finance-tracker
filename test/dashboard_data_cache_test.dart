import 'package:finance_tracker/features/dashboard/models/dashboard_data.dart';
import 'package:finance_tracker/features/dashboard/models/dashboard_data_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

void main() {
  DashboardData snapshot() => const DashboardData(
        allTransactions: [],
        accounts: [],
        categories: [],
      );

  test('reuses a snapshot while the database version is unchanged', () async {
    final cache = DashboardDataCache();
    var loads = 0;

    Future<DashboardData> loader() async {
      loads++;
      return snapshot();
    }

    final first = await cache.load(version: 1, loader: loader);
    final second = await cache.load(version: 1, loader: loader);

    expect(identical(first, second), isTrue);
    expect(loads, 1);
  });

  test('loads fresh data after the database version changes', () async {
    final cache = DashboardDataCache();
    var loads = 0;

    Future<DashboardData> loader() async {
      loads++;
      return snapshot();
    }

    await cache.load(version: 1, loader: loader);
    await cache.load(version: 2, loader: loader);

    expect(loads, 2);
  });

  test('shares an in-flight load for matching versions', () async {
    final cache = DashboardDataCache();
    var loads = 0;

    Future<DashboardData> loader() async {
      loads++;
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return snapshot();
    }

    await Future.wait([
      cache.load(version: 1, loader: loader),
      cache.load(version: 1, loader: loader),
    ]);

    expect(loads, 1);
  });

  test('an older load cannot replace a newer completed snapshot', () async {
    final cache = DashboardDataCache();
    final older = Completer<DashboardData>();
    final newer = Completer<DashboardData>();

    final olderRequest = cache.load(version: 1, loader: () => older.future);
    final newerRequest = cache.load(version: 2, loader: () => newer.future);
    newer.complete(snapshot());
    await newerRequest;
    older.complete(snapshot());
    await olderRequest;

    var loads = 0;
    await cache.load(version: 2, loader: () async {
      loads++;
      return snapshot();
    });

    expect(loads, 0);
  });
}
