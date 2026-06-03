package com.example.al_ribat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HabitsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habits_widget).apply {
                val totalHabits = widgetData.getInt("totalHabits", 0)
                val completedHabits = widgetData.getInt("completedHabits", 0)
                val dateString = widgetData.getString("currentDate", "")
                val habitsList = widgetData.getString("habitsList", "")
                
                setTextViewText(R.id.tv_date, dateString)
                setTextViewText(R.id.tv_progress, "$completedHabits / $totalHabits")
                
                if (totalHabits > 0) {
                    val progress = (completedHabits.toFloat() / totalHabits * 100).toInt()
                    setProgressBar(R.id.pb_progress, 100, progress, false)
                    setTextViewText(R.id.tv_habits_list, habitsList)
                    setViewVisibility(R.id.tv_habits_list, android.view.View.VISIBLE)
                    setViewVisibility(R.id.tv_message, android.view.View.GONE)
                } else {
                    setProgressBar(R.id.pb_progress, 100, 0, false)
                    setViewVisibility(R.id.tv_habits_list, android.view.View.GONE)
                    setViewVisibility(R.id.tv_message, android.view.View.VISIBLE)
                    setTextViewText(R.id.tv_message, "لا توجد عادات لليوم.")
                }

                // Make widget clickable to open the app
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
