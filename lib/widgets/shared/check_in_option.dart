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

    // Map type to M3 container colors using semantic extensions
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

    return Card(
      // elevation: isSelected ? 0 : 1,
      color: containerColor,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: contentColor, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: contentColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: contentColor,
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
                Icon(Icons.check_circle_rounded, color: contentColor, size: 24)
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: contentColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
