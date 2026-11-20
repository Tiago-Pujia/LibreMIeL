import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/parsers/miel_parsers.dart';

import '../fixtures/miel_fixtures.dart';

void main() {
  group('MielParsers', () {
    test('parseInternoHtml extrae materias, ocultas y badges exactos', () {
      final overview = parseInternoHtml(fixtureInternoConBadges);

      expect(overview.studentName, 'ALUMNO, EJEMPLO');
      expect(overview.unreadTitleMessages, 1);
      expect(overview.globalNovedadesBadge, 1);
      expect(overview.subjects, hasLength(1));

      final sub = overview.subjects.first;
      expect(sub.idComision, '117967');
      expect(sub.commissionCode, '01-2900');
      expect(sub.isHidden, isFalse);
      expect(sub.contenidosBadge, 2);
      expect(sub.mensajesBadge, 1);
      expect(sub.foroBadge, 3);
      expect(sub.hasPortafolio, isTrue);
      expect(sub.hasEvaluacion, isTrue);
    });

    test(
      'parseInternoHtml distingue materias ocultas (.materia-bloque-oculta)',
      () {
        final overview = parseInternoHtml(fixtureInternoSinBadges);
        expect(overview.subjects, hasLength(2));
        expect(overview.subjects[0].isHidden, isFalse);
        expect(overview.subjects[1].isHidden, isTrue);
        expect(overview.subjects[1].contenidosBadge, 5);
      },
    );

    test('parseCursoDetallesHtml extrae docentes Tutor/a normalizados', () {
      final details = parseCursoDetallesHtml(fixtureCursoDetalles, '117967');
      expect(details.term, '2C 2026');
      expect(details.modality, 'Presencial');
      expect(
        details.teachers.map((t) => t.normalizedName),
        containsAll(['docente, uno', 'docente, dos']),
      );
    });

    test(
      'parseContenidosHtml captura IDs, w3-pale-yellow y estado de descarga',
      () {
        final items = parseContenidosHtml(
          fixtureContenidosConNovedad,
          '117967',
        );
        expect(items, hasLength(3));

        expect(items[0].idElemento, '5001');
        expect(items[0].moduleName, 'Generalidades');
        expect(items[0].title, 'Acta de Cursada 2026');
        expect(items[0].uploadDate, '19/11/2026');
        expect(items[0].sizeLabel, '150 KB');
        expect(items[0].isHighlightedNew, isTrue);
        expect(items[0].isDownloaded, isFalse);

        expect(items[1].idElemento, '5002');
        expect(items[1].isExternal, isTrue);
        expect(items[1].isHighlightedNew, isTrue);

        expect(items[2].idElemento, '4001');
        expect(items[2].isHighlightedNew, isFalse);
        expect(items[2].isDownloaded, isTrue);
      },
    );

    test('parsePortafolioPracticasHtml y parsePortafolioCorreccionesHtml extraen correcciones', () {
      final practices = parsePortafolioPracticasHtml(
        fixturePortafolioCorregido,
        '117967',
      );
      expect(practices, hasLength(1));
      expect(practices.first.idPractica, '282463');
      expect(practices.first.moduleName, 'Módulo 1');
      expect(practices.first.title, 'TP N°1');
      expect(practices.first.correctionDate, '16/11/2026');
      expect(practices.first.status, 'VISTO');
      expect(practices.first.grade, '9');

      final corrections = parsePortafolioCorreccionesHtml(
        fixturePortafolioEntregasCorregido,
      );
      expect(corrections, hasLength(1));
      expect(corrections.first.status, 'VISTO');
      expect(corrections.first.grade, '9');
      expect(corrections.first.observations, 'Excelente resolución.');
      expect(corrections.first.correctedBy, 'DOCENTE, UNO');
    });

    test('parseMensajeriaEntradaHtml distingue no leídos, adjuntos y mensaje de Corrección', () {
      final msgs = parseMensajeriaEntradaHtml(
        fixtureMensajeriaConCorreccion,
        '117967',
      );
      expect(msgs, hasLength(2));

      expect(msgs[0].idMensaje, '11135488');
      expect(msgs[0].isUnread, isTrue);
      expect(msgs[0].hasAttachment, isTrue);
      expect(isPortfolioCorrectionMessage(msgs[0]), isTrue);
      expect(isSenderTeacher(msgs[0].senderName, ['docente, uno']), isTrue);

      expect(msgs[1].idMensaje, '11130001');
      expect(msgs[1].isUnread, isFalse);
      expect(msgs[1].readDate, '11/11/2026');
    });

    test('parseForoTemasHtml y parseForoMensajesHtml detectan respuestas docentes al usuario', () {
      final topics = parseForoTemasHtml(fixtureForoTemasConActividad, '117967');
      expect(topics, hasLength(1));
      expect(topics.first.idTema, '229745');
      expect(topics.first.unreadBadge, 3);
      expect(topics.first.messageCount, 8);
      expect(topics.first.lastMessageDate, '20/11/2026 12:30:00');

      final thread = parseForoMensajesHtml(
        fixtureForoMensajesHilo,
        '117967',
        '229745',
      );
      expect(thread.currentUserId, '900001');
      expect(thread.messages, hasLength(5));

      final teacherReplyToMe = thread.messages.firstWhere(
        (m) => m.id == '6193120',
      );
      final studentReplyInMyThread = thread.messages.firstWhere(
        (m) => m.id == '6193121',
      );
      final teacherReplyToOther = thread.messages.firstWhere(
        (m) => m.id == '6193201',
      );

      expect(isTeacherReplyToCurrentUser(teacherReplyToMe, thread), isTrue);
      expect(
        isTeacherReplyToCurrentUser(studentReplyInMyThread, thread),
        isFalse,
      );
      expect(isTeacherReplyToCurrentUser(teacherReplyToOther, thread), isFalse);
    });

    test('parseEvaluacionesHtml detecta evaluaciones abiertas y con clave', () {
      final evals = parseEvaluacionesHtml(fixtureEvaluaciones, '117967');
      expect(evals, hasLength(1));
      expect(evals.first.id, '7781');
      expect(evals.first.isEnabled, isTrue);
      expect(evals.first.requiresPassword, isTrue);
      expect(evals.first.status, 'Abierto');
    });
  });
}
