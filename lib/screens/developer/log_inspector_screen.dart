import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/developer/log_service.dart';

class LogInspectorScreen extends StatefulWidget {
  const LogInspectorScreen({super.key});

  @override
  State<LogInspectorScreen> createState() => _LogInspectorScreenState();
}

class _LogInspectorScreenState extends State<LogInspectorScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _autoScroll = true;
  bool _isSearching = false;
  String _query = '';

  List<DateTime> _availableDates = [];
  DateTime _selectedDate = DateTime.now();
  List<LogEntry> _staticLogs = []; // used only when viewing a non-today date
  bool _isLoadingDate = false;

  bool get _isViewingToday => _isSameDay(_selectedDate, DateTime.now());

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    LogService.instance.logCountNotifier.addListener(_onNewLog);
    _loadAvailableDates();
  }

  @override
  void dispose() {
    LogService.instance.logCountNotifier.removeListener(_onNewLog);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableDates() async {
    final dates = await LogService.instance.getAvailableLogDates();
    if (mounted) {
      setState(() {
        _availableDates = dates;
        if (!dates.any((d) => _isSameDay(d, DateTime.now()))) {
          _availableDates = [DateTime.now(), ...dates];
        }
      });
    }
  }

  void _onNewLog() {
    if (!mounted || !_isViewingToday) return;
    setState(() {});
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoadingDate = !_isSameDay(date, DateTime.now());
    });

    if (!_isSameDay(date, DateTime.now())) {
      final entries = await LogService.instance.loadLogsForDate(date);
      if (mounted) {
        setState(() {
          _staticLogs = entries;
          _isLoadingDate = false;
        });
      }
    } else {
      setState(() {}); // switch back to live buffer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _query = '';
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  Future<void> _confirmClearCurrentDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isViewingToday
              ? 'Clear Today\'s Logs?'
              : 'Delete This Day\'s Log File?',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This permanently deletes the log file for ${DateFormat('dd MMM yyyy').format(_selectedDate)}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LogService.instance.deleteLogFile(_selectedDate);
      await _loadAvailableDates();
      if (!_isViewingToday) {
        setState(() => _staticLogs = []);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceLogs = _isViewingToday ? LogService.instance.logs : _staticLogs;
    final filtered = _query.isEmpty
        ? sourceLogs
        : sourceLogs
            .where(
                (l) => l.message.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _query = val),
              )
            : const Text('Log Inspector',
                style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white70),
            tooltip: _isSearching ? 'Close Search' : 'Search Logs',
            onPressed: _toggleSearch,
          ),
          if (_isViewingToday)
            IconButton(
              icon: Icon(
                _autoScroll
                    ? Icons.vertical_align_bottom_rounded
                    : Icons.pause_circle_outline_rounded,
                color: _autoScroll ? const Color(0xFF6366F1) : Colors.white54,
              ),
              tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
            tooltip: 'Delete This Day\'s Log',
            onPressed: _confirmClearCurrentDay,
          ),
        ],
      ),
      body: Column(
        children: [
          // Day selector strip
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                        isToday ? 'Today' : DateFormat('dd MMM').format(date)),
                    selected: isSelected,
                    onSelected: (_) => _selectDate(date),
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _isLoadingDate
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))))
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isNotEmpty
                              ? 'No logs match "$_query"'
                              : 'No logs for this day.',
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            final timeStr = DateFormat('HH:mm:ss.SSS')
                                .format(entry.timestamp);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      height: 1.4),
                                  children: [
                                    TextSpan(
                                      text: '$timeStr  ',
                                      style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                        text: entry.message,
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
