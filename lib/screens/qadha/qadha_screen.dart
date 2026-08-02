import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/app_snackbar.dart';
import '../../widgets/shared/prayer_card.dart';

/// Layar Qadha — hutang solat sepanjang riwayat pencatatan.
///
/// Hutang hanya berasal dari solat yang **kamu sendiri** tandai terlewat.
/// Hari yang tidak tercatat sama sekali muncul terpisah sebagai ajakan
/// konfirmasi, bukan langsung dihitung sebagai hutang.
/// Cara mengurutkan hutang.
enum QadhaGrouping { byDate, byPrayer }

class QadhaScreen extends ConsumerStatefulWidget {
  const QadhaScreen({super.key});

  @override
  ConsumerState<QadhaScreen> createState() => _QadhaScreenState();
}

class _QadhaScreenState extends ConsumerState<QadhaScreen> {
  // Default per tanggal: orang mengingat hutangnya sebagai "12 Januari saya
  // bolong Subuh dan Isya", bukan sebagai "saya punya 2 hutang Subuh".
  QadhaGrouping _grouping = QadhaGrouping.byDate;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final byDate = _grouping == QadhaGrouping.byDate;
    // Fixed 56px overflows once system font scale grows the segmented
    // button's label text (Dynamic Type / large accessibility text sizes).
    final segmentedHeight = 56 * MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qadha'),
        bottom: state.hasData
            ? PreferredSize(
                preferredSize: Size.fromHeight(segmentedHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SegmentedButton<QadhaGrouping>(
                    segments: const [
                      ButtonSegment(
                        value: QadhaGrouping.byDate,
                        icon: Icon(Icons.event_rounded),
                        label: Text('Per Tanggal'),
                      ),
                      ButtonSegment(
                        value: QadhaGrouping.byPrayer,
                        icon: Icon(Icons.access_time_rounded),
                        label: Text('Per Waktu'),
                      ),
                    ],
                    selected: {_grouping},
                    onSelectionChanged: (s) =>
                        setState(() => _grouping = s.first),
                  ),
                ),
              )
            : null,
      ),
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
              if (byDate) ...[
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
                  // pilihan yang belum tersimpan berpindah ke hari yang salah.
                  ...state.outstandingByDate.map(
                    (day) => _QadhaDayCard(key: ValueKey(day.date), day: day),
                  ),
                ],
              ] else ...[
                _SectionHeader(
                  title: 'Rincian per Waktu',
                  subtitle: state.ledger.outstandingQadha > 0
                      ? 'Untuk melunasi banyak sekaligus pada satu waktu solat.'
                      : 'Tidak ada hutang yang tersisa.',
                ),
                ...PrayerName.values.map(
                  (name) => _QadhaRow(
                    prayerName: name,
                    tally: state.ledger.tallyFor(name),
                  ),
                ),
              ],
              if (state.recentlyPaid.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Baru Saja Diqadha',
                  subtitle:
                      'Setiap pembayaran tercatat di sini dan bisa dibatalkan '
                      'kapan saja — tidak perlu buru-buru menekan "urungkan".',
                ),
                ...state.recentlyPaid.map((p) => _PaidQadhaTile(prayer: p)),
              ],
              if (state.incompleteDays.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Perlu Dikonfirmasi',
                  subtitle:
                      '${state.incompleteDays.length} hari tidak tercatat. '
                      'Aplikasi tidak menebak — beri tahu apa yang terjadi.',
                ),
                ...state.incompleteDays
                    .take(_visibleConfirmationDays)
                    .map((day) => _ConfirmDayCard(day: day)),
                if (state.incompleteDays.length > _visibleConfirmationDays)
                  _RemainingHint(
                    hidden:
                        state.incompleteDays.length - _visibleConfirmationDays,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Hari yang ditawarkan sekaligus. Daftar panjang membuat layar ini terasa
  /// seperti tagihan, bukan alat bantu — sisanya menyusul setelah dibereskan.
  static const _visibleConfirmationDays = 7;
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
              overall.qadhaPaid > 0
                  ? 'Sejak $since. Sudah kamu qadha: ${overall.qadhaPaid} solat.'
                  : 'Dihitung sejak catatan pertamamu, $since.',
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
/// Mengetuk sebuah waktu solat **tidak menyimpan apa pun** — ia hanya menandai
/// pilihan. Data baru berubah setelah tombol simpan ditekan, dan tombol itu
/// menyebutkan berapa yang akan dilunasi.
///
/// Ini disengaja: catatan solat terlalu sensitif untuk dipertaruhkan pada
/// ketukan tunggal. Snackbar "urungkan" tidak cukup, karena ia menuntut user
/// menyadari kesalahannya dalam hitungan detik — padahal justru salah ketuk
/// yang tidak disadari itulah masalahnya. Dengan memilih dulu, salah ketuk
/// tidak berbiaya: batalkan pilihannya, tidak ada yang pernah tertulis.
class _QadhaDayCard extends ConsumerStatefulWidget {
  const _QadhaDayCard({super.key, required this.day});

  final QadhaDay day;

  @override
  ConsumerState<_QadhaDayCard> createState() => _QadhaDayCardState();
}

class _QadhaDayCardState extends ConsumerState<_QadhaDayCard> {
  /// Id baris yang sedang dipilih — masih di memori, belum tersimpan.
  final Set<int> _selected = {};

  /// Mencegah double-tap pada tombol simpan memicu dua kali penyimpanan
  /// sementara permintaan pertama masih berjalan.
  bool _isSaving = false;

  QadhaDay get _day => widget.day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsed = DateTime.parse(_day.date);
    final weekday = DateFormat('EEEE', 'id_ID').format(parsed);
    final formatted = DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
    final hasSelection = _selected.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Kartu yang punya pilihan tertunda diberi garis tepi supaya jelas ada
      // sesuatu yang menunggu diselesaikan di sini.
      shape: hasSelection
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary, width: 2),
            )
          : null,
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
                final isSelected = _selected.contains(id);
                return FilterChip(
                  avatar: isSelected
                      ? null
                      : Icon(
                          prayerIcon(prayer.prayerName),
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  label: Text(prayer.prayerName.displayName),
                  selected: isSelected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  }),
                );
              }).toList(),
            ),
            if (hasSelection) ...[
              const SizedBox(height: 16),
              Text(
                'Belum tersimpan. Periksa dulu pilihanmu.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(_selected.clear),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Tandai ${_selected.length} lunas'),
                    ),
                  ),
                ],
              ),
            ] else if (_day.prayers.length > 1) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(
                    () => _selected.addAll(_day.prayers.map((p) => p.id!)),
                  ),
                  child: const Text('Pilih semua'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);
    final chosen = _day.prayers.where((p) => _selected.contains(p.id!));

    final ids = <int>[];
    for (final prayer in chosen) {
      final paid = await notifier.payQadhaFor(_day.date, prayer.prayerName);
      if (paid != null) ids.add(paid.id!);
    }

    if (mounted) setState(() => _isSaving = false);
    if (ids.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} qadha ${_shortDate(_day.date)} lunas.'),
        // Lihat catatan di home_screen: tanpa ini snackbar tidak hilang sendiri.
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

