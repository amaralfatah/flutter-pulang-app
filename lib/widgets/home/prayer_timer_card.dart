import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../patterns/pattern_painters.dart';

/// Card widget yang menampilkan info solat berikutnya
/// Dengan background pattern Islamic geometric
class PrayerTimerCard extends ConsumerWidget {
  const PrayerTimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesState = ref.watch(prayerTimesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.primary,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: IslamicPatternPainter(
            color: colorScheme.onPrimary,
            opacity: 0.1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context, prayerTimesState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrayerTimesState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    if (state.isLoading) {
      return SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: onPrimary, strokeWidth: 3),
        ),
      );
    }

    if (state.error != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: onPrimary.withValues(alpha: 0.7),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat jadwal',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: onPrimary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Label with Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_rounded,
              color: onPrimary.withValues(alpha: 0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Solat Berikutnya',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Prayer Name - Hero text
        Text(
          state.nextPrayerName ?? '-',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Prayer Time
        Text(
          state.nextPrayerTime ?? '--:--',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: onPrimary, letterSpacing: 1),
        ),

        const SizedBox(height: 20),

        // Countdown Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, color: onPrimary, size: 16),
              const SizedBox(width: 6),
              Text(
                _getCountdownText(state.remainingTime),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCountdownText(Duration? duration) {
    if (duration == null) return 'Selesai hari ini';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours jam $minutes menit lagi';
    } else if (minutes > 0) {
      return '$minutes menit lagi';
    } else {
      return 'Sebentar lagi';
    }
  }
}
