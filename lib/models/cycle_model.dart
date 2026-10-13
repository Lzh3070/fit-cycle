import 'dart:convert';

class CycleDay {
  final String id;
  String title;
  bool isRest;
  String notes;

  CycleDay({
    required this.id,
    required this.title,
    this.isRest = false,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isRest': isRest,
      'notes': notes,
    };
  }

  factory CycleDay.fromMap(Map<String, dynamic> map) {
    return CycleDay(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isRest: map['isRest'] ?? false,
      notes: map['notes'] ?? '',
    );
  }
}

class WorkoutRecord {
  final String date; // YYYY-MM-DD
  final String title;
  final bool isRest;
  final int dayIndex;

  WorkoutRecord({
    required this.date,
    required this.title,
    required this.isRest,
    required this.dayIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'title': title,
      'isRest': isRest,
      'dayIndex': dayIndex,
    };
  }

  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutRecord(
      date: map['date'] ?? '',
      title: map['title'] ?? '',
      isRest: map['isRest'] ?? false,
      dayIndex: map['dayIndex'] ?? 0,
    );
  }
}

class WorkoutCycle {
  String name;
  List<CycleDay> days;
  int currentIndex;
  String? lastCompletedDate; // YYYY-MM-DD
  List<WorkoutRecord> history;
  bool autoAdvance; // 是否次日自动轮转
  String? lastActiveDate; // 上次活跃日期 YYYY-MM-DD

  WorkoutCycle({
    required this.name,
    required this.days,
    this.currentIndex = 0,
    this.lastCompletedDate,
    List<WorkoutRecord>? history,
    this.autoAdvance = true,
    this.lastActiveDate,
  }) : history = history ?? [];

  CycleDay? get currentDay {
    if (days.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= days.length) return days.first;
    return days[currentIndex];
  }

  CycleDay? get nextDay {
    if (days.length <= 1) return currentDay;
    final nextIdx = (currentIndex + 1) % days.length;
    return days[nextIdx];
  }

  bool isTodayCompleted(String todayStr) {
    return lastCompletedDate == todayStr;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'days': days.map((d) => d.toMap()).toList(),
      'currentIndex': currentIndex,
      'lastCompletedDate': lastCompletedDate,
      'history': history.map((h) => h.toMap()).toList(),
      'autoAdvance': autoAdvance,
      'lastActiveDate': lastActiveDate,
    };
  }

  factory WorkoutCycle.fromMap(Map<String, dynamic> map) {
    return WorkoutCycle(
      name: map['name'] ?? '我的训练循环',
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => CycleDay.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      currentIndex: map['currentIndex'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'],
      history: (map['history'] as List<dynamic>?)
              ?.map((h) => WorkoutRecord.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      autoAdvance: map['autoAdvance'] ?? true,
      lastActiveDate: map['lastActiveDate'],
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkoutCycle.fromJson(String source) =>
      WorkoutCycle.fromMap(json.decode(source));
}
