import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/home/prayer_timer_card.dart';
import '../../widgets/shared/prayer_card.dart';
import '../../widgets/shared/check_in_option.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final prayerTimesState = ref.watch(prayerTimesProvider);
    final todayPrayersState = ref.watch(todayPrayersProvider);

    // Actions
    final prayerTimesNotifier = ref.read(prayerTimesProvider.notifier);
    final todayPrayersNotifier = ref.read(todayPrayersProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              prayerTimesNotifier.refresh();
              todayPrayersNotifier.refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await prayerTimesNotifier.refresh();
          await todayPrayersNotifier.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            // Header: Location & Date (SEPARATED)
            _buildHeader(context, ref),

            const SizedBox(height: 16),

            // Timer Card (ONLY next prayer info)
            const PrayerTimerCard(),

            const SizedBox(height: 24),

            // Section Title with Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Jadwal Hari Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Progress Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${todayPrayersState.completedCount}/5',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Prayer List
            if (prayerTimesState.prayerTime == null)
              _buildEmptyState()
            else
              ..._buildPrayerList(
                context,
                ref,
                prayerTimesState.prayerTime!,
                todayPrayersState,
              ),
          ],
        ),
      ),
    );
  }

  /// Header terpisah untuk lokasi dan tanggal
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        settings.cityName ?? 'Pilih Kota',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Jadwal solat tidak tersedia',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih kota di Pengaturan',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerList(
    BuildContext context,
    WidgetRef ref,
    PrayerTime prayerTime,
    TodayPrayersState prayersState,
  ) {
    final prayers = [
      (PrayerName.subuh, prayerTime.subuh),
      (PrayerName.dzuhur, prayerTime.dzuhur),
      (PrayerName.ashar, prayerTime.ashar),
      (PrayerName.maghrib, prayerTime.maghrib),
      (PrayerName.isya, prayerTime.isya),
    ];

    // Determine next prayer for highlighting
    final nextPrayerState = ref.watch(prayerTimesProvider);
    final nextPrayerNameStr = nextPrayerState.nextPrayerName;

    return prayers.map((item) {
      final name = item.$1;
      final time = item.$2;

      // Get existing status if any
      final prayerRecord = prayersState.getPrayerByName(name);
      final isNext =
          name.toString().split('.').last.toLowerCase() ==
          nextPrayerNameStr?.toLowerCase();

      return PrayerCard(
        prayerName: name,
        status: prayerRecord?.status,
        subtitle: time,
        isHighlighted: isNext,
        onTap: () => _handlePrayerTap(context, ref, name, time, prayerRecord),
      );
    }).toList();
  }

  Future<void> _handlePrayerTap(
    BuildContext context,
    WidgetRef ref,
    PrayerName name,
    String time,
    Prayer? existingRecord,
  ) async {
    final isEdit = existingRecord != null;
    final displayName =
        name.value.substring(0, 1).toUpperCase() + name.value.substring(1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.bottomSheetRadius),
        ),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Edit $displayName' : 'Check-in $displayName',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            CheckInOption(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              title: 'Tepat Waktu',
              subtitle: 'Solat dilakukan di awal waktu',
              isSelected: existingRecord?.status == PrayerStatus.onTime,
              onTap: () {
                Navigator.pop(context);
                _checkIn(ref, name, PrayerStatus.onTime);
              },
            ),
            const SizedBox(height: 12),
            CheckInOption(
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
              title: 'Terlambat / Qadha',
              subtitle: 'Solat dilakukan setelah waktu ideal',
              isSelected: existingRecord?.status == PrayerStatus.late,
              onTap: () {
                Navigator.pop(context);
                _checkIn(ref, name, PrayerStatus.late);
              },
            ),
            const SizedBox(height: 12),
            CheckInOption(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              title: 'Terlewat',
              subtitle: 'Tidak solat',
              isSelected: existingRecord?.status == PrayerStatus.missed,
              onTap: () {
                Navigator.pop(context);
                _checkIn(ref, name, PrayerStatus.missed);
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _checkIn(WidgetRef ref, PrayerName name, PrayerStatus status) {
    ref
        .read(todayPrayersProvider.notifier)
        .checkIn(prayerName: name, status: status);
  }
}
