import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/home/prayer_timer_card.dart';
import '../../widgets/shared/prayer_card.dart';
import '../../widgets/shared/check_in_bottom_sheet.dart';

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
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh_rounded),
        //     onPressed: () {
        //       prayerTimesNotifier.refresh();
        //       todayPrayersNotifier.refresh();
        //     },
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
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
                    ),
                  ),
                  const Spacer(),
                  // Progress Badge - tonal pill, labelled for screen readers.
                  Semantics(
                    label:
                        '${todayPrayersState.completedCount} dari 5 solat selesai',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todayPrayersState.completedCount}/5',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Prayer List
            if (prayerTimesState.prayerTime == null)
              _buildEmptyState(context)
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
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        settings.cityName ?? 'Pilih Kota',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Jadwal solat tidak tersedia',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih kota di Pengaturan',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
    await CheckInBottomSheet.show(
      context: context,
      prayerName: name,
      currentStatus: existingRecord?.status,
      onStatusSelected: (status) {
        ref
            .read(todayPrayersProvider.notifier)
            .checkIn(prayerName: name, status: status);
      },
    );
  }
}
