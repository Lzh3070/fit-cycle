import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cycle_model.dart';
import '../providers/cycle_provider.dart';
import '../utils/app_toast.dart';

class CalendarDayItem {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isPast;
  final bool isFuture;
  final bool isCompleted;
  final bool isRest;
  final String title;
  final String notes;
  final int? cycleIndex;
  final bool hasRecord;

  CalendarDayItem({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
    required this.isCompleted,
    required this.isRest,
    required this.title,
    this.notes = '',
    this.cycleIndex,
    this.hasRecord = false,
  });
}

class CycleCalendarScreen extends StatefulWidget {
  final DateTime? initialSelectedDate;

  const CycleCalendarScreen({super.key, this.initialSelectedDate});

  @override
  State<CycleCalendarScreen> createState() => _CycleCalendarScreenState();
}

class _CycleCalendarScreenState extends State<CycleCalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    final init = widget.initialSelectedDate ?? now;
    _selectedDate = DateTime(init.year, init.month, init.day);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  CalendarDayItem _computeDayItem(DateTime date, WorkoutCycle? cycle) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(target);

    final isToday = target.isAtSameMomentAs(today);
    final isPast = target.isBefore(today);
    final isFuture = target.isAfter(today);
    final isCurrentMonth = target.month == _displayedMonth.month;

    if (cycle == null || cycle.days.isEmpty) {
      return CalendarDayItem(
        date: target,
        isCurrentMonth: isCurrentMonth,
        isToday: isToday,
        isPast: isPast,
        isFuture: isFuture,
        isCompleted: false,
        isRest: false,
        title: '未配置循环',
      );
    }

    if (isToday) {
      final currentDay = cycle.currentDay;
      final isCompleted = cycle.isTodayCompleted(dateStr);
      return CalendarDayItem(
        date: target,
        isCurrentMonth: isCurrentMonth,
        isToday: true,
        isPast: false,
        isFuture: false,
        isCompleted: isCompleted,
        isRest: currentDay?.isRest ?? false,
        title: currentDay?.title ?? '今日计划',
        notes: currentDay?.notes ?? '',
        cycleIndex: cycle.currentIndex,
        hasRecord: isCompleted,
      );
    }

    if (isPast) {
      // 查找历史打卡记录
      WorkoutRecord? record;
      try {
        record = cycle.history.firstWhere((r) => r.date == dateStr);
      } catch (_) {
        record = null;
      }

      if (record != null) {
        return CalendarDayItem(
          date: target,
          isCurrentMonth: isCurrentMonth,
          isToday: false,
          isPast: true,
          isFuture: false,
          isCompleted: true,
          isRest: record.isRest,
          title: record.title,
          cycleIndex: record.dayIndex,
          hasRecord: true,
        );
      } else {
        return CalendarDayItem(
          date: target,
          isCurrentMonth: isCurrentMonth,
          isToday: false,
          isPast: true,
          isFuture: false,
          isCompleted: false,
          isRest: false,
          title: '未打卡记录',
          hasRecord: false,
        );
      }
    }

    // 未来日期：基于当前循环指针与自然日差推算排期
    final diffDays = target.difference(today).inDays;
    final projectedIndex = (cycle.currentIndex + diffDays) % cycle.days.length;
    final projectedDay = cycle.days[projectedIndex];

    return CalendarDayItem(
      date: target,
      isCurrentMonth: isCurrentMonth,
      isToday: false,
      isPast: false,
      isFuture: true,
      isCompleted: false,
      isRest: projectedDay.isRest,
      title: projectedDay.title,
      notes: projectedDay.notes,
      cycleIndex: projectedIndex,
      hasRecord: false,
    );
  }

  List<CalendarDayItem> _buildMonthGrid(WorkoutCycle? cycle) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    // weekday: 1 = Monday, ..., 7 = Sunday
    final int weekdayOffset = firstDayOfMonth.weekday - 1;
    final startDate = firstDayOfMonth.subtract(Duration(days: weekdayOffset));

    final List<CalendarDayItem> items = [];
    for (int i = 0; i < 42; i++) {
      final date = startDate.add(Duration(days: i));
      items.add(_computeDayItem(date, cycle));
    }

    // 如果最后一行全部是下个月的日期，精简为 35 天网格
    if (items.length == 42 && !items[35].isCurrentMonth) {
      bool allNextMonth = true;
      for (int i = 35; i < 42; i++) {
        if (items[i].isCurrentMonth) {
          allNextMonth = false;
          break;
        }
      }
      if (allNextMonth) {
        return items.sublist(0, 35);
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CycleProvider>();
    final cycle = provider.cycle;
    final gridItems = _buildMonthGrid(cycle);
    final selectedDayInfo = _computeDayItem(_selectedDate, cycle);

    // 计算当月统计数据
    int monthWorkouts = 0;
    int monthRests = 0;
    int monthCompleted = 0;
    for (final item in gridItems) {
      if (item.isCurrentMonth) {
        if (item.isCompleted) monthCompleted++;
        if (item.isRest) {
          monthRests++;
        } else if (item.title != '未打卡记录' && item.title != '未配置循环') {
          monthWorkouts++;
        }
      }
    }

    final monthTitle = DateFormat('yyyy年 M月', 'zh_CN').format(_displayedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('排期日历预览', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _jumpToToday,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: const Color(0xFF34D399),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
              ),
              child: const Text('回到今天', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Month Selector Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                  tooltip: '上一月',
                ),
                Column(
                  children: [
                    Text(
                      monthTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '训练 $monthWorkouts 天',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '休息 $monthRests 天',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        if (monthCompleted > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· 已打卡 $monthCompleted 次',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                  tooltip: '下一月',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Calendar Grid Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.7)),
            ),
            child: Column(
              children: [
                // Weekday Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _WeekdayLabel(text: '一'),
                    _WeekdayLabel(text: '二'),
                    _WeekdayLabel(text: '三'),
                    _WeekdayLabel(text: '四'),
                    _WeekdayLabel(text: '五'),
                    _WeekdayLabel(text: '六'),
                    _WeekdayLabel(text: '日'),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 8),

                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 6,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: gridItems.length,
                  itemBuilder: (context, index) {
                    final item = gridItems[index];
                    final isSelected = item.date.isAtSameMomentAs(_selectedDate);

                    return _CalendarCell(
                      item: item,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedDate = item.date;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Selected Day Detail Card (Double-Bezel Architecture)
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selectedDayInfo.isRest
                    ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (selectedDayInfo.isRest ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                      .withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedDayInfo.isRest
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFF064E3B).withValues(alpha: 0.85), const Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Tags Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: (selectedDayInfo.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399))
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (selectedDayInfo.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          selectedDayInfo.isToday
                              ? 'TODAY · 今日计划'
                              : (selectedDayInfo.isPast
                                  ? (selectedDayInfo.isCompleted ? 'COMPLETED · 已打卡' : 'RECORD · 历史记录')
                                  : 'SCHEDULED · 循环排期'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: selectedDayInfo.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(selectedDayInfo.date),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Title & Rest Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDayInfo.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            decoration: (selectedDayInfo.isToday && selectedDayInfo.isCompleted)
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF34D399),
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selectedDayInfo.isRest
                              ? const Color(0xFF312E81)
                              : const Color(0xFF064E3B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedDayInfo.isRest ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          selectedDayInfo.isRest ? '恢复休整' : '强化训练',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selectedDayInfo.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (selectedDayInfo.cycleIndex != null && cycle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '属于当前循环第 ${(selectedDayInfo.cycleIndex! + 1)} / ${cycle.days.length} 天',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                    ),
                  ],

                  if (selectedDayInfo.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        selectedDayInfo.notes,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0), height: 1.4),
                      ),
                    ),
                  ],

                  // Action or Info Note
                  const SizedBox(height: 14),
                  if (selectedDayInfo.isToday) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedDayInfo.isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedDayInfo.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            size: 16,
                            color: selectedDayInfo.isCompleted ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedDayInfo.isCompleted ? '今日目标已打卡达成' : '今日计划待打卡完成',
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedDayInfo.isCompleted ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (selectedDayInfo.isFuture && selectedDayInfo.cycleIndex != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '系统根据当前滚动循环推算该日安排',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                title: Text('切换循环到「${selectedDayInfo.title}」？'),
                                content: Text('确认将今日计划直接切换到第 ${(selectedDayInfo.cycleIndex! + 1)} 天吗？'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    onPressed: () {
                                      provider.jumpToDay(selectedDayInfo.cycleIndex!);
                                      Navigator.pop(ctx);
                                      AppToast.success(context, '已将今日计划切换为「${selectedDayInfo.title}」');
                                    },
                                    child: const Text('确认切换', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF475569)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('设为今日计划', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
                        ),
                      ],
                    ),
                  ] else if (selectedDayInfo.isPast) ...[
                    Text(
                      selectedDayInfo.isCompleted ? '该日已按计划完成打卡' : '该日未记录打卡',
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedDayInfo.isCompleted ? const Color(0xFF34D399) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final CalendarDayItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color dayNumberColor;
    if (!item.isCurrentMonth) {
      dayNumberColor = const Color(0xFF475569);
    } else if (item.isToday) {
      dayNumberColor = Colors.white;
    } else {
      dayNumberColor = const Color(0xFFCBD5E1);
    }

    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: (item.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399)).withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      );
    } else if (item.isToday) {
      decoration = BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRest ? const Color(0xFF6366F1) : const Color(0xFF10B981),
          width: 1.2,
        ),
      );
    } else {
      decoration = BoxDecoration(
        color: item.isCurrentMonth
            ? const Color(0xFF1E293B).withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      );
    }

    // 微标签文字与颜色
    Widget? statusBadge;
    if (item.isCurrentMonth) {
      if (item.isRest) {
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF312E81).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '休',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFFA5B4FC),
              height: 1.1,
            ),
          ),
        );
      } else if (item.title != '未打卡记录' && item.title != '未配置循环') {
        final shortTitle = item.title.length > 2 ? item.title.substring(0, 2) : item.title;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: item.isCompleted
                ? const Color(0xFF064E3B)
                : const Color(0xFF064E3B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: item.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
              width: 0.6,
            ),
          ),
          child: Text(
            shortTitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: item.isCompleted ? const Color(0xFF34D399) : const Color(0xFF6EE7B7),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: item.isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                    color: dayNumberColor,
                  ),
                ),
                if (item.isToday) ...[
                  const SizedBox(width: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: item.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            if (statusBadge != null)
              statusBadge
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
