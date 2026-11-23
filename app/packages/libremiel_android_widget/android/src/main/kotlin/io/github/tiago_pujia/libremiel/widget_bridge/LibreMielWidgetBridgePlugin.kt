package io.github.tiago_pujia.libremiel.widget_bridge

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class LibreMielWidgetBridgePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener {

    companion object {
        const val CHANNEL_NAME = "io.github.tiago_pujia.libremiel/android_widget"
        const val PREFS_NAME = "libremiel_widget_prefs"
        const val KEY_SNAPSHOT_JSON = "snapshot_json"
        const val KEY_IS_REFRESHING = "is_refreshing"
        const val KEY_REFRESH_STARTED_AT = "refresh_started_at"
        const val ACTION_WIDGET_OPEN = "io.github.tiago_pujia.libremiel.ACTION_WIDGET_OPEN"
        const val EXTRA_WIDGET_PAYLOAD = "libremiel_widget_payload"
        const val COMPACT_PROVIDER_CLASS =
            "io.github.tiago_pujia.libremiel.widget.MielCompactWidgetProvider"
        const val FEED_PROVIDER_CLASS =
            "io.github.tiago_pujia.libremiel.widget.MielFeedWidgetProvider"
    }

    private var applicationContext: Context? = null
    private var channel: MethodChannel? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingInitialLaunchPayload: String? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        captureInitialIntentIfPresent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    private fun captureInitialIntentIfPresent(intent: Intent?) {
        if (intent == null || intent.action != ACTION_WIDGET_OPEN) return
        val payload = intent.getStringExtra(EXTRA_WIDGET_PAYLOAD)
        intent.removeExtra(EXTRA_WIDGET_PAYLOAD)
        if (!payload.isNullOrEmpty()) {
            pendingInitialLaunchPayload = payload
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        if (intent.action != ACTION_WIDGET_OPEN) return false
        val payload = intent.getStringExtra(EXTRA_WIDGET_PAYLOAD)
        intent.removeExtra(EXTRA_WIDGET_PAYLOAD)
        activityBinding?.activity?.setIntent(intent)
        if (!payload.isNullOrEmpty()) {
            mainHandler.post {
                channel?.invokeMethod("onWidgetTapped", payload)
            }
        }
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Contexto de aplicación no disponible", null)
            return
        }

        when (call.method) {
            "updateSnapshot" -> {
                val snapshotJson = call.argument<String>("snapshotJson")
                if (snapshotJson.isNullOrEmpty()) {
                    result.error("INVALID_SNAPSHOT", "snapshotJson vacío", null)
                    return
                }
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit()
                    .putString(KEY_SNAPSHOT_JSON, snapshotJson)
                    .putBoolean(KEY_IS_REFRESHING, false)
                    .putLong(KEY_REFRESH_STARTED_AT, 0L)
                    .commit()
                notifyAllWidgetProviders(context)
                result.success(true)
            }

            "clearSnapshot" -> {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit()
                    .remove(KEY_SNAPSHOT_JSON)
                    .putBoolean(KEY_IS_REFRESHING, false)
                    .putLong(KEY_REFRESH_STARTED_AT, 0L)
                    .commit()
                notifyAllWidgetProviders(context)
                result.success(true)
            }

            "consumeInitialLaunchPayload" -> {
                val payload = pendingInitialLaunchPayload
                pendingInitialLaunchPayload = null
                result.success(payload)
            }

            "isPinWidgetSupported" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = AppWidgetManager.getInstance(context)
                    result.success(manager?.isRequestPinAppWidgetSupported ?: false)
                } else {
                    result.success(false)
                }
            }

            "requestPinWidget" -> {
                val kind = call.argument<String>("kind") ?: "compact"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = AppWidgetManager.getInstance(context)
                    if (manager != null && manager.isRequestPinAppWidgetSupported) {
                        val providerClass =
                            if (kind == "feed") FEED_PROVIDER_CLASS else COMPACT_PROVIDER_CLASS
                        val component = ComponentName(context.packageName, providerClass)
                        result.success(manager.requestPinAppWidget(component, null, null))
                    } else {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun notifyAllWidgetProviders(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val providers = listOf(COMPACT_PROVIDER_CLASS, FEED_PROVIDER_CLASS)
        for (providerClass in providers) {
            val component = ComponentName(context.packageName, providerClass)
            val ids = manager.getAppWidgetIds(component)
            if (ids != null && ids.isNotEmpty()) {
                val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    this.component = component
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(updateIntent)
            }
        }
    }
}
