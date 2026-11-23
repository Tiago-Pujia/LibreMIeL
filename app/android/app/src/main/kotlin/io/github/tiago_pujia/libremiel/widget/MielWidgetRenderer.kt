package io.github.tiago_pujia.libremiel.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import io.github.tiago_pujia.libremiel.R

object MielWidgetRenderer {

    private data class SubjectChipIds(
        val containerId: Int,
        val nameId: Int,
        val badgeId: Int,
    )

    private data class FeedItemIds(
        val containerId: Int,
        val unreadBarId: Int,
        val iconId: Int,
        val titleId: Int,
        val metaId: Int,
        val timeId: Int,
    )

    private val subjectChipSlots = listOf(
        SubjectChipIds(R.id.feed_subject_0, R.id.feed_subject_0_name, R.id.feed_subject_0_badge),
        SubjectChipIds(R.id.feed_subject_1, R.id.feed_subject_1_name, R.id.feed_subject_1_badge),
        SubjectChipIds(R.id.feed_subject_2, R.id.feed_subject_2_name, R.id.feed_subject_2_badge),
    )

    private val feedItemSlots = listOf(
        FeedItemIds(
            R.id.feed_item_0,
            R.id.feed_item_0_unread_bar,
            R.id.feed_item_0_icon,
            R.id.feed_item_0_title,
            R.id.feed_item_0_meta,
            R.id.feed_item_0_time,
        ),
        FeedItemIds(
            R.id.feed_item_1,
            R.id.feed_item_1_unread_bar,
            R.id.feed_item_1_icon,
            R.id.feed_item_1_title,
            R.id.feed_item_1_meta,
            R.id.feed_item_1_time,
        ),
        FeedItemIds(
            R.id.feed_item_2,
            R.id.feed_item_2_unread_bar,
            R.id.feed_item_2_icon,
            R.id.feed_item_2_title,
            R.id.feed_item_2_meta,
            R.id.feed_item_2_time,
        ),
        FeedItemIds(
            R.id.feed_item_3,
            R.id.feed_item_3_unread_bar,
            R.id.feed_item_3_icon,
            R.id.feed_item_3_title,
            R.id.feed_item_3_meta,
            R.id.feed_item_3_time,
        ),
        FeedItemIds(
            R.id.feed_item_4,
            R.id.feed_item_4_unread_bar,
            R.id.feed_item_4_icon,
            R.id.feed_item_4_title,
            R.id.feed_item_4_meta,
            R.id.feed_item_4_time,
        ),
    )

