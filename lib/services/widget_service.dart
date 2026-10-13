import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/cycle_model.dart';

class WidgetService {
  static const String appWidgetProviderName = 'FitCycleWidgetProvider';

  static Future<void> updateWidget(WorkoutCycle? cycle) async {
    try {
      if (cycle == null || cycle.days.isEmpty) {
        await HomeWidget.saveWidgetData<String>('cycle_title', '练啥 · FitCycle');
        await HomeWidget.saveWidgetData<String>('day_title', '点击打开设置循环');
        await HomeWidget.saveWidgetData<String>('progress_text', '待配置');
        await HomeWidget.saveWidgetData<String>('next_day_text', '下一轮: --');
        await HomeWidget.saveWidgetData<String>('status_text', '点击配置');
        await HomeWidget.saveWidgetData<bool>('is_rest', false);
        await HomeWidget.saveWidgetData<bool>('is_completed', false);
        await HomeWidget.saveWidgetData<bool>('auto_advance', false);
        await HomeWidget.saveWidgetData<int>('cycle_length', 0);
      } else {
        final current = cycle.currentDay;
        final next = cycle.nextDay;
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final isCompleted = cycle.isTodayCompleted(todayStr);

        final cycleName = cycle.name.isNotEmpty ? cycle.name : '我的训练计划';
        final dayTitle = current?.title ?? '未命名';
        final progress = 'Day ${cycle.currentIndex + 1}/${cycle.days.length}';
        final nextTitle = '下轮: ${next?.title ?? "--"}';
        final status = isCompleted ? '今日已完成' : '待打卡';

        final titlesJoined = cycle.days.map((d) => d.title).join(';;;');
        final isRestJoined = cycle.days.map((d) => d.isRest ? '1' : '0').join(';;;');

        await HomeWidget.saveWidgetData<String>('cycle_title', cycleName);
        await HomeWidget.saveWidgetData<String>('day_title', dayTitle);
        await HomeWidget.saveWidgetData<String>('progress_text', progress);
        await HomeWidget.saveWidgetData<String>('next_day_text', nextTitle);
        await HomeWidget.saveWidgetData<String>('status_text', status);
        await HomeWidget.saveWidgetData<bool>('is_rest', current?.isRest ?? false);
        await HomeWidget.saveWidgetData<bool>('is_completed', isCompleted);
        await HomeWidget.saveWidgetData<String>('last_completed_date', cycle.lastCompletedDate ?? '');

        // 存储次日 0 点本地自动计算所需锚点（支持顺延后锚点后移）
        final anchorDate = cycle.lastActiveDate ?? todayStr;
        await HomeWidget.saveWidgetData<bool>('auto_advance', cycle.autoAdvance);
        await HomeWidget.saveWidgetData<String>('anchor_date', anchorDate);
        await HomeWidget.saveWidgetData<int>('anchor_index', cycle.currentIndex);
        await HomeWidget.saveWidgetData<int>('cycle_length', cycle.days.length);
        await HomeWidget.saveWidgetData<String>('days_titles', titlesJoined);
        await HomeWidget.saveWidgetData<String>('days_is_rest', isRestJoined);
      }

      await HomeWidget.updateWidget(name: appWidgetProviderName);
    } catch (e) {
      // Ignore background or initial update errors safely
    }
  }
}
