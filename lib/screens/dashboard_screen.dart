import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../services/update_service.dart';
import '../utils/app_toast.dart';
import 'cycle_editor_screen.dart';
import 'cycle_calendar_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.performCheck(context, isManual: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CycleProvider>();
    final cycle = provider.cycle;

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (cycle == null || cycle.days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('练啥 · FitCycle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center_outlined, size: 72, color: Color(0xFF10B981)),
                const SizedBox(height: 16),
                const Text(
                  '未设置训练循环',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  '设定滚动循环，开始记录',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CycleEditorScreen(isInitialSetup: true)),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('开始设置循环', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentDay = cycle.currentDay!;
    final isCompleted = provider.isTodayCompleted;
    final formattedDate = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(cycle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '排期日历',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CycleCalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: '打卡历史',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: '管理训练循环',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CycleEditorScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'update') {
                UpdateService.performCheck(context, isManual: true);
              } else if (val == 'about') {
                _showAboutModal(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'update',
                child: Row(
                  children: [
                    Icon(Icons.system_update_alt_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 10),
                    Text('检查更新', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                    SizedBox(width: 10),
                    Text('关于应用', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadCycle(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Date Header & Auto-Advance Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    final nextVal = !cycle.autoAdvance;
                    provider.toggleAutoAdvance(nextVal);
                    AppToast.info(context, nextVal ? '已开启次日自动轮转' : '已切换为手动打卡推进');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cycle.autoAdvance ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cycle.autoAdvance ? const Color(0xFF10B981) : const Color(0xFF475569),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cycle.autoAdvance ? Icons.autorenew_rounded : Icons.touch_app_outlined,
                          size: 13,
                          color: cycle.autoAdvance ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cycle.autoAdvance ? '自动轮转' : '手动推进',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cycle.autoAdvance ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // HERO CARD: Today's Focus
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: currentDay.isRest
                      ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                      : const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (currentDay.isRest ? const Color(0xFF6366F1) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentDay.isRest
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [const Color(0xFF064E3B).withValues(alpha: 0.9), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentDay.isRest ? const Color(0xFF4338CA) : const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentDay.isRest ? '休息' : 'Day ${cycle.currentIndex + 1}/${cycle.days.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 13, color: Color(0xFF34D399)),
                                SizedBox(width: 4),
                                Text(
                                  '已完成',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      currentDay.title,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF34D399),
                        decorationThickness: 2.5,
                      ),
                    ),

                    if (currentDay.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentDay.notes,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Actions
                    if (!isCompleted)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed: () {
                                provider.completeToday();
                                AppToast.success(context, '今日已打卡');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    '完成打卡',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: () {
                                provider.postponeDay();
                                AppToast.warning(context, '计划已顺延');
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text(
                                '顺延一天',
                                style: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF064E3B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 14, color: Color(0xFF34D399)),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '今日已完成',
                                  style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => provider.undoToday(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('撤销', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Schedule Preview Strip (Replaces redundant standalone next-day card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF38BDF8)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '排期预览',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CycleCalendarScreen()),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '查看日历',
                              style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF38BDF8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final date = DateTime.now().add(Duration(days: i));
                        final isTodayItem = i == 0;
                        final cycleIdx = (cycle.currentIndex + i) % cycle.days.length;
                        final dayPlan = cycle.days[cycleIdx];
                        final isItemRest = dayPlan.isRest;
                        final isItemCompleted = isTodayItem && isCompleted;

                        final weekdayStr = isTodayItem
                            ? '今天'
                            : (i == 1 ? '明天' : DateFormat('E', 'zh_CN').format(date));
                        final dateStr = DateFormat('M/d').format(date);

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CycleCalendarScreen(initialSelectedDate: date),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 86,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isTodayItem
                                  ? (isItemRest ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFF064E3B).withValues(alpha: 0.35))
                                  : const Color(0xFF0F172A).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isTodayItem
                                    ? (isItemRest ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                                    : const Color(0xFF334155).withValues(alpha: 0.6),
                                width: isTodayItem ? 1.4 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      weekdayStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isTodayItem ? FontWeight.bold : FontWeight.w500,
                                        color: isTodayItem ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isItemRest
                                        ? const Color(0xFF312E81)
                                        : const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isItemRest ? '休' : 'Day ${cycleIdx + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isItemRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                                Text(
                                  dayPlan.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isTodayItem ? FontWeight.bold : FontWeight.w500,
                                    color: isTodayItem ? Colors.white : const Color(0xFFCBD5E1),
                                    decoration: isItemCompleted ? TextDecoration.lineThrough : null,
                                    decorationColor: const Color(0xFF34D399),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cycle Sequence Track
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '循环序列',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${cycle.days.length} 天',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...List.generate(cycle.days.length, (index) {
              final day = cycle.days[index];
              final isCurrent = index == cycle.currentIndex;

              return InkWell(
                onTap: () {
                  if (!isCurrent) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: Text('切换到第 ${index + 1} 天？'),
                        content: Text('确认将今日训练切换为「${day.title}」吗？桌面小组件也会同步切换。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                            onPressed: () {
                              provider.jumpToDay(index);
                              Navigator.pop(ctx);
                            },
                            child: const Text('确认切换', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? (day.isRest ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                          : const Color(0xFF334155).withValues(alpha: 0.5),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? (day.isRest ? const Color(0xFF4338CA) : const Color(0xFF10B981))
                              : const Color(0xFF334155),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          day.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF064E3B)
                                : (day.isRest ? const Color(0xFF312E81) : const Color(0xFF064E3B)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isCompleted ? '已完成' : '当前',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF34D399)
                                  : (day.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399)),
                            ),
                          ),
                        )
                      else if (day.isRest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF312E81).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '休',
                            style: TextStyle(fontSize: 10, color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logos/logo_4_dial_plate.png',
                  width: 72,
                  height: 72,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '练啥 · FitCycle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '当前版本 v${UpdateService.currentVersion}',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 8),
              const Text(
                '专为健力打造的滚动分化循环看板',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        UpdateService.performCheck(context, isManual: true);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF38BDF8)),
                      label: const Text('检查更新', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        UpdateService.openExternalUrl(context, 'https://github.com/Lzh3070/fit-cycle');
                      },
                      icon: const Icon(Icons.code_rounded, size: 18, color: Colors.white),
                      label: const Text('GitHub', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
