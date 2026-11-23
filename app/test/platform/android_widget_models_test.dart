import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/models/miel_models.dart';
import 'package:libremiel/core/storage/app_database.dart';
import 'package:libremiel/platform/android_widget_models.dart';

void main() {
  group('AndroidWidgetSnapshot serialization', () {
    test('serializa y deserializa roundtrip completo', () {
      final snapshot = AndroidWidgetSnapshot(
        isAuthenticated: true,
        serverStatus: MielServerStatus.mielDown,
        authPaused: true,
        unreadCount: 4,
        pendingSubjectsBadgeCount: 2,
        lastSyncAt: DateTime.utc(2026, 11, 23, 14, 30),
        lastOnlineSuccessAt: DateTime.utc(2026, 11, 23, 14, 0),
        recentNotifications: [
          AndroidWidgetNotificationItem(
            id: 42,
            idComision: '117967',
            subjectName: 'Sistemas Embebidos',
            module: 'mensajeria',
            title: 'DOCENTE, UNO (Docente)',
            body: 'Entrega del TP 2 📎',
            targetUrl: 'https://miel.unlam.edu.ar/mensajeria/verEntrada/99',
            isRead: false,
            createdAt: DateTime.utc(2026, 11, 23, 14, 20),
          ),
        ],
        activeSubjects: const [
          AndroidWidgetSubjectItem(
            idComision: '117967',
            name: 'Sistemas Embebidos',
            commissionCode: '01-1300',
            contenidosBadge: 1,
            mensajesBadge: 2,
            foroBadge: 0,
            defaultTool: 'mensajeria',
          ),
        ],
      );

      final raw = snapshot.toJsonString();
      final decoded = AndroidWidgetSnapshot.tryFromJsonString(raw);

      expect(decoded, isNotNull);
      expect(decoded!.isAuthenticated, isTrue);
      expect(decoded.serverStatus, MielServerStatus.mielDown);
      expect(decoded.authPaused, isTrue);
      expect(decoded.unreadCount, 4);
      expect(decoded.pendingSubjectsBadgeCount, 2);
      expect(decoded.lastSyncAt, DateTime.utc(2026, 11, 23, 14, 30));
      expect(decoded.lastOnlineSuccessAt, DateTime.utc(2026, 11, 23, 14, 0));
      expect(decoded.recentNotifications, hasLength(1));
      expect(decoded.recentNotifications.first.id, 42);
      expect(decoded.recentNotifications.first.module, 'mensajeria');
      expect(decoded.activeSubjects, hasLength(1));
      expect(decoded.activeSubjects.first.totalBadges, 3);
      expect(decoded.activeSubjects.first.defaultTool, 'mensajeria');
    });

    test('signedOut limpia listas y contadores, y tryFromJsonString tolera JSON inválido', () {
      final signedOut = AndroidWidgetSnapshot.signedOut();
      expect(signedOut.isAuthenticated, isFalse);
      expect(signedOut.unreadCount, 0);
      expect(signedOut.recentNotifications, isEmpty);
      expect(signedOut.activeSubjects, isEmpty);

      expect(AndroidWidgetSnapshot.tryFromJsonString(null), isNull);
      expect(AndroidWidgetSnapshot.tryFromJsonString(''), isNull);
      expect(AndroidWidgetSnapshot.tryFromJsonString('{bad json'), isNull);
    });
  });

  group('AndroidWidgetSnapshotBuilder & AppDatabase queries', () {
    late AppDatabase db;
    const builder = AndroidWidgetSnapshotBuilder();

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('construye snapshot priorizando materias con badges, ocultando materias inactivas y priorizando no leídas', () async {
      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '101',
          name: 'Algebra',
          commissionCode: '01-1000',
          isHidden: false,
          contenidosBadge: 0,
          mensajesBadge: 0,
          foroBadge: 0,
          hasContenidos: true,
        ),
        DateTime(2026, 11, 23, 10, 0),
      );

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '102',
          name: 'Sistemas Operativos',
          commissionCode: '02-2000',
          isHidden: false,
          contenidosBadge: 2,
          mensajesBadge: 1,
          foroBadge: 0,
          hasContenidos: true,
          hasMensajeria: true,
        ),
        DateTime(2026, 11, 23, 10, 0),
      );

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '103',
          name: 'Materia Oculta',
          commissionCode: '03-3000',
          isHidden: true,
          contenidosBadge: 5,
        ),
        DateTime(2026, 11, 23, 10, 0),
      );

      await db.upsertSubjectFromInterno(
        const MielSubjectBadgeSummary(
          idComision: '104',
          name: 'Forzada Visible',
          commissionCode: '04-4000',
          isHidden: true,
          foroBadge: 3,
          hasContenidos: false,
          hasForo: true,
        ),
        DateTime(2026, 11, 23, 10, 0),
      );
      await db.setSubjectLocalVisibility('104', 1);

      // Insertar 6 notificaciones: 2 no leídas (más viejas que algunas leídas) + 4 leídas
      for (var i = 1; i <= 4; i++) {
        await db.insertNotificationIfNew(
          DetectedNotification(
            dedupeKey: 'read_$i',
            idComision: '101',
            subjectName: 'Algebra',
            module: MielModuleType.contenidos,
            title: 'Leída $i',
            body: 'Contenido $i',
            targetUrl: 'https://miel.unlam.edu.ar/',
            detectedAt: DateTime(2026, 11, 23, 12, i),
          ),
        );
      }
      final allInserted = await db.getRecentNotifications(limit: 10);
      for (final row in allInserted) {
        await db.markNotificationRead(row.id, isRead: true);
      }

      await db.insertNotificationIfNew(
        DetectedNotification(
          dedupeKey: 'unread_1',
          idComision: '102',
          subjectName: 'Sistemas Operativos',
          module: MielModuleType.mensajeria,
          title: 'Sin leer vieja',
          body: 'Aviso urgente',
          targetUrl:
              'https://miel.unlam.edu.ar/mensajeria/entrada/comision/102',
          detectedAt: DateTime(2026, 11, 23, 9, 0),
        ),
      );

      await db.setSetting(
        SettingKeys.lastCycle1At,
        DateTime(2026, 11, 23, 13, 45).toIso8601String(),
      );

      expect(await db.getUnreadNotificationsCount(), 1);
      final recent = await db.getRecentNotifications(limit: 5);
      expect(recent, hasLength(5));
      expect(recent.first.title, 'Sin leer vieja');
      expect(recent.first.isRead, isFalse);

      final snapshot = await builder.buildFromDatabase(
        database: db,
        isAuthenticated: true,
        serverStatus: MielServerStatus.online,
      );

      expect(snapshot.isAuthenticated, isTrue);
      expect(snapshot.unreadCount, 1);
      expect(snapshot.pendingSubjectsBadgeCount, 2);
      expect(snapshot.lastSyncAt, DateTime(2026, 11, 23, 13, 45));
      expect(snapshot.recentNotifications, hasLength(5));
      expect(snapshot.recentNotifications.first.title, 'Sin leer vieja');

      // Materias ordenadas por badges: 104 y 102 empatan con 3 badges (desempate alfabético: 'Forzada Visible' antes de 'Sistemas Operativos'), luego 101 (0 badges); 103 excluida
      expect(
        snapshot.activeSubjects.map((s) => s.idComision),
        equals(['104', '102', '101']),
      );
      expect(snapshot.activeSubjects[0].defaultTool, 'foros');
      expect(snapshot.activeSubjects[1].defaultTool, 'mensajeria');
      expect(snapshot.activeSubjects[2].defaultTool, 'contenidos');
    });

    test('devuelve signedOut cuando isAuthenticated es false aunque haya datos en SQLite', () async {
      await db.insertNotificationIfNew(
        DetectedNotification(
          dedupeKey: 'secret',
          idComision: '101',
          subjectName: 'Materia Privada',
          module: MielModuleType.mensajeria,
          title: 'Mensaje privado',
          body: 'No debe mostrarse',
          targetUrl: '',
          detectedAt: DateTime(2026, 11, 23, 10, 0),
        ),
      );

      final snapshot = await builder.buildFromDatabase(
        database: db,
        isAuthenticated: false,
        serverStatus: MielServerStatus.online,
      );

      expect(snapshot.isAuthenticated, isFalse);
      expect(snapshot.unreadCount, 0);
      expect(snapshot.recentNotifications, isEmpty);
      expect(snapshot.activeSubjects, isEmpty);
    });
  });
}
