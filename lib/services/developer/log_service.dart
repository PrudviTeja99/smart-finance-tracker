import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  LogEntry(this.timestamp, this.message);

  String toLine() => '${timestamp.toIso8601String()}|$message';

  static LogEntry? fromLine(String line) {
    final sepIndex = line.indexOf('|');
    if (sepIndex == -1) return null;
    final tsStr = line.substring(0, sepIndex);
    final msg = line.substring(sepIndex + 1);
    final ts = DateTime.tryParse(tsStr);
    if (ts == null) return null;
    return LogEntry(ts, msg);
  }
}

/// Persists app logs to one file per day, with today's file also mirrored
/// into an in-memory buffer for fast live updates in the Log Inspector.
class LogService {
  LogService._privateConstructor();
  static final LogService instance = LogService._privateConstructor();

  static const String portName = 'log_forwarder_port';
  static final DateFormat _fileDateFormat = DateFormat('yyyy-MM-dd');

  final List<LogEntry> _logs = []; // live buffer — always represents TODAY
  final ValueNotifier<int> logCountNotifier = ValueNotifier(0);
  static const int _maxLogsInMemory = 1000;

  ReceivePort? _receivePort;
  Directory? _logsDir;
  bool _hydrated = false;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<Directory> _getLogsDir() async {
    if (_logsDir != null) return _logsDir!;
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/app_logs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _logsDir = dir;
    return dir;
  }

  Future<File> _fileForDate(DateTime date) async {
    final dir = await _getLogsDir();
    final name = _fileDateFormat.format(date);
    return File('${dir.path}/log_$name.txt');
  }

  /// Call ONCE from the main (UI) isolate at app startup — registers the
  /// isolate port AND loads today's existing log lines (if any) back into
  /// memory, so a restarted app still shows today's history immediately.
  Future<void> initIsolateListener() async {
    if (_receivePort == null) {
      _receivePort = ReceivePort();
      IsolateNameServer.removePortNameMapping(portName);
      IsolateNameServer.registerPortWithName(_receivePort!.sendPort, portName);
      _receivePort!.listen((message) {
        if (message is String) addLog(message);
      });
    }

    if (!_hydrated) {
      _hydrated = true;
      try {
        final todayEntries = await loadLogsForDate(DateTime.now());
        _logs
          ..clear()
          ..addAll(todayEntries.length > _maxLogsInMemory
              ? todayEntries.sublist(todayEntries.length - _maxLogsInMemory)
              : todayEntries);
        logCountNotifier.value++;
      } catch (e) {
        debugPrint('LogService: failed to hydrate today\'s logs: $e');
      }
    }
  }

  void addLog(String message) {
    final entry = LogEntry(DateTime.now(), message);
    _logs.add(entry);
    if (_logs.length > _maxLogsInMemory) {
      _logs.removeAt(0);
    }
    logCountNotifier.value++;
    _appendToFile(entry); // fire-and-forget; persistence shouldn't block UI
  }

  Future<void> _appendToFile(LogEntry entry) async {
    try {
      final file = await _fileForDate(entry.timestamp);
      await file.writeAsString('${entry.toLine()}\n',
          mode: FileMode.append, flush: false);
    } catch (e) {
      debugPrint('LogService: failed to write log to file: $e');
    }
  }

  void clear() {
    // Clears the live in-memory view only. Does not delete file history —
    // use deleteLogFile()/deleteAllLogFiles() for that.
    _logs.clear();
    logCountNotifier.value++;
  }

  /// Returns available log dates (most recent first) based on files on disk.
  Future<List<DateTime>> getAvailableLogDates() async {
    final dir = await _getLogsDir();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((f) => f is File && f.path.endsWith('.txt'))
        .toList();
    final dates = <DateTime>[];
    for (var f in files) {
      final name = f.uri.pathSegments.last; // log_yyyy-MM-dd.txt
      final match = RegExp(r'log_(\d{4}-\d{2}-\d{2})\.txt').firstMatch(name);
      if (match != null) {
        final parsed = DateTime.tryParse(match.group(1)!);
        if (parsed != null) dates.add(parsed);
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// Reads all log entries for a given date from disk.
  Future<List<LogEntry>> loadLogsForDate(DateTime date) async {
    final file = await _fileForDate(date);
    if (!await file.exists()) return [];
    final lines = await file.readAsLines();
    final entries = <LogEntry>[];
    for (var line in lines) {
      final entry = LogEntry.fromLine(line);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  Future<void> deleteLogFile(DateTime date) async {
    final file = await _fileForDate(date);
    if (await file.exists()) await file.delete();
    if (_isSameDay(date, DateTime.now())) {
      clear();
    }
  }

  Future<void> deleteAllLogFiles() async {
    final dir = await _getLogsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _logsDir = null;
    clear();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static void logFromAnyIsolate(String message) {
    final sendPort = IsolateNameServer.lookupPortByName(portName);
    if (sendPort != null) {
      sendPort.send(message);
    } else {
      debugPrint(message); // fallback if called before listener is ready
    }
  }
}
