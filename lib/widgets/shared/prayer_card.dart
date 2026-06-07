import 'package:flutter/material.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';

/// Shared Prayer Card Widget - displays prayer with emoji icon and status
/// Used in both CalendarScreen and HomeScreen
class PrayerCard extends StatelessWidget {
  final PrayerName prayerName;
  final PrayerStatus? status;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const PrayerCard({
    super.key,
    required this.prayerName,
    this.status,
    this.subtitle,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        status == PrayerStatus.onTime || status == PrayerStatus.late;
    final isLate = status == PrayerStatus.late;
    final isMissed = status == PrayerStatus.missed;

    final colorScheme = Theme.of(context).colorScheme;

    // Determine status icon and color using semantic extensions
    Color statusBgColor;
    Color statusIconColor;
    IconData statusIcon;

    if (isCompleted) {
      statusBgColor = isLate
          ? colorScheme.statusLateContainer
          : colorScheme.statusOnTimeContainer;
      statusIconColor = isLate
          ? colorScheme.onStatusLateContainer
          : colorScheme.onStatusOnTimeContainer;
      statusIcon = Icons.check_rounded;
    } else if (isMissed) {
      statusBgColor = colorScheme.statusMissedContainer;
      statusIconColor = colorScheme.onStatusMissedContainer;
      statusIcon = Icons.close_rounded;
    } else {
      statusBgColor = colorScheme.surfaceContainerHighest;
      statusIconColor = colorScheme.onSurfaceVariant;
      statusIcon = Icons.remove_rounded;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Use secondaryContainer for highlight to differentiate from onTime status
      color: isHighlighted ? colorScheme.secondaryContainer : null,
      // elevation: isHighlighted ? 0 : 1,
      shape: isHighlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.secondary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Prayer Icon (decorative - the name is announced as text)
              Icon(_getIcon(prayerName), color: colorScheme.primary, size: 24),
              const SizedBox(width: 16),

              // Prayer Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(prayerName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle ?? _getStatusText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Circle Icon - only show if status is set.
              // Wrapped in Semantics so the state is announced, not conveyed
              // by colour/icon alone (a11y: color-not-only).
              if (status != null)
                Semantics(
                  label: 'Status: ${_getStatusText()}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusIconColor, size: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get icon for prayer
  IconData _getIcon(PrayerName name) {
    switch (name) {
      case PrayerName.subuh:
        return Icons.wb_twilight_rounded;
      case PrayerName.dzuhur:
        return Icons.wb_sunny_rounded;
      case PrayerName.ashar:
        return Icons.wb_cloudy_rounded;
      case PrayerName.maghrib:
        return Icons.nights_stay_rounded;
      case PrayerName.isya:
        return Icons.bedtime_rounded;
    }
  }

  /// Get display name for prayer
  String _getDisplayName(PrayerName name) {
    switch (name) {
      case PrayerName.subuh:
        return 'Subuh';
      case PrayerName.dzuhur:
        return 'Dzuhur';
      case PrayerName.ashar:
        return 'Ashar';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isya:
        return 'Isya';
    }
  }

  /// Get status text based on prayer status
  String _getStatusText() {
    switch (status) {
      case PrayerStatus.onTime:
        return 'Tepat Waktu';
      case PrayerStatus.late:
        return 'Qadha';
      case PrayerStatus.missed:
        return 'Terlewat';
      case null:
        return 'Belum dicatat';
    }
  }
}
