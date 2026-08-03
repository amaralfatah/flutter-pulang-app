import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/prayer_card.dart';
import '../../widgets/shared/unconfirmed_days_sheet.dart';

/// Ringkasan solat sepanjang riwayat pencatatan.
///
/// Angka di sini sengaja tidak dibatasi 7 atau 30 hari terakhir: solat itu
/// akumulatif, jadi dasarnya adalah seluruh rentang sejak catatan pertama.
class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerProvider);

    if (state.isLoading && !state.hasData) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }
    if (state.error != null) return _ErrorCard(message: state.error!);
    if (!state.hasData) return const _EmptyState();

    final ledger = state.ledger;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        _OverallCard(
          ledger: ledger,
          currentStreak: state.currentStreak,
          longestStreak: state.longestStreak,
        ),
        const SizedBox(height: 24),
        const _SectionHeader('Rincian per Waktu'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: PrayerName.values
                  .map(
                    (name) => _PrayerBreakdownTile(
                      prayerName: name,
                      tally: ledger.tallyFor(name),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (ledger.weakestPrayer != null) _InsightNote(ledger: ledger),
        if (state.incompleteDays.isNotEmpty)
          _UnrecordedNote(incompleteDays: state.incompleteDays),
      ],
    );
  }
}

/// Kartu utama: porsi solat yang terpenuhi sepanjang riwayat, plus streak.
///
/// Streak ikut di sini — dulu dua kartu terpisah dengan paragraf penjelas,
/// padahal isinya cuma dua angka pendek.
class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.ledger,
    required this.currentStreak,
    required this.longestStreak,
  });

  final PrayerLedger ledger;
  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final overall = ledger.overall;
    final percentage = overall.fulfilledRatio * 100;
    final since = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(ledger.startDate!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sejak $since',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: overall.fulfilledRatio,
                minHeight: 8,
                backgroundColor: colorScheme.outlineVariant,
                color: colorScheme.primary,
                semanticsLabel: 'Konsistensi sepanjang riwayat',
                semanticsValue: '${percentage.toStringAsFixed(0)} persen',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${overall.fulfilled} dari ${overall.known} solat tercatat '
              'sudah dikerjakan · ${ledger.closedDays} hari',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Streak $currentStreak hari · terpanjang $longestStreak hari',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu temuan yang bisa ditindaklanjuti, bukan sekadar angka. Sengaja teks
/// biasa, bukan kartu berwarna: satu-satunya penekanan di halaman ini adalah
/// angka besar di atas.
class _InsightNote extends StatelessWidget {
  const _InsightNote({required this.ledger});

  final PrayerLedger ledger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weakest = ledger.weakestPrayer!;
    final tally = ledger.tallyFor(weakest);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${weakest.displayName} paling sering terlewat — '
              '${tally.outstanding} kali belum diqadha.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris rincian per waktu solat, dengan bar proporsi status.
class _PrayerBreakdownTile extends StatelessWidget {
  const _PrayerBreakdownTile({required this.prayerName, required this.tally});

  final PrayerName prayerName;
  final PrayerTally tally;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(prayerIcon(prayerName), color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              prayerName.displayName,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: _StatusBar(tally: tally)),
          const SizedBox(width: 12),
          Text(
            '${(tally.fulfilledRatio * 100).toStringAsFixed(0)}%',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar proporsi: tepat waktu, terlambat, qadha lunas, hutang, belum tercatat.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.tally});

  final PrayerTally tally;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (tally.total == 0) return const SizedBox.shrink();

    final segments = <({int flex, Color color})>[
      (flex: tally.onTime, color: colorScheme.statusOnTime),
      (flex: tally.late, color: colorScheme.statusLate),
      (flex: tally.outstanding, color: colorScheme.statusMissed),
      (flex: tally.unrecorded, color: colorScheme.outlineVariant),
    ].where((s) => s.flex > 0).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: segments
              .map(
                (s) => Expanded(
                  flex: s.flex,
                  child: ColoredBox(color: s.color, child: const SizedBox()),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Menjelaskan kenapa ada slot yang tidak masuk hitungan persentase, dan
/// membuka daftar tanggalnya kalau ditekan — jalur yang sama dengan yang
/// dipakai di Qadha, supaya keduanya menunjuk ke satu tempat yang konsisten.
class _UnrecordedNote extends ConsumerWidget {
  const _UnrecordedNote({required this.incompleteDays});

  final List<IncompleteDay> incompleteDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = incompleteDays.length;

    return InkWell(
      onTap: () => showUnconfirmedDaysPicker(context, ref, incompleteDays),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                count == 1
                    ? '1 hari tidak pernah tercatat dan tidak dihitung sebagai hutang.'
                    : '$count hari tidak pernah tercatat dan tidak dihitung sebagai hutang.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $message',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada statistik',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Catat solatmu di Home untuk melihat konsistensi dan streak di sini.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
