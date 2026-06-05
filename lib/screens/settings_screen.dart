import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Routines & Tracking',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text('Day Starts At'),
            subtitle: const Text('For night owls. Routines won\'t reset until this time.'),
            trailing: DropdownButton<int>(
              value: settingsProvider.dayStartsAtHour,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setDayStartsAtHour(value);
                }
              },
              items: List.generate(7, (index) {
                final hour = index; // 0 to 6 (12 AM to 6 AM)
                final timeString = hour == 0 ? '12:00 AM' : '$hour:00 AM';
                return DropdownMenuItem(
                  value: hour,
                  child: Text(timeString),
                );
              }),
            ),
          ),
          ListTile(
            title: const Text('Week Starts On'),
            subtitle: const Text('Used for future statistics and calendar views.'),
            trailing: DropdownButton<int>(
              value: settingsProvider.weekStartsOnDay,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setWeekStartsOnDay(value);
                }
              },
              items: const [
                DropdownMenuItem(value: 1, child: Text('Monday')),
                DropdownMenuItem(value: 7, child: Text('Sunday')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
