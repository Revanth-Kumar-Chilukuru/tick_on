import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../constants/rage_messages.dart';
import 'routine_stats_sheet.dart';

class TaskCard extends StatefulWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  static int _rapidTapCount = 0;
  static DateTime? _lastTapTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final task = widget.task;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: task.isCompleted ? 0 : 2,
        color: task.isCompleted
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surface,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) => _toggleTask(context, taskProvider),
            activeColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface,
              fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    task.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time, 
                      size: 14, 
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(task.timestamp),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (task.isRoutine) ...[
                      const SizedBox(width: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            'Routine',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: () {
              if (task.isActiveRoutine) {
                _showRoutineDeleteRageDialog(context, taskProvider);
              } else if (task.isCompleted) {
                _showPermanentDeleteDialog(context, taskProvider);
              } else {
                _showRagebaitDialog(context, taskProvider);
              }
            },
          ),
          onTap: () {
            if (task.isActiveRoutine) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RoutineStatsSheet(routine: task),
              );
            } else {
              _toggleTask(context, taskProvider);
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleTask(
    BuildContext context,
    TaskProvider taskProvider,
  ) async {
    final task = widget.task;
    final wasCompleted = task.isCompleted;

    // Easter egg check
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 4000) {
      _rapidTapCount++;
      if (_rapidTapCount >= 4) {
        _rapidTapCount = 0;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Go focus on your work instead of playing with this. - Revanth'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      _rapidTapCount = 1;
    }
    _lastTapTime = now;

    if (wasCompleted) {
      HapticFeedback.selectionClick();
      if (task.isRoutine) {
        await taskProvider.toggleTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Routine moved back to Pending.'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => taskProvider.toggleTask(task.id),
              ),
            ),
          );
        }
      } else {
        _showUntickDialog(context, taskProvider);
      }
      return;
    }

    await taskProvider.toggleTask(task.id);
    HapticFeedback.mediumImpact();
    if (context.mounted) {
      _showRewardDialog(context, taskProvider, task.isActiveRoutine);
    }
  }

  void _showRewardDialog(BuildContext context, TaskProvider taskProvider, bool isRoutine) {
    final assetPath = isRoutine ? 'assets/lottie/routine_reward.json' : 'assets/lottie/reward.json';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Lottie.asset(
            assetPath,
            repeat: false,
          ),
        );
      },
    );
  }

  void _showPermanentDeleteDialog(BuildContext context, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This completed task will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await taskProvider.permanentlyDeleteTask(widget.task.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _showUntickDialog(BuildContext context, TaskProvider taskProvider) {
    final random = Random();
    final reopenMessages = [
      "I thought we had a deal. You said it was done. - Revanth",
      "Un-completing a task? That's a new level of procrastination. - Revanth",
      "So... you lied to me? It wasn't actually finished? - Revanth",
      "You're breaking my heart. Just leave it checked. - Revanth",
      "Tick it, untick it, tick it, untick it. Make up your mind! - Revanth",
      "I was already planning the celebration party. Cancel the confetti. - Revanth",
      "Are you seriously reopening this? - Revanth"
    ];
    final message = reopenMessages[random.nextInt(reopenMessages.length)];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/question.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Nevermind'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              await taskProvider.toggleTask(widget.task.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Reopen Task'),
          ),
        ],
      ),
    );
  }

  void _showRoutineDeleteRageDialog(BuildContext context, TaskProvider taskProvider) {
    final isDoneAtLeastOnce = widget.task.completionDates.isNotEmpty;

    if (!isDoneAtLeastOnce) {
      _showRagebaitDialog(context, taskProvider);
      return;
    }

    final random = Random();
    final dialogues = [
      "Quitting a habit? That's just sad. - Revanth",
      "Building habits is hard. Giving up is easy. - Revanth",
      "I thought you wanted to be better... - Revanth",
    ];
    final message = dialogues[random.nextInt(dialogues.length)];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/disappointed.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("That's what I thought"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await taskProvider.permanentlyDeleteTask(widget.task.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Delete Habit'),
          ),
        ],
      ),
    );
  }

  void _showRagebaitDialog(BuildContext context, TaskProvider taskProvider) {
    final random = Random();
    final message = RageMessages.messages[random.nextInt(RageMessages.messages.length)];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/rage.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel (Coward)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await taskProvider.deleteTask(widget.task.id);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Delete It'),
          ),
        ],
      ),
    );
  }
}
