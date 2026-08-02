import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/prayer_card.dart';

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
    final overall = ledger.overall;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        _OverallCard(ledger: ledger),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Streak',
                  value: '${state.currentStreak}',
                  unit: 'hari',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Terpanjang',
                  value: '${state.longestStreak}',
                  unit: 'hari',
                  icon: Icons.emoji_events_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (ledger.weakestPrayer != null)
          _InsightCard(ledger: ledger),
        const _SectionHeader('Rincian per Waktu'),
        ...PrayerName.values.map(
          (name) => _PrayerBreakdownTile(
            prayerName: name,
            tally: ledger.tallyFor(name),
          ),
        ),
        if (overall.unrecorded > 0) _UnrecordedNote(count: overall.unrecorded),
      ],
    );
  }
}

/// Kartu utama: porsi solat yang terpenuhi sepanjang riwayat.
class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.ledger});

  final PrayerLedger ledger;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sejak $since',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timeline_rounded,
                    size: 32,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: overall.fulfilledRatio,
                minHeight: 10,
                backgroundColor: colorScheme.outlineVariant,
                color: colorScheme.primary,
                semanticsLabel: 'Konsistensi sepanjang riwayat',
                semanticsValue: '${percentage.toStringAsFixed(1)} persen',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${overall.fulfilled} dari ${overall.known} solat yang tercatat '
              'sudah dikerjakan, terkumpul dalam ${ledger.closedDays} hari.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu temuan yang bisa ditindaklanjuti, bukan sekadar angka.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.ledger});

  final PrayerLedger ledger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weakest = ledger.weakestPrayer!;
    final tally = ledger.tallyFor(weakest);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: colorScheme.onSecondaryContainer,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weakest.displayName} paling sering terlewat',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tally.outstanding} kali belum diqadha. Ini titik yang '
                    'paling berdampak kalau kamu perbaiki lebih dulu.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  prayerIcon(prayerName),
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prayerName.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${(tally.fulfilledRatio * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusBar(tally: tally),
            const SizedBox(height: 10),
            Text(
              _summaryLine(tally),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryLine(PrayerTally tally) {
    final parts = <String>[
      '${tally.onTime} tepat waktu',
      if (tally.late > 0) '${tally.late} terlambat',
      if (tally.qadhaPaid > 0) '${tally.qadhaPaid} diqadha',
      if (tally.outstanding > 0) '${tally.outstanding} hutang',
      if (tally.unrecorded > 0) '${tally.unrecorded} belum tercatat',
    ];
    return parts.join(' · ');
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
      (flex: tally.qadhaPaid, color: colorScheme.tertiary.withValues(alpha: .5)),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.onTertiaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary,
                              height: 1,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          unit,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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

/// Menjelaskan kenapa ada slot yang tidak masuk hitungan persentase.
class _UnrecordedNote extends StatelessWidget {
  const _UnrecordedNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Text(
        '$count slot tidak pernah tercatat dan tidak dihitung sebagai hutang. '
        'Konfirmasi di menu Qadha kalau kamu ingat apa yang terjadi.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
