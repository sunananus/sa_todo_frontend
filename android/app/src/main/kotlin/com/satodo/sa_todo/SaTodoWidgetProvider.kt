package com.satodo.sa_todo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class SaTodoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private val PRIORITY_COLORS = mapOf(
            3 to 0xFFFF3B30.toInt(), // high - red
            2 to 0xFFFF9500.toInt(), // medium - orange
            1 to 0xFF34C759.toInt(), // low - green
            0 to 0xFF8E8E93.toInt(), // none - gray
        )

        private fun isDarkMode(context: Context): Boolean {
            val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
            return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
        }

        private fun getColor(context: Context, resId: Int): Int {
            return ContextCompat.getColor(context, resId)
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_sa_todo)

            // 动态设置文字颜色（使用颜色资源，自动适配深色模式）
            val textPrimary = getColor(context, R.color.widget_text_primary)
            val textSecondary = getColor(context, R.color.widget_text_secondary)

            views.setTextColor(R.id.tv_title, textPrimary)
            views.setTextColor(R.id.tv_task_count, textSecondary)

            // 读取小组件数据
            val widgetData = HomeWidgetPlugin.getData(context)
            val taskCount = widgetData.getInt("task_count", 0)
            val tasksJson = widgetData.getString("pending_tasks", "[]")

            // 更新任务计数
            views.setTextViewText(R.id.tv_task_count, "$taskCount pending")

            // 解析任务列表
            val tasks = try {
                val jsonArray = JSONArray(tasksJson)
                (0 until jsonArray.length()).map { i ->
                    jsonArray.getJSONObject(i)
                }
            } catch (e: Exception) {
                emptyList()
            }

            // 更新任务行
            for (i in 0 until 5) {
                val rowId = context.resources.getIdentifier("task_row_$i", "id", context.packageName)
                val titleId = context.resources.getIdentifier("task_title_$i", "id", context.packageName)
                val dotId = context.resources.getIdentifier("priority_dot_$i", "id", context.packageName)

                if (i < tasks.size) {
                    val task = tasks[i]
                    views.setViewVisibility(rowId, View.VISIBLE)
                    views.setTextViewText(titleId, task.getString("title"))
                    views.setTextColor(titleId, textPrimary)
                    val priority = task.getInt("priority")
                    val color = PRIORITY_COLORS[priority] ?: PRIORITY_COLORS[0]!!
                    views.setInt(dotId, "setBackgroundColor", color)
                } else {
                    views.setViewVisibility(rowId, View.GONE)
                }
            }

            // 设置空状态文字颜色
            views.setTextColor(R.id.tv_empty_check, textSecondary)
            views.setTextColor(R.id.tv_empty_label, textSecondary)

            // 显示/隐藏空状态
            views.setViewVisibility(
                R.id.empty_state,
                if (tasks.isEmpty()) View.VISIBLE else View.GONE
            )
            views.setViewVisibility(
                R.id.task_list_container,
                if (tasks.isEmpty()) View.GONE else View.VISIBLE
            )

            // 设置快速添加按钮的 PendingIntent
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("satodo://quickadd")).apply {
                `package` = context.packageName
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.btn_quick_add, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
