import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/shared/check_in_option.dart';
import '../../widgets/shared/prayer_card.dart';

/// Calendar Screen - Displays prayer attendance in calendar view
/// Each segment in the ring represents individual prayer status
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Solat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              ref.read(calendarProvider.notifier).onPageChanged(DateTime.now());
              ref.read(calendarProvider.notifier).selectDay(DateTime.now());
            },
            tooltip: 'Hari Ini',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          _buildCalendar(context, ref, state),
          const SizedBox(height: 16),
          if (state.selectedDay != null)
            _buildSelectedDayDetail(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    WidgetRef ref,
    CalendarState state,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
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
            color: AppColors.secondary,
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),

        // Days of week style
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: AppColors.textSecondary,
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
          defaultTextStyle: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: AppColors.textPrimary),
          weekendTextStyle: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: AppColors.textPrimary),
          todayTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          selectedTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.white,
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
    final hasAnyStatus =
        dayStatus != null && dayStatus.statusList.any((s) => s != null);

    return Container(
      margin: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (5 segments) - show for unselected days with any status
          if (hasAnyStatus && !isSelected)
            SizedBox(
              width: 40,
              height: 40,
              child: CustomPaint(
                painter: _SegmentedRingPainter(
                  statusList: dayStatus.statusList,
                  backgroundColor: AppColors.divider,
                  strokeWidth: 2.5,
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
                  ? AppColors.primary
                  : isToday
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: (isSelected || isToday)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(completedCount),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Prayer List
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else
          _buildPrayerList(context, ref, prayers, selectedDay),
      ],
    );
  }

  Widget _buildStatusBadge(int count) {
    final color = _getProgressColor(count);
    final text = _getStatusText(count);
    final icon = count == 5
        ? Icons.check_circle_rounded
        : count > 0
        ? Icons.circle
        : Icons.radio_button_unchecked;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
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
    final displayName = _getPrayerDisplayName(prayerName);
    final isEdit = existingPrayer != null;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.bottomSheetRadius),
        ),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Edit $displayName' : 'Catat $displayName',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(selectedDay),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CheckInOption(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              title: 'Tepat Waktu',
              subtitle: 'Solat dilakukan di awal waktu',
              isSelected: existingPrayer?.status == PrayerStatus.onTime,
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(calendarProvider.notifier)
                    .checkInForDate(
                      date: selectedDay,
                      prayerName: prayerName,
                      status: PrayerStatus.onTime,
                    );
              },
            ),
            const SizedBox(height: 12),
            CheckInOption(
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
              title: 'Qadha / Terlambat',
              subtitle: 'Solat dilakukan di luar waktu',
              isSelected: existingPrayer?.status == PrayerStatus.late,
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(calendarProvider.notifier)
                    .checkInForDate(
                      date: selectedDay,
                      prayerName: prayerName,
                      status: PrayerStatus.late,
                    );
              },
            ),
            const SizedBox(height: 12),
            CheckInOption(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              title: 'Terlewat',
              subtitle: 'Tidak solat',
              isSelected: existingPrayer?.status == PrayerStatus.missed,
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(calendarProvider.notifier)
                    .checkInForDate(
                      date: selectedDay,
                      prayerName: prayerName,
                      status: PrayerStatus.missed,
                    );
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(int count) {
    if (count == 5) return AppColors.success;
    if (count >= 3) return AppColors.warning;
    if (count >= 1) return AppColors.error;
    return AppColors.disabled;
  }

  String _getStatusText(int count) {
    if (count == 5) return '5/5 Sempurna';
    if (count == 0) return 'Belum ada data';
    return '$count/5 Tercatat';
  }

  String _getPrayerDisplayName(PrayerName name) {
    switch (name) {
      case PrayerName.subuh:
        return 'Subuh';
      case PrayerName.dzuhur:
        return 'Dzuhur';
      case PrayerName.ashar:
        return 'Ashar';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isya:
        return 'Isya';
    }
  }
}

/// Custom painter for segmented circular progress ring
/// Each segment represents a specific prayer with its status-based color
class _SegmentedRingPainter extends CustomPainter {
  /// Status list in order: [Subuh, Dzuhur, Ashar, Maghrib, Isya]
  final List<PrayerStatus?> statusList;
  final Color backgroundColor;
  final double strokeWidth;

  _SegmentedRingPainter({
    required this.statusList,
    required this.backgroundColor,
    required this.strokeWidth,
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
        return AppColors.success;
      case PrayerStatus.late:
        return AppColors.warning;
      case PrayerStatus.missed:
        return AppColors.error;
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
