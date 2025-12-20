import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
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

    // Determine status icon and color
    Color statusBgColor;
    Color statusIconColor;
    IconData statusIcon;

    if (isCompleted) {
      statusBgColor = isLate
          ? AppColors.warning.withOpacity(0.15)
          : AppColors.success.withOpacity(0.15);
      statusIconColor = isLate ? AppColors.warning : AppColors.success;
      statusIcon = Icons.check_rounded;
    } else if (isMissed) {
      statusBgColor = AppColors.error.withOpacity(0.15);
      statusIconColor = AppColors.error;
      statusIcon = Icons.close_rounded;
    } else {
      statusBgColor = AppColors.divider.withOpacity(0.5);
      statusIconColor = AppColors.textSecondary;
      statusIcon = Icons.remove_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Emoji Icon
                Text(
                  _getEmoji(prayerName),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),

                // Prayer Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(prayerName),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? _getStatusText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Circle Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusIconColor, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get emoji for prayer
  String _getEmoji(PrayerName name) {
    switch (name) {
      case PrayerName.subuh:
        return '\u{1F319}'; // 🌙 Crescent Moon
      case PrayerName.dzuhur:
        return '\u{2600}'; // ☀ Sun
      case PrayerName.ashar:
        return '\u{1F31E}'; // 🌞 Sun With Face
      case PrayerName.maghrib:
        return '\u{26C5}'; // ⛅ Sun Behind Cloud
      case PrayerName.isya:
        return '\u{2B50}'; // ⭐ Star
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
