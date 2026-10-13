import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../services/update_service.dart';
import '../utils/app_toast.dart';
import 'cycle_editor_screen.dart';
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

    if (cycle == null || cycle.days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('练啥 · FitCycle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center_outlined, size: 72, color: Color(0xFF38BDF8)),
                const SizedBox(height: 20),
                const Text(
                  '还没有配置训练循环',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  '自由设置你的分化轮转天数与部位，完全由你定义',
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
    final nextDay = cycle.nextDay;
    final isCompleted = provider.isTodayCompleted;
    final formattedDate = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(cycle.name),
        actions: [
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
            // Date Header
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
                    AppToast.info(context, nextVal ? '已开启「次日 0 点自动轮转」' : '已切换为「手动打卡轮转」');
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
                          cycle.autoAdvance ? '次日自动轮转' : '手动打卡推进',
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

            // HERO CARD: Today's Focus (Double-Bezel Architecture)
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '第 ${cycle.currentIndex + 1} / ${cycle.days.length} 天',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted ? const Color(0xFF10B981) : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 14,
                                color: isCompleted ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCompleted ? '今日已练完' : '待完成',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (currentDay.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (currentDay.isRest ? const Color(0xFF818CF8) : const Color(0xFF34D399)).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentDay.isRest
                                ? 'REST & RECOVERY'
                                : (isCompleted ? 'COMPLETED · 今日已练完' : 'TODAY\'S TARGET'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: currentDay.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentDay.isRest
                              ? '恢复休整'
                              : (isCompleted ? '已达成' : '重点强化'),
                          style: TextStyle(
                            fontSize: 12,
                            color: currentDay.isRest ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentDay.title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
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

                    const SizedBox(height: 24),

                    // Action Buttons with Nested Island Architecture
                    if (!isCompleted) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            provider.completeToday();
                            AppToast.success(context, '今日打卡成功！已记录完成');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '完成今日打卡',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            provider.postponeDay();
                            AppToast.warning(context, '已顺延！今天的计划已推迟至明天');
                          },
                          icon: const Icon(Icons.schedule_rounded, color: Color(0xFF94A3B8), size: 18),
                          label: const Text(
                            '顺延一天 (今日未练 · 计划后移)',
                            style: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF334155)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF34D399)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '今日训练已练完，目标达成！',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextDay != null
                                        ? '明日将轮转至：${nextDay.title}（第 ${((cycle.currentIndex + 1) % cycle.days.length) + 1} 天）'
                                        : '已完成今日全部计划',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => provider.undoToday(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('撤销打卡', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Next Day Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '明天轮转预告',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextDay != null ? nextDay.title : '循环结束',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (nextDay?.isRest ?? false)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('休息', style: TextStyle(fontSize: 11, color: Color(0xFFA5B4FC))),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Full Cycle Sequence Track
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '完整循环序列',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '共 ${cycle.days.length} 天一轮',
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
                            isCompleted ? '今日已练完' : '当前',
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
                        const Text(
                          '休息日',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Desktop Widget Instructions Card (Double-Bezel & Step Capsules)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.4)),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.widgets_outlined, color: Color(0xFF38BDF8), size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '桌面 2×1 小组件使用指引',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'WIDGET',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '无需频繁打开应用，在手机桌面即可抬手扫视今日训练目标与循环进度：',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STEP 1', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                                SizedBox(height: 2),
                                Text('长按桌面空白', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STEP 2', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                                SizedBox(height: 2),
                                Text('选择小组件', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.6)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STEP 3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                SizedBox(height: 2),
                                Text('拖放「练啥」', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
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
                '专为健身爱好者打造的滚动分化（Rolling Split）极简看板',
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