/// Satu baris waktu solat: sisa hutang + tombol bayar.
class _QadhaRow extends ConsumerWidget {
  const _QadhaRow({required this.prayerName, required this.tally});

  final PrayerName prayerName;
  final PrayerTally tally;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDebt = tally.outstanding > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Icon(prayerIcon(prayerName), color: colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDebt
                        ? '${tally.outstanding} belum dibayar'
                        : 'Lunas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasDebt
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                      fontWeight: hasDebt ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDebt)
              FilledButton.tonal(
                onPressed: () => _pay(context, ref),
                child: const Text('Bayar'),
              )
            else if (tally.qadhaPaid > 0)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  /// Mencatat qadha itu keputusan, bukan penghitung yang boleh ditekan cepat.
  /// Jadi tanggal hutang yang akan dilunasi ditunjukkan lebih dulu — user tahu
  /// persis apa yang berubah sebelum menyetujuinya. Jumlahnya bisa disetel di
  /// lembar yang sama supaya melunasi banyak sekaligus tetap satu keputusan.
  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);

    final queue = await notifier.peekOutstandingQadha(prayerName);
    if (!context.mounted) return;
    if (queue.isEmpty) {
      messenger.showSnackBar(
        AppSnackBar.info(
          colorScheme,
          'Tidak ada hutang ${prayerName.displayName}.',
        ),
      );
      return;
    }

    final count = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _PayConfirmSheet(prayerName: prayerName, queue: queue),
    );
    if (count == null || count < 1) return;

    final paid = await notifier.payQadha(prayerName, count: count);
    if (paid.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          paid.length == 1
              ? '${prayerName.displayName} ${_shortDate(paid.first.date)} tercatat lunas.'
              : '${paid.length} qadha ${prayerName.displayName} tercatat lunas.',
        ),
        // Lihat catatan di home_screen: tanpa ini snackbar tidak hilang sendiri.
        persist: false,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () =>
              notifier.undoPayQadha(paid.map((p) => p.id!).toList()),
        ),
      ),
    );
  }
}

