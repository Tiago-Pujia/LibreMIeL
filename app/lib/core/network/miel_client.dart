import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/miel_models.dart';
import '../parsers/text_normalizer.dart';

export '../parsers/text_normalizer.dart' show kMielBaseUrl;

/// Resultado de una descarga autenticada de archivo desde MIeL.
class DownloadedFileResult {
  const DownloadedFileResult({
    required this.filePath,
    required this.fileName,
    required this.bytesWritten,
  });

  final String filePath;
  final String fileName;
  final int bytesWritten;
}

/// Detecta si el HTML devuelto por MIeL corresponde a un redirect de sesión vencida (`/principal/home/`).
bool isLikelyLoginRedirectHtml(String html) {
  if (html.isEmpty) return false;
  return html.contains('id="formLogin"') ||
      (html.contains('/principal/event/login') &&
          html.contains('name="clave"'));
}

/// Contrato abstracto de acceso HTTP de solo lectura a MIeL para `SyncEngine`.
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

/// Contrato exclusivo para acciones de lectura interactiva iniciadas explícitamente
/// por el usuario en la **Fase 2 — Lectura** (nunca usado por `SyncEngine`).
abstract class MielInteractiveReader implements MielApiClient {
  Future<String> fetchContenidosGlosarioHtml(
    String idComision, {
    String? letra,
  });
  Future<String> fetchContenidosFaqHtml(String idComision);
  Future<void> markExternalContentDownloaded(
    String idComision,
    String idElemento,
  );

  Future<String> fetchPortafolioArchivosEnviadosHtml(String idComision);
  Future<String> fetchPortafolioGruposHtml(String idComision);
  Future<String> fetchPortafolioNotasHtml(String idComision);
  Future<String> fetchPortafolioCompetenciasHtml(String idComision);

  Future<String> fetchMensajeriaEntradaPageHtml(
    String idComision, {
    int page = 1,
  });
  Future<String> fetchMensajeriaSalidaHtml(String idComision, {int page = 1});
  Future<String> fetchMensajeriaBorradoresHtml(
    String idComision, {
    int page = 1,
  });
  Future<String> fetchMensajeriaFavoritosHtml(
    String idComision, {
    int page = 1,
  });
  Future<String> fetchMensajeriaDetalleHtml(String urlOrPath);
  Future<String> fetchMensajeriaDestinatariosHtml(String urlOrPath);

  Future<String> fetchEncuestasHtml(String idComision);
  Future<String> fetchAutoguiaHtml(String idComision);

  Future<Uint8List> downloadAuthenticatedBytes(String urlOrPath);
  Future<DownloadedFileResult> downloadAuthenticatedFile(
    String urlOrPath,
    String destinationDir, {
    String? fallbackFileName,
    void Function(int received, int total)? onProgress,
  });
}

/// Cliente HTTP nativo de LibreMIeL basado en `Dio` + `CookieJar`.
///
/// - Mantiene `PHPSESSID` y `SESSID` (afinidad de nodo).
/// - Ejecuta peticiones de forma secuencial para no sobrecargar los servidores de UNLaM.
/// - Aplica backoff exponencial únicamente en errores transitorios (`5xx` / timeout).
class DioMielClient implements MielInteractiveReader {
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
                 'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 LibreMIeL/0.2',
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

