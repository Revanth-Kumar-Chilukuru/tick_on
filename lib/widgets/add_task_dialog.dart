import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  final bool initialIsRoutine;

  const AddTaskDialog({
    super.key,
    this.initialIsRoutine = false,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late bool _isRoutine;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _isRoutine = widget.initialIsRoutine;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isRoutine ? 'Add New Routine' : 'Add New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Routine'),
                      value: _isRoutine,
                      onChanged: (value) {
                        setState(() {
                          _isRoutine = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _reminderTime == null
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: _reminderTime == null
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Set Reminder',
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          _reminderTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addTask,
          child: Text(_isRoutine ? 'Add Routine' : 'Add Task'),
        ),
      ],
    );
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      DateTime? reminder;
      if (_reminderTime != null) {
        final now = DateTime.now();
        reminder = DateTime(
          now.year,
          now.month,
          now.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
        // If the time is in the past, schedule for tomorrow
        if (reminder.isBefore(now)) {
          reminder = reminder.add(const Duration(days: 1));
        }
      }

      final task = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isRoutine: _isRoutine,
        reminderTime: reminder,
      );

      context.read<TaskProvider>().addTask(task);
      Navigator.of(context).pop();
    }
  }
}
