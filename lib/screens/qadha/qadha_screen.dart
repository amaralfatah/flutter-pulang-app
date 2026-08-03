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
              if (state.outstandingByDate.isEmpty)
                const _NoDebtCard()
              else ...[
                _TotalCard(ledger: state.ledger),
                const SizedBox(height: 16),
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
///
/// Kartu tonal M3 biasa: warna container dari skema, tipografi langsung dari
/// text theme, tanpa berat huruf atau letter-spacing khusus.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.ledger});

  final PrayerLedger ledger;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final since = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(ledger.startDate!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.statusMissedContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belum diqadha',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onStatusMissedContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${ledger.overall.outstanding}',
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.onStatusMissedContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'solat',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onStatusMissedContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tercatat sejak $since',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onStatusMissedContainer,
              ),
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
    // Satu baris judul: "Sen, 12 Januari 2026". Hari dan tanggal dibaca
    // sekaligus, dan jumlah hutangnya sudah terlihat dari jumlah chip —
    // tidak perlu badge angka yang mengulanginya.
    final title = DateFormat(
      'EEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(_day.date));
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_day.prayers.length > 1)
                  TextButton(
                    onPressed: _paying.isEmpty ? _payAll : null,
                    child: const Text('Lunas semua'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
                      : Icon(prayerIcon(prayer.prayerName), size: 18),
                  label: Text(prayer.prayerName.displayName),
                  onPressed: isPaying ? null : () => _payOne(prayer),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Melunasi satu waktu solat — meminta konfirmasi dulu karena tidak boleh
  /// terjadi hanya karena salah ketuk.
  Future<void> _payOne(Prayer prayer) async {
    final confirmed = await _confirmPay(
      title: 'Tandai lunas?',
      message:
          '${prayer.prayerName.displayName} ${_shortDate(_day.date)} akan '
          'ditandai lunas.',
    );
    if (!confirmed || !mounted) return;

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
        content: Text(
          '${prayer.prayerName.displayName} ${_shortDate(date)} lunas.',
        ),
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
    final prayers = _day.prayers;
    final confirmed = await _confirmPay(
      title: 'Tandai semua lunas?',
      message:
          '${prayers.length} hutang solat ${_shortDate(_day.date)} akan '
          'ditandai lunas sekaligus.',
    );
    if (!confirmed || !mounted) return;

    final date = _day.date;
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

  /// Dialog konfirmasi sebelum aksi lunas dieksekusi.
  Future<bool> _confirmPay({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, lunas'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Ditampilkan saat tidak ada hutang tersisa pada tampilan per tanggal.
class _NoDebtCard extends StatelessWidget {
  const _NoDebtCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 8),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hutang solat',
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
    final count = incompleteDays.length;

    // ListTile di dalam Card: pola baris navigasi standar M3, jadi tidak perlu
    // menyusun ikon/teks/chevron sendiri.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.event_busy_outlined),
        title: Text('$count hari belum tercatat'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showUnconfirmedDaysPicker(context, ref, incompleteDays),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