  Future<Response<T>> _requestWithBackoff<T>(
    Future<Response<T>> Function() send,
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

  String _normalizeMielPath(String urlOrPath) {
    final trimmed = urlOrPath.trim();
    if (trimmed.startsWith(kMielBaseUrl)) {
      final rel = trimmed.substring(kMielBaseUrl.length);
      return rel.isEmpty ? '/' : rel;
    }
    return trimmed;
  }

  @override
  Future<MielLoginResult> login(
    String username,
    String password, {
    bool remember = true,
  }) {
    return _enqueue(() async {
      try {
        // 1. Limpiar cookies previas y obtener PHPSESSID/SESSID limpios en /principal/home/
        //    para evitar arrastre de sesión al cambiar de cuenta.
        await _cookieJar.deleteAll();
        await _requestWithBackoff(() => _dio.get<String>('/principal/home/'));

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
              message: 'Respuesta inesperada del servidor de MIeL.',
            );
          }
          decoded = parsed;
        } catch (_) {
          return const MielLoginResult(
            status: MielAuthStatus.invalidResponse,
            message: 'No se pudo interpretar la respuesta de login de MIeL.',
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
              message: 'Usuario o contraseña incorrectos en MIeL.',
            );
          case 3:
            return const MielLoginResult(
              status: MielAuthStatus.accountBlocked,
              rawCode: 3,
              message: 'Tu cuenta de MIeL figura bloqueada (estado 3).',
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
              'Error de red al conectar con MIeL: ${e.message ?? e.type.name}',
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
      final normalized = _normalizeMielPath(path);
      final response = await _requestWithBackoff(
        () => _dio.get<String>(normalized),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 400) {
        throw HttpException(
          'MIeL respondió HTTP $status al consultar $normalized',
        );
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

  // --- MielInteractiveReader (Fase 2 — Lectura interactiva iniciada por el usuario) ---

  @override
  Future<String> fetchContenidosGlosarioHtml(
    String idComision, {
    String? letra,
  }) {
    if (letra == null || letra.isEmpty) {
      return _getHtml('/contenido/glosario/comision/$idComision');
    }
    if (letra == 'Todos') {
      return _getHtml('/contenido/glosario/comision/$idComision/letra');
    }
    return _getHtml(
      '/contenido/glosario/comision/$idComision/letra/${Uri.encodeComponent(letra)}',
    );
  }

  @override
  Future<String> fetchContenidosFaqHtml(String idComision) =>
      _getHtml('/contenido/faq/comision/$idComision');

  @override
  Future<void> markExternalContentDownloaded(
    String idComision,
    String idElemento,
  ) {
    return _enqueue(() async {
      try {
        await _requestWithBackoff(
          () => _dio.get<String>(
            '/contenido/event/marcarElementoDescargadoAjax/comision/$idComision?id=$idElemento',
            options: Options(
              headers: const {'X-Requested-With': 'XMLHttpRequest'},
            ),
          ),
        );
      } catch (_) {
        // Acción de conveniencia visual; no debe bloquear la apertura del enlace externo.
      }
    });
  }

  @override
  Future<String> fetchPortafolioArchivosEnviadosHtml(String idComision) =>
      _getHtml('/portafolio/archivosEnviados/comision/$idComision');

  @override
  Future<String> fetchPortafolioGruposHtml(String idComision) =>
      _getHtml('/portafolio/grupos/comision/$idComision');

  @override
  Future<String> fetchPortafolioNotasHtml(String idComision) =>
      _getHtml('/portafolio/notas/comision/$idComision');

  @override
  Future<String> fetchPortafolioCompetenciasHtml(String idComision) =>
      _getHtml('/portafolio/competencias/comision/$idComision');

  @override
  Future<String> fetchMensajeriaEntradaPageHtml(
    String idComision, {
    int page = 1,
  }) {
    if (page <= 1) return fetchMensajeriaEntradaHtml(idComision);
    return _getHtml('/mensajeria/entrada/comision/$idComision/pag/$page');
  }

  @override
  Future<String> fetchMensajeriaSalidaHtml(String idComision, {int page = 1}) {
    if (page <= 1) return _getHtml('/mensajeria/salida/comision/$idComision');
    return _getHtml('/mensajeria/salida/comision/$idComision/pag/$page');
  }

  @override
  Future<String> fetchMensajeriaBorradoresHtml(
    String idComision, {
    int page = 1,
  }) {
    if (page <= 1) {
      return _getHtml('/mensajeria/borradores/comision/$idComision');
    }
    return _getHtml('/mensajeria/borradores/comision/$idComision/pag/$page');
  }

  @override
  Future<String> fetchMensajeriaFavoritosHtml(
    String idComision, {
    int page = 1,
  }) {
    if (page <= 1) {
      return _getHtml('/mensajeria/favoritos/comision/$idComision');
    }
    return _getHtml('/mensajeria/favoritos/comision/$idComision/pag/$page');
  }

  @override
  Future<String> fetchMensajeriaDetalleHtml(String urlOrPath) =>
      _getHtml(urlOrPath);

  @override
  Future<String> fetchMensajeriaDestinatariosHtml(String urlOrPath) =>
      _getHtml(urlOrPath);

  @override
  Future<String> fetchEncuestasHtml(String idComision) =>
      _getHtml('/encuesta/encuestas/comision/$idComision');

  @override
  Future<String> fetchAutoguiaHtml(String idComision) =>
      _getHtml('/autoguia/modulos/comision/$idComision');

  @override
  Future<Uint8List> downloadAuthenticatedBytes(String urlOrPath) {
    return _enqueue(() async {
      final normalized = _normalizeMielPath(urlOrPath);
      final response = await _requestWithBackoff(
        () => _dio.get<List<int>>(
          normalized,
          options: Options(responseType: ResponseType.bytes),
        ),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 400 || response.data == null) {
        throw HttpException(
          'No se pudo descargar recurso ($status): $normalized',
        );
      }
      return Uint8List.fromList(response.data!);
    });
  }

  @override
  Future<DownloadedFileResult> downloadAuthenticatedFile(
    String urlOrPath,
    String destinationDir, {
    String? fallbackFileName,
    void Function(int received, int total)? onProgress,
  }) {
    return _enqueue(() async {
      final normalized = _normalizeMielPath(urlOrPath);
      final dir = Directory(destinationDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final response = await _requestWithBackoff(
        () => _dio.get<List<int>>(
          normalized,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 2),
          ),
          onReceiveProgress: onProgress,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 400 || response.data == null) {
        throw HttpException(
          'MIeL respondió HTTP $status al descargar $normalized',
        );
      }

      final extractedName = extractDownloadedFileName(
        contentDisposition: response.headers.value('content-disposition'),
        urlOrPath: normalized,
        fallbackFileName: fallbackFileName,
      );

      final targetFile = allocateUniqueFilePath(destinationDir, extractedName);
      final bytes = response.data!;
      await File(targetFile).writeAsBytes(bytes, flush: true);

      return DownloadedFileResult(
        filePath: targetFile,
        fileName: p.basename(targetFile),
        bytesWritten: bytes.length,
      );
    });
  }
}

/// Extrae y sanitiza el nombre de un archivo descargado desde `Content-Disposition` o la URL de MIeL.
String extractDownloadedFileName({
  String? contentDisposition,
  required String urlOrPath,
  String? fallbackFileName,
}) {
  var candidate = '';

  if (contentDisposition != null && contentDisposition.isNotEmpty) {
    // filename*=UTF-8''nombre.pdf
    final utf8Match = RegExp(
      r"filename\*\s*=\s*UTF-8''([^;\r\n]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (utf8Match != null) {
      candidate = Uri.decodeFull(utf8Match.group(1)!.trim());
    } else {
      final stdMatch = RegExp(
        r'filename\s*=\s*"?([^";\r\n]+)"?',
        caseSensitive: false,
      ).firstMatch(contentDisposition);
      if (stdMatch != null) {
        candidate = stdMatch.group(1)!.trim();
      }
    }
  }

  if (candidate.isEmpty) {
    // URLs de MIeL: /a/{nombreCodificado}/id/{id} o /a/{nombreCodificado}/t/M
    final aMatch = RegExp(r'/a/([^/?#]+)').firstMatch(urlOrPath);
    if (aMatch != null) {
      var decoded = aMatch.group(1)!;
      try {
        decoded = Uri.decodeComponent(decoded);
      } catch (_) {}
      // Quitar prefijo de código de materia como "3656\_" o "3656_"
      decoded = decoded
          .replaceAll(r'\_', '_')
          .replaceFirst(RegExp(r'^\d{3,6}_'), '');
      if (decoded.contains('.')) {
        candidate = decoded;
      }
    }
  }

  if (candidate.isEmpty &&
      fallbackFileName != null &&
      fallbackFileName.trim().isNotEmpty) {
    candidate = fallbackFileName.trim();
  }

  if (candidate.isEmpty) {
    candidate = 'archivo_miel.pdf';
  }

  // Sanitizar caracteres inválidos o traversal de directorios
  var safe = candidate
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  while (safe.startsWith('.')) {
    safe = safe.substring(1).trim();
  }
  if (safe.isEmpty) {
    safe = 'archivo_miel.pdf';
  }
  return safe;
}

/// Si el archivo ya existe en `dirPath`, genera `nombre (2).ext`, `nombre (3).ext`, etc.
String allocateUniqueFilePath(String dirPath, String fileName) {
  var candidatePath = p.join(dirPath, fileName);
  if (!File(candidatePath).existsSync()) {
    return candidatePath;
  }

  final ext = p.extension(fileName);
  final base = p.basenameWithoutExtension(fileName);
  for (var i = 2; i < 1000; i++) {
    candidatePath = p.join(dirPath, '$base ($i)$ext');
    if (!File(candidatePath).existsSync()) {
      return candidatePath;
    }
  }
  return p.join(
    dirPath,
    '${base}_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
}
