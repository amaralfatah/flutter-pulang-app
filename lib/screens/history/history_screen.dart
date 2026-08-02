import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import 'calendar_view.dart';
import 'statistics_view.dart';

/// Dua cara melihat ke belakang.
enum HistoryTab { calendar, statistics }

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
  HistoryTab _tab = HistoryTab.calendar;

  @override
  Widget build(BuildContext context) {
    final isCalendar = _tab == HistoryTab.calendar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
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
              tooltip: 'Hari Ini',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<HistoryTab>(
              segments: const [
                ButtonSegment(
                  value: HistoryTab.calendar,
                  icon: Icon(Icons.calendar_month_rounded),
                  label: Text('Kalender'),
                ),
                ButtonSegment(
                  value: HistoryTab.statistics,
                  icon: Icon(Icons.insights_rounded),
                  label: Text('Ringkasan'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
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
