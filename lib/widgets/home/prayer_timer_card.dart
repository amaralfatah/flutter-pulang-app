import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../patterns/pattern_painters.dart';

/// Tinggi baris label+countdown (26) + jarak (10) + baris hero (32).
const double _contentHeight = 68;

/// Card widget yang menampilkan info solat berikutnya
/// Dengan background pattern Islamic geometric
class PrayerTimerCard extends ConsumerWidget {
  const PrayerTimerCard({super.key, this.onTap});

  /// Membuka check-in untuk solat berikutnya. Null saat belum ada solat
  /// berikutnya yang bisa dicatat (mis. masih menunggu jadwal dimuat).
  final VoidCallback? onTap;

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
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildContent(context, prayerTimesState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrayerTimesState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    // Semua state dipaksa setinggi kartu normal supaya tinggi kartu tidak
    // melompat saat jadwal selesai dimuat atau gagal.
    if (state.isLoading) {
      return const SizedBox(
        height: _contentHeight,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    if (state.error != null) {
      return SizedBox(
        height: _contentHeight,
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: onPrimary.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gagal memuat jadwal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: onPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris label + countdown. Countdown ditaruh di sini, bukan di bawah
        // nama solat, supaya teks panjangnya tidak pernah beradu ruang
        // dengan nama + jam di baris hero.
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: onPrimary.withValues(alpha: 0.8),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Solat Berikutnya',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: onPrimary, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _getCountdownText(state.remainingTime),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Baris hero: nama solat + jamnya, disejajarkan pada baseline.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                state.nextPrayerName ?? '-',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              state.nextPrayerTime ?? '--:--',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.9),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getCountdownText(Duration? duration) {
    // Only reachable when the schedule time could not be parsed; the
    // all-prayers-passed case now counts down to tomorrow's Subuh.
    if (duration == null) return 'Waktu tidak diketahui';

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
