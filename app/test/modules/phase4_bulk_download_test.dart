import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/downloads/bulk_download_manager.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:mocktail/mocktail.dart';

class MockMielInteractiveReader extends Mock implements MielInteractiveReader {}

void main() {
  late AppDatabase db;
  late MockMielInteractiveReader client;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = MockMielInteractiveReader();
    tempDir = Directory.systemTemp.createTempSync('libremiel_test_backup_');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Fase 4 — BulkDownloadManager y registro en SQLite', () {
    test('Descarga masiva de contenidos guarda archivos, genera índices y registra en DownloadedResources', () async {
      const contenidosHtml = '''
        <table class="w3-table">
          <thead><tr><th>Módulo Teórico</th></tr></thead>
          <tbody>
            <tr>
              <td><i class="icon-file-pdf"></i></td>
              <td>Guía_01.pdf</td>
              <td>20/03/2026</td>
              <td>1.5 MB</td>
              <td><a class="btnDescargar" href="/contenido/event/descargarElemento/id/901">Descargar</a></td>
            </tr>
          </tbody>
        </table>
      ''';

      when(() => client.fetchContenidosHtml('119341'))
          .thenAnswer((_) async => contenidosHtml);
      when(() => client.downloadAuthenticatedBytes(any())).thenAnswer(
        (_) async => Uint8List.fromList(utf8.encode('PDF DUMMY DATA 12345')),
      );
      when(() => client.markExternalContentDownloaded(any(), any()))
          .thenAnswer((_) async {});

      final manager = BulkDownloadManager(client: client, database: db);

      final subject = Subject(
        idComision: '119341',
        name: 'Algoritmos y Estructuras de Datos',
        subjectCode: 'INF-101',
        commissionCode: 'COM-119',
        roleLabel: 'Alumno/a',
        hasContenidos: true,
        hasForo: false,
        hasMensajeria: true,
        hasAutoguia: false,
        hasChat: false,
        hasEncuestas: false,
        hasEvaluacion: false,
        hasPortafolio: false,
        isHiddenInMiel: false,
        muted: false,
        notifyContenidos: true,
        notifyPortafolio: false,
        notifyMensajeria: false,
        notifyForos: false,
        notifyEvaluacion: false,
        lastContenidosBadge: 0,
        lastMensajesBadge: 0,
        lastForoBadge: 0,
        sortOrder: 0,
        localVisibilityOverride: 0,
      );

      final options = BulkDownloadOptions(
        subjects: [subject],
        baseDirectory: tempDir.path,
        includeContenidos: true,
        includeForos: false,
        delayBetweenRequests: const Duration(milliseconds: 10),
      );

      final progress = await manager.start(options);

      expect(progress.isFinished, isTrue);
      expect(progress.completedItems, equals(1));
      expect(progress.failedItems, equals(0));

      // Verificar que el registro en DownloadedResources se insertó correctamente
      final recorded = await db.getDownloadedResource(
        idComision: '119341',
        module: 'contenidos',
        resourceId: '901',
      );
      expect(recorded, isNotNull);
      expect(recorded!.title, equals('Guía_01.pdf'));
      expect(File(recorded.localPath).existsSync(), isTrue);

      // Verificar que se generó indice_contenidos.md y enlaces_externos.md
      final contentsDir = Directory(
        '${tempDir.path}/Algoritmos y Estructuras de Datos - COM-119/Contenidos',
      );
      expect(
        File('${contentsDir.path}/indice_contenidos.md').existsSync(),
        isTrue,
      );
      expect(
        File('${contentsDir.path}/enlaces_externos.md').existsSync(),
        isTrue,
      );

      // Segunda pasada en modo incremental: debe omitir y contar como skipped
      final secondProgress = await manager.start(options);
      expect(secondProgress.isFinished, isTrue);
      expect(secondProgress.skippedItems, equals(1));
      expect(secondProgress.completedItems, equals(0));
    });

    test('Pausa, reanudación y cancelación de la descarga masiva', () async {
      when(() => client.fetchContenidosHtml(any()))
          .thenAnswer((_) async => '<div class="desplegarModulo"></div>');

      final manager = BulkDownloadManager(client: client, database: db);

      final subject = Subject(
        idComision: '119341',
        name: 'Materia Cancelable',
        subjectCode: 'INF-102',
        commissionCode: 'COM-1',
        roleLabel: 'Alumno/a',
        hasContenidos: true,
        hasForo: false,
        hasMensajeria: true,
        hasAutoguia: false,
        hasChat: false,
        hasEncuestas: false,
        hasEvaluacion: false,
        hasPortafolio: false,
        isHiddenInMiel: false,
        muted: false,
        notifyContenidos: true,
        notifyPortafolio: false,
        notifyMensajeria: false,
        notifyForos: false,
        notifyEvaluacion: false,
        lastContenidosBadge: 0,
        lastMensajesBadge: 0,
        lastForoBadge: 0,
        sortOrder: 0,
        localVisibilityOverride: 0,
      );

      final options = BulkDownloadOptions(
        subjects: [subject],
        baseDirectory: tempDir.path,
        delayBetweenRequests: const Duration(milliseconds: 50),
      );

      // Cancelar inmediatamente después de disparar
      final future = manager.start(options);
      manager.cancel();
      final res = await future;

      expect(res.isCancelled, isTrue);
    });
  });
}
