import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dua cara melihat ke belakang di layar Riwayat.
enum HistoryTab { calendar, statistics }

class HistoryTabNotifier extends Notifier<HistoryTab> {
  @override
  HistoryTab build() => HistoryTab.calendar;

  void select(HistoryTab tab) => state = tab;
}

/// Tab yang sedang aktif di layar Riwayat. Diekspos sebagai provider —
/// bukan state lokal — supaya layar lain (misalnya saat melompat ke tanggal
/// tertentu dari Qadha atau Ringkasan) bisa memastikan Kalender yang
/// tampil, tanpa bergantung pada tab mana yang terakhir dibuka user.
final historyTabProvider = NotifierProvider<HistoryTabNotifier, HistoryTab>(
  HistoryTabNotifier.new,
);
