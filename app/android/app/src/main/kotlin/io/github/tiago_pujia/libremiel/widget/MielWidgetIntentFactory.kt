package io.github.tiago_pujia.libremiel.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.github.tiago_pujia.libremiel.MainActivity
import io.github.tiago_pujia.libremiel.widget_bridge.LibreMielWidgetBridgePlugin
import org.json.JSONObject

object MielWidgetIntentFactory {

    fun createLaunchAppPendingIntent(
        context: Context,
        widgetKind: String,
        appWidgetId: Int,
        slotIndex: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("libremiel://widget/launch/$widgetKind/$appWidgetId/$slotIndex")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode(widgetKind, appWidgetId, slotIndex),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun createDeepLinkPendingIntent(
        context: Context,
        widgetKind: String,
        appWidgetId: Int,
        slotIndex: Int,
        idComision: String,
        module: String,
        targetUrl: String = "",
        notificationId: Int? = null,
    ): PendingIntent {
        val payloadJson = JSONObject().apply {
            put("idComision", idComision)
            put("module", module)
            put("targetUrl", targetUrl)
            if (notificationId != null && notificationId > 0) {
                put("notificationId", notificationId)
            }
        }.toString()

        val intent = Intent(context, MainActivity::class.java).apply {
            action = LibreMielWidgetBridgePlugin.ACTION_WIDGET_OPEN
            data = Uri.parse("libremiel://widget/tap/$widgetKind/$appWidgetId/$slotIndex")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(LibreMielWidgetBridgePlugin.EXTRA_WIDGET_PAYLOAD, payloadJson)
        }
        return PendingIntent.getActivity(
            context,
            requestCode(widgetKind, appWidgetId, slotIndex),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun createRefreshPendingIntent(
        context: Context,
        providerClass: Class<*>,
        widgetKind: String,
        appWidgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, providerClass).apply {
            action = MielWidgetRefreshDispatcher.ACTION_WIDGET_REFRESH
            data = Uri.parse("libremiel://widget/refresh/$widgetKind/$appWidgetId")
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(widgetKind, appWidgetId, 99),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestCode(widgetKind: String, appWidgetId: Int, slotIndex: Int): Int {
        val kindOffset = if (widgetKind == "feed") 1_000_000 else 0
        return kindOffset + (appWidgetId * 100) + slotIndex
    }
}
