import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/providers.dart';

/// History Screen - Displays list of past prayer consistency
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Solat'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh_rounded),
        //     onPressed: () {
        //       ref.read(historyProvider.notifier).refresh();
        //     },
        //   ),
        // ],
      ),
      body: state.isLoading && state.entries.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : state.entries.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                await ref.read(historyProvider.notifier).refresh();
              },
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                itemCount: state.entries.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.entries.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final entry = state.entries[index];
                  return _buildHistoryItem(context, entry);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat solat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai catat solatmu hari ini!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(entry.date);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    final isFull = entry.completedCount == 5;
    final percentage = entry.completedCount / 5;

    // Define prayer names in order
    final prayers = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showHistoryDetail(context, entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFull
                              ? '✨ Sempurna! 5 Waktu'
                              : '${5 - entry.completedCount} Terlewat',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _getStatusColor(
                                  context,
                                  entry.completedCount,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildProgressCircle(
                    context,
                    percentage,
                    entry.completedCount,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: prayers.map((name) {
                  // Determine status: onTime, late, or missed
                  String status = 'missed';
                  if (entry.onTimePrayers.contains(name)) {
                    status = 'on_time';
                  } else if (entry.latePrayers.contains(name)) {
                    status = 'late';
                  }
                  return _buildPrayerBadge(context, name, status);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
      ),
      builder: (context) => _HistoryDetailSheet(entry: entry),
    );
  }

  Widget _buildProgressCircle(
    BuildContext context,
    double percentage,
    int count,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _getStatusColor(context, count);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: percentage,
              backgroundColor: colorScheme.outlineVariant,
              color: color,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerBadge(
    BuildContext context,
    String name,
    String status, // 'on_time', 'late', or 'missed'
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // Map prayer name to initial letter
    String label = '';
    switch (name) {
      case 'subuh':
        label = 'S';
        break;
      case 'dzuhur':
        label = 'D';
        break;
      case 'ashar':
        label = 'A';
        break;
      case 'maghrib':
        label = 'M';
        break;
      case 'isya':
        label = 'I';
        break;
    }

    // Determine colors based on status
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (status) {
      case 'on_time':
        bgColor = colorScheme.primaryContainer;
        borderColor = colorScheme.primary;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case 'late':
        bgColor = colorScheme.tertiaryContainer;
        borderColor = colorScheme.tertiary;
        textColor = colorScheme.onTertiaryContainer;
        break;
      default: // missed
        bgColor = colorScheme.errorContainer;
        borderColor = colorScheme.error;
        textColor = colorScheme.onErrorContainer;
    }

    return Tooltip(
      message: name[0].toUpperCase() + name.substring(1),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    if (count == 5) return colorScheme.primary; // Success
    if (count >= 3) return colorScheme.tertiary; // Warning (amber)
    return colorScheme.error;
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = DateTime.parse(entry.date);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    final prayers = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Text(
              formattedDate,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              entry.completedCount == 5
                  ? 'Alhamdulillah, solat lengkap!'
                  : '${5 - entry.completedCount} solat terlewat hari ini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Prayer List
            ...prayers.map((name) {
              String status = 'missed';
              if (entry.onTimePrayers.contains(name)) {
                status = 'on_time';
              } else if (entry.latePrayers.contains(name)) {
                status = 'late';
              }

              return _buildDetailRow(context, name, status);
            }),

            const SizedBox(height: 24),

            // Close Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String name, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final prayerName = name[0].toUpperCase() + name.substring(1);

    IconData icon;
    Color color;
    String statusText;
    Color bgColor;

    switch (status) {
      case 'on_time':
        icon = Icons.check_circle_rounded;
        color = colorScheme.primary;
        statusText = 'Tepat Waktu';
        bgColor = colorScheme.primaryContainer;
        break;
      case 'late':
        icon = Icons.warning_rounded;
        color = colorScheme.tertiary;
        statusText = 'Qadha / Terlambat';
        bgColor = colorScheme.tertiaryContainer;
        break;
      default:
        icon = Icons.cancel_rounded;
        color = colorScheme.error;
        statusText = 'Terlewat';
        bgColor = colorScheme.errorContainer;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(_getPrayerIcon(name), color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
    switch (name) {
      case 'subuh':
        return Icons.wb_twilight_rounded;
      case 'dzuhur':
        return Icons.wb_sunny_rounded;
      case 'ashar':
        return Icons.wb_cloudy_rounded;
      case 'maghrib':
        return Icons.nights_stay_rounded;
      case 'isya':
        return Icons.bedtime_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}
