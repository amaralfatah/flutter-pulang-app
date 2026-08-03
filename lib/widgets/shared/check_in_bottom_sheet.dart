import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'check_in_option.dart';

/// Callback when a status is selected
typedef OnStatusSelected = void Function(PrayerStatus status);

/// Reusable bottom sheet for prayer check-in
/// Used by both HomeScreen and CalendarScreen
class CheckInBottomSheet extends StatelessWidget {
  final PrayerName prayerName;
  final PrayerStatus? currentStatus;
  final String? subtitle;
  final OnStatusSelected onStatusSelected;

  /// Menghapus catatan ini sepenuhnya, mengembalikannya ke "Belum dicatat".
  /// Hanya relevan saat [currentStatus] sudah terisi — tanpa jalur ini,
  /// salah tap tidak bisa dikembalikan ke kosong, hanya bisa ditimpa status
  /// lain.
  final VoidCallback? onDelete;

  const CheckInBottomSheet({
    super.key,
    required this.prayerName,
    required this.onStatusSelected,
    this.currentStatus,
    this.subtitle,
    this.onDelete,
  });

  /// Show the check-in bottom sheet
  static Future<void> show({
    required BuildContext context,
    required PrayerName prayerName,
    required OnStatusSelected onStatusSelected,
    PrayerStatus? currentStatus,
    String? subtitle,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      // M3 native drag handle + extra-large (28dp) top corners.
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (sheetContext) => CheckInBottomSheet(
        prayerName: prayerName,
        currentStatus: currentStatus,
        subtitle: subtitle,
        onDelete: onDelete == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                onDelete();
              },
        onStatusSelected: (status) {
          Navigator.pop(sheetContext);
          onStatusSelected(status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = currentStatus != null;
    final displayName = _getDisplayName(prayerName);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              isEdit ? 'Edit $displayName' : 'Catat $displayName',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            // Optional Subtitle (e.g., date)
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // On Time Option
            CheckInOption(
              icon: Icons.check_circle_rounded,
              type: CheckInType.onTime,
              title: 'Tepat Waktu',
              subtitle: 'Solat dilakukan di awal waktu',
              isSelected: currentStatus == PrayerStatus.onTime,
              onTap: () => onStatusSelected(PrayerStatus.onTime),
            ),
            const SizedBox(height: 12),

            // Late Option
            CheckInOption(
              icon: Icons.schedule_rounded,
              type: CheckInType.late,
              title: 'Qadha / Terlambat',
              subtitle: 'Solat dilakukan di luar waktu',
              isSelected: currentStatus == PrayerStatus.late,
              onTap: () => onStatusSelected(PrayerStatus.late),
            ),
            const SizedBox(height: 12),

            // Missed Option
            CheckInOption(
              icon: Icons.cancel_rounded,
              type: CheckInType.missed,
              title: 'Terlewat',
              subtitle: 'Tidak solat',
              isSelected: currentStatus == PrayerStatus.missed,
              onTap: () => onStatusSelected(PrayerStatus.missed),
            ),

            const SizedBox(height: 24),

            // Delete: only offered when there's actually a record to remove.
            if (isEdit && onDelete != null) ...[
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                label: Text(
                  'Hapus catatan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
