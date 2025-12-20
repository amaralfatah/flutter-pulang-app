import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';

class PrayerListItem extends StatelessWidget {
  final PrayerName prayerName;
  final String time;
  final PrayerStatus? status;
  final VoidCallback? onTap;
  final bool isNext;

  const PrayerListItem({
    super.key,
    required this.prayerName,
    required this.time,
    this.status,
    this.onTap,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isNext ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [AppShadows.light],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon Status
                _buildStatusIcon(),
                const SizedBox(width: 16),

                // Name & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPrayerName(prayerName),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action/Status Text
                if (status == null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status!),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (status == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.5),
            width: 2,
          ),
        ),
      );
    }

    IconData icon;
    Color color = _getStatusColor();

    switch (status!) {
      case PrayerStatus.onTime:
        icon = Icons.check_circle_rounded;
        break;
      case PrayerStatus.late:
        icon = Icons.schedule_rounded;
        break;
      case PrayerStatus.missed:
        icon = Icons.cancel_rounded;
        break;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _getPrayerName(PrayerName name) {
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

  String _getStatusText(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.onTime:
        return 'Tepat Waktu';
      case PrayerStatus.late:
        return 'Terlambat';
      case PrayerStatus.missed:
        return 'Terlewat';
    }
  }

  Color _getStatusColor() {
    if (status == null) return AppColors.primary;
    switch (status!) {
      case PrayerStatus.onTime:
        return AppColors.success;
      case PrayerStatus.late:
        return AppColors.warning;
      case PrayerStatus.missed:
        return AppColors.error;
    }
  }

  Color _getTextColor() {
    if (status == null) return AppColors.secondary;
    return _getStatusColor();
  }
}
