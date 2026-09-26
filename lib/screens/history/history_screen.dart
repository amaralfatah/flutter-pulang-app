import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/extensions/context_extensions.dart';
import '../../providers/providers.dart';
import 'calendar_view.dart';
import 'statistics_view.dart';

/// Layar Riwayat — gabungan Kalender dan Statistik.
///
/// Keduanya menjawab pertanyaan yang sama ("bagaimana catatan solatku?") dan
/// membaca data yang sama, jadi keduanya berbagi satu tujuan navigasi. Kalender
/// untuk menelusuri hari tertentu, Ringkasan untuk melihat polanya.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(historyTabProvider);
    final isCalendar = tab == HistoryTab.calendar;
    // Fixed 56px overflows once system font scale grows the segmented
    // button's label text (Dynamic Type / large accessibility text sizes).
    final segmentedHeight = 56 * MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.historyTitle),
        actions: [
          // Hanya relevan saat kalender tampil.
          if (isCalendar)
            IconButton(
              icon: const Icon(Icons.today_rounded),
              onPressed: () {
                final notifier = ref.read(calendarProvider.notifier);
                notifier.onPageChanged(DateTime.now());
                notifier.selectDay(DateTime.now());
              },
              tooltip: context.l10n.historyToday,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(segmentedHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<HistoryTab>(
              segments: [
                ButtonSegment(
                  value: HistoryTab.calendar,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(context.l10n.historyTabCalendar),
                ),
                ButtonSegment(
                  value: HistoryTab.statistics,
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(context.l10n.historyTabStatistics),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (selection) => ref
                  .read(historyTabProvider.notifier)
                  .select(selection.first),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await ref.read(calendarProvider.notifier).refresh();
          await ref.read(ledgerProvider.notifier).refresh();
        },
        // IndexedStack supaya posisi gulir dan bulan yang sedang dibuka tidak
        // ikut hilang setiap kali user berpindah segmen.
        child: IndexedStack(
          index: isCalendar ? 0 : 1,
          children: const [CalendarView(), StatisticsView()],
        ),
      ),
    );
  }
}
