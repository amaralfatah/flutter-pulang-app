import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import 'prayer_provider.dart';

/// State for statistics
class StatisticsState {
  final int currentStreak;
  final int totalCompleted;
  final Map<String, int> weeklyStats;
  final Map<String, int> statusCount;
  final bool isLoading;
  final String? error;

  const StatisticsState({
    this.currentStreak = 0,
    this.totalCompleted = 0,
    this.weeklyStats = const {},
    this.statusCount = const {},
    this.isLoading = false,
    this.error,
  });

  StatisticsState copyWith({
    int? currentStreak,
    int? totalCompleted,
    Map<String, int>? weeklyStats,
    Map<String, int>? statusCount,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsState(
      currentStreak: currentStreak ?? this.currentStreak,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      statusCount: statusCount ?? this.statusCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Calculate weekly completion percentage
  double get weeklyPercentage {
    if (weeklyStats.isEmpty) return 0;
    final totalPossible = 7 * 5; // 7 days * 5 prayers
    final completed = weeklyStats.values.fold(0, (sum, count) => sum + count);
    return (completed / totalPossible * 100).clamp(0, 100);
  }

  /// Get on-time count
  int get onTimeCount => statusCount['on_time'] ?? 0;

  /// Get late count
  int get lateCount => statusCount['late'] ?? 0;

  /// Get missed count
  int get missedCount => statusCount['missed'] ?? 0;
}

/// Notifier for statistics (Riverpod 3 syntax)
class StatisticsNotifier extends Notifier<StatisticsState> {
  DatabaseService get _databaseService => ref.read(databaseServiceProvider);

  @override
  StatisticsState build() {
    _loadStatistics();
    return const StatisticsState(isLoading: true);
  }

  /// Load all statistics
  Future<void> _loadStatistics() async {
    try {
      final streak = await _databaseService.getCurrentStreak();
      final totalCompleted = await _databaseService.getTotalCompletedCount();
      final weeklyStats = await _databaseService.getWeeklyStats();

      // Calculate date range for status count (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final startDate = _formatDate(weekAgo);
      final endDate = _formatDate(now);

      final statusCount = await _databaseService.getStatusCount(
        startDate: startDate,
        endDate: endDate,
      );

      state = StatisticsState(
        currentStreak: streak,
        totalCompleted: totalCompleted,
        weeklyStats: weeklyStats,
        statusCount: statusCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadStatistics();
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Provider for statistics
final statisticsProvider =
    NotifierProvider<StatisticsNotifier, StatisticsState>(
      StatisticsNotifier.new,
    );

/// Provider for current streak
final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(statisticsProvider).currentStreak;
});

/// Provider for weekly percentage
final weeklyPercentageProvider = Provider<double>((ref) {
  return ref.watch(statisticsProvider).weeklyPercentage;
});

/// Provider for total completed prayers
final totalCompletedProvider = Provider<int>((ref) {
  return ref.watch(statisticsProvider).totalCompleted;
});
