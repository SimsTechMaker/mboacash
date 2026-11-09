package com.ndi.carnet237

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget: the money available and a button straight to quick
 * entry. The app writes the texts (already translated, and the amount hidden
 * when a lock code is set); the widget only shows them.
 */
class QuickWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_widget).apply {
                setTextViewText(R.id.widget_label, widgetData.getString("label", "Disponible"))
                setTextViewText(R.id.widget_amount, widgetData.getString("amount", "—"))
                setTextViewText(R.id.widget_add, widgetData.getString("add", "+"))
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("mynkap://home")))
                setOnClickPendingIntent(R.id.widget_add, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("mynkap://quick")))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
