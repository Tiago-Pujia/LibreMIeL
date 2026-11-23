import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';

import '../core/models/miel_models.dart';

/// Genera un identificador de notificación positivo de 31 bits determinista
/// (FNV-1a sobre UTF-8), consistente entre isolates y reinicios del proceso.
int deterministicNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final positive = hash & 0x7fffffff;
  return positive == 0 ? 1 : positive;
}

/// Payload estructurado para responder al toque de una notificación nativa o widget.
class NotificationTapPayload {
  const NotificationTapPayload({
    required this.idComision,
    required this.module,
    required this.targetUrl,
    this.notificationId,
  });

  final String idComision;
  final String module;
  final String targetUrl;
  final int? notificationId;

  Map<String, dynamic> toJson() => {
    'idComision': idComision,
    'module': module,
    'targetUrl': targetUrl,
    if (notificationId != null) 'notificationId': notificationId,
  };

  factory NotificationTapPayload.fromJson(Map<String, dynamic> json) =>
      NotificationTapPayload(
        idComision: json['idComision'] as String? ?? '',
        module: json['module'] as String? ?? '',
        targetUrl: json['targetUrl'] as String? ?? '',
        notificationId: (json['notificationId'] as num?)?.toInt(),
      );
}

/// Servicio multiplataforma de notificaciones nativas (Android, Linux, Windows, macOS).
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    this.isAndroidOverride,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  @visibleForTesting
  final bool? isAndroidOverride;
  bool _initialized = false;
  bool _permissionsRequested = false;

  bool get _isAndroid => isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);

  /// Stream global para notificar a la app cuando el usuario pulsa una notificación.
  static final StreamController<NotificationTapPayload> onNotificationTapped =
      StreamController<NotificationTapPayload>.broadcast();

  static const String androidSmallIcon = 'ic_stat_libremiel';
  static const String androidUpdatesChannelId = 'libremiel_updates';
  static const String androidUpdatesChannelName = 'Novedades de MIeL';
  static const String androidUpdatesChannelDesc =
      'Avisos de Contenidos, Portafolio, Mensajería, Foros y Evaluaciones en MIeL (UNLaM)';
  static const String androidSystemChannelId = 'libremiel_system';
  static const String androidSystemChannelName = 'Sistema y actualizaciones';
  static const String androidSystemChannelDesc =
      'Actualizaciones de LibreMIeL y avisos de recuperación de los servidores de MIeL';
  static const String _windowsAppUserModelId = 'LibreMIeL.UNLaM.Desktop.1';
  static const String _windowsGuid = '7c3a8d12-4b65-4e9a-9f11-84c0a5c8f310';
  static const Color _mielEmerald = Color(0xFF009674);

  /// Inicializa el plugin nativo y los canales de Android.
  ///
  /// En ejecuciones en segundo plano sin `Activity` (por ejemplo, `WorkManager`),
  /// **debe** invocarse con `requestPermissions: false` porque
  /// `requestNotificationsPermission()` en Android requiere una `Activity` activa.
  Future<void> initialize({bool requestPermissions = true}) async {
    if (kIsWeb) return;

    if (_initialized) {
      if (requestPermissions && !_permissionsRequested && _isAndroid) {
        await _requestAndroidPermissionSafely();
      }
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
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

    if (_isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (requestPermissions) {
        await _requestAndroidPermissionSafely(androidPlugin: androidPlugin);
      }

      const updatesChannel = AndroidNotificationChannel(
        androidUpdatesChannelId,
        androidUpdatesChannelName,
        description: androidUpdatesChannelDesc,
        importance: Importance.high,
        enableLights: true,
        ledColor: _mielEmerald,
      );
      const systemChannel = AndroidNotificationChannel(
        androidSystemChannelId,
        androidSystemChannelName,
        description: androidSystemChannelDesc,
        importance: Importance.defaultImportance,
        enableLights: true,
        ledColor: _mielEmerald,
      );
      await androidPlugin?.createNotificationChannel(updatesChannel);
      await androidPlugin?.createNotificationChannel(systemChannel);
    }

    _initialized = true;
  }

  Future<void> _requestAndroidPermissionSafely({
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  }) async {
    try {
      final plugin =
          androidPlugin ??
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await plugin?.requestNotificationsPermission();
      _permissionsRequested = true;
    } catch (e, st) {
      debugPrint('No se pudo solicitar permiso de notificaciones: $e\n$st');
    }
  }

  /// Consulta en Android si las notificaciones del sistema están habilitadas.
  Future<bool?> areNotificationsEnabled() async {
    if (kIsWeb || !_isAndroid) return null;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled();
    } catch (_) {
      return null;
    }
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
        await initialize(requestPermissions: false);
      }

      final byCommission = <String, List<DetectedNotification>>{};

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

        final groupKey = _groupKeyFor(n.idComision);

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            androidUpdatesChannelId,
            androidUpdatesChannelName,
            channelDescription: androidUpdatesChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            color: _mielEmerald,
            subText: n.subjectName,
            styleInformation: styleInformation,
            category: category,
            groupKey: groupKey,
            groupAlertBehavior: GroupAlertBehavior.children,
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
            id: deterministicNotificationId(n.dedupeKey),
            title: n.title,
            body: n.body,
            notificationDetails: details,
            payload: payload,
          );
          if (groupKey != null) {
            (byCommission[n.idComision] ??= []).add(n);
          }
        } catch (e, st) {
          debugPrint(
            'Error emitiendo notificación nativa (${n.dedupeKey}): $e\n$st',
          );
        }
      }

      // En Android, emitir una notificación resumen silenciosa por cada comisión
      // con 2 o más novedades para que el sistema las agrupe prolijamente.
      if (_isAndroid) {
        for (final entry in byCommission.entries) {
          final items = entry.value;
          if (items.length < 2) continue;
          final idComision = entry.key;
          final subjectName = items.first.subjectName;
          final groupKey = _groupKeyFor(idComision);
          if (groupKey == null) continue;

          final summaryTitle = subjectName.isNotEmpty
              ? subjectName
              : 'Novedades de MIeL';
          final summaryBody = '${items.length} novedades nuevas';
          final lines = items
              .take(5)
              .map((n) => '${n.title}: ${n.body}')
              .toList(growable: false);

          final summaryPayload = jsonEncode(
            NotificationTapPayload(
              idComision: idComision,
              module: items.first.module.name,
              targetUrl: items.first.targetUrl,
            ).toJson(),
          );

          final summaryDetails = NotificationDetails(
            android: AndroidNotificationDetails(
              androidUpdatesChannelId,
              androidUpdatesChannelName,
              channelDescription: androidUpdatesChannelDesc,
              importance: Importance.high,
              priority: Priority.high,
              color: _mielEmerald,
              subText: subjectName,
              styleInformation: InboxStyleInformation(
                lines,
                contentTitle: summaryTitle,
                summaryText: summaryBody,
              ),
              groupKey: groupKey,
              setAsGroupSummary: true,
              groupAlertBehavior: GroupAlertBehavior.children,
              channelShowBadge: true,
              enableLights: true,
              ledColor: _mielEmerald,
              ledOnMs: 1000,
              ledOffMs: 500,
            ),
          );

          try {
            await _plugin.show(
              id: deterministicNotificationId('group:$idComision'),
              title: summaryTitle,
              body: summaryBody,
              notificationDetails: summaryDetails,
              payload: summaryPayload,
            );
          } catch (e, st) {
            debugPrint(
              'Error emitiendo resumen de grupo ($idComision): $e\n$st',
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('Error general en showBatch: $e\n$st');
    }
  }

  String? _groupKeyFor(String idComision) {
    if (idComision.isEmpty ||
        idComision == 'global' ||
        idComision == 'sistema') {
      return null;
    }
    return 'io.github.tiago_pujia.libremiel.$idComision';
  }

  Future<void> showUpdateNotification({
    required String version,
    required String releaseNotes,
    String? assetName,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize(requestPermissions: false);
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
          androidSystemChannelId,
          androidSystemChannelName,
          channelDescription: androidSystemChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
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
        id: deterministicNotificationId(dedupeKey),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('Error emitiendo notificación de actualización: $e\n$st');
    }
  }

  /// Notifica que los servidores de MIeL volvieron a responder normalmente tras una caída.
  Future<void> showMielRecoveredNotification() async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize(requestPermissions: false);
      }

      const title = 'MIeL volvió a estar en línea';
      const body =
          'Los servidores de MIeL (UNLaM) respondieron normalmente y se reanudó la sincronización.';

      final payload = jsonEncode(
        const NotificationTapPayload(
          idComision: 'sistema',
          module: 'sistema',
          targetUrl: '',
        ).toJson(),
      );

      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          androidSystemChannelId,
          androidSystemChannelName,
          channelDescription: androidSystemChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: _mielEmerald,
          subText: 'Conexión restablecida',
          category: AndroidNotificationCategory.status,
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

      await _plugin.show(
        id: deterministicNotificationId('miel_recovered'),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint(
        'Error emitiendo notificación de recuperación de MIeL: $e\n$st',
      );
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
