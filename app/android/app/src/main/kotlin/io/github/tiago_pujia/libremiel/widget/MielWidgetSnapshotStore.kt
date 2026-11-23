package io.github.tiago_pujia.libremiel.widget

import android.content.Context
import io.github.tiago_pujia.libremiel.widget_bridge.LibreMielWidgetBridgePlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class WidgetSubjectData(
    val idComision: String,
    val name: String,
    val commissionCode: String,
    val totalBadges: Int,
    val defaultTool: String,
)

data class WidgetNotificationData(
    val id: Int,
    val idComision: String,
    val subjectName: String,
    val module: String,
    val title: String,
    val body: String,
    val targetUrl: String,
    val isRead: Boolean,
    val createdAtIso: String,
)

data class WidgetSnapshotData(
    val isAuthenticated: Boolean,
    val serverStatus: String,
    val authPaused: Boolean,
    val unreadCount: Int,
    val pendingSubjectsBadgeCount: Int,
    val lastSyncIso: String?,
    val isRefreshing: Boolean,
    val recentNotifications: List<WidgetNotificationData>,
    val activeSubjects: List<WidgetSubjectData>,
) {
    companion object {
        fun signedOut(): WidgetSnapshotData = WidgetSnapshotData(
            isAuthenticated = false,
            serverStatus = "online",
            authPaused = false,
            unreadCount = 0,
            pendingSubjectsBadgeCount = 0,
            lastSyncIso = null,
            isRefreshing = false,
            recentNotifications = emptyList(),
            activeSubjects = emptyList(),
        )
    }
}

object MielWidgetSnapshotStore {
    private const val REFRESH_TTL_MILLIS = 45_000L

    fun load(context: Context): WidgetSnapshotData {
        val prefs = context.getSharedPreferences(
            LibreMielWidgetBridgePlugin.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        val raw = prefs.getString(LibreMielWidgetBridgePlugin.KEY_SNAPSHOT_JSON, null)
            ?: return WidgetSnapshotData.signedOut()
        if (raw.isBlank()) return WidgetSnapshotData.signedOut()

        val startedAt = prefs.getLong(LibreMielWidgetBridgePlugin.KEY_REFRESH_STARTED_AT, 0L)
        val rawRefreshing = prefs.getBoolean(LibreMielWidgetBridgePlugin.KEY_IS_REFRESHING, false)
        val elapsed = System.currentTimeMillis() - startedAt
        val isRefreshing = rawRefreshing && startedAt > 0L && elapsed in 0L..REFRESH_TTL_MILLIS

        return try {
            val json = JSONObject(raw)
            val isAuthenticated = json.optBoolean("isAuthenticated", false)
            if (!isAuthenticated) {
                return WidgetSnapshotData.signedOut()
            }

            val notifsArray = json.optJSONArray("recentNotifications")
            val notifications = buildList {
                if (notifsArray != null) {
                    for (i in 0 until notifsArray.length()) {
                        val item = notifsArray.optJSONObject(i) ?: continue
                        add(
                            WidgetNotificationData(
                                id = item.optInt("id", 0),
                                idComision = item.optString("idComision", ""),
                                subjectName = item.optString("subjectName", ""),
                                module = item.optString("module", "novedades"),
                                title = item.optString("title", ""),
                                body = item.optString("body", ""),
                                targetUrl = item.optString("targetUrl", ""),
                                isRead = item.optBoolean("isRead", false),
                                createdAtIso = item.optString("createdAt", ""),
                            ),
                        )
                    }
                }
            }

            val subjectsArray = json.optJSONArray("activeSubjects")
            val subjects = buildList {
                if (subjectsArray != null) {
                    for (i in 0 until subjectsArray.length()) {
                        val item = subjectsArray.optJSONObject(i) ?: continue
                        val c = item.optInt("contenidosBadge", 0)
                        val m = item.optInt("mensajesBadge", 0)
                        val f = item.optInt("foroBadge", 0)
                        val total = item.optInt("totalBadges", c + m + f)
                        add(
                            WidgetSubjectData(
                                idComision = item.optString("idComision", ""),
                                name = item.optString("name", ""),
                                commissionCode = item.optString("commissionCode", ""),
                                totalBadges = total,
                                defaultTool = item.optString("defaultTool", "contenidos"),
                            ),
                        )
                    }
                }
            }

            WidgetSnapshotData(
                isAuthenticated = true,
                serverStatus = json.optString("serverStatus", "online"),
                authPaused = json.optBoolean("authPaused", false),
                unreadCount = json.optInt("unreadCount", 0),
                pendingSubjectsBadgeCount = json.optInt("pendingSubjectsBadgeCount", 0),
                lastSyncIso = json.optString("lastSyncAt", "").takeIf { it.isNotBlank() },
                isRefreshing = isRefreshing,
                recentNotifications = notifications,
                activeSubjects = subjects,
            )
        } catch (_: Exception) {
            WidgetSnapshotData.signedOut()
        }
    }

    fun setRefreshing(context: Context, refreshing: Boolean) {
        val prefs = context.getSharedPreferences(
            LibreMielWidgetBridgePlugin.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
        prefs.edit()
            .putBoolean(LibreMielWidgetBridgePlugin.KEY_IS_REFRESHING, refreshing)
            .putLong(
                LibreMielWidgetBridgePlugin.KEY_REFRESH_STARTED_AT,
                if (refreshing) System.currentTimeMillis() else 0L,
            )
            .commit()
    }

    fun formatTimeShort(rawIso: String?): String {
        if (rawIso.isNullOrBlank()) return "--:--"
        val parsed = parseIsoDate(rawIso)
        if (parsed != null) {
            val outFmt = SimpleDateFormat("HH:mm", Locale.getDefault())
            return outFmt.format(parsed)
        }
        val tIndex = rawIso.indexOf('T')
        if (tIndex != -1 && rawIso.length >= tIndex + 6) {
            return rawIso.substring(tIndex + 1, tIndex + 6)
        }
        return "--:--"
    }

    private fun parseIsoDate(rawIso: String): Date? {
        val trimmed = rawIso.trim()
        val hasUtc = trimmed.endsWith("Z", ignoreCase = true)
        val clean = trimmed
            .replace("Z", "", ignoreCase = true)
            .replace(Regex("""([+-]\d{2}:\d{2})$"""), "")
            .let { base ->
                val dotIdx = base.indexOf('.')
                if (dotIdx == -1) {
                    base
                } else {
                    val frac = base.substring(dotIdx + 1)
                    val ms = frac.take(3).padEnd(3, '0')
                    "${base.substring(0, dotIdx)}.$ms"
                }
            }

        val patterns = listOf("yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss")
        for (pattern in patterns) {
            try {
                val fmt = SimpleDateFormat(pattern, Locale.US).apply {
                    if (hasUtc) {
                        timeZone = TimeZone.getTimeZone("UTC")
                    }
                }
                val parsed = fmt.parse(clean)
                if (parsed != null) return parsed
            } catch (_: Exception) {
                // Probar siguiente formato
            }
        }
        return null
    }
}
