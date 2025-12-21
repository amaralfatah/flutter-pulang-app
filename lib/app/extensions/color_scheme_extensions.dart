import 'package:flutter/material.dart';

/// ColorScheme extensions for semantic status colors
/// This keeps M3 compliance while providing readable aliases
extension StatusColors on ColorScheme {
  // ============ ON TIME / SUCCESS ============
  /// Status: On Time - uses primary (green)
  Color get statusOnTime => primary;
  Color get onStatusOnTime => onPrimary;
  Color get statusOnTimeContainer => primaryContainer;
  Color get onStatusOnTimeContainer => onPrimaryContainer;

  // ============ LATE / WARNING ============
  /// Status: Late/Qadha - uses tertiary (amber)
  Color get statusLate => tertiary;
  Color get onStatusLate => onTertiary;
  Color get statusLateContainer => tertiaryContainer;
  Color get onStatusLateContainer => onTertiaryContainer;

  // ============ MISSED / ERROR ============
  /// Status: Missed - uses error (red)
  Color get statusMissed => error;
  Color get onStatusMissed => onError;
  Color get statusMissedContainer => errorContainer;
  Color get onStatusMissedContainer => onErrorContainer;
}
