import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class RoutineStatsSheet extends StatelessWidget {
  final Task routine;

  const RoutineStatsSheet({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Basic streak calculation
    int currentStreak = 0;
    if (routine.completionDates.isNotEmpty) {
      final sortedDates = List<DateTime>.from(routine.completionDates)
        ..sort((a, b) => b.compareTo(a));
      
      final now = DateTime.now();
      DateTime lastChecked = DateTime(now.year, now.month, now.day);
      
      for (final date in sortedDates) {
        final d = DateTime(date.year, date.month, date.day);
        if (d.isAtSameMomentAs(lastChecked) || d.isAtSameMomentAs(lastChecked.subtract(const Duration(days: 1)))) {
          if (!d.isAtSameMomentAs(lastChecked) || currentStreak == 0) {
            if (!d.isAtSameMomentAs(lastChecked)) {
              lastChecked = d;
            }
            currentStreak++;
          }
        } else {
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  routine.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    'Routine',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (routine.description != null && routine.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              routine.description!,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                label: 'Started On',
                value: DateFormat('MMM dd, yyyy').format(routine.timestamp),
                icon: Icons.calendar_today,
                theme: theme,
              ),
              _StatCard(
                label: 'Total Days',
                value: '${routine.completionDates.length}',
                icon: Icons.check_circle_outline,
                theme: theme,
              ),
              _StatCard(
                label: 'Streak',
                value: '$currentStreak',
                icon: Icons.local_fire_department,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
