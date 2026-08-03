import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../providers/providers.dart';

/// Menampilkan daftar tanggal yang belum tercatat, terurut dari yang paling
/// lama. Memilih satu langsung membuka Kalender pada hari itu — tidak perlu
/// menyelesaikan yang tertua dulu, dan tidak perlu scroll kalender bulan demi
/// bulan untuk menemukannya. Dipakai bersama oleh Qadha dan Ringkasan supaya
/// keduanya menunjuk ke satu jalur yang sama, bukan alur yang berbeda-beda.
Future<void> showUnconfirmedDaysPicker(
  BuildContext context,
  WidgetRef ref,
  List<IncompleteDay> days,
) async {
  final chosen = await showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _UnconfirmedDaysSheet(days: days),
  );
  if (chosen == null || !context.mounted) return;

  ref.read(calendarProvider.notifier)
    ..onPageChanged(chosen)
    ..selectDay(chosen);
  // Dipaksa ke tab Kalender: kalau dipanggil dari dalam Ringkasan (tab lain
  // pada layar Riwayat yang sama), navigasi rute saja tidak mengganti tab
  // yang sedang tampil.
  ref.read(historyTabProvider.notifier).select(HistoryTab.calendar);
  context.go(AppRoutes.history);
}

class _UnconfirmedDaysSheet extends StatelessWidget {
  const _UnconfirmedDaysSheet({required this.days});

  final List<IncompleteDay> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih tanggal untuk membukanya di Kalender',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final parsed = DateTime.parse(day.date);
                final missing = 5 - day.recorded;
                return ListTile(
                  leading: Icon(
                    Icons.event_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed),
                  ),
                  subtitle: Text(
                    missing == 1 ? '1 waktu belum tercatat' : '$missing waktu belum tercatat',
                  ),
                  onTap: () => Navigator.pop(context, parsed),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
