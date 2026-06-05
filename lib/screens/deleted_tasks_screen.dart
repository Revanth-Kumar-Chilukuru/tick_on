import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class DeletedTasksScreen extends StatelessWidget {
  const DeletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deletedTasks = context.select<TaskProvider, List<Task>>(
      (provider) => provider.deletedTasks,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wall of Shame'),
      ),
      body: CustomScrollView(
        slivers: [
          if (deletedTasks.isEmpty)
            const _EmptyDeletedSliver()
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${deletedTasks.length} task${deletedTasks.length == 1 ? '' : 's'} awaiting redemption',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: deletedTasks.length,
              itemBuilder: (context, index) {
                return _DeletedTaskCard(task: deletedTasks[index]);
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
      floatingActionButton: deletedTasks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _confirmEmptyWall(context),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Empty Wall'),
            )
          : null,
    );
  }

  void _confirmEmptyWall(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Wall of Shame?'),
        content: const Text('This permanently removes every deleted task.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().clearDeletedTasks();
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}

class _DeletedTaskCard extends StatelessWidget {
  final Task task;

  const _DeletedTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<TaskProvider>();
    final deletedAt = task.deletedAt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: theme.colorScheme.error,
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(task.description!),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                deletedAt == null
                    ? 'Deleted sometime in the fog'
                    : 'Deleted ${DateFormat('MMM dd, yyyy | HH:mm').format(deletedAt)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore task',
              onPressed: () => provider.restoreTask(task.id),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_forever_outlined,
                color: theme.colorScheme.error,
              ),
              tooltip: 'Delete forever',
              onPressed: () => provider.permanentlyDeleteTask(task.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDeletedSliver extends StatelessWidget {
  const _EmptyDeletedSliver();

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
                Icons.delete_sweep_outlined,
                size: 80,
                color: theme.colorScheme.error.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                'The wall is clean',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'No deleted tasks are haunting this place.',
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