    fun renderCompactWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle?,
    ) {
        val snapshot = MielWidgetSnapshotStore.load(context)
        val views = RemoteViews(context.packageName, R.layout.widget_miel_compact)

        if (!snapshot.isAuthenticated) {
            views.setViewVisibility(R.id.compact_signed_out_container, View.VISIBLE)
            views.setViewVisibility(R.id.compact_full_container, View.GONE)
            views.setViewVisibility(R.id.compact_strip_container, View.GONE)
            views.setOnClickPendingIntent(
                R.id.compact_root,
                MielWidgetIntentFactory.createLaunchAppPendingIntent(
                    context = context,
                    widgetKind = "compact",
                    appWidgetId = appWidgetId,
                    slotIndex = 0,
                ),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val minHeightDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120) ?: 120
        val useStripLayout = minHeightDp in 1 until 90

        views.setViewVisibility(R.id.compact_signed_out_container, View.GONE)
        val statusLabel = statusLabelFor(snapshot)
        val syncText = if (snapshot.isRefreshing) {
            "Actualizando…"
        } else {
            "Act. ${MielWidgetSnapshotStore.formatTimeShort(snapshot.lastSyncIso)}"
        }
        val latest = snapshot.recentNotifications.firstOrNull()

        val refreshIntent = MielWidgetIntentFactory.createRefreshPendingIntent(
            context = context,
            providerClass = MielCompactWidgetProvider::class.java,
            widgetKind = "compact",
            appWidgetId = appWidgetId,
        )

        if (useStripLayout) {
            views.setViewVisibility(R.id.compact_full_container, View.GONE)
            views.setViewVisibility(R.id.compact_strip_container, View.VISIBLE)

            if (snapshot.unreadCount > 0) {
                views.setViewVisibility(R.id.compact_strip_badge, View.VISIBLE)
                views.setTextViewText(
                    R.id.compact_strip_badge,
                    if (snapshot.unreadCount > 99) "99+" else snapshot.unreadCount.toString(),
                )
            } else {
                views.setViewVisibility(R.id.compact_strip_badge, View.GONE)
            }

            val stripTitle = when {
                latest != null -> latest.title
                snapshot.unreadCount > 0 -> "${snapshot.unreadCount} novedades sin leer"
                else -> "Todo al día"
            }
            views.setTextViewText(R.id.compact_strip_title, stripTitle)
            views.setTextViewText(R.id.compact_strip_subtitle, "$statusLabel · $syncText")
            views.setOnClickPendingIntent(R.id.compact_strip_refresh_btn, refreshIntent)

            val tapIntent = if (latest != null) {
                MielWidgetIntentFactory.createDeepLinkPendingIntent(
                    context = context,
                    widgetKind = "compact",
                    appWidgetId = appWidgetId,
                    slotIndex = 1,
                    idComision = latest.idComision,
                    module = latest.module,
                    targetUrl = latest.targetUrl,
                    notificationId = latest.id,
                )
            } else {
                MielWidgetIntentFactory.createDeepLinkPendingIntent(
                    context = context,
                    widgetKind = "compact",
                    appWidgetId = appWidgetId,
                    slotIndex = 1,
                    idComision = "home",
                    module = "home",
                )
            }
            views.setOnClickPendingIntent(R.id.compact_root, tapIntent)
            views.setOnClickPendingIntent(R.id.compact_strip_body, tapIntent)
        } else {
            views.setViewVisibility(R.id.compact_strip_container, View.GONE)
            views.setViewVisibility(R.id.compact_full_container, View.VISIBLE)

            applyStatusPill(context, views, R.id.compact_status_pill, snapshot)
            views.setTextViewText(R.id.compact_sync_time, syncText)
            views.setOnClickPendingIntent(R.id.compact_refresh_btn, refreshIntent)

            if (snapshot.unreadCount > 0) {
                views.setViewVisibility(R.id.compact_all_clear_icon, View.GONE)
                views.setViewVisibility(R.id.compact_unread_number, View.VISIBLE)
                views.setTextViewText(
                    R.id.compact_unread_number,
                    if (snapshot.unreadCount > 99) "99+" else snapshot.unreadCount.toString(),
                )
                views.setTextColor(R.id.compact_unread_number, context.getColor(R.color.widget_badge_red))
                views.setTextViewText(
                    R.id.compact_unread_label,
                    if (snapshot.unreadCount == 1) "novedad sin leer" else "novedades sin leer",
                )
            } else {
                views.setViewVisibility(R.id.compact_all_clear_icon, View.VISIBLE)
                views.setViewVisibility(R.id.compact_unread_number, View.GONE)
                views.setTextViewText(R.id.compact_unread_label, "Todo al día")
            }

            val subjectsSummary = when {
                snapshot.pendingSubjectsBadgeCount == 1 -> "1 materia con avisos"
                snapshot.pendingSubjectsBadgeCount > 1 -> "${snapshot.pendingSubjectsBadgeCount} materias con avisos"
                snapshot.activeSubjects.isNotEmpty() -> "${snapshot.activeSubjects.size} materias activas"
                else -> "Sin avisos pendientes"
            }
            views.setTextViewText(R.id.compact_subjects_summary, subjectsSummary)

            val homeIntent = MielWidgetIntentFactory.createDeepLinkPendingIntent(
                context = context,
                widgetKind = "compact",
                appWidgetId = appWidgetId,
                slotIndex = 2,
                idComision = "home",
                module = "home",
            )
            views.setOnClickPendingIntent(R.id.compact_root, homeIntent)
            views.setOnClickPendingIntent(
                R.id.compact_count_row,
                MielWidgetIntentFactory.createDeepLinkPendingIntent(
                    context = context,
                    widgetKind = "compact",
                    appWidgetId = appWidgetId,
                    slotIndex = 3,
                    idComision = "global",
                    module = "novedades",
                ),
            )

            if (latest != null) {
                val cardBg = if (latest.isRead) {
                    R.drawable.widget_card_bg
                } else {
                    R.drawable.widget_unread_card_bg
                }
                views.setInt(R.id.compact_last_notif_card, "setBackgroundResource", cardBg)
                val subjectText = if (latest.subjectName.isNotBlank()) {
                    latest.subjectName
                } else {
                    "Última novedad"
                }
                views.setTextViewText(R.id.compact_last_notif_subject, subjectText)
                val preview = if (latest.body.isNotBlank() && latest.title != latest.body) {
                    "${latest.title} · ${latest.body}"
                } else {
                    latest.title
                }
                views.setTextViewText(R.id.compact_last_notif_title, preview)
                views.setOnClickPendingIntent(
                    R.id.compact_last_notif_card,
                    MielWidgetIntentFactory.createDeepLinkPendingIntent(
                        context = context,
                        widgetKind = "compact",
                        appWidgetId = appWidgetId,
                        slotIndex = 4,
                        idComision = latest.idComision,
                        module = latest.module,
                        targetUrl = latest.targetUrl,
                        notificationId = latest.id,
                    ),
                )
            } else {
                views.setInt(R.id.compact_last_notif_card, "setBackgroundResource", R.drawable.widget_card_bg)
                views.setTextViewText(R.id.compact_last_notif_subject, "Última novedad")
                views.setTextViewText(R.id.compact_last_notif_title, "Sin novedades recientes")
                views.setOnClickPendingIntent(R.id.compact_last_notif_card, homeIntent)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    fun renderFeedWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle?,
    ) {
        val snapshot = MielWidgetSnapshotStore.load(context)
        val views = RemoteViews(context.packageName, R.layout.widget_miel_feed)

        if (!snapshot.isAuthenticated) {
            views.setViewVisibility(R.id.feed_signed_out_container, View.VISIBLE)
            views.setViewVisibility(R.id.feed_auth_container, View.GONE)
            views.setOnClickPendingIntent(
                R.id.feed_root,
                MielWidgetIntentFactory.createLaunchAppPendingIntent(
                    context = context,
                    widgetKind = "feed",
                    appWidgetId = appWidgetId,
                    slotIndex = 0,
                ),
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        views.setViewVisibility(R.id.feed_signed_out_container, View.GONE)
        views.setViewVisibility(R.id.feed_auth_container, View.VISIBLE)

        val homeIntent = MielWidgetIntentFactory.createDeepLinkPendingIntent(
            context = context,
            widgetKind = "feed",
            appWidgetId = appWidgetId,
            slotIndex = 1,
            idComision = "home",
            module = "home",
        )
        val novedadesIntent = MielWidgetIntentFactory.createDeepLinkPendingIntent(
            context = context,
            widgetKind = "feed",
            appWidgetId = appWidgetId,
            slotIndex = 2,
            idComision = "global",
            module = "novedades",
        )
        views.setOnClickPendingIntent(R.id.feed_root, homeIntent)
        views.setOnClickPendingIntent(R.id.feed_header_home, homeIntent)
        views.setOnClickPendingIntent(R.id.feed_unread_pill, novedadesIntent)

        if (snapshot.unreadCount > 0) {
            val label = if (snapshot.unreadCount == 1) "1 sin leer" else "${snapshot.unreadCount} sin leer"
            views.setTextViewText(R.id.feed_unread_pill, label)
            views.setInt(R.id.feed_unread_pill, "setBackgroundResource", R.drawable.widget_badge_red_bg)
            views.setTextColor(R.id.feed_unread_pill, 0xFFFFFFFF.toInt())
        } else {
            views.setTextViewText(R.id.feed_unread_pill, "Al día")
            views.setInt(R.id.feed_unread_pill, "setBackgroundResource", R.drawable.widget_status_online_bg)
            views.setTextColor(R.id.feed_unread_pill, context.getColor(R.color.widget_status_online_text))
        }

        applyStatusPill(context, views, R.id.feed_status_pill, snapshot)

        val syncText = if (snapshot.isRefreshing) {
            "Actualizando…"
        } else {
            MielWidgetSnapshotStore.formatTimeShort(snapshot.lastSyncIso)
        }
        views.setTextViewText(R.id.feed_sync_time, syncText)
        views.setOnClickPendingIntent(
            R.id.feed_refresh_btn,
            MielWidgetIntentFactory.createRefreshPendingIntent(
                context = context,
                providerClass = MielFeedWidgetProvider::class.java,
                widgetKind = "feed",
                appWidgetId = appWidgetId,
            ),
        )

        // Franja de materias activas (hasta 3 chips)
        val subjects = snapshot.activeSubjects.take(subjectChipSlots.size)
        if (subjects.isEmpty()) {
            views.setViewVisibility(R.id.feed_subjects_strip, View.GONE)
        } else {
            views.setViewVisibility(R.id.feed_subjects_strip, View.VISIBLE)
            for (i in subjectChipSlots.indices) {
                val chip = subjectChipSlots[i]
                if (i < subjects.size) {
                    val subject = subjects[i]
                    views.setViewVisibility(chip.containerId, View.VISIBLE)
                    views.setTextViewText(chip.nameId, subject.name)
                    if (subject.totalBadges > 0) {
                        views.setViewVisibility(chip.badgeId, View.VISIBLE)
                        views.setTextViewText(chip.badgeId, subject.totalBadges.toString())
                    } else {
                        views.setViewVisibility(chip.badgeId, View.GONE)
                    }
                    views.setOnClickPendingIntent(
                        chip.containerId,
                        MielWidgetIntentFactory.createDeepLinkPendingIntent(
                            context = context,
                            widgetKind = "feed",
                            appWidgetId = appWidgetId,
                            slotIndex = 10 + i,
                            idComision = subject.idComision,
                            module = subject.defaultTool,
                        ),
                    )
                } else {
                    views.setViewVisibility(chip.containerId, View.GONE)
                }
            }
        }

        // Cantidad de filas visibles según altura del widget
        val minHeightDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 130) ?: 130
        val maxVisibleRows = when {
            minHeightDp >= 220 -> 5
            minHeightDp >= 150 -> 4
            else -> 3
        }
        val items = snapshot.recentNotifications.take(maxVisibleRows)

        if (items.isEmpty()) {
            views.setViewVisibility(R.id.feed_empty_state, View.VISIBLE)
            views.setViewVisibility(R.id.feed_items_container, View.GONE)
            views.setOnClickPendingIntent(R.id.feed_empty_state, novedadesIntent)
        } else {
            views.setViewVisibility(R.id.feed_empty_state, View.GONE)
            views.setViewVisibility(R.id.feed_items_container, View.VISIBLE)

            for (i in feedItemSlots.indices) {
                val slot = feedItemSlots[i]
                if (i < items.size) {
                    val item = items[i]
                    views.setViewVisibility(slot.containerId, View.VISIBLE)
                    views.setInt(
                        slot.containerId,
                        "setBackgroundResource",
                        if (item.isRead) R.drawable.widget_card_bg else R.drawable.widget_unread_card_bg,
                    )
                    views.setViewVisibility(
                        slot.unreadBarId,
                        if (item.isRead) View.GONE else View.VISIBLE,
                    )
                    views.setImageViewResource(slot.iconId, iconForModule(item.module))
                    views.setTextViewText(slot.titleId, item.title)

                    val meta = buildString {
                        if (item.subjectName.isNotBlank()) append(item.subjectName)
                        if (item.body.isNotBlank()) {
                            if (isNotEmpty()) append(" · ")
                            append(item.body)
                        }
                    }
                    views.setTextViewText(slot.metaId, meta)
                    views.setTextViewText(
                        slot.timeId,
                        MielWidgetSnapshotStore.formatTimeShort(item.createdAtIso),
                    )
                    views.setOnClickPendingIntent(
                        slot.containerId,
                        MielWidgetIntentFactory.createDeepLinkPendingIntent(
                            context = context,
                            widgetKind = "feed",
                            appWidgetId = appWidgetId,
                            slotIndex = 20 + i,
                            idComision = item.idComision,
                            module = item.module,
                            targetUrl = item.targetUrl,
                            notificationId = item.id,
                        ),
                    )
                } else {
                    views.setViewVisibility(slot.containerId, View.GONE)
                }
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun statusLabelFor(snapshot: WidgetSnapshotData): String = when {
        snapshot.authPaused -> "Revisar clave"
        snapshot.serverStatus == "mielDown" -> "MIeL caído"
        snapshot.serverStatus == "deviceOffline" -> "Sin red"
        else -> "En línea"
    }

    private fun applyStatusPill(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        snapshot: WidgetSnapshotData,
    ) {
        val (label, bgRes, textColorRes) = when {
            snapshot.authPaused -> Triple(
                "Revisar clave",
                R.drawable.widget_status_auth_bg,
                R.color.widget_status_auth_text,
            )
            snapshot.serverStatus == "mielDown" -> Triple(
                "MIeL caído",
                R.drawable.widget_status_down_bg,
                R.color.widget_status_down_text,
            )
            snapshot.serverStatus == "deviceOffline" -> Triple(
                "Sin red",
                R.drawable.widget_status_offline_bg,
                R.color.widget_status_offline_text,
            )
            else -> Triple(
                "En línea",
                R.drawable.widget_status_online_bg,
                R.color.widget_status_online_text,
            )
        }
        views.setTextViewText(viewId, label)
        views.setInt(viewId, "setBackgroundResource", bgRes)
        views.setTextColor(viewId, context.getColor(textColorRes))
    }

    private fun iconForModule(module: String): Int = when (module) {
        "contenidos" -> R.drawable.ic_widget_contenidos
        "mensajeria" -> R.drawable.ic_widget_mensajeria
        "foros", "foro" -> R.drawable.ic_widget_foros
        "portafolio" -> R.drawable.ic_widget_portafolio
        "evaluacion" -> R.drawable.ic_widget_evaluacion
        else -> R.drawable.ic_widget_novedades
    }
}
