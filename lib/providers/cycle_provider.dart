import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/cycle_model.dart';
import '../services/widget_service.dart';

class CycleProvider extends ChangeNotifier {
  static const String _storageKey = 'workout_cycle_data_v1';

  WorkoutCycle? _cycle;
  bool _isLoading = true;

  WorkoutCycle? get cycle => _cycle;
  bool get isLoading => _isLoading;
  bool get hasCycle => _cycle != null && _cycle!.days.isNotEmpty;

  String get todayDateString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool get isTodayCompleted {
    if (_cycle == null) return false;
    return _cycle!.isTodayCompleted(todayDateString);
  }

  CycleProvider() {
    loadCycle();
  }

  Future<void> loadCycle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _cycle = WorkoutCycle.fromJson(jsonStr);

        // 次日 0 点自动轮转推进处理
        if (_cycle != null && _cycle!.autoAdvance && _cycle!.days.isNotEmpty) {
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);

          if (_cycle!.lastActiveDate != null) {
            try {
              final lastDateParsed = DateFormat('yyyy-MM-dd').parse(_cycle!.lastActiveDate!);
              final lastDateOnly = DateTime(lastDateParsed.year, lastDateParsed.month, lastDateParsed.day);
              final deltaDays = todayDateOnly.difference(lastDateOnly).inDays;

              if (deltaDays > 0) {
                _cycle!.currentIndex = (_cycle!.currentIndex + deltaDays) % _cycle!.days.length;
                _cycle!.lastActiveDate = todayDateString;
                await prefs.setString(_storageKey, _cycle!.toJson());
              }
            } catch (_) {
              _cycle!.lastActiveDate = todayDateString;
              await prefs.setString(_storageKey, _cycle!.toJson());
            }
          } else {
            _cycle!.lastActiveDate = todayDateString;
            await prefs.setString(_storageKey, _cycle!.toJson());
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load cycle: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      WidgetService.updateWidget(_cycle);
    }
  }

  Future<void> saveCycle(WorkoutCycle newCycle) async {
    newCycle.lastActiveDate ??= todayDateString;
    _cycle = newCycle;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, newCycle.toJson());
      await WidgetService.updateWidget(_cycle);
    } catch (e) {
      debugPrint('Failed to save cycle: $e');
    }
  }

  Future<void> toggleAutoAdvance(bool value) async {
    if (_cycle == null) return;
    _cycle!.autoAdvance = value;
    _cycle!.lastActiveDate = todayDateString;
    await saveCycle(_cycle!);
  }

  Future<void> completeToday() async {
    if (_cycle == null || _cycle!.days.isEmpty) return;

    final current = _cycle!.currentDay;
    if (current == null) return;

    final record = WorkoutRecord(
      date: todayDateString,
      title: current.title,
      isRest: current.isRest,
      dayIndex: _cycle!.currentIndex,
    );

    _cycle!.history.insert(0, record);
    _cycle!.lastCompletedDate = todayDateString;
    _cycle!.lastActiveDate = todayDateString;
    _cycle!.currentIndex = (_cycle!.currentIndex + 1) % _cycle!.days.length;

    await saveCycle(_cycle!);
  }

  Future<void> undoToday() async {
    if (_cycle == null || _cycle!.days.isEmpty) return;

    if (_cycle!.history.isNotEmpty && _cycle!.history.first.date == todayDateString) {
      _cycle!.history.removeAt(0);
    }

    _cycle!.lastCompletedDate = null;
    _cycle!.currentIndex = (_cycle!.currentIndex - 1 + _cycle!.days.length) % _cycle!.days.length;

    await saveCycle(_cycle!);
  }

  Future<void> jumpToDay(int index) async {
    if (_cycle == null || index < 0 || index >= _cycle!.days.length) return;
    _cycle!.currentIndex = index;
    _cycle!.lastActiveDate = todayDateString;
    await saveCycle(_cycle!);
  }

  Future<void> postponeDay() async {
    // 顺延一天：不推进索引，仅仅刷新桌面小组件并保留当前训练给明天
    if (_cycle != null) {
      _cycle!.lastActiveDate = todayDateString;
      await saveCycle(_cycle!);
    } else {
      await WidgetService.updateWidget(_cycle);
      notifyListeners();
    }
  }

  Future<void> clearCycle() async {
    _cycle = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await WidgetService.updateWidget(null);
  }
}
