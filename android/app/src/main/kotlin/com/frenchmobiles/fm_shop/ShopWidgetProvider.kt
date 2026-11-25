package com.frenchmobiles.fm_shop

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The phone's home-screen widget: today's sales, how they came in, the
 * repairs that are late / due today / ready, and what customers owe.
 *
 * The words and figures are written by the app (lib/data/shop_widget.dart)
 * in the shop's language; this only puts them on the screen. Tapping the
 * widget opens the app; the refresh button asks the app, in the background,
 * to read today's figures again.
 */
class ShopWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.shop_widget).apply {
            fun text(id: Int, key: String, fallback: String) {
              setTextViewText(id, widgetData.getString(key, null) ?: fallback)
            }
            text(R.id.widget_title, "w_title", "Today's sales")
            text(R.id.widget_amount, "w_amount", "₹0")
            text(R.id.widget_split, "w_split", "Open the app once to start")
            text(R.id.widget_late, "w_late", "Late 0")
            text(R.id.widget_due, "w_due", "Due today 0")
            text(R.id.widget_ready, "w_ready", "Ready 0")
            text(R.id.widget_updated, "w_updated", "")

            fun optional(id: Int, key: String) {
              val v = widgetData.getString(key, null)
              if (v.isNullOrEmpty()) {
                setViewVisibility(id, View.GONE)
              } else {
                setTextViewText(id, v)
                setViewVisibility(id, View.VISIBLE)
              }
            }
            optional(R.id.widget_repairs, "w_repairs")
            optional(R.id.widget_net, "w_net")
            optional(R.id.widget_late_job, "w_late_job")
            optional(R.id.widget_stock, "w_stock")

            val owed = widgetData.getString("w_owed", null)
            if (owed.isNullOrEmpty()) {
              setViewVisibility(R.id.widget_owed, View.GONE)
            } else {
              setTextViewText(R.id.widget_owed, owed)
              setViewVisibility(R.id.widget_owed, View.VISIBLE)
            }

            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setOnClickPendingIntent(
                R.id.widget_refresh,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("shopwidget://refresh"),
                ),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
