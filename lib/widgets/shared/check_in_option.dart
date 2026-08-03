import 'package:flutter/material.dart';

import '../../app/extensions/color_scheme_extensions.dart';

/// Type of check-in option for M3 color mapping
enum CheckInType { onTime, late, missed }

/// Shared check-in option widget for bottom sheets
/// Used in HomeScreen and CalendarScreen for prayer check-in
class CheckInOption extends StatelessWidget {
  final IconData icon;
  final CheckInType type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  const CheckInOption({
    super.key,
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Map type to M3 container colors using semantic extensions. The badge
    // keeps each option's color identity even though the row itself is flat,
    // so the three options stay distinguishable at a glance.
    final (Color containerColor, Color contentColor) = switch (type) {
      CheckInType.onTime => (
        colorScheme.statusOnTimeContainer,
        colorScheme.onStatusOnTimeContainer,
      ),
      CheckInType.late => (
        colorScheme.statusLateContainer,
        colorScheme.onStatusLateContainer,
      ),
      CheckInType.missed => (
        colorScheme.statusMissedContainer,
        colorScheme.onStatusMissedContainer,
      ),
    };

    // Selected-state border/check use the bright (non-container) tone —
    // the container tone is muted in dark mode and read as barely-there.
    final Color activeColor = switch (type) {
      CheckInType.onTime => colorScheme.statusOnTime,
      CheckInType.late => colorScheme.statusLate,
      CheckInType.missed => colorScheme.statusMissed,
    };

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor, width: 2)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: containerColor,
                foregroundColor: contentColor,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: activeColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
