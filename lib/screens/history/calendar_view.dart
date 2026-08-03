import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/extensions/color_scheme_extensions.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/app_snackbar.dart';
import '../../widgets/shared/check_in_bottom_sheet.dart';
import '../../widgets/shared/prayer_card.dart';

/// Tampilan kalender kehadiran solat. Setiap segmen pada cincin mewakili satu
/// waktu solat. Dipakai sebagai salah satu segmen di layar Riwayat, jadi ia
/// tidak membawa Scaffold maupun AppBar sendiri.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  /// Mulai dari mode minggu: grid sebulan penuh setinggi ~350px selalu
  /// mendorong daftar solat hari terpilih ke bawah lipatan, padahal daftar
  /// itulah yang ditap. Grid tetap sekali ketuk lewat handle di bawah.
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _buildCalendar(context, ref, state),
        const SizedBox(height: 12),
        _buildLegend(context),
        const SizedBox(height: 16),
        if (state.selectedDay != null)
          _buildSelectedDayDetail(context, ref, state),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    WidgetRef ref,
    CalendarState state,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: state.focusedDay,
            selectedDayPredicate: (day) => isSameDay(state.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(calendarProvider.notifier).selectDay(selectedDay);
            },
            onPageChanged: (focusedDay) {
              ref.read(calendarProvider.notifier).onPageChanged(focusedDay);
            },
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Minggu',
              CalendarFormat.month: 'Bulan',
            },
            // Hanya swipe horizontal (ganti bulan/minggu). Swipe vertikal
            // dibiarkan lewat ke ListView halaman supaya scroll ke bawah tetap
            // enak — makanya buka/tutup lewat handle, bukan gestur.
            availableGestures: AvailableGestures.horizontalSwipe,
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'id_ID',
            rowHeight: 52,
            daysOfWeekHeight: 40,

            // Header style
            headerStyle: HeaderStyle(
              // Pemicu buka/tutup ditaruh sebagai handle di bawah grid, bukan di
              // header: tombol di sini akan mendesak judul bulan keluar dari
              // tengah dan merusak simetri chevron–judul–chevron.
              formatButtonVisible: false,
              titleCentered: true,
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
              titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).colorScheme.primary, // Header title usually primary
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),

            // Days of week style
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Calendar style - handled by custom builders
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(2),
              defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
              weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
              todayDecoration: const BoxDecoration(shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(shape: BoxShape.circle),
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
              weekendTextStyle: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
              todayTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            // Custom builders for segmented progress ring
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, focusedDay) {
                final dayStatus = state.getPrayerStatus(date);
                return _buildDayCell(
                  context,
                  date,
                  dayStatus,
                  isToday: false,
                  isSelected: false,
                );
              },
              todayBuilder: (context, date, focusedDay) {
                final dayStatus = state.getPrayerStatus(date);
                return _buildDayCell(
                  context,
                  date,
                  dayStatus,
                  isToday: true,
                  isSelected: false,
                );
              },
              selectedBuilder: (context, date, focusedDay) {
                final dayStatus = state.getPrayerStatus(date);
                return _buildDayCell(
                  context,
                  date,
                  dayStatus,
                  isToday: false,
                  isSelected: true,
                );
              },
            ),
          ),
          _buildFormatHandle(context),
        ],
      ),
    );
  }

  void _setFormat(CalendarFormat format) {
    if (_format == format) return;
    setState(() => _format = format);
  }

  /// Handle buka/tutup grid: ketuk, atau seret naik/turun.
  ///
  /// Gestur vertikal sengaja diklaim hanya oleh strip setinggi 32px ini, bukan
  /// oleh `availableGestures` pada kalender. Kalau seluruh grid yang menangkap
  /// drag vertikal, di mode bulan ia menutupi hampir seluruh layar dan tidak
  /// menyisakan permukaan untuk menggulir ke daftar solat di bawahnya.
  Widget _buildFormatHandle(BuildContext context) {
    final isMonth = _format == CalendarFormat.month;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0) {
          _setFormat(CalendarFormat.week);
        } else if (velocity > 0) {
          _setFormat(CalendarFormat.month);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Semantics(
            button: true,
            label: isMonth
                ? 'Kuncupkan ke tampilan minggu'
                : 'Perluas ke tampilan bulan',
            // Target ketuk dibatasi 64px di tengah: InkWell selebar Card akan
            // memercikkan ripple melewati sudut membulatnya.
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _setFormat(
                isMonth ? CalendarFormat.week : CalendarFormat.month,
              ),
              child: SizedBox(
                width: 64,
                height: 32,
                child: AnimatedRotation(
                  turns: isMonth ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Warna pada cincin progres tidak boleh jadi satu-satunya penanda status —
  /// legenda ini memberi label teks agar tetap terbaca oleh yang buta warna.
  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      (colorScheme.statusOnTime, 'Tepat waktu'),
      (colorScheme.statusLate, 'Terlambat'),
      (colorScheme.statusMissed, 'Terlewat'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$1,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  /// Build a single day cell with segmented progress ring
  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    DayPrayerStatus? dayStatus, {
    required bool isToday,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAnyStatus =
        dayStatus != null && dayStatus.statusList.any((s) => s != null);
    final recordedCount =
        dayStatus?.statusList.where((s) => s != null).length ?? 0;

    return Semantics(
      label: hasAnyStatus
          ? '${date.day}, $recordedCount dari 5 solat tercatat'
          : '${date.day}',
      child: Container(
        margin: const EdgeInsets.all(2),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring (5 segments) - tetap tampil walau hari terpilih.
            // Ring 40px dengan stroke 2.5 berakhir di radius 17.5, sedangkan
            // lingkaran isian 30px berhenti di radius 15 -> ada jarak 2.5px.
            if (hasAnyStatus)
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _SegmentedRingPainter(
                    statusList: dayStatus.statusList,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                    strokeWidth: 2.5,
                    colorScheme: Theme.of(
                      context,
                    ).colorScheme, // Pass colorScheme to painter
                  ),
                ),
              ),

            // Background circle for today/selected
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : isToday
                    ? colorScheme.primaryContainer
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : isToday
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(
    BuildContext context,
    WidgetRef ref,
    CalendarState state,
  ) {
    final selectedDay = state.selectedDay!;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDay);
    final prayers = state.selectedDayPrayers;
    // Count all recorded prayers (onTime, late, or missed)
    final totalRecordedCount = prayers.length;
    // Count only completed prayers for progress color — qadha yang sudah
    // dilunasi ikut terhitung tertunaikan, sama seperti di streak.
    final completedCount = prayers.where((p) => p.isFulfilled).length;
    final today = DateTime.now();
    final isPastDay = selectedDay.isBefore(
      DateTime(today.year, today.month, today.day),
    );
    final missing = 5 - totalRecordedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(
                context,
                totalRecordedCount: totalRecordedCount,
                completedCount: completedCount,
              ),
            ],
          ),
        ),

        // Prayer List
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // Hanya untuk hari lampau: hari ini dan masa depan wajar belum
          // lengkap, jadi tidak perlu ajakan konfirmasi.
          if (isPastDay && missing > 0)
            _buildIncompleteBanner(context, ref, selectedDay, missing),
          _buildPrayerList(context, ref, prayers, selectedDay),
        ],
      ],
    );
  }

  /// Ajakan melengkapi hari lampau yang belum tercatat penuh — sengaja
  /// ditempel pada hari yang bersangkutan, bukan didaftar terpisah, supaya
  /// tanggalnya tidak pernah ambigu. Menandai "terlewat" di sini menambah
  /// hutang qadha, jadi konsekuensinya dieja dulu lewat dialog konfirmasi.
  Widget _buildIncompleteBanner(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDay,
    int missing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$missing waktu belum tercatat',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Aplikasi tidak menebak — beri tahu apa yang terjadi, atau isi satu-satu lewat daftar di bawah.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmIncompleteDay(
                      context,
                      ref,
                      selectedDay,
                      missing,
                      PrayerStatus.late,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Solat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmIncompleteDay(
                      context,
                      ref,
                      selectedDay,
                      missing,
                      PrayerStatus.missed,
                    ),
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

  /// Satu ketukan di sini mengubah beberapa slot sekaligus, jadi tanggal dan
  /// akibatnya dieja dulu. Menandai terlewat menambah hutang qadha — itu bukan
  /// hal yang pantas terjadi karena jempol yang meleset.
  Future<void> _confirmIncompleteDay(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDay,
    int missing,
    PrayerStatus status,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(ledgerProvider.notifier);
    final isMissed = status == PrayerStatus.missed;
    final formatted = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDay);
    final dateStr = _formatDateKey(selectedDay);

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

    final ids = await notifier.confirmDay(dateStr, status);
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

  static String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildStatusBadge(
    BuildContext context, {
    required int totalRecordedCount,
    required int completedCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _getProgressColors(
      totalRecordedCount: totalRecordedCount,
      completedCount: completedCount,
      colorScheme: colorScheme,
    );
    final text = _getStatusText(
      totalRecordedCount: totalRecordedCount,
      completedCount: completedCount,
    );
    final icon = completedCount == 5
        ? Icons.check_circle_rounded
        : totalRecordedCount > 0
        ? Icons.circle
        : Icons.radio_button_unchecked;

    // Tonal chip (container + on-container) — matches the badge style on the
    // Statistics screen so the same status reads as the same colour everywhere.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onContainer, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(
    BuildContext context,
    WidgetRef ref,
    List<Prayer> prayers,
    DateTime selectedDay,
  ) {
    final prayerNames = [
      PrayerName.subuh,
      PrayerName.dzuhur,
      PrayerName.ashar,
      PrayerName.maghrib,
      PrayerName.isya,
    ];

    return Column(
      children: prayerNames.map((prayerName) {
        final prayer = prayers
            .where((p) => p.prayerName == prayerName)
            .firstOrNull;

        return PrayerCard(
          prayerName: prayerName,
          status: prayer?.status,
          onTap: () =>
              _handlePrayerTap(context, ref, prayerName, prayer, selectedDay),
        );
      }).toList(),
    );
  }

  Future<void> _handlePrayerTap(
    BuildContext context,
    WidgetRef ref,
    PrayerName prayerName,
    Prayer? existingPrayer,
    DateTime selectedDay,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(selectedDay);

    await CheckInBottomSheet.show(
      context: context,
      prayerName: prayerName,
      currentStatus: existingPrayer?.status,
      subtitle: formattedDate,
      onDelete: existingPrayer?.id == null
          ? null
          : () async {
              await ref
                  .read(calendarProvider.notifier)
                  .deletePrayerForDate(existingPrayer!.id!, selectedDay);
              if (!context.mounted) return;

              messenger.showSnackBar(
                AppSnackBar.info(
                  colorScheme,
                  'Catatan ${prayerName.displayName} $formattedDate dihapus.',
                ),
              );
            },
      onStatusSelected: (status) {
        ref
            .read(calendarProvider.notifier)
            .checkInForDate(
              date: selectedDay,
              prayerName: prayerName,
              status: status,
            );
      },
    );
  }

  /// Tonal (container + on-container) pair for the day-summary badge. Uses the
  /// same MD3 status containers as the Statistics screen, so "Terlewat" reads
  /// as the same red (errorContainer) in both menus.
  ({Color container, Color onContainer}) _getProgressColors({
    required int totalRecordedCount,
    required int completedCount,
    required ColorScheme colorScheme,
  }) {
    if (completedCount == 5) {
      // Selesai (hijau)
      return (
        container: colorScheme.statusOnTimeContainer,
        onContainer: colorScheme.onStatusOnTimeContainer,
      );
    }
    // Progress sebagian -> amber (bukan error). `error`/merah hanya untuk
    // kondisi benar-benar terlewat agar semantik warna M3 tetap benar.
    if (completedCount >= 1) {
      return (
        container: colorScheme.statusLateContainer,
        onContainer: colorScheme.onStatusLateContainer,
      );
    }
    // Tercatat tapi tidak ada yang selesai = semua terlewat.
    if (totalRecordedCount > 0) {
      return (
        container: colorScheme.statusMissedContainer,
        onContainer: colorScheme.onStatusMissedContainer,
      );
    }
    // Belum ada data -> netral.
    return (
      container: colorScheme.surfaceContainerHighest,
      onContainer: colorScheme.onSurfaceVariant,
    );
  }

  String _getStatusText({
    required int totalRecordedCount,
    required int completedCount,
  }) {
    if (completedCount == 5) return '5/5 Sempurna';
    if (totalRecordedCount == 0) return 'Belum ada data';
    return '$totalRecordedCount/5 Tercatat';
  }
}

/// Custom painter for segmented circular progress ring
/// Each segment represents a specific prayer with its status-based color
class _SegmentedRingPainter extends CustomPainter {
  /// Status list in order: [Subuh, Dzuhur, Ashar, Maghrib, Isya]
  final List<PrayerStatus?> statusList;
  final Color backgroundColor;
  final double strokeWidth;
  final ColorScheme colorScheme;

  _SegmentedRingPainter({
    required this.statusList,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 5 segments with 15 degree gaps
    const gapDegrees = 15.0;
    const totalSegments = 5;
    final segmentDegrees =
        (360.0 - (gapDegrees * totalSegments)) / totalSegments;

    // Start from top (-90 degrees in radians)
    const startAngle = -math.pi / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < totalSegments; i++) {
      // Calculate start angle for this segment
      final segmentStart =
          startAngle + (i * (segmentDegrees + gapDegrees)) * (math.pi / 180);
      final sweepAngle = segmentDegrees * (math.pi / 180);

      // Draw background arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segmentStart,
        sweepAngle,
        false,
        backgroundPaint,
      );

      // Get status for this segment
      final status = i < statusList.length ? statusList[i] : null;

      // Only draw colored arc if there's a status
      if (status != null) {
        final statusPaint = Paint()
          ..color = _getStatusColor(status)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          segmentStart,
          sweepAngle,
          false,
          statusPaint,
        );
      }
    }
  }

  /// Get color based on prayer status
  Color _getStatusColor(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.onTime:
        return colorScheme.statusOnTime;
      case PrayerStatus.late:
        return colorScheme.statusLate;
      case PrayerStatus.missed:
        return colorScheme.statusMissed;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    if (oldDelegate.statusList.length != statusList.length) return true;
    for (var i = 0; i < statusList.length; i++) {
      if (oldDelegate.statusList[i] != statusList[i]) return true;
    }
    return oldDelegate.backgroundColor != backgroundColor;
  }
}
