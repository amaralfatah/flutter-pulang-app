import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';
import 'prayer_provider.dart';

/// State for History
class HistoryState {
  final List<HistoryEntry> entries;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const HistoryState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  HistoryState copyWith({
    List<HistoryEntry>? entries,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// A simple model for History List Item
class HistoryEntry {
  final String date;
  final int completedCount;
  final int totalCount;
  final List<String> completedPrayers;
  final List<String> onTimePrayers;
  final List<String> latePrayers;

  HistoryEntry({
    required this.date,
    required this.completedCount,
    this.totalCount = 5,
    this.completedPrayers = const [],
    this.onTimePrayers = const [],
    this.latePrayers = const [],
  });
}

/// Notifier for History
class HistoryNotifier extends Notifier<HistoryState> {
  DatabaseService get _databaseService => ref.read(databaseServiceProvider);
  static const int _limit = 20;

  @override
  HistoryState build() {
    Future.microtask(() => loadInitial());
    return const HistoryState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _databaseService.getHistoryStats(
        limit: _limit,
        offset: 0,
      );
      final entries = data.map((e) {
        final completedStr = e['completed_prayers'] as String?;
        final completedList =
            completedStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        final onTimeStr = e['on_time_prayers'] as String?;
        final onTimeList =
            onTimeStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        final lateStr = e['late_prayers'] as String?;
        final lateList =
            lateStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        return HistoryEntry(
          date: e['date'] as String,
          completedCount: e['completed_count'] as int,
          completedPrayers: completedList,
          onTimePrayers: onTimeList,
          latePrayers: lateList,
        );
      }).toList();

      state = HistoryState(
        entries: entries,
        isLoading: false,
        hasMore: entries.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final currentLength = state.entries.length;
      final data = await _databaseService.getHistoryStats(
        limit: _limit,
        offset: currentLength,
      );

      final newEntries = data.map((e) {
        final completedStr = e['completed_prayers'] as String?;
        final completedList =
            completedStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        final onTimeStr = e['on_time_prayers'] as String?;
        final onTimeList =
            onTimeStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        final lateStr = e['late_prayers'] as String?;
        final lateList =
            lateStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
        return HistoryEntry(
          date: e['date'] as String,
          completedCount: e['completed_count'] as int,
          completedPrayers: completedList,
          onTimePrayers: onTimeList,
          latePrayers: lateList,
        );
      }).toList();

      state = state.copyWith(
        entries: [...state.entries, ...newEntries],
        isLoading: false,
        hasMore: newEntries.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);
