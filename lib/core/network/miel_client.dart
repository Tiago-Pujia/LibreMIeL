import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/miel_models.dart';
import '../parsers/text_normalizer.dart';

/// Contrato abstracto de acceso HTTP de solo lectura a MIEL.
///
/// Nota de diseño: intencionalmente NO expone `/mensajeria/verEntrada/...`
/// para impedir que el motor de sincronización marque mensajes como leídos.
abstract class MielApiClient {
  Future<MielLoginResult> login(
    String username,
    String password, {
    bool remember = true,
  });

  Future<bool> isLogged();
  Future<void> refreshSession();
  Future<void> clearSession();

  Future<String> fetchInternoHtml();
  Future<String> fetchCursoDetallesHtml(String idComision);
  Future<String> fetchContenidosHtml(String idComision);
  Future<String> fetchPortafolioPracticasHtml(String idComision);
  Future<String> fetchPortafolioEntregasHtml(
    String idComision,
    String idPractica,
  );
  Future<String> fetchMensajeriaEntradaHtml(String idComision);
  Future<String> fetchForoTemasHtml(String idComision);
  Future<String> fetchForoMensajesHtml(String idComision, String idTema);
  Future<String> fetchEvaluacionesHtml(String idComision);
}

/// Cliente HTTP nativo de LibreMIEL basado en `Dio` + `CookieJar`.
///
/// - Mantiene `PHPSESSID` y `SESSID` (afinidad de nodo).
/// - Ejecuta peticiones de forma secuencial para no sobrecargar los servidores de UNLaM.
/// - Aplica backoff exponencial únicamente en errores transitorios (`5xx` / timeout).
class DioMielClient implements MielApiClient {
  DioMielClient({
    required this._cookieJar,
    Dio? dio,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 600),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: kMielBaseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 25),
               followRedirects: true,
               maxRedirects: 5,
               responseType: ResponseType.plain,
               headers: const {
                 'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 LibreMIEL/0.1',
                 'Accept-Language': 'es-AR,es;q=0.9',
               },
               validateStatus: (status) => status != null && status < 500,
             ),
           ) {
    final alreadyHasCookieMgr = _dio.interceptors.any(
      (i) => i is CookieManager,
    );
    if (!alreadyHasCookieMgr) {
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
  }

  /// Crea una instancia persistiendo las cookies en el directorio de soporte local.
  static Future<DioMielClient> createPersistent() async {
    final supportDir = await getApplicationSupportDirectory();
    final cookieDir = Directory(p.join(supportDir.path, 'miel_cookies'));
    if (!cookieDir.existsSync()) {
      cookieDir.createSync(recursive: true);
    }
    final jar = PersistCookieJar(storage: FileStorage(cookieDir.path));
    return DioMielClient(cookieJar: jar);
  }

  final CookieJar _cookieJar;
  final Dio _dio;
  final int maxRetries;
  final Duration initialBackoff;

  Future<void> _serialQueue = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _serialQueue = _serialQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (err, st) {
        completer.completeError(err, st);
      }
    });
    return completer.future;
  }

  Future<Response<String>> _requestWithBackoff(
    Future<Response<String>> Function() send,
  ) async {
    var delay = initialBackoff;
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await send();
        final status = response.statusCode ?? 0;
        if (status >= 500 && attempt < maxRetries) {
          await Future<void>.delayed(delay);
          delay *= 2;
          continue;
        }
        return response;
      } on DioException catch (e) {
        final isTransient =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response?.statusCode ?? 0) >= 500;
        if (isTransient && attempt < maxRetries) {
          await Future<void>.delayed(delay);
          delay *= 2;
          continue;
        }
        rethrow;
      }
    }
  }

  @override
  Future<MielLoginResult> login(
    String username,
    String password, {
    bool remember = true,
  }) {
    return _enqueue(() async {
      try {
        // 1. Obtener PHPSESSID y SESSID iniciales en /principal/home/
        final homeUri = Uri.parse('$kMielBaseUrl/principal/home/');
        final existingCookies = await _cookieJar.loadForRequest(homeUri);
        if (existingCookies.isEmpty) {
          await _requestWithBackoff(() => _dio.get<String>('/principal/home/'));
        }

        // 2. Enviar credenciales en application/x-www-form-urlencoded (sin CSRF/CAPTCHA)
        final payload = <String, dynamic>{
          'usuario': username.trim(),
          'clave': password,
          if (remember) 'recordar': 'on',
        };

        final response = await _requestWithBackoff(
          () => _dio.post<String>(
            '/principal/event/login/',
            data: payload,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: const {
                'X-Requested-With': 'XMLHttpRequest',
                'Referer': '$kMielBaseUrl/principal/home/',
              },
            ),
          ),
        );

        final rawBody = (response.data ?? '').trim();
        Map<String, dynamic> decoded;
        try {
          final parsed = jsonDecode(rawBody);
          if (parsed is! Map<String, dynamic>) {
            return const MielLoginResult(
              status: MielAuthStatus.invalidResponse,
              message: 'Respuesta inesperada del servidor de MIEL.',
            );
          }
          decoded = parsed;
        } catch (_) {
          return const MielLoginResult(
            status: MielAuthStatus.invalidResponse,
            message: 'No se pudo interpretar la respuesta de login de MIEL.',
          );
        }

        final estado = decoded['estado'] is int
            ? decoded['estado'] as int
            : int.tryParse('${decoded['estado']}');

        switch (estado) {
          case 0:
            return const MielLoginResult(status: MielAuthStatus.ok, rawCode: 0);
          case 1:
          case 2:
            return MielLoginResult(
              status: MielAuthStatus.invalidCredentials,
              rawCode: estado,
              message: 'Usuario o contraseña incorrectos en MIEL.',
            );
          case 3:
            return const MielLoginResult(
              status: MielAuthStatus.accountBlocked,
              rawCode: 3,
              message: 'Tu cuenta de MIEL figura bloqueada (estado 3).',
            );
          default:
            return MielLoginResult(
              status: MielAuthStatus.invalidResponse,
              rawCode: estado,
              message: 'Código de respuesta desconocido en login: $estado.',
            );
        }
      } on DioException catch (e) {
        return MielLoginResult(
          status: MielAuthStatus.networkError,
          message:
              'Error de red al conectar con MIEL: ${e.message ?? e.type.name}',
        );
      }
    });
  }

  @override
  Future<bool> isLogged() {
    return _enqueue(() async {
      try {
        final response = await _requestWithBackoff(
          () => _dio.get<String>(
            '/principal/event/isLogged/',
            options: Options(
              headers: const {'X-Requested-With': 'XMLHttpRequest'},
            ),
          ),
        );
        return (response.data ?? '').trim() == '1';
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Future<void> refreshSession() {
    return _enqueue(() async {
      await _requestWithBackoff(
        () => _dio.get<String>(
          '/principal/event/recargarSesion/',
          options: Options(
            headers: const {'X-Requested-With': 'XMLHttpRequest'},
          ),
        ),
      );
    });
  }

  @override
  Future<void> clearSession() {
    return _enqueue(() async {
      await _cookieJar.deleteAll();
    });
  }

  Future<String> _getHtml(String path) {
    return _enqueue(() async {
      final response = await _requestWithBackoff(() => _dio.get<String>(path));
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 400) {
        throw HttpException('MIEL respondió HTTP $status al consultar $path');
      }
      return response.data ?? '';
    });
  }

  @override
  Future<String> fetchInternoHtml() => _getHtml('/principal/interno/');

  @override
  Future<String> fetchCursoDetallesHtml(String idComision) =>
      _getHtml('/principal/cursoDetalles/id/$idComision');

  @override
  Future<String> fetchContenidosHtml(String idComision) =>
      _getHtml('/contenido/archivos/comision/$idComision');

  @override
  Future<String> fetchPortafolioPracticasHtml(String idComision) =>
      _getHtml('/portafolio/practicas/comision/$idComision');

  @override
  Future<String> fetchPortafolioEntregasHtml(
    String idComision,
    String idPractica,
  ) => _getHtml('/portafolio/entregas/comision/$idComision/id/$idPractica');

  @override
  Future<String> fetchMensajeriaEntradaHtml(String idComision) =>
      _getHtml('/mensajeria/entrada/comision/$idComision');

  @override
  Future<String> fetchForoTemasHtml(String idComision) =>
      _getHtml('/forov2/temas/comision/$idComision');

  @override
  Future<String> fetchForoMensajesHtml(String idComision, String idTema) =>
      _getHtml('/forov2/mensajes/comision/$idComision/tema/$idTema');

  @override
  Future<String> fetchEvaluacionesHtml(String idComision) =>
      _getHtml('/evaluacion/evaluaciones/comision/$idComision');
}
