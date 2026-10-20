package com.example.uth_flow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
    }

    companion object {
        private const val PREFS_NAME = "uth_flow_widget_prefs"
        private const val KEY_WIDGET_DATA = "widget_schedule_data"

        fun updateWidgetData(context: Context, jsonString: String) {
            try {
                // Lưu vào SharedPreferences riêng của Widget
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString(KEY_WIDGET_DATA, jsonString).apply()

                // Lưu dự phòng vào FlutterSharedPreferences
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                flutterPrefs.edit().putString("flutter.$KEY_WIDGET_DATA", jsonString).apply()

                // Cập nhật ngay tất cả widget đang hiển thị trên launcher
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val component = ComponentName(context, ScheduleWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(component)

                for (id in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            } catch (e: Exception) {
                android.util.Log.e("ScheduleWidget", "Error updating widget data", e)
            }
        }

        private fun getTodayDateShort(): String {
            val cal = Calendar.getInstance()
            val dayOfWeek = when (cal.get(Calendar.DAY_OF_WEEK)) {
                Calendar.MONDAY -> "T2"
                Calendar.TUESDAY -> "T3"
                Calendar.WEDNESDAY -> "T4"
                Calendar.THURSDAY -> "T5"
                Calendar.FRIDAY -> "T6"
                Calendar.SATURDAY -> "T7"
                Calendar.SUNDAY -> "CN"
                else -> ""
            }
            val sdf = SimpleDateFormat("d/M", Locale.getDefault())
            return "$dayOfWeek, ${sdf.format(cal.time)}"
        }

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)

            // Intent mở app khi bấm vào widget
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Đọc dữ liệu lịch học từ SharedPreferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            var jsonString = prefs.getString(KEY_WIDGET_DATA, null)
            if (jsonString.isNullOrEmpty()) {
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                jsonString = flutterPrefs.getString("flutter.$KEY_WIDGET_DATA", null)
            }

            if (jsonString.isNullOrEmpty()) {
                views.setViewVisibility(R.id.widget_classes_layout, View.GONE)
                views.setViewVisibility(R.id.widget_empty_layout, View.VISIBLE)
                views.setTextViewText(R.id.widget_header_title, "UTH Flow")
                views.setTextViewText(R.id.widget_date_badge, getTodayDateShort())
                views.setTextViewText(R.id.widget_empty_title, "Chưa đồng bộ lịch học")
                views.setTextViewText(R.id.widget_empty_subtext, "Chạm vào đây để mở ứng dụng UTH Flow")
                appWidgetManager.updateAppWidget(appWidgetId, views)
                return
            }

            try {
                val data = JSONObject(jsonString)
                val todayDate = data.optString("todayDate", getTodayDateShort())
                val isTodayFinished = data.optBoolean("isTodayFinished", false)
                val hasTomorrowClasses = data.optBoolean("hasTomorrowClasses", false)
                val tomorrowDate = data.optString("tomorrowDate", "")

                val todayArray = data.optJSONArray("todayClasses") ?: JSONArray()
                val tomorrowArray = data.optJSONArray("tomorrowClasses") ?: JSONArray()

                // Lọc các ca học chưa kết thúc trong ngày hôm nay
                val activeTodayClasses = mutableListOf<JSONObject>()
                for (i in 0 until todayArray.length()) {
                    val item = todayArray.optJSONObject(i)
                    if (item != null && !item.optBoolean("isFinished", false)) {
                        activeTodayClasses.add(item)
                    }
                }

                if (activeTodayClasses.isNotEmpty()) {
                    // Còn ca học trong ngày hôm nay
                    views.setTextViewText(R.id.widget_header_title, "Lịch học hôm nay")
                    views.setTextViewText(R.id.widget_date_badge, todayDate)
                    views.setViewVisibility(R.id.widget_empty_layout, View.GONE)
                    views.setViewVisibility(R.id.widget_classes_layout, View.VISIBLE)

                    // Ca 1
                    val c1 = activeTodayClasses[0]
                    views.setTextViewText(R.id.widget_class_1_name, c1.optString("name", "Môn học"))
                    views.setTextViewText(R.id.widget_class_1_time, c1.optString("time", "--:--"))
                    views.setTextViewText(R.id.widget_class_1_room, c1.optString("room", "Đang xếp phòng"))

                    // Ca 2 (nếu có)
                    if (activeTodayClasses.size >= 2) {
                        val c2 = activeTodayClasses[1]
                        views.setViewVisibility(R.id.widget_divider_class, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_class_2, View.VISIBLE)
                        views.setTextViewText(R.id.widget_class_2_name, c2.optString("name", "Môn học"))
                        views.setTextViewText(R.id.widget_class_2_time, c2.optString("time", "--:--"))
                        views.setTextViewText(R.id.widget_class_2_room, c2.optString("room", "Đang xếp phòng"))
                    } else {
                        views.setViewVisibility(R.id.widget_divider_class, View.GONE)
                        views.setViewVisibility(R.id.widget_class_2, View.GONE)
                    }

                    // Ca thứ 3 trở lên
                    if (activeTodayClasses.size > 2) {
                        val more = activeTodayClasses.size - 2
                        views.setViewVisibility(R.id.widget_more_classes, View.VISIBLE)
                        views.setTextViewText(R.id.widget_more_classes, "+ $more ca học khác...")
                    } else {
                        views.setViewVisibility(R.id.widget_more_classes, View.GONE)
                    }
                } else {
                    // Hôm nay không có ca học hoặc đã học xong hết các ca
                    if (hasTomorrowClasses && tomorrowArray.length() > 0) {
                        val headerText = if (isTodayFinished) "Đã xong hôm nay • Ngày mai" else "Lịch học ngày mai"
                        views.setTextViewText(R.id.widget_header_title, headerText)
                        views.setTextViewText(R.id.widget_date_badge, if (tomorrowDate.isNotEmpty()) tomorrowDate else todayDate)
                        views.setViewVisibility(R.id.widget_empty_layout, View.GONE)
                        views.setViewVisibility(R.id.widget_classes_layout, View.VISIBLE)

                        val c1 = tomorrowArray.optJSONObject(0) ?: JSONObject()
                        views.setTextViewText(R.id.widget_class_1_name, c1.optString("name", "Môn học"))
                        views.setTextViewText(R.id.widget_class_1_time, c1.optString("time", "--:--"))
                        views.setTextViewText(R.id.widget_class_1_room, c1.optString("room", "Đang xếp phòng"))

                        if (tomorrowArray.length() >= 2) {
                            val c2 = tomorrowArray.optJSONObject(1) ?: JSONObject()
                            views.setViewVisibility(R.id.widget_divider_class, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_class_2, View.VISIBLE)
                            views.setTextViewText(R.id.widget_class_2_name, c2.optString("name", "Môn học"))
                            views.setTextViewText(R.id.widget_class_2_time, c2.optString("time", "--:--"))
                            views.setTextViewText(R.id.widget_class_2_room, c2.optString("room", "Đang xếp phòng"))
                        } else {
                            views.setViewVisibility(R.id.widget_divider_class, View.GONE)
                            views.setViewVisibility(R.id.widget_class_2, View.GONE)
                        }

                        if (tomorrowArray.length() > 2) {
                            val more = tomorrowArray.length() - 2
                            views.setViewVisibility(R.id.widget_more_classes, View.VISIBLE)
                            views.setTextViewText(R.id.widget_more_classes, "+ $more ca học khác...")
                        } else {
                            views.setViewVisibility(R.id.widget_more_classes, View.GONE)
                        }
                    } else {
                        // Cả hôm nay và ngày mai đều không có lịch học
                        views.setTextViewText(R.id.widget_header_title, "Lịch học UTH")
                        views.setTextViewText(R.id.widget_date_badge, todayDate)
                        views.setViewVisibility(R.id.widget_classes_layout, View.GONE)
                        views.setViewVisibility(R.id.widget_empty_layout, View.VISIBLE)

                        if (isTodayFinished) {
                            views.setTextViewText(R.id.widget_empty_title, "Đã xong lịch học hôm nay ✓")
                            views.setTextViewText(R.id.widget_empty_subtext, "Ngày mai không có lịch học, nghỉ ngơi thật tốt nhé!")
                        } else {
                            views.setTextViewText(R.id.widget_empty_title, "Hôm nay không có lịch học 🎉")
                            views.setTextViewText(R.id.widget_empty_subtext, "Ngày mai cũng không có lịch học, tận hưởng nhé!")
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("ScheduleWidget", "Error rendering widget", e)
                views.setViewVisibility(R.id.widget_classes_layout, View.GONE)
                views.setViewVisibility(R.id.widget_empty_layout, View.VISIBLE)
                views.setTextViewText(R.id.widget_header_title, "UTH Flow")
                views.setTextViewText(R.id.widget_empty_title, "Lịch học UTH")
                views.setTextViewText(R.id.widget_empty_subtext, "Chạm để cập nhật lịch học")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
