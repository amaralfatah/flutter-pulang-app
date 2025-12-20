import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../patterns/pattern_painters.dart';

/// Card widget yang menampilkan info solat berikutnya
/// Dengan background pattern Islamic geometric
class PrayerTimerCard extends ConsumerWidget {
  const PrayerTimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesState = ref.watch(prayerTimesProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: AppColors.primary,
        boxShadow: [AppShadows.light],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: CustomPaint(
          painter: IslamicPatternPainter(color: Colors.white, opacity: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context, prayerTimesState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrayerTimesState state) {
    if (state.isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
                color: Colors.white.withOpacity(0.7),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat jadwal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
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
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Solat Berikutnya',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Prayer Name - Hero text
        Text(
          state.nextPrayerName ?? '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 8),

        // Prayer Time
        Text(
          state.nextPrayerTime ?? '--:--',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 20),

        // Countdown Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _getCountdownText(state.remainingTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
