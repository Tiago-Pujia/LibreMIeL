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
import 'miel_upload_helpers.dart';

export '../parsers/text_normalizer.dart' show kMielBaseUrl;
export 'miel_upload_helpers.dart';

/// Excepción lanzada cuando MIeL devuelve la pantalla de login por sesión vencida
/// durante una operación interactiva o de escritura.
class MielSessionExpiredException implements Exception {
  const MielSessionExpiredException([
    this.message = 'La sesión con MIeL expiró. Reintentando reconexión…',
  ]);

  final String message;

  @override
  String toString() => message;
}

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
/// ni operaciones de escritura para impedir efectos colaterales en segundo plano.
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

/// Contrato aislado para operaciones de escritura/mutación iniciadas explícitamente
/// por el usuario en **Fase 3 — Escritura** (jamás expuesto a `SyncEngine`).
abstract class MielWriter {
  // --- Mensajería ---
  Future<String> fetchMensajeriaRedactarHtml(String idComision);

  Future<void> sendMensajeriaMessage({
    required String idComision,
    required List<ComposeRecipientOption> recipients,
    required String subject,
    required String bodyPlainText,
    bool saveAsDraft = false,
    String? attachmentPath,
  });

  Future<void> sendMensajeriaReply({
    required String idComision,
    required String respondsToMessageId,
    required List<ComposeRecipientOption> recipients,
    required String bodyPlainText,
    String? attachmentPath,
  });

  Future<void> toggleMensajeriaFavorite({
    required String idComision,
    required String idMensaje,
    required bool currentlyFavorite,
    required String buzonActual,
  });

  Future<void> toggleMensajeriaRead({
    required String idComision,
    required String idMensaje,
    required bool currentlyRead,
    required String buzonActual,
  });

  Future<void> markAllMensajeriaRead(String idComision);

  Future<void> deleteMensajeriaDraft({
    required String idComision,
    required String idMensaje,
  });

  // --- Portafolio ---
  Future<void> submitPortafolioEntrega({
    required String idComision,
    required String idPractica,
    required String tutorDestinatarioId,
    String observations = '',
    String? externalLink,
    String? attachmentPath,
  });

  // --- Foros (forov2) ---
  Future<void> postForoNewMessage({
    required String idComision,
    required String idTema,
    required String bodyPlainText,
    String? attachmentPath,
  });

  Future<void> postForoReply({
    required String idComision,
    required String idTema,
    required String rootParentMessageId,
    required String bodyPlainText,
    String? mentionUserId,
    String? mentionMessageId,
    String? mentionUserName,
    String? attachmentPath,
  });

  /// Alterna Me gusta (`marcarUtil`) y devuelve el nuevo contador de votos del servidor.
  Future<int> toggleForoLike({
    required String idComision,
    required String idMensaje,
    required bool currentlyLiked,
  });

  Future<void> markAllForoTopicsRead(String idComision);

  // --- Evaluación ---
  Future<String> submitEvaluacionClave({
    required String idComision,
    required String idEvaluacion,
    String clave = '',
  });
}

/// Cliente HTTP nativo de LibreMIeL basado en `Dio` + `CookieJar`.
///
/// - Mantiene `PHPSESSID` y `SESSID` (afinidad de nodo).
/// - Ejecuta peticiones de forma secuencial para no sobrecargar los servidores de UNLaM.
/// - Aplica backoff exponencial únicamente en errores transitorios (`5xx` / timeout).
class DioMielClient implements MielInteractiveReader, MielWriter {
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

      final contentType = (response.headers.value('content-type') ?? '')
          .toLowerCase();
      final bytes = response.data!;
      if (contentType.contains('text/html') && bytes.length < 32768) {
        final preview = utf8.decode(bytes, allowMalformed: true);
        if (isLikelyLoginRedirectHtml(preview)) {
          throw const MielSessionExpiredException();
        }
      }

      final extractedName = extractDownloadedFileName(
        contentDisposition: response.headers.value('content-disposition'),
        urlOrPath: normalized,
        fallbackFileName: fallbackFileName,
      );

