import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/core/sync/offline_prefetcher.dart';

class TrackingInteractiveReader implements MielInteractiveReader {
  final List<String> calls = [];

  @override
  Future<String> fetchInternoHtml() async {
    calls.add('fetchInternoHtml');
    return '<html>Interno</html>';
  }

  @override
  Future<String> fetchCursoDetallesHtml(String idComision) async {
    calls.add('fetchCursoDetallesHtml:$idComision');
    return '<html>Docentes $idComision</html>';
  }

  @override
  Future<String> fetchContenidosHtml(String idComision) async {
    calls.add('fetchContenidosHtml:$idComision');
    return '<html>Contenidos $idComision</html>';
  }

  @override
  Future<String> fetchPortafolioPracticasHtml(String idComision) async {
    calls.add('fetchPortafolioPracticasHtml:$idComision');
    return '<html>Practicas $idComision</html>';
  }

  @override
  Future<String> fetchMensajeriaEntradaPageHtml(
    String idComision, {
    int page = 1,
  }) async {
    calls.add('fetchMensajeriaEntradaPageHtml:$idComision:p$page');
    return '<html>Mensajes $idComision</html>';
  }

  @override
  Future<String> fetchForoTemasHtml(String idComision) async {
    calls.add('fetchForoTemasHtml:$idComision');
    return '<html>ForoTemas $idComision</html>';
  }

  @override
  Future<String> fetchEvaluacionesHtml(String idComision) async {
    calls.add('fetchEvaluacionesHtml:$idComision');
    return '<html>Evaluaciones $idComision</html>';
  }

  @override
  Future<String> fetchEncuestasHtml(String idComision) async {
    calls.add('fetchEncuestasHtml:$idComision');
    return '<html>Encuestas $idComision</html>';
  }

  @override
  Future<String> fetchAutoguiaHtml(String idComision) async {
    calls.add('fetchAutoguiaHtml:$idComision');
    return '<html>Autoguia $idComision</html>';
  }

  // Métodos no usados por prefetcher (lanzan UnimplementedError si son llamados por error)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late TrackingInteractiveReader client;
  late OfflinePrefetcher prefetcher;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = TrackingInteractiveReader();
    prefetcher = OfflinePrefetcher(client: client, database: db);
  });

  tearDown(() async {
    await db.close();
  });

  Subject makeSubject({
    required String idComision,
    required String name,
    bool hasContenidos = true,
    int lastContenidosBadge = 0,
    bool hasPortafolio = true,
    bool hasMensajeria = true,
    bool hasForo = true,
    bool hasEvaluacion = true,
    bool hasEncuestas = false,
    bool hasAutoguia = false,
  }) {
    return Subject(
      idComision: idComision,
      name: name,
      subjectCode: 'COD_$idComision',
      commissionCode: 'COM_$idComision',
      roleLabel: 'Alumno/a',
      hasContenidos: hasContenidos,
      hasForo: hasForo,
      hasMensajeria: hasMensajeria,
      hasAutoguia: hasAutoguia,
      hasChat: false,
      hasEncuestas: hasEncuestas,
      hasEvaluacion: hasEvaluacion,
      hasPortafolio: hasPortafolio,
      isHiddenInMiel: false,
      muted: false,
      notifyContenidos: true,
      notifyPortafolio: false,
      notifyMensajeria: false,
      notifyForos: false,
      notifyEvaluacion: false,
      lastContenidosBadge: lastContenidosBadge,
      lastMensajesBadge: 0,
      lastForoBadge: 0,
      sortOrder: 0,
      localVisibilityOverride: 0,
    );
  }

  group('OfflinePrefetcher security & side-effect invariants', () {
    test('CRITICAL RULE 1: Never fetches Contenidos when badge == 0', () async {
      final s = makeSubject(
        idComision: '100',
        name: 'Algoritmos',
        hasContenidos: true,
        lastContenidosBadge: 0,
      );

      final count = await prefetcher.prefetchSafeModules(activeSubjects: [s]);

      expect(count, greaterThan(0));
      expect(client.calls, isNot(contains('fetchContenidosHtml:100')));
    });

    test('CRITICAL RULE 1 & 11: Never fetches Contenidos even when badge > 0 (avoids wiping muted/baseline badges)', () async {
      final s = makeSubject(
        idComision: '200',
        name: 'Bases de Datos',
        hasContenidos: true,
        lastContenidosBadge: 2,
      );

      final count = await prefetcher.prefetchSafeModules(activeSubjects: [s]);

      expect(count, greaterThan(0));
      expect(client.calls, isNot(contains('fetchContenidosHtml:200')));
      expect(await db.getOfflinePage('contenidos:200'), isNull);
    });

    test('Precaches principal and safe modules in database', () async {
      final s = makeSubject(
        idComision: '300',
        name: 'Sistemas Operativos',
        hasContenidos: false,
        hasPortafolio: true,
        hasMensajeria: true,
        hasForo: true,
        hasEvaluacion: true,
        hasEncuestas: true,
        hasAutoguia: true,
      );

      await prefetcher.prefetchSafeModules(activeSubjects: [s]);

      expect(await db.getOfflinePage('principal:interno'), isNotNull);
      expect(await db.getOfflinePage('cursoDetalles:300'), isNotNull);
      expect(await db.getOfflinePage('portafolio:practicas:300'), isNotNull);
      expect(await db.getOfflinePage('mensajeria:entrada:300:p1'), isNotNull);
      expect(await db.getOfflinePage('foro:temas:300'), isNotNull);
      expect(await db.getOfflinePage('evaluaciones:300'), isNotNull);
      expect(await db.getOfflinePage('encuestas:300'), isNotNull);
      expect(await db.getOfflinePage('autoguia:300'), isNotNull);
    });

    test('skipInterno avoids duplicate fetchInternoHtml call', () async {
      final s = makeSubject(idComision: '350', name: 'Redes');
      await prefetcher.prefetchSafeModules(
        activeSubjects: [s],
        skipInterno: true,
      );
      expect(client.calls, isNot(contains('fetchInternoHtml')));
    });

    test('Early termination on cancellation token', () async {
      final s = makeSubject(idComision: '400', name: 'Redes');

      var cancelNow = true;
      final count = await prefetcher.prefetchSafeModules(
        activeSubjects: [s],
        isCancelled: () => cancelNow,
      );

      expect(count, 0);
      expect(client.calls, isEmpty);
      expect(await db.getOfflineCacheTotalBytes(), 0);
    });
  });
}
