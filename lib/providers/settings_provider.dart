import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  int _dayStartsAtHour = 0; // 0 = 12:00 AM, 3 = 3:00 AM
  int _weekStartsOnDay = 1; // 1 = Monday, 7 = Sunday (ISO standard)

  int get dayStartsAtHour => _dayStartsAtHour;
  int get weekStartsOnDay => _weekStartsOnDay;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _dayStartsAtHour = _prefs.getInt('day_starts_at_hour') ?? 0;
    _weekStartsOnDay = _prefs.getInt('week_starts_on_day') ?? 1;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setDayStartsAtHour(int hour) async {
    if (hour < 0 || hour > 12) return; // limit to morning
    _dayStartsAtHour = hour;
    await _prefs.setInt('day_starts_at_hour', hour);
    notifyListeners();
  }

  Future<void> setWeekStartsOnDay(int day) async {
    if (day < 1 || day > 7) return;
    _weekStartsOnDay = day;
    await _prefs.setInt('week_starts_on_day', day);
    notifyListeners();
  }
}
