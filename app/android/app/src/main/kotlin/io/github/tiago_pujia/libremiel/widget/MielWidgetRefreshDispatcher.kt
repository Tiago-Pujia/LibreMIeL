package io.github.tiago_pujia.libremiel.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.SharedPreferenceHelper
import dev.fluttercommunity.workmanager.UNIQUE_NAME_KEY
import io.github.tiago_pujia.libremiel.MainActivity

object MielWidgetRefreshDispatcher {
    const val ACTION_WIDGET_REFRESH = "io.github.tiago_pujia.libremiel.ACTION_WIDGET_REFRESH"
    const val WIDGET_REFRESH_TASK_NAME = "libremiel_widget_refresh"

    fun handleRefreshAction(context: Context) {
        val snapshot = MielWidgetSnapshotStore.load(context)
        if (!snapshot.isAuthenticated) {
            MielWidgetSnapshotStore.setRefreshing(context, false)
            redrawAllWidgets(context)
            openMainApp(context)
            return
        }

        val callbackHandle = SharedPreferenceHelper.getCallbackHandle(context)
        if (callbackHandle == -1L) {
            MielWidgetSnapshotStore.setRefreshing(context, false)
            redrawAllWidgets(context)
            openMainApp(context)
            return
        }

        MielWidgetSnapshotStore.setRefreshing(context, true)
        redrawAllWidgets(context)

        try {
            val inputData = Data.Builder()
                .putString(BackgroundWorker.DART_TASK_KEY, WIDGET_REFRESH_TASK_NAME)
                .putString(UNIQUE_NAME_KEY, WIDGET_REFRESH_TASK_NAME)
                .build()

            val request = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
                .setInputData(inputData)
                .setConstraints(Constraints.NONE)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WIDGET_REFRESH_TASK_NAME,
                ExistingWorkPolicy.KEEP,
                request,
            )
        } catch (_: Exception) {
            MielWidgetSnapshotStore.setRefreshing(context, false)
            redrawAllWidgets(context)
        }
    }

    fun redrawAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return

        val compactComponent = ComponentName(context, MielCompactWidgetProvider::class.java)
        for (id in manager.getAppWidgetIds(compactComponent)) {
            MielWidgetRenderer.renderCompactWidget(
                context = context,
                appWidgetManager = manager,
                appWidgetId = id,
                options = manager.getAppWidgetOptions(id),
            )
        }

        val feedComponent = ComponentName(context, MielFeedWidgetProvider::class.java)
        for (id in manager.getAppWidgetIds(feedComponent)) {
            MielWidgetRenderer.renderFeedWidget(
                context = context,
                appWidgetManager = manager,
                appWidgetId = id,
                options = manager.getAppWidgetOptions(id),
            )
        }
    }

    private fun openMainApp(context: Context) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {}
    }
}
