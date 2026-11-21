import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/miel_models.dart';

/// Servicio multiplataforma de notificaciones nativas (Android, Linux, Windows, macOS).
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _androidChannelId = 'libremiel_updates';
  static const String _androidChannelName = 'Novedades de MIeL';
  static const String _androidChannelDesc =
      'Avisos de Contenidos, Portafolio, Mensajería y Foros en MIeL (UNLaM)';
  static const String _windowsAppUserModelId = 'LibreMIeL.UNLaM.Desktop.1';
  static const String _windowsGuid = '7c3a8d12-4b65-4e9a-9f11-84c0a5c8f310';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir en MIeL'),
      windows: WindowsInitializationSettings(
        appName: 'LibreMIeL',
        appUserModelId: _windowsAppUserModelId,
        guid: _windowsGuid,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> showBatch(List<DetectedNotification> notifications) async {
    if (notifications.isEmpty || kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    for (final n in notifications) {
      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        linux: const LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        ),
        macOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      );

      await _plugin.show(
        id: n.dedupeKey.hashCode & 0x7fffffff,
        title: n.title,
        body: n.body,
        notificationDetails: details,
        payload: n.targetUrl,
      );
    }
  }

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    final url = response.payload;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
