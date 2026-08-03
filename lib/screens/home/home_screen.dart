import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
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
        // Kiblat dan Pengaturan tinggal di sini, bukan di bottom nav: keduanya
        // dibuka sesekali, jadi tidak layak menahan slot navigasi utama.
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.push(AppRoutes.qibla),
            tooltip: 'Kiblat',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await prayerTimesNotifier.refresh();
          await todayPrayersNotifier.refresh();
        },
        child: ListView(
          // Error/empty states are short enough to not fill the viewport;
          // without this, RefreshIndicator can't be triggered from them.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            // Header: Location & Date (SEPARATED)
            _buildHeader(context, ref),

            const SizedBox(height: 16),

            // Timer Card (ONLY next prayer info)
            PrayerTimerCard(onTap: () => _handleTimerTap(context, ref)),

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

            // Prayer List — each load state gets its own treatment so the
            // screen never shows "tidak tersedia" while it is still loading,
            // nor blames a missing city for what is actually a network error.
            if (prayerTimesState.isLoading)
              _buildLoadingState(context)
            else if (prayerTimesState.error != null)
              _buildErrorState(context, prayerTimesNotifier)
            else if (prayerTimesState.prayerTime == null)
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

    // The location line doubles as the way to change it, so it stays tappable
    // even once a city is set — otherwise "Pilih Kota" reads as a dead end.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => context.push(AppRoutes.settings),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
                        const SizedBox(width: 4),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }

  /// Placeholder rows shown while the schedule is still being fetched, so the
  /// list keeps its final shape instead of collapsing to a message.
  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(5, (_) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 96,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 56,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Load failure is a different problem from "no city picked" — offer a retry
  /// instead of sending the user to Pengaturan for something already set.
  Widget _buildErrorState(
    BuildContext context,
    PrayerTimesNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat jadwal solat',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa koneksi internet lalu coba lagi.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Jadwal solat tidak tersedia',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih kota terlebih dahulu supaya jadwal bisa dimuat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // An empty state without a way out forces the user to go hunting.
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Pilih kota'),
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

  /// Kartu timer menampilkan solat berikutnya — jadikan ia jalan pintas untuk
  /// mencatatnya, tanpa harus mencari barisnya di daftar di bawah.
  void _handleTimerTap(BuildContext context, WidgetRef ref) {
    final state = ref.read(prayerTimesProvider);
    final prayerTime = state.prayerTime;
    final nextName = state.nextPrayerName;
    // "Subuh (besok)" berarti semua solat hari ini sudah lewat waktunya —
    // belum ada yang bisa dicatat untuk esok.
    if (prayerTime == null || nextName == null || nextName.contains('besok')) {
      return;
    }

    final match = PrayerName.values
        .where((p) => p.displayName == nextName)
        .firstOrNull;
    if (match == null) return;

    final time = _timeForPrayer(prayerTime, match);
    final existingRecord = ref.read(todayPrayersProvider).getPrayerByName(match);
    _handlePrayerTap(context, ref, match, time, existingRecord);
  }

  String _timeForPrayer(PrayerTime prayerTime, PrayerName name) {
    switch (name) {
      case PrayerName.subuh:
        return prayerTime.subuh;
      case PrayerName.dzuhur:
        return prayerTime.dzuhur;
      case PrayerName.ashar:
        return prayerTime.ashar;
      case PrayerName.maghrib:
        return prayerTime.maghrib;
      case PrayerName.isya:
        return prayerTime.isya;
    }
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
      onDelete: existingRecord == null
          ? null
          : () => _handleDelete(context, ref, name, existingRecord),
      onStatusSelected: (status) =>
          _handleStatusSelected(context, ref, name, status),
    );
  }

  Future<void> _handleStatusSelected(
    BuildContext context,
    WidgetRef ref,
    PrayerName name,
    PrayerStatus status,
  ) async {
    await ref
        .read(todayPrayersProvider.notifier)
        .checkIn(prayerName: name, status: status);
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    PrayerName name,
    Prayer record,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(todayPrayersProvider.notifier);

    await notifier.deletePrayer(record.id!);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('Catatan ${name.displayName} dihapus.'),
        persist: false,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => notifier.restorePrayer(record),
        ),
      ),
    );
  }

}
