import 'dart:async';
import 'database_service.dart';

/// Service to detect date changes and trigger missed prayer marking
/// Note: This service needs to be initialized with provider references
/// from the app's main provider layer to avoid circular dependencies
class DateChangeService {
  final DatabaseService _databaseService;
  Timer? _timer;
  String _lastCheckedDate = '';

  // Callback to invalidate providers when date changes
  final void Function()? onDateChanged;

  DateChangeService(this._databaseService, {this.onDateChanged});

  /// Start monitoring for date changes
  void startMonitoring() {
    _lastCheckedDate = _getCurrentDate();

    // Check every minute if date has changed
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final currentDate = _getCurrentDate();

      if (currentDate != _lastCheckedDate) {
        // Date has changed! Mark missed prayers for yesterday
        try {
          await _databaseService.markMissedPrayers();
          _lastCheckedDate = currentDate;

          // Trigger callback to invalidate providers
          onDateChanged?.call();
        } catch (e) {
          // Silent fail - will retry on next check
        }
      }
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Get current date as string (YYYY-MM-DD)
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
