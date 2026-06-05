import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_card.dart';
import 'completed_tasks_screen.dart';
import 'deleted_tasks_screen.dart';
import 'settings_screen.dart';
// import 'routines_screen.dart'; // No longer needed as separate screen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasDeletedTasks = context.watch<TaskProvider>().deletedTasks.isNotEmpty;

    final screens = [
      const _HomeTab(),
      const CompletedTasksScreen(),
      if (hasDeletedTasks) const DeletedTasksScreen(),
    ];

    // If we're on the Shame tab and it gets hidden, fallback to Home
    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: screens[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
          if (hasDeletedTasks)
            const NavigationDestination(
              icon: Icon(Icons.delete_sweep_outlined),
              selectedIcon: Icon(Icons.delete_sweep),
              label: 'Shame',
            ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final pendingTasks = context.select<TaskProvider, List<Task>>(
      (provider) => provider.pendingTasks,
    );
    final routineTasks = context.select<TaskProvider, List<Task>>(
      (provider) => provider.routineTasks,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TickOn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: themeProvider.toggleTheme,
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.pending_actions,
              title: 'Pending Tasks',
            ),
          ),
          if (pendingTasks.isEmpty)
            const _EmptyTaskSliver(
              icon: Icons.task_alt,
              title: 'All caught up!',
              subtitle: 'Enjoy your free time, or add a new task.',
            )
          else
            SliverList.builder(
              itemCount: pendingTasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: pendingTasks[index]);
              },
            ),

          const SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.repeat,
              title: 'Routines',
            ),
          ),
          if (routineTasks.isEmpty)
            const _EmptyTaskSliver(
              icon: Icons.all_inclusive,
              title: 'No active routines',
              subtitle: 'Add daily tasks you want to repeat.',
              isSmall: true,
            )
          else
            SliverList.builder(
              itemCount: routineTasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: routineTasks[index]);
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTaskDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptyTaskSliver extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSmall;

  const _EmptyTaskSliver({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = isSmall ? 16.0 : 32.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSmall ? 48 : 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: isSmall 
                ? theme.textTheme.titleMedium
                : theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
