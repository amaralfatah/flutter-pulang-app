import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_theme.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(historyProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: state.isLoading && state.entries.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.entries.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: AppColors.primary,
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat solat',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai catat solatmu hari ini!',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HistoryEntry entry) {
    final date = DateTime.parse(entry.date);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    final isFull = entry.completedCount == 5;
    final percentage = entry.completedCount / 5;

    // Define prayer names in order
    final prayers = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        // border: Border.all(color: AppColors.divider),
        boxShadow: [AppShadows.light],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detail untuk $formattedDate belum tersedia'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.secondary,
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFull
                                ? '✨ Sempurna! 5 Waktu'
                                : '${5 - entry.completedCount} Terlewat',
                            style: TextStyle(
                              color: _getStatusColor(entry.completedCount),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildProgressCircle(percentage, entry.completedCount),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prayers.map((name) {
                    final isCompleted = entry.completedPrayers.contains(name);
                    return _buildPrayerBadge(context, name, isCompleted);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(double percentage, int count) {
    final color = _getStatusColor(count);
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
              backgroundColor: AppColors.divider,
              color: color,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
    bool isCompleted,
  ) {
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

    return Tooltip(
      message: name[0].toUpperCase() + name.substring(1),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.divider.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isCompleted ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int count) {
    if (count == 5) return AppColors.success;
    if (count >= 3) return AppColors.warning;
    return AppColors.error;
  }
}
