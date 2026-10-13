package com.fitcycle.fit_cycle

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class FitCycleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val todayStr = dateFormat.format(Date())

        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val cycleTitle = widgetData.getString("cycle_title", "练啥 · FitCycle") ?: "练啥 · FitCycle"
                var dayTitle = widgetData.getString("day_title", "点击打开设置训练循环") ?: "点击打开设置训练循环"
                var progressText = widgetData.getString("progress_text", "待配置") ?: "待配置"
                var nextDayText = widgetData.getString("next_day_text", "下一轮: --") ?: "下一轮: --"
                var statusText = widgetData.getString("status_text", "今日待打卡") ?: "今日待打卡"
                var isRest = widgetData.getBoolean("is_rest", false)
                var isCompleted = widgetData.getBoolean("is_completed", false)

                val autoAdvance = widgetData.getBoolean("auto_advance", true)
                val anchorDateStr = widgetData.getString("anchor_date", null)
                val anchorIndex = widgetData.getInt("anchor_index", 0)
                val cycleLength = widgetData.getInt("cycle_length", 0)
                val daysTitles = widgetData.getString("days_titles", null)
                val daysIsRest = widgetData.getString("days_is_rest", null)

                // 次日 0 点本地自动计算滚动推进（无需唤醒应用）
                if (autoAdvance && anchorDateStr != null && cycleLength > 0 && daysTitles != null) {
                    try {
                        val anchorDate = dateFormat.parse(anchorDateStr)
                        val todayDate = dateFormat.parse(todayStr)
                        if (anchorDate != null && todayDate != null) {
                            val diffMillis = todayDate.time - anchorDate.time
                            val diffDays = TimeUnit.DAYS.convert(diffMillis, TimeUnit.MILLISECONDS).toInt()
                            if (diffDays > 0) {
                                val titlesList = daysTitles.split(";;;")
                                val isRestList = daysIsRest?.split(";;;") ?: emptyList()
                                val curIdx = (anchorIndex + diffDays) % cycleLength
                                val nextIdx = (curIdx + 1) % cycleLength

                                if (curIdx in titlesList.indices) {
                                    dayTitle = titlesList[curIdx]
                                    progressText = "Day ${curIdx + 1}/$cycleLength"
                                    isRest = if (curIdx in isRestList.indices) isRestList[curIdx] == "1" else false
                                    isCompleted = false
                                    statusText = "今日待打卡"
                                }
                                if (nextIdx in titlesList.indices) {
                                    nextDayText = "下轮: ${titlesList[nextIdx]}"
                                }
                            }
                        }
                    } catch (_: Exception) {
                    }
                }

                setTextViewText(R.id.widget_cycle_name, cycleTitle)
                setTextViewText(R.id.widget_day_title, dayTitle)
                setTextViewText(R.id.widget_progress, progressText)
                setTextViewText(R.id.widget_next_day, nextDayText)
                setTextViewText(R.id.widget_status, statusText)

                if (isRest) {
                    setTextViewText(R.id.widget_day_label, "恢复休整")
                    setInt(R.id.widget_progress, "setBackgroundResource", R.drawable.widget_rest_badge_bg)
                    setTextColor(R.id.widget_progress, android.graphics.Color.parseColor("#A5B4FC"))
                } else {
                    setTextViewText(R.id.widget_day_label, "今日训练")
                    setInt(R.id.widget_progress, "setBackgroundResource", R.drawable.widget_badge_bg)
                    setTextColor(R.id.widget_progress, android.graphics.Color.parseColor("#34D399"))
                }

                // 点击小组件启动主页面
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
