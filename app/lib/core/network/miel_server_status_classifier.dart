import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/miel_models.dart';

/// Detecta si una cadena HTML recibida corresponde a una página de caída,
/// mantenimiento o error del servidor web (Apache, Nginx, PHP 5xx) de MIeL.
bool isLikelyMielMaintenanceHtml(String html) {
  if (html.isEmpty) return false;
  final lower = html.toLowerCase();
  return lower.contains('502 bad gateway') ||
      lower.contains('503 service') ||
      lower.contains('504 gateway time-out') ||
      lower.contains('service temporarily unavailable') ||
      lower.contains('internal server error') ||
      (lower.contains('mantenimiento') && lower.contains('servidor'));
}

/// Clasifica deterministamente una excepción o error de red en:
/// - [MielServerStatus.deviceOffline]: el dispositivo local no tiene conexión, interfaz o DNS.
/// - [MielServerStatus.mielDown]: MIeL está caído (5xx, Connection refused, TLS, timeout del servidor).
MielServerStatus classifyMielNetworkError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      return MielServerStatus.mielDown;
    }

    final inner = error.error;
    if (inner != null) {
      return classifyMielNetworkError(inner);
    }

    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionTimeout) {
      return MielServerStatus.mielDown;
    }

    if (error.type == DioExceptionType.connectionError) {
      final msg = error.message?.toLowerCase() ?? '';
      if (_isDeviceOfflineString(msg)) {
        return MielServerStatus.deviceOffline;
      }
      return MielServerStatus.mielDown;
    }
  }

  if (error is SocketException) {
    final osMsg = error.osError?.message.toLowerCase() ?? '';
    final msg = error.message.toLowerCase();
    final combined = '$msg $osMsg';

    if (_isMielDownSocketString(combined)) {
      return MielServerStatus.mielDown;
    }
    if (_isDeviceOfflineString(combined)) {
      return MielServerStatus.deviceOffline;
    }
    // Por defecto ante fallo de socket sin ruta/lookup
    return MielServerStatus.deviceOffline;
  }

  if (error is HandshakeException ||
      error is TlsException ||
      error is CertificateException) {
    return MielServerStatus.mielDown;
  }

  if (error is TimeoutException) {
    return MielServerStatus.mielDown;
  }

  if (error is HttpException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('504') ||
        msg.contains('mantenimiento') ||
        msg.contains('refused')) {
      return MielServerStatus.mielDown;
    }
    if (_isDeviceOfflineString(msg)) {
      return MielServerStatus.deviceOffline;
    }
    return MielServerStatus.mielDown;
  }

  final str = error.toString().toLowerCase();
  if (_isDeviceOfflineString(str)) {
    return MielServerStatus.deviceOffline;
  }
  if (_isMielDownSocketString(str) ||
      str.contains('502') ||
      str.contains('503') ||
      str.contains('504') ||
      str.contains('500')) {
    return MielServerStatus.mielDown;
  }

  return MielServerStatus.mielDown;
}

bool _isDeviceOfflineString(String s) {
  return s.contains('failed host lookup') ||
      s.contains('no address associated') ||
      s.contains('network is unreachable') ||
      s.contains('no route to host') ||
      s.contains('temporary failure in name resolution') ||
      s.contains('enotfound') ||
      s.contains('ehostunreach') ||
      s.contains('enetunreach');
}

bool _isMielDownSocketString(String s) {
  return s.contains('connection refused') ||
      s.contains('connection reset') ||
      s.contains('broken pipe') ||
      s.contains('econnrefused') ||
      s.contains('econnreset') ||
      s.contains('handshake') ||
      s.contains('software caused connection abort');
}
