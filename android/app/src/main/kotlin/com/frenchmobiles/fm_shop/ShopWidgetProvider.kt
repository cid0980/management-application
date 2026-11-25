package com.frenchmobiles.fm_shop

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import kotlin.math.abs
import kotlin.math.max

/**
 * The phone's home-screen widget: today's money (total, net, spent), how it
 * came in (UPI / cash / other / repairs, in columns), the next repairs to
 * give back with the time left on each (or how late), and stock, calls and
 * money owed.
 *
 * The words and figures are written by the app (lib/data/shop_widget.dart)
 * in the shop's language; this puts them on the screen. A repair's "3h left"
 * is worked out here, from its promised time, every time the widget is drawn
 * (Android redraws it every half hour), so it does not stay stuck at what
 * the app last wrote. The sum is the same as `countdown` in
 * lib/domain/dashboard/widget_summary.dart.
 *
 * Tapping a repair opens that repair; tapping elsewhere opens the app; the
 * refresh button asks the app, in the background, to read today's figures
 * again.
 */
class ShopWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val now = System.currentTimeMillis()
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.shop_widget).apply {
            fun get(key: String): String? = widgetData.getString(key, null)
            fun text(id: Int, key: String, fallback: String) {
              setTextViewText(id, get(key) ?: fallback)
            }
            fun optional(id: Int, key: String) {
              val v = get(key)
              if (v.isNullOrEmpty()) {
                setViewVisibility(id, View.GONE)
              } else {
                setTextViewText(id, v)
                setViewVisibility(id, View.VISIBLE)
              }
            }

            text(R.id.widget_title, "w_title", "Today's sales")
            text(R.id.widget_amount, "w_amount", "₹0")
            text(R.id.widget_updated, "w_updated", "")
            optional(R.id.widget_net, "w_net")
            optional(R.id.widget_spent, "w_spent")

            text(R.id.widget_l_upi, "w_l_upi", "UPI")
            text(R.id.widget_v_upi, "w_v_upi", "₹0")
            text(R.id.widget_l_cash, "w_l_cash", "Cash")
            text(R.id.widget_v_cash, "w_v_cash", "₹0")
            text(R.id.widget_l_rep, "w_l_rep", "Repairs")
            text(R.id.widget_v_rep, "w_v_rep", "₹0")
            if (get("w_v_other").isNullOrEmpty()) {
              setViewVisibility(R.id.widget_col_other, View.GONE)
            } else {
              text(R.id.widget_l_other, "w_l_other", "Other")
              text(R.id.widget_v_other, "w_v_other", "")
              setViewVisibility(R.id.widget_col_other, View.VISIBLE)
            }

            text(R.id.widget_jobs_title, "w_jobs_title", "Repairs")
            text(R.id.widget_late, "w_late", "0 late")
            text(R.id.widget_due, "w_due", "0 today")
            text(R.id.widget_ready, "w_ready", "0 ready")

            val rows = intArrayOf(R.id.widget_job0, R.id.widget_job1, R.id.widget_job2)
            val names =
                intArrayOf(R.id.widget_job0_name, R.id.widget_job1_name, R.id.widget_job2_name)
            val chips =
                intArrayOf(R.id.widget_job0_chip, R.id.widget_job1_chip, R.id.widget_job2_chip)
            val count = get("w_job_n")?.toIntOrNull() ?: 0
            for (i in rows.indices) {
              if (i >= count) {
                setViewVisibility(rows[i], View.GONE)
                continue
              }
              setViewVisibility(rows[i], View.VISIBLE)
              text(names[i], "w_job$i", "")
              val at = get("w_job${i}_at")?.toLongOrNull()
              val (label, kind) =
                  if (at == null) Pair(get("w_t_ready") ?: "Ready", READY)
                  else countdown(at, now, widgetData)
              setTextViewText(chips[i], label)
              val (bg, ink) =
                  when (kind) {
                    LATE -> Pair(R.drawable.widget_chip_late, "#991B1B")
                    TODAY -> Pair(R.drawable.widget_chip_due, "#92400E")
                    READY -> Pair(R.drawable.widget_chip_ready, "#166534")
                    else -> Pair(R.drawable.widget_chip_later, "#F4F7F2")
                  }
              setInt(chips[i], "setBackgroundResource", bg)
              setTextColor(chips[i], Color.parseColor(ink))
              val id = get("w_job${i}_id")
              if (!id.isNullOrEmpty()) {
                // The app's own address for the repair page: Flutter hands
                // the path ("/service/<id>") to the app's router.
                setOnClickPendingIntent(
                    rows[i],
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("shopwidget://open/service/" + Uri.encode(id)),
                    ),
                )
              }
            }
            if (count == 0 && get("w_jobs_empty") != null) {
              optional(R.id.widget_jobs_empty, "w_jobs_empty")
            } else {
              setViewVisibility(R.id.widget_jobs_empty, View.GONE)
            }

            text(R.id.widget_stock, "w_stock", "")
            optional(R.id.widget_owed, "w_owed")

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

  private companion object {
    const val LATE = 0
    const val TODAY = 1
    const val LATER = 2
    const val READY = 3

    /** "45m left", "3h late", "2d left", in the words the app wrote. */
    fun countdown(at: Long, now: Long, d: SharedPreferences): Pair<String, Int> {
      val diff = at - now
      val mins = abs(diff) / 60000L
      val (n, key, fallback) =
          when {
            mins < 60 -> Triple(max(mins, 1L), "w_u_m", "{n}m")
            mins < 24 * 60 -> Triple(mins / 60, "w_u_h", "{n}h")
            else -> Triple(mins / (24 * 60), "w_u_d", "{n}d")
          }
      val t = (d.getString(key, null) ?: fallback).replace("{n}", n.toString())
      if (diff < 0) {
        return Pair((d.getString("w_t_late", null) ?: "{t} late").replace("{t}", t), LATE)
      }
      val endOfToday =
          Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.DAY_OF_MONTH, 1)
          }.timeInMillis
      val left = (d.getString("w_t_left", null) ?: "{t} left").replace("{t}", t)
      return Pair(left, if (at < endOfToday) TODAY else LATER)
    }
  }
}
