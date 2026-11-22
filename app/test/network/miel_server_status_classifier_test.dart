import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/network/miel_server_status_classifier.dart';

void main() {
  group('isLikelyMielMaintenanceHtml', () {
    test('returns false for empty or normal HTML', () {
      expect(isLikelyMielMaintenanceHtml(''), isFalse);
      expect(
        isLikelyMielMaintenanceHtml(
          '<html><body><h1>Bienvenido a MIeL</h1></body></html>',
        ),
        isFalse,
      );
      expect(
        isLikelyMielMaintenanceHtml('<div class="comision">Contenido</div>'),
        isFalse,
      );
    });

    test('detects 502 Bad Gateway', () {
      expect(
        isLikelyMielMaintenanceHtml(
          '<html><head><title>502 Bad Gateway</title></head><body><center><h1>502 Bad Gateway</h1></center><hr><center>nginx</center></body></html>',
        ),
        isTrue,
      );
    });

    test('detects 503 Service Unavailable', () {
      expect(
        isLikelyMielMaintenanceHtml(
          '<html><body>503 Service Temporarily Unavailable</body></html>',
        ),
        isTrue,
      );
    });

    test('detects 504 Gateway Time-out', () {
      expect(
        isLikelyMielMaintenanceHtml(
          '<html><body>504 Gateway Time-out</body></html>',
        ),
        isTrue,
      );
    });

    test('detects Internal Server Error', () {
      expect(
        isLikelyMielMaintenanceHtml(
          '<html><body>500 Internal Server Error</body></html>',
        ),
        isTrue,
      );
    });

    test('detects maintenance message with server keyword', () {
      expect(
        isLikelyMielMaintenanceHtml(
          '<p>El servidor se encuentra en mantenimiento programado.</p>',
        ),
        isTrue,
      );
    });
  });

  group('classifyMielNetworkError', () {
    test('classifies Dio 5xx response as mielDown', () {
      final dio502 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 502,
        ),
      );
      expect(classifyMielNetworkError(dio502), MielServerStatus.mielDown);

      final dio500 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 500,
        ),
      );
      expect(classifyMielNetworkError(dio500), MielServerStatus.mielDown);
    });

    test('classifies Dio timeouts as mielDown', () {
      final sendTimeout = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.sendTimeout,
      );
      expect(classifyMielNetworkError(sendTimeout), MielServerStatus.mielDown);

      final receiveTimeout = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(
        classifyMielNetworkError(receiveTimeout),
        MielServerStatus.mielDown,
      );

      final connTimeout = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(classifyMielNetworkError(connTimeout), MielServerStatus.mielDown);
    });

    test(
      'classifies Dio connectionError with DNS failure as deviceOffline',
      () {
        final dnsError = DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
          message: 'Failed host lookup: miel.unlam.edu.ar',
        );
        expect(
          classifyMielNetworkError(dnsError),
          MielServerStatus.deviceOffline,
        );
      },
    );

    test('classifies SocketException connection refused as mielDown', () {
      const socketRefused = SocketException(
        'OS Error: Connection refused, errno = 111',
        osError: OSError('Connection refused', 111),
      );
      expect(
        classifyMielNetworkError(socketRefused),
        MielServerStatus.mielDown,
      );
    });

    test('classifies SocketException host lookup failure as deviceOffline', () {
      const socketDns = SocketException(
        'Failed host lookup: miel.unlam.edu.ar',
        osError: OSError('No address associated with hostname', 7),
      );
      expect(
        classifyMielNetworkError(socketDns),
        MielServerStatus.deviceOffline,
      );

      const netUnreach = SocketException(
        'Network is unreachable',
        osError: OSError('Network is unreachable', 101),
      );
      expect(
        classifyMielNetworkError(netUnreach),
        MielServerStatus.deviceOffline,
      );
    });

    test('classifies HandshakeException and TlsException as mielDown', () {
      const handshake = HandshakeException('Handshake error in client');
      expect(classifyMielNetworkError(handshake), MielServerStatus.mielDown);

      const tls = TlsException('SSL connection closed');
      expect(classifyMielNetworkError(tls), MielServerStatus.mielDown);
    });

    test('classifies TimeoutException as mielDown', () {
      final timeout = TimeoutException('Operation timed out');
      expect(classifyMielNetworkError(timeout), MielServerStatus.mielDown);
    });

    test('classifies HttpException with 502/mantenimiento as mielDown', () {
      const http502 = HttpException('502 Bad Gateway');
      expect(classifyMielNetworkError(http502), MielServerStatus.mielDown);

      const httpMaint = HttpException('Servidor en mantenimiento');
      expect(classifyMielNetworkError(httpMaint), MielServerStatus.mielDown);
    });
  });
}
