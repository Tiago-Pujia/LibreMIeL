import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/models/miel_models.dart';
import '../core/storage/app_database.dart';
import 'android_widget_models.dart';
import 'notification_service.dart';

enum AndroidWidgetKind { compact, feed }

/// Servicio puente entre LibreMIeL (UI o isolate de `WorkManager`) y los
/// `AppWidgetProvider` nativos en Android a través de `libremiel_android_widget`.
class AndroidWidgetService {
  const AndroidWidgetService({
    MethodChannel? channel,
    this.isAndroidOverride,
    this.snapshotBuilder = const AndroidWidgetSnapshotBuilder(),
  }) : _channel = channel ?? _defaultChannel;

  static const String channelName =
      'io.github.tiago_pujia.libremiel/android_widget';
  static const MethodChannel _defaultChannel = MethodChannel(channelName);

  /// Stream global para abrir módulos internos cuando el usuario toca un widget
  /// con la app ya en ejecución (*warm start*).
  static final StreamController<NotificationTapPayload> onWidgetTapped =
      StreamController<NotificationTapPayload>.broadcast();

  static bool _handlerRegistered = false;

  final MethodChannel _channel;
  @visibleForTesting
  final bool? isAndroidOverride;
  final AndroidWidgetSnapshotBuilder snapshotBuilder;

  bool get isSupported => isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);

  /// Registra el receptor de toques desde widgets cuando la app está abierta.
  Future<void> initialize({bool forceRegisterHandler = false}) async {
    if (!isSupported) return;
    if (_handlerRegistered && !forceRegisterHandler) return;
    _channel.setMethodCallHandler(_handleNativeCall);
    _handlerRegistered = true;
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onWidgetTapped') {
      final payload = parseTapPayload(call.arguments);
      if (payload != null) {
        onWidgetTapped.add(payload);
      }
    }
    return null;
  }

  /// Parsea un payload recibido desde Kotlin (JSON String o Map).
  static NotificationTapPayload? parseTapPayload(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return NotificationTapPayload.fromJson(decoded);
        }
        if (decoded is Map) {
          return NotificationTapPayload.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } else if (raw is Map<String, dynamic>) {
        return NotificationTapPayload.fromJson(raw);
      } else if (raw is Map) {
        return NotificationTapPayload.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  /// Envía la instantánea serializada al puente nativo para persistirla en
  /// `SharedPreferences` y disparar `ACTION_APPWIDGET_UPDATE`.
  Future<void> updateSnapshot(AndroidWidgetSnapshot snapshot) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('updateSnapshot', <String, dynamic>{
        'snapshotJson': snapshot.toJsonString(),
      });
    } catch (_) {}
  }

  /// Construye la instantánea desde [database] y actualiza los widgets Android.
  Future<void> syncFromDatabase({
    required AppDatabase database,
    required bool isAuthenticated,
    required MielServerStatus serverStatus,
    bool? authPaused,
    DateTime? lastSyncAt,
    DateTime? lastOnlineSuccessAt,
  }) async {
    if (!isSupported) return;
    if (!isAuthenticated) {
      await clearSnapshot();
      return;
    }
    final snapshot = await snapshotBuilder.buildFromDatabase(
      database: database,
      isAuthenticated: isAuthenticated,
      serverStatus: serverStatus,
      authPaused: authPaused,
      lastSyncAt: lastSyncAt,
      lastOnlineSuccessAt: lastOnlineSuccessAt,
    );
    await updateSnapshot(snapshot);
  }

  /// Limpia inmediatamente los datos persistidos y redibuja en estado "Sesión cerrada".
  Future<void> clearSnapshot() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('clearSnapshot');
    } catch (_) {}
  }

  /// Consume el payload de apertura si la app fue iniciada desde un widget (*cold start*).
  Future<NotificationTapPayload?> consumeInitialTapPayload() async {
    if (!isSupported) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'consumeInitialLaunchPayload',
      );
      return parseTapPayload(raw);
    } catch (_) {
      return null;
    }
  }

  /// Indica si el launcher actual en Android 8.0+ soporta fijar widgets desde la app.
  Future<bool> isPinWidgetSupported() async {
    if (!isSupported) return false;
    try {
      return (await _channel.invokeMethod<bool>('isPinWidgetSupported')) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Solicita al sistema fijar uno de los widgets de LibreMIeL en la pantalla de inicio.
  Future<bool> requestPinWidget(AndroidWidgetKind kind) async {
    if (!isSupported) return false;
    try {
      return (await _channel.invokeMethod<bool>(
            'requestPinWidget',
            <String, dynamic>{'kind': kind.name},
          )) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