/// Lembar konfirmasi pembayaran: menyebut tanggal hutangnya dengan jelas dan
/// membiarkan user menentukan berapa banyak yang dilunasi sekali jalan.
class _PayConfirmSheet extends StatefulWidget {
  const _PayConfirmSheet({required this.prayerName, required this.queue});

  final PrayerName prayerName;

  /// Hutang yang mengantre, tertua dulu.
  final List<Prayer> queue;

  @override
  State<_PayConfirmSheet> createState() => _PayConfirmSheetState();
}

class _PayConfirmSheetState extends State<_PayConfirmSheet> {
  int _count = 1;

  int get _max => widget.queue.length;

  /// Tanggal-tanggal yang akan tersentuh oleh pilihan saat ini.
  List<Prayer> get _selected => widget.queue.take(_count).toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = widget.prayerName.displayName;
    final remaining = _max - _count;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  prayerIcon(widget.prayerName),
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Qadha $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Berapa qadha $name yang sudah kamu kerjakan?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _CountStepper(
              value: _count,
              max: _max,
              onChanged: (value) => setState(() => _count = value),
            ),
            const SizedBox(height: 20),
            Text(
              _count == 1
                  ? 'Tanggal yang akan ditandai lunas:'
                  : 'Tanggal yang akan ditandai lunas ($_count tertua):',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            // Daftarnya ditampilkan utuh, bukan diringkas jadi rentang: user
            // harus bisa memastikan tanggal mana persisnya yang berubah.
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: _selected
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(DateTime.parse(p.date)),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              remaining > 0
                  ? 'Sisa hutang $name setelah ini: $remaining.'
                  : 'Setelah ini hutang $name lunas semua.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _count),
                    child: Text(
                      _count == 1 ? 'Tandai Lunas' : 'Tandai $_count Lunas',
                    ),
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

/// Pemilih jumlah dengan tombol tambah/kurang.
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
          tooltip: 'Kurangi',
        ),
        Expanded(
          child: Center(
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Tambah',
        ),
        if (max > 1) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: value == max ? null : () => onChanged(max),
            child: const Text('Semua'),
          ),
        ],
      ],
    );
  }
}

/// Satu pembayaran qadha yang sudah tercatat, lengkap dengan tombol batal.
class _PaidQadhaTile extends ConsumerWidget {
  const _PaidQadhaTile({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${prayer.prayerName.displayName} · ${_shortDate(prayer.date)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Diqadha ${_paidWhen(prayer.qadhaPaidAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(ledgerProvider.notifier).undoPayQadha([prayer.id!]),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  String _paidWhen(String? isoTimestamp) {
    if (isoTimestamp == null) return '-';
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(parsed);
  }
}

String _shortDate(String date) =>
    DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(date));

/// Kartu untuk satu hari yang catatannya belum lengkap.
class _ConfirmDayCard extends ConsumerWidget {
  const _ConfirmDayCard({required this.day});

  final IncompleteDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final missing = 5 - day.recorded;
    final formatted = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(day.date));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatted,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$missing waktu belum tercatat',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirm(context, ref, PrayerStatus.late),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Solat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _confirm(context, ref, PrayerStatus.missed),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Terlewat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Satu ketukan di sini mengubah lima slot sekaligus, jadi tanggal dan
  /// akibatnya dieja dulu. Menandai terlewat menambah hutang qadha — itu bukan
  /// hal yang pantas terjadi karena jempol yang meleset.
  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    PrayerStatus status,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);
    final missing = 5 - day.recorded;
    final isMissed = status == PrayerStatus.missed;
    final formatted = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(day.date));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isMissed ? 'Tandai Terlewat?' : 'Tandai Sudah Solat?'),
        content: Text(
          isMissed
              ? '$missing waktu pada $formatted akan dicatat terlewat dan '
                    'menambah hutang qadha sebanyak $missing.'
              : '$missing waktu pada $formatted akan dicatat sudah dikerjakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isMissed
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            child: Text(isMissed ? 'Ya, terlewat' : 'Ya, sudah'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ids = await notifier.confirmDay(day.date, status);
    if (ids.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isMissed
              ? '$formatted dicatat terlewat.'
              : '$formatted dicatat sudah dikerjakan.',
        ),
        // Lihat catatan di home_screen: tanpa ini snackbar tidak hilang sendiri.
        persist: false,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => notifier.undoConfirmDay(ids),
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

class _RemainingHint extends StatelessWidget {
  const _RemainingHint({required this.hidden});

  final int hidden;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        'Masih ada $hidden hari lagi. Beres dulu yang di atas, sisanya muncul menyusul.',
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