      final targetFile = allocateUniqueFilePath(destinationDir, extractedName);
      await File(targetFile).writeAsBytes(bytes, flush: true);

      return DownloadedFileResult(
        filePath: targetFile,
        fileName: p.basename(targetFile),
        bytesWritten: bytes.length,
      );
    });
  }

  // --- Fase 3: Implementación de MielWriter (escritura/mutación aislada) ---

  String _assertWriteResponse(Response<String> response, String endpoint) {
    final status = response.statusCode ?? 0;
    final body = response.data ?? '';
    if (isLikelyLoginRedirectHtml(body)) {
      throw const MielSessionExpiredException();
    }
    if (status < 200 || status >= 400) {
      throw HttpException('MIeL respondió HTTP $status al enviar a $endpoint');
    }
    return body;
  }

  @override
  Future<String> fetchMensajeriaRedactarHtml(String idComision) =>
      _getHtml('/mensajeria/redactar/comision/$idComision');

  @override
  Future<void> sendMensajeriaMessage({
    required String idComision,
    required List<ComposeRecipientOption> recipients,
    required String subject,
    required String bodyPlainText,
    bool saveAsDraft = false,
    String? attachmentPath,
  }) {
    return _enqueue(() async {
      final cleanSubject = subject.trim();
      final bodyHtml = plainTextToMielHtml(bodyPlainText);
      if (cleanSubject.isEmpty) {
        throw ArgumentError('El asunto es obligatorio.');
      }
      if (bodyHtml.isEmpty) {
        throw ArgumentError('El mensaje no puede estar vacío.');
      }
      if (!saveAsDraft && recipients.isEmpty) {
        throw ArgumentError('Seleccioná al menos un destinatario.');
      }
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        final err = validateMielUploadFile(
          filePath: attachmentPath,
          maxSizeMb: kMielMaxUploadMbLarge,
        );
        if (err != null) throw ArgumentError(err);
      }

      final formData = FormData();
      formData.fields.add(MapEntry('borrador', saveAsDraft ? '1' : '0'));
      formData.fields.add(const MapEntry('destinatarios', ''));
      for (final rec in recipients) {
        formData.fields.add(MapEntry('${rec.contactType}[]', rec.contactId));
      }
      formData.fields.add(MapEntry('asunto', cleanSubject));
      formData.fields.add(MapEntry('texto', encodeMielBase64Utf8(bodyHtml)));
      formData.fields.add(const MapEntry('adjuntoReenvio', ''));

      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'archivo',
            await MultipartFile.fromFile(
              attachmentPath,
              filename: p.basename(attachmentPath),
            ),
          ),
        );
      }

      final path = '/mensajeria/event/enviarMensaje/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'Referer': '$kMielBaseUrl/mensajeria/redactar/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> sendMensajeriaReply({
    required String idComision,
    required String respondsToMessageId,
    required List<ComposeRecipientOption> recipients,
    required String bodyPlainText,
    String? attachmentPath,
  }) {
    return _enqueue(() async {
      final bodyHtml = plainTextToMielHtml(bodyPlainText);
      if (bodyHtml.isEmpty) {
        throw ArgumentError('La respuesta no puede estar vacía.');
      }
      if (recipients.isEmpty) {
        throw ArgumentError('Seleccioná al menos un destinatario.');
      }
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        final err = validateMielUploadFile(
          filePath: attachmentPath,
          maxSizeMb: kMielMaxUploadMbLarge,
        );
        if (err != null) throw ArgumentError(err);
      }

      final formData = FormData();
      formData.fields.add(MapEntry('respondeA', respondsToMessageId));
      formData.fields.add(const MapEntry('destinatarios', ''));
      for (final rec in recipients) {
        formData.fields.add(MapEntry('${rec.contactType}[]', rec.contactId));
      }
      formData.fields.add(MapEntry('texto', encodeMielBase64Utf8(bodyHtml)));

      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'archivo',
            await MultipartFile.fromFile(
              attachmentPath,
              filename: p.basename(attachmentPath),
            ),
          ),
        );
      }

      final path = '/mensajeria/event/enviarRespuesta/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'Referer':
                '$kMielBaseUrl/mensajeria/verEntrada/comision/$idComision/pag/1/from/entrada/id/$respondsToMessageId',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> toggleMensajeriaFavorite({
    required String idComision,
    required String idMensaje,
    required bool currentlyFavorite,
    required String buzonActual,
  }) {
    return _enqueue(() async {
      final formData = FormData();
      formData.fields.add(MapEntry('idMensajeFavorito', idMensaje));
      formData.fields.add(
        MapEntry('estadoFavorito', currentlyFavorite ? '1' : '0'),
      );
      formData.fields.add(MapEntry('buzonActual', buzonActual));

      final path = '/mensajeria/event/marcarFavorito/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer':
                '$kMielBaseUrl/mensajeria/$buzonActual/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> toggleMensajeriaRead({
    required String idComision,
    required String idMensaje,
    required bool currentlyRead,
    required String buzonActual,
  }) {
    return _enqueue(() async {
      final formData = FormData();
      formData.fields.add(MapEntry('idMensajeLeido', idMensaje));
      formData.fields.add(MapEntry('estadoLeido', currentlyRead ? '1' : '0'));
      formData.fields.add(MapEntry('buzonActual', buzonActual));

      final path = '/mensajeria/event/marcarLeido/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer':
                '$kMielBaseUrl/mensajeria/$buzonActual/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> markAllMensajeriaRead(String idComision) {
    return _enqueue(() async {
      final path =
          '/mensajeria/event/marcarTodosComoLeidos/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$kMielBaseUrl/mensajeria/entrada/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> deleteMensajeriaDraft({
    required String idComision,
    required String idMensaje,
  }) {
    return _enqueue(() async {
      final path = '/mensajeria/event/eliminarBorrador/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: {'idMensajeEliminar': idMensaje},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Referer':
                '$kMielBaseUrl/mensajeria/borradores/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> submitPortafolioEntrega({
    required String idComision,
    required String idPractica,
    required String tutorDestinatarioId,
    String observations = '',
    String? externalLink,
    String? attachmentPath,
  }) {
    return _enqueue(() async {
      final hasLink = externalLink != null && externalLink.trim().isNotEmpty;
      final hasFile = attachmentPath != null && attachmentPath.trim().isNotEmpty;
      if (!hasFile && !hasLink) {
        throw ArgumentError('Adjuntá un archivo o ingresá un enlace.');
      }
      if (hasFile) {
        final err = validateMielUploadFile(
          filePath: attachmentPath,
          maxSizeMb: kMielMaxUploadMbLarge,
        );
        if (err != null) throw ArgumentError(err);
      }

      final formData = FormData();
      formData.fields.add(MapEntry('codPractica', idPractica));
      formData.fields.add(
        MapEntry(
          'tutorDestinatario',
          tutorDestinatarioId.isEmpty ? '0' : tutorDestinatarioId,
        ),
      );
      formData.fields.add(MapEntry('observaciones', observations.trim()));
      if (hasLink) {
        formData.fields.add(MapEntry('enlace', externalLink.trim()));
      }
      if (hasFile) {
        formData.files.add(
          MapEntry(
            'archivo',
            await MultipartFile.fromFile(
              attachmentPath,
              filename: p.basename(attachmentPath),
            ),
          ),
        );
      }

      final path = '/portafolio/event/nuevaEntrega/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'Referer':
                '$kMielBaseUrl/portafolio/entregas/comision/$idComision/id/$idPractica',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> postForoNewMessage({
    required String idComision,
    required String idTema,
    required String bodyPlainText,
    String? attachmentPath,
  }) {
    return _enqueue(() async {
      final bodyHtml = plainTextToMielHtml(bodyPlainText);
      if (bodyHtml.isEmpty) {
        throw ArgumentError('Escribí un mensaje antes de publicar.');
      }
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        final err = validateMielUploadFile(
          filePath: attachmentPath,
          maxSizeMb: kMielMaxUploadMbForum,
        );
        if (err != null) throw ArgumentError(err);
      }

      final formData = FormData();
      formData.fields.add(MapEntry('codTemaMensaje', idTema));
      formData.fields.add(
        MapEntry('mensajeNuevo', encodeMielBase64Utf8(bodyHtml)),
      );
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'archivoMensaje',
            await MultipartFile.fromFile(
              attachmentPath,
              filename: p.basename(attachmentPath),
            ),
          ),
        );
      }

      final path = '/forov2/event/nuevoMensajeAjax/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer':
                '$kMielBaseUrl/forov2/mensajes/comision/$idComision/tema/$idTema',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<void> postForoReply({
    required String idComision,
    required String idTema,
    required String rootParentMessageId,
    required String bodyPlainText,
    String? mentionUserId,
    String? mentionMessageId,
    String? mentionUserName,
    String? attachmentPath,
  }) {
    return _enqueue(() async {
      final mentionPrefix =
          (mentionUserName != null &&
              mentionUserName.trim().isNotEmpty &&
              mentionMessageId != null &&
              mentionMessageId.trim().isNotEmpty)
          ? buildForoMentionPrefixHtml(
              authorUserId: mentionUserId ?? '',
              messageId: mentionMessageId,
              mentionName: mentionUserName,
            )
          : null;
      final bodyHtml = plainTextToMielHtml(
        bodyPlainText,
        mentionPrefixHtml: mentionPrefix,
      );
      if (bodyPlainText.trim().isEmpty) {
        throw ArgumentError('Escribí una respuesta antes de enviar.');
      }
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        final err = validateMielUploadFile(
          filePath: attachmentPath,
          maxSizeMb: kMielMaxUploadMbForum,
        );
        if (err != null) throw ArgumentError(err);
      }

      final formData = FormData();
      formData.fields.add(MapEntry('codTemaRespuesta', idTema));
      formData.fields.add(MapEntry('respondeA', rootParentMessageId));
      formData.fields.add(
        MapEntry('respuestaNueva', encodeMielBase64Utf8(bodyHtml)),
      );
      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'archivoRespuesta',
            await MultipartFile.fromFile(
              attachmentPath,
              filename: p.basename(attachmentPath),
            ),
          ),
        );
      }

      final path = '/forov2/event/nuevaRespuestaAjax/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: formData,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer':
                '$kMielBaseUrl/forov2/mensajes/comision/$idComision/tema/$idTema',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<int> toggleForoLike({
    required String idComision,
    required String idMensaje,
    required bool currentlyLiked,
  }) {
    return _enqueue(() async {
      final path = '/forov2/event/marcarUtil/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: {'idMensaje': idMensaje, 'util': currentlyLiked ? '1' : '0'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$kMielBaseUrl/forov2/temas/comision/$idComision',
          },
        ),
      );
      final raw = _assertWriteResponse(response, path).trim();
      final count = int.tryParse(raw.replaceAll('"', ''));
      if (count == null || count < 0) {
        throw FormatException(
          'MIeL no pudo actualizar el voto del mensaje (respuesta: $raw).',
        );
      }
      return count;
    });
  }

  @override
  Future<void> markAllForoTopicsRead(String idComision) {
    return _enqueue(() async {
      final path = '/forov2/event/marcarTemasComoLeidos/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        options: Options(
          headers: {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': '$kMielBaseUrl/forov2/temas/comision/$idComision',
          },
        ),
      );
      _assertWriteResponse(response, path);
    });
  }

  @override
  Future<String> submitEvaluacionClave({
    required String idComision,
    required String idEvaluacion,
    String clave = '',
  }) {
    return _enqueue(() async {
      final path = '/evaluacion/event/ingresar/comision/$idComision';
      final response = await _dio.post<String>(
        path,
        data: {'idEvaluacion': idEvaluacion, 'clave': clave},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Referer':
                '$kMielBaseUrl/evaluacion/evaluaciones/comision/$idComision',
          },
        ),
      );
      return _assertWriteResponse(response, path);
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
