import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/network/miel_client.dart';
import 'package:libremiel/core/parsers/miel_parsers.dart';

import '../fixtures/miel_fixtures.dart';

void main() {
  group('MielParsers', () {
    test('parseInternoHtml extrae materias, ocultas, foto de perfil y badges exactos', () {
      final overview = parseInternoHtml(fixtureInternoConBadges);

      expect(overview.studentName, 'ALUMNO, EJEMPLO');
      expect(
        overview.studentAvatarUrl,
        'https://miel.unlam.edu.ar/data2/avatares/demo_student.jpg?1001',
      );
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

    test('parseInternoHtml extrae subjectCode, commissionCode con guiones y roleLabel', () {
      const html = '''
        <html><body>
          <div class="materia-bloque" data-id="11001">
            <div class="materia-titulo">Programación Inicial</div>
            <div class="w3-small">3623 - Com: 08-4300 - Alumno/a</div>
            <div class="materia-herramientas">
              <a href="/contenido/archivos/comision/11001">Contenidos</a>
              <a href="/autoguia/index/comision/11001">Autoguía</a>
              <a href="/encuesta/encuestas/comision/11001">Encuestas</a>
            </div>
          </div>
          <div class="materia-bloque" data-id="11002">
            <div class="materia-titulo">Tutorías-DIIT</div>
            <div class="w3-small">TUTO_DIIT - Com: 2026-INFORMATICA-02 - Alumno/a</div>
            <div class="materia-herramientas">
              <a href="/chat/salas/comision/11002">Chat</a>
            </div>
          </div>
        </body></html>
        ''';
      final overview = parseInternoHtml(html);
      expect(overview.subjects, hasLength(2));

      final s1 = overview.subjects[0];
      expect(s1.subjectCode, '3623');
      expect(s1.commissionCode, '08-4300');
      expect(s1.roleLabel, 'Alumno/a');
      expect(s1.hasAutoguia, isTrue);
      expect(s1.hasEncuestas, isTrue);

      final s2 = overview.subjects[1];
      expect(s2.subjectCode, 'TUTO_DIIT');
      expect(s2.commissionCode, '2026-INFORMATICA-02');
      expect(s2.roleLabel, 'Alumno/a');
      expect(s2.hasChat, isTrue);
    });

    test('parseCursoDetallesHtml extrae docentes Tutor/a normalizados', () {
      final details = parseCursoDetallesHtml(fixtureCursoDetalles, '117967');
      expect(details.term, '2C 2026');
      expect(details.modality, 'Presencial');
      expect(
        details.teachers.map((t) => t.normalizedName),
        containsAll(['docente, uno', 'docente, dos']),
      );
    });

    test('parseContenidosHtml captura IDs, w3-pale-yellow, descripción y estado de descarga', () {
      final items = parseContenidosHtml(fixtureContenidosConNovedad, '117967');
      expect(items, hasLength(3));

      expect(items[0].idElemento, '5001');
      expect(items[0].moduleName, 'Generalidades');
      expect(items[0].title, 'Acta de Cursada 2026');
      expect(items[0].description, 'Descripción oculta');
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
    });

    test('parseContenidosPageHtml preserva acordeones .desplegarModulo y múltiples pares thead/tbody', () {
      final page = parseContenidosPageHtml(
        fixtureContenidosFase2Jerarquico,
        '117967',
      );
      expect(page.sections, hasLength(2));
      expect(page.allItems, hasLength(3));

      final folderSection = page.sections[0];
      expect(folderSection.isCollapsibleFolder, isTrue);
      expect(folderSection.title, 'Presentaciones de Clase');
      expect(folderSection.unreadBadge, 1);
      expect(folderSection.submodules, hasLength(1));
      expect(folderSection.submodules.first.title, 'Slides Teoría');

      final directSection = page.sections[1];
      expect(directSection.isCollapsibleFolder, isFalse);
      expect(directSection.submodules, hasLength(2));
      expect(
        directSection.submodules[0].title,
        'Módulo 00 | Presentación de la materia',
      );
      expect(
        directSection.submodules[1].title,
        'Módulo 01 | Modelos de Ciclo de Vida',
      );
      expect(
        directSection.submodules[1].items.first.description,
        'https://prezi.example.com/ciclo-de-vida',
      );
    });

    test('parsePortafolioPracticasHtml, parsePortafolioEntregasDetalleHtml y parsePortafolioNotasHtml', () {
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

      final detail = parsePortafolioEntregasDetalleHtml(
        fixturePortafolioEntregasCorregido,
        '117967',
        '282463',
      );
      expect(detail.headerTitle, 'Trabajos Prácticos - TP N°1');
      expect(detail.deliveryModeLabel, 'Entrega obligatoria grupal');
      expect(detail.corrections, hasLength(1));
      expect(detail.corrections.first.status, 'VISTO');
      expect(detail.corrections.first.grade, '9');
      expect(detail.corrections.first.observations, 'Excelente resolución.');
      expect(detail.corrections.first.correctedBy, 'DOCENTE, UNO');

      expect(detail.deliveries, hasLength(1));
      expect(detail.deliveries.first.title, '1º ENTREGA');
      expect(detail.deliveries.first.fileName, 'Entrega-Grupo-Demo.pdf');
      expect(detail.deliveries.first.isGroupDelivery, isTrue);
      expect(detail.deliveries.first.groupName, 'Grupo Demo');
      expect(detail.deliveries.first.members, hasLength(2));
      expect(detail.deliveries.first.message, 'Adjuntamos entrega final');

      final notas = parsePortafolioNotasHtml(fixturePortafolioNotasAsistencia);
      expect(notas.attendance, hasLength(3));
      expect(notas.attendance[0].date, '18/08/2026');
      expect(notas.attendance[0].isPresent, isTrue);
      expect(notas.attendance[0].isJustified, isFalse);
      expect(notas.attendance[0].modality, 'Virtual');
      expect(notas.attendance[1].date, '25/08/2026');
      expect(notas.attendance[1].status, 'Justificado');
      expect(notas.attendance[1].isPresent, isFalse);
      expect(notas.attendance[1].isJustified, isTrue);
      expect(notas.attendance[2].isPresent, isFalse);
      expect(notas.attendance[2].isJustified, isFalse);
    });

    test('parseMensajeriaBandejaHtml y parseMensajeriaDetalleHtml extraen paginación, favoritos, respuesta y adjuntos', () {
      final box = parseMensajeriaBandejaHtml(
        fixtureMensajeriaConCorreccion,
        '117967',
      );
      expect(box.currentPage, 1);
      expect(box.totalPages, 2);
      expect(box.messages, hasLength(2));

      expect(box.messages[0].idMensaje, '11135488');
      expect(box.messages[0].isUnread, isTrue);
      expect(box.messages[0].isFavorite, isTrue);
      expect(box.messages[0].hasAttachment, isTrue);
      expect(isPortfolioCorrectionMessage(box.messages[0]), isTrue);
      expect(
        isSenderTeacher(box.messages[0].senderName, ['docente, uno']),
        isTrue,
      );

      expect(box.messages[1].idMensaje, '11130001');
      expect(box.messages[1].isUnread, isFalse);
      expect(box.messages[1].isReplied, isTrue);
      expect(box.messages[1].readDate, '11/11/2026');

      final detail = parseMensajeriaDetalleHtml(
        fixtureMensajeriaVerEntradaDetalle,
        '117967',
        '11023589',
      );
      expect(detail.subject, 'Ejercicio de bondad de ajuste');
      expect(detail.senderName, 'DOCENTE, UNO');
      expect(detail.senderRole, 'Tutor/a');
      expect(
        detail.senderAvatarUrl,
        'https://miel.unlam.edu.ar/data2/avatares/demo_teacher.jpg?2002',
      );
      expect(detail.isTeacher, isTrue);
      expect(detail.recipientsSummary, 'Para: 49 personas');
      expect(detail.recipientsPopupUrl, contains('verDestinatariosEntrada'));
      expect(detail.dateTime, '20/10/2026 16:39:47 hs.');
      expect(detail.bodyPlainText, contains('presencial'));
      expect(detail.attachments, hasLength(1));
      expect(detail.attachments.first.fileName, 'enunciado_bondad.pdf');
      expect(detail.attachments.first.fileType, 'pdf');
    });

    test('parseForoTemasHtml y parseForoMensajesHtml detectan temas públicos, adjuntos, votos y respuestas docentes', () {
      final topics = parseForoTemasHtml(fixtureForoTemasConActividad, '117967');
      expect(topics, hasLength(1));
      expect(topics.first.idTema, '229745');
      expect(topics.first.unreadBadge, 3);
      expect(topics.first.isPublic, isTrue);
      expect(topics.first.description, 'Espacio de consultas');
      expect(topics.first.messageCount, 8);
      expect(topics.first.lastMessageDate, '20/11/2026 12:30:00');

      final thread = parseForoMensajesHtml(
        fixtureForoMensajesHilo,
        '117967',
        '229745',
      );
      expect(thread.currentUserId, '900001');
      expect(thread.totalMessagesCount, 5);
      expect(thread.messages, hasLength(5));

      final rootMsg = thread.messages.firstWhere((m) => m.id == '6193115');
      expect(
        rootMsg.authorAvatarUrl,
        'https://miel.unlam.edu.ar/data2/avatares/demo_student.jpg?1001',
      );
      expect(rootMsg.likesCount, 2);
      expect(rootMsg.imageAttachments, hasLength(1));
      expect(
        rootMsg.imageAttachments.first.fileName,
        '3656_captura_formula.png',
      );

      final teacherReplyToMe = thread.messages.firstWhere(
        (m) => m.id == '6193120',
      );
      expect(
        teacherReplyToMe.authorAvatarUrl,
        'https://miel.unlam.edu.ar/data2/avatares/demo_teacher.jpg?2002',
      );
      expect(teacherReplyToMe.fileAttachments, hasLength(1));
      expect(
        teacherReplyToMe.fileAttachments.first.fileName,
        'Guia4-Resuelta.pdf',
      );
      expect(teacherReplyToMe.fileAttachments.first.fileType, 'pdf');

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

    test('parseEvaluacionesHtml soporta tanto tablas de 5 como de 6 columnas oficiales', () {
      final evals5 = parseEvaluacionesHtml(fixtureEvaluaciones, '117967');
      expect(evals5, hasLength(1));
      expect(evals5.first.id, '7781');
      expect(evals5.first.isEnabled, isTrue);
      expect(evals5.first.requiresPassword, isTrue);
      expect(evals5.first.status, 'Abierto');

      final evals6 = parseEvaluacionesHtml(
        fixtureEvaluaciones6Columnas,
        '117919',
      );
      expect(evals6, hasLength(1));
      expect(evals6.first.id, '8890');
      expect(evals6.first.type, 'Auto-Evaluacion');
      expect(evals6.first.isEnabled, isTrue);
      expect(evals6.first.isLockOpen, isTrue);
      expect(evals6.first.status, '0/2 intentos');
    });

    test('extractDownloadedFileName sanitiza nombres desde Content-Disposition y URLs de MIeL', () {
      expect(
        extractDownloadedFileName(
          contentDisposition: 'attachment; filename="Guia_TP_1.pdf"',
          urlOrPath:
              '/contenido/event/descargarElemento/comision/117/a/foo/id/1',
        ),
        'Guia_TP_1.pdf',
      );
      expect(
        extractDownloadedFileName(
          urlOrPath: '/mensajeria/event/descargar/comision/117919/a/3656%5C_enunciado_bondad.pdf/t/M',
        ),
        'enunciado_bondad.pdf',
      );
    });
  });
}
