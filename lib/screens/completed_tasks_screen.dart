import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completedTasks = context.select<TaskProvider, List<Task>>(
      (provider) => provider.completedTasks,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        actions: [
          if (completedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Move completed to Wall of Shame',
              onPressed: () => _confirmClearCompleted(context),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (completedTasks.isEmpty)
            const _EmptyCompletedSliver()
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${completedTasks.length} finished and counted',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: completedTasks[index]);
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  void _confirmClearCompleted(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Completed?'),
        content: const Text('These tasks will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().clearCompletedTasks();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCompletedSliver extends StatelessWidget {
  const _EmptyCompletedSliver();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.secondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing completed yet',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Future wins will stack up here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
