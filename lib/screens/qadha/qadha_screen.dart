import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/prayer_card.dart';
import '../../widgets/shared/unconfirmed_days_sheet.dart';

/// Layar Qadha — murni soal hutang solat sepanjang riwayat pencatatan.
///
/// Hutang hanya berasal dari solat yang **kamu sendiri** tandai terlewat.
/// Hari yang tidak tercatat sama sekali bukan urusan layar ini — itu
/// dikonfirmasi di Kalender, pada hari yang bersangkutan, supaya tanggalnya
/// tidak pernah ambigu. Di sini hanya ada tautan ringkas ke sana.
///
/// Selalu dikelompokkan per tanggal: orang mengingat hutangnya sebagai
/// "12 Januari saya bolong Subuh dan Isya", bukan sebagai "saya punya 2
/// hutang Subuh".
class QadhaScreen extends ConsumerStatefulWidget {
  const QadhaScreen({super.key});

  @override
  ConsumerState<QadhaScreen> createState() => _QadhaScreenState();
}

class _QadhaScreenState extends ConsumerState<QadhaScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Qadha')),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () => ref.read(ledgerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            if (state.isLoading && !state.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              )
            else if (state.error != null)
              _ErrorCard(message: state.error!)
            else if (!state.hasData)
              const _EmptyState()
            else ...[
              _TotalCard(ledger: state.ledger),
              const SizedBox(height: 24),
              if (state.outstandingByDate.isEmpty)
                const _NoDebtCard()
              else ...[
                const _SectionHeader(
                  title: 'Hutang per Tanggal',
                  subtitle:
                      'Ketuk waktu solat yang sudah kamu qadha. Tanggalnya '
                      'terlihat jelas, dan bisa dibatalkan kapan saja.',
                ),
                // Key per tanggal: tanpa ini Flutter bisa memakai ulang state
                // sebuah kartu untuk tanggal lain saat daftar menyusut, dan
                // id yang sedang diproses (_paying) berpindah ke hari yang salah.
                ...state.outstandingByDate.map(
                  (day) => _QadhaDayCard(key: ValueKey(day.date), day: day),
                ),
              ],
              if (state.incompleteDays.isNotEmpty) ...[
                const SizedBox(height: 24),
                _UnconfirmedDaysRow(incompleteDays: state.incompleteDays),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ringkasan hutang keseluruhan.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.ledger});

  final PrayerLedger ledger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overall = ledger.overall;
    final outstanding = overall.outstanding;
    final isClear = outstanding == 0;

    final container = isClear
        ? colorScheme.statusOnTimeContainer
        : colorScheme.statusMissedContainer;
    final onContainer = isClear
        ? colorScheme.onStatusOnTimeContainer
        : colorScheme.onStatusMissedContainer;

    final since = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(ledger.startDate!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: container,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isClear
                      ? Icons.verified_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: onContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isClear ? 'Tidak ada hutang' : 'Hutang Solat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$outstanding',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: onContainer,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'solat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: onContainer),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dihitung sejak catatan pertamamu, $since.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: onContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu tanggal dengan hutang yang menempel padanya.
///
/// Mengetuk sebuah waktu solat langsung melunasinya — sama seperti mengetuk
/// solat di Home langsung mencatatnya. Salah ketuk tidak berbahaya: snackbar
/// "urungkan" muncul seketika, dan pelunasan yang sudah lewat snackbar pun
/// tetap bisa dibatalkan dari daftar "Baru Saja Diqadha" di bawah.
class _QadhaDayCard extends ConsumerStatefulWidget {
  const _QadhaDayCard({super.key, required this.day});

  final QadhaDay day;

  @override
  ConsumerState<_QadhaDayCard> createState() => _QadhaDayCardState();
}

class _QadhaDayCardState extends ConsumerState<_QadhaDayCard> {
  /// Id baris yang sedang diproses — dikunci sementara supaya tap ganda tidak
  /// memicu dua kali pelunasan sebelum permintaan pertama selesai.
  final Set<int> _paying = {};

  QadhaDay get _day => widget.day;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.parse(_day.date);
    final weekday = DateFormat('EEEE', 'id_ID').format(parsed);
    final formatted = DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatted,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        weekday,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.statusMissedContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_day.prayers.length} hutang',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onStatusMissedContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _day.prayers.map((prayer) {
                final id = prayer.id!;
                final isPaying = _paying.contains(id);
                return ActionChip(
                  avatar: isPaying
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          prayerIcon(prayer.prayerName),
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  label: Text(prayer.prayerName.displayName),
                  onPressed: isPaying ? null : () => _payOne(prayer),
                );
              }).toList(),
            ),
            if (_day.prayers.length > 1) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _paying.isEmpty ? _payAll : null,
                  child: const Text('Tandai semua lunas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Melunasi satu waktu solat — dipanggil langsung saat chip-nya diketuk.
  Future<void> _payOne(Prayer prayer) async {
    final id = prayer.id!;
    final date = _day.date;
    setState(() => _paying.add(id));
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);

    final paid = await notifier.payQadhaFor(date, prayer.prayerName);

    if (mounted) setState(() => _paying.remove(id));
    if (paid == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('${prayer.prayerName.displayName} ${_shortDate(date)} lunas.'),
        // Lihat catatan di home_screen: tanpa ini snackbar tidak hilang sendiri.
        persist: false,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => notifier.undoPayQadha([paid.id!]),
        ),
      ),
    );
  }

  /// Melunasi seluruh hutang hari ini sekaligus, satu snackbar untuk semua.
  Future<void> _payAll() async {
    final date = _day.date;
    final prayers = _day.prayers;
    setState(() => _paying.addAll(prayers.map((p) => p.id!)));
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);

    final ids = <int>[];
    for (final prayer in prayers) {
      final paid = await notifier.payQadhaFor(date, prayer.prayerName);
      if (paid != null) ids.add(paid.id!);
      if (mounted) setState(() => _paying.remove(prayer.id!));
    }

    if (ids.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} qadha ${_shortDate(date)} lunas.'),
        persist: false,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => notifier.undoPayQadha(ids),
        ),
      ),
    );
  }
}

/// Ditampilkan saat tidak ada hutang tersisa pada tampilan per tanggal.
class _NoDebtCard extends StatelessWidget {
  const _NoDebtCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hutang tersisa',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _shortDate(String date) =>
    DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(date));

/// Tautan ringkas ke hari-hari yang belum tercatat — bukan urusan Qadha.
///
/// Konfirmasinya (sudah solat / terlewat) dilakukan di Kalender, tepat pada
/// hari yang bersangkutan, supaya tanggalnya tidak pernah ambigu. Menekan
/// baris ini membuka daftar tanggalnya; memilih satu langsung melompat ke
/// hari itu di Kalender — tidak perlu menyelesaikan yang tertua dulu, dan
/// tidak perlu scroll kalender bulan demi bulan untuk menemukannya.
class _UnconfirmedDaysRow extends ConsumerWidget {
  const _UnconfirmedDaysRow({required this.incompleteDays});

  final List<IncompleteDay> incompleteDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = incompleteDays.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showUnconfirmedDaysPicker(context, ref, incompleteDays),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 hari belum tercatat'
                      : '$count hari belum tercatat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
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
          'Gagal memuat data qadha: $message',
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada catatan',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai catat solatmu di Home. Hutang qadha dihitung sejak catatan '
            'pertama, dan hanya dari solat yang kamu tandai terlewat.',
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
