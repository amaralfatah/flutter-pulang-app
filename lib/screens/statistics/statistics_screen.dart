import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Statistics Screen - Displays user's prayer consistency and streak
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final weeklyPercentage = ref.watch(weeklyPercentageProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final totalCompleted = ref.watch(totalCompletedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await ref.read(statisticsProvider.notifier).refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          children: [
            if (state.isLoading)
              Center(
                child: LinearProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else if (state.error != null)
              Card(
                margin: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${state.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),

            // Weekly Progress Section
            _buildWeeklyProgressCard(context, weeklyPercentage),
            const SizedBox(height: 16),

            // Streak & Total Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Streak',
                      value: '$currentStreak',
                      unit: 'Hari',
                      icon: Icons.local_fire_department_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Total Solat',
                      value: '$totalCompleted',
                      unit: 'Kali',
                      icon: Icons.check_circle_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary, // Success -> Primary
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Status Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Detail 7 Hari Terakhir',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusDetailCard(context, state.statusCount),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, double percentage) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minggu Ini',
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
                    Icons.pie_chart_rounded,
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
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: colorScheme.outlineVariant,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Konsistensi solat dalam 7 hari terakhir',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // Get appropriate container color based on the passed color
    final containerColor = color == colorScheme.tertiary
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
                              color: color,
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          unit.toLowerCase(),
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
                  const SizedBox(height: 2),
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

  Widget _buildStatusDetailCard(
    BuildContext context,
    Map<String, int> statusCount,
  ) {
    final onTime = statusCount['on_time'] ?? 0;
    final late = statusCount['late'] ?? 0;
    final missed = statusCount['missed'] ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildStatusRow(
            context,
            label: 'Tepat Waktu',
            count: onTime,
            iconColor: colorScheme.primary,
            containerColor: colorScheme.primaryContainer,
            contentColor: colorScheme.onPrimaryContainer,
            icon: Icons.check_circle_rounded,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _buildStatusRow(
            context,
            label: 'Terlambat/Qadha',
            count: late,
            iconColor: colorScheme.tertiary,
            containerColor: colorScheme.tertiaryContainer,
            contentColor: colorScheme.onTertiaryContainer,
            icon: Icons.warning_rounded,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _buildStatusRow(
            context,
            label: 'Terlewat',
            count: missed,
            iconColor: colorScheme.error,
            containerColor: colorScheme.errorContainer,
            contentColor: colorScheme.onErrorContainer,
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required int count,
    required Color iconColor,
    required Color containerColor,
    required Color contentColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            // padding: const EdgeInsets.all(8),
            // decoration: BoxDecoration(
            //   color: containerColor.withOpacity(0.5),
            //   shape: BoxShape.circle,
            // ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: contentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
