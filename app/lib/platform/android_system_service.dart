import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio puente hacia APIs nativas de sistema de Android (batería y ajustes
/// de notificaciones) expuesto por `MainActivity.kt`.
class AndroidSystemService {
  const AndroidSystemService({MethodChannel? channel, this.isAndroidOverride})
    : _channel = channel ?? _defaultChannel;

  static const MethodChannel _defaultChannel = MethodChannel(
    'io.github.tiago_pujia.libremiel/android_system',
  );

  final MethodChannel _channel;
  @visibleForTesting
  final bool? isAndroidOverride;

  bool get isSupported => isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);

  /// Devuelve `true` si Android ya exime a LibreMIeL de las optimizaciones de
  /// batería ("Sin restricciones"), `false` si está optimizada/restringida, o
  /// `null` si no aplica o no pudo determinarse.
  Future<bool?> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
    } catch (_) {
      return null;
    }
  }

  /// Abre el diálogo nativo para solicitar "Sin restricciones" de batería o,
  /// como respaldo en capas OEM restrictivas, la pantalla de ajustes correspondiente.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!isSupported) return false;
    try {
      return (await _channel.invokeMethod<bool>(
            'requestIgnoreBatteryOptimizations',
          )) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la configuración nativa de notificaciones y canales de LibreMIeL en Android.
  Future<bool> openAppNotificationSettings() async {
    if (!isSupported) return false;
    try {
      return (await _channel.invokeMethod<bool>(
            'openAppNotificationSettings',
          )) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
