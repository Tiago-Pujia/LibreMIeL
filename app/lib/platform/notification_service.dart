import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';

import '../core/models/miel_models.dart';

/// Payload estructurado para responder al toque de una notificación nativa.
class NotificationTapPayload {
  const NotificationTapPayload({
    required this.idComision,
    required this.module,
    required this.targetUrl,
  });

  final String idComision;
  final String module;
  final String targetUrl;

  Map<String, dynamic> toJson() => {
    'idComision': idComision,
    'module': module,
    'targetUrl': targetUrl,
  };

  factory NotificationTapPayload.fromJson(Map<String, dynamic> json) =>
      NotificationTapPayload(
        idComision: json['idComision'] as String? ?? '',
        module: json['module'] as String? ?? '',
        targetUrl: json['targetUrl'] as String? ?? '',
      );
}

/// Servicio multiplataforma de notificaciones nativas (Android, Linux, Windows, macOS).
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Stream global para notificar a la app cuando el usuario pulsa una notificación.
  static final StreamController<NotificationTapPayload> onNotificationTapped =
      StreamController<NotificationTapPayload>.broadcast();

  static const String _androidChannelId = 'libremiel_updates';
  static const String _androidChannelName = 'Novedades de MIeL';
  static const String _androidChannelDesc =
      'Avisos de Contenidos, Portafolio, Mensajería y Foros en MIeL (UNLaM)';
  static const String _windowsAppUserModelId = 'LibreMIeL.UNLaM.Desktop.1';
  static const String _windowsGuid = '7c3a8d12-4b65-4e9a-9f11-84c0a5c8f310';
  static const Color _mielEmerald = Color(0xFF009674);

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir LibreMIeL'),
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
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
        enableLights: true,
        ledColor: _mielEmerald,
      );
      await androidPlugin?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Retorna los detalles de lanzamiento si la app fue abierta al pulsar una notificación.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    if (kIsWeb) return null;
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } catch (_) {
      return null;
    }
  }

  Future<void> showBatch(List<DetectedNotification> notifications) async {
    if (notifications.isEmpty || kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize();
      }

      for (final n in notifications) {
        final styleInformation = BigTextStyleInformation(
          n.body,
          contentTitle: n.title,
          summaryText: n.subjectName,
        );

        final payload = jsonEncode(
          NotificationTapPayload(
            idComision: n.idComision,
            module: n.module.name,
            targetUrl: n.targetUrl,
          ).toJson(),
        );

        final category = switch (n.module) {
          MielModuleType.mensajeria => AndroidNotificationCategory.message,
          MielModuleType.foros => AndroidNotificationCategory.social,
          _ => AndroidNotificationCategory.event,
        };

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: _mielEmerald,
            subText: n.subjectName,
            styleInformation: styleInformation,
            category: category,
            groupKey: 'io.github.tiago_pujia.libremiel.${n.idComision}',
            channelShowBadge: true,
            enableLights: true,
            ledColor: _mielEmerald,
            ledOnMs: 1000,
            ledOffMs: 500,
          ),
          linux: const LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.normal,
          ),
          macOS: const DarwinNotificationDetails(),
          windows: const WindowsNotificationDetails(),
        );

        try {
          await _plugin.show(
            id: n.dedupeKey.hashCode & 0x7fffffff,
            title: n.title,
            body: n.body,
            notificationDetails: details,
            payload: payload,
          );
        } catch (e, st) {
          debugPrint(
            'Error emitiendo notificación nativa (${n.dedupeKey}): $e\n$st',
          );
        }
      }
    } catch (e, st) {
      debugPrint('Error general en showBatch: $e\n$st');
    }
  }

  Future<void> showUpdateNotification({
    required String version,
    required String releaseNotes,
    String? assetName,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize();
      }

      final title = 'Actualización disponible: LibreMIeL v$version';
      final cleanNotes = releaseNotes.trim();
      final body = cleanNotes.isNotEmpty
          ? cleanNotes.split('\n').first.trim()
          : 'Hay una nueva versión disponible con mejoras y correcciones.';

      final styleInformation = BigTextStyleInformation(
        cleanNotes.isNotEmpty ? cleanNotes : body,
        contentTitle: title,
        summaryText: 'LibreMIeL v$version',
      );

      final payload = jsonEncode(
        const NotificationTapPayload(
          idComision: '',
          module: 'app_update',
          targetUrl: 'libremiel://update',
        ).toJson(),
      );

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: _mielEmerald,
          subText: 'Actualización disponible',
          styleInformation: styleInformation,
          category: AndroidNotificationCategory.status,
          channelShowBadge: true,
          enableLights: true,
          ledColor: _mielEmerald,
          ledOnMs: 1000,
          ledOffMs: 500,
        ),
        linux: const LinuxNotificationDetails(
          urgency: LinuxNotificationUrgency.normal,
        ),
        macOS: const DarwinNotificationDetails(),
        windows: const WindowsNotificationDetails(),
      );

      final dedupeKey = 'app_update_$version';
      await _plugin.show(
        id: dedupeKey.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('Error emitiendo notificación de actualización: $e\n$st');
    }
  }

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    // Si la app está en escritorio, traer la ventana al frente
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      try {
        await windowManager.show();
        await windowManager.focus();
      } catch (_) {}
    }

    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        onNotificationTapped.add(NotificationTapPayload.fromJson(decoded));
      }
    } catch (_) {
      // Ignorar payloads no serializados como JSON
    }
  }
}
