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
class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _buildCalendar(context, ref, state),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TableCalendar(
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
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'id_ID',
          rowHeight: 52,
          daysOfWeekHeight: 40,

          // Header style
          headerStyle: HeaderStyle(
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
            defaultTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            weekendTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            todayTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            selectedTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
            // Progress ring (5 segments) - tetap tampil walau hari terpilih,
            // ring (40px) berada di luar lingkaran isian terpilih (36px).
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
              width: 36,
              height: 36,
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
    // Count only completed prayers (onTime or late) for progress color
    final completedCount = prayers
        .where(
          (p) =>
              p.status == PrayerStatus.onTime || p.status == PrayerStatus.late,
        )
        .length;

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
        else
          _buildPrayerList(context, ref, prayers, selectedDay),
      ],
    );
  }

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
        final status = prayer?.status;

        return PrayerCard(
          prayerName: prayerName,
          status: status,
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
      isOutstandingQadha: existingPrayer?.isOutstandingQadha ?? false,
      onQadhaPaid: () async {
        final paid = await ref
            .read(calendarProvider.notifier)
            .payQadhaForDate(date: selectedDay, prayerName: prayerName);
        if (!paid) return;

        messenger.showSnackBar(
          AppSnackBar.success(
            colorScheme,
            'Qadha ${prayerName.displayName} $formattedDate tercatat lunas.',
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
