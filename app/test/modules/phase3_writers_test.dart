import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/network/miel_upload_helpers.dart';
import 'package:libremiel/core/parsers/forov2_parser.dart';
import 'package:libremiel/core/parsers/mensajeria_parser.dart';
import 'package:libremiel/core/parsers/portafolio_parser.dart';

void main() {
  group('Fase 3 — Escritura y codificación nativa fiel a MIeL', () {
    test('encodeMielBase64Utf8 y plainTextToMielHtml preservan tildes, saltos de línea y menciones', () {
      const input = 'Hola profe,\n¿Cómo estás? Probando áéíóú ñ.\nSaludos.';
      final html = plainTextToMielHtml(input);
      expect(html, contains('Hola profe,<br>'));
      expect(html, contains('Probando áéíóú ñ.'));

      final base64Encoded = encodeMielBase64Utf8(html);
      final decodedHtml = utf8.decode(base64.decode(base64Encoded));
      expect(decodedHtml, equals(html));

      const mentionAuthor = 'Gómez Martín';
      final mentionPrefix = buildForoMentionPrefixHtml(
        authorUserId: '4321',
        messageId: '9876',
        mentionName: mentionAuthor,
      );
      final htmlWithMention = plainTextToMielHtml(
        'Gracias por la respuesta.',
        mentionPrefixHtml: mentionPrefix,
      );
      expect(
        htmlWithMention,
        contains(
          'class="tagUsuario" data-idUsuario="4321" data-idMensaje="9876">@Gómez Martín</strong>&nbsp;',
        ),
      );
    });

    test('validateMielUploadFile rechaza extensiones prohibidas y archivos que superan el límite de MIeL', () {
      final tempDir = Directory.systemTemp.createTempSync('miel_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final phpFile = File('${tempDir.path}/script.php')
        ..writeAsStringSync('dummy');
      expect(
        validateMielUploadFile(filePath: phpFile.path, maxSizeMb: 40),
        contains('Tipo de archivo no permitido por MIeL (.php)'),
      );

      final validPdf = File('${tempDir.path}/informe.pdf')
        ..writeAsStringSync('contenido de prueba');
      expect(
        validateMielUploadFile(filePath: validPdf.path, maxSizeMb: 40),
        isNull,
      );

      // Simular archivo mayor a 5 MB para foros
      expect(
        validateMielUploadFile(
          filePath: validPdf.path,
          maxSizeMb: 5,
          fileSizeBytes: 6 * 1024 * 1024,
        ),
        contains('supera el límite de 5 MB de MIeL'),
      );
    });

    test('parseMensajeriaRedactarHtml extrae correctamente los destinatarios disponibles de la comisión', () {
      const html = '''
        <html>
          <body>
            <form id="formRedactar" method="post">
              <input type="hidden" name="borrador" id="borrador" value="0">
              <input type="hidden" name="idMensaje" id="idMensaje" value="0">
              <input type="text" name="asunto" id="asunto">
              <div id="listaDestinatarios">
                <a href="javascript:void(0)" data-type="tutores" data-id="101">Prof. Juan Pérez (Tutor)</a>
                <a href="javascript:void(0)" data-type="alumnos" data-id="202">María González (Compañera)</a>
                <a href="javascript:void(0)" data-type="alumnos" data-id="303">Lucas Benítez (Compañero)</a>
              </div>
            </form>
          </body>
        </html>
      ''';

      final formData = parseMensajeriaRedactarHtml(html, '119341');
      expect(formData.recipients.length, equals(3));
      expect(
        formData.recipients.first.displayName,
        equals('Prof. Juan Pérez (Tutor)'),
      );
      expect(formData.recipients.first.contactType, equals('tutores'));
      expect(
        formData.recipients[1].displayName,
        equals('María González (Compañera)'),
      );
      expect(formData.recipients[1].contactType, equals('alumnos'));
    });

    test('parsePortafolioEntregasDetalleHtml extrae metadatos de nueva entrega (#formNuevaEntrega)', () {
      const html = '''
        <div class="practica-detalle">
          <h3>Trabajo Práctico N° 1 - Programación</h3>
          <p>Fecha límite: 20/05/2026</p>
          <div class="consigna">Resolver los ejercicios 1 a 4.</div>

          <form id="formNuevaEntrega" action="/portafolio/event/nuevaEntrega/comision/119341" method="post" enctype="multipart/form-data">
            <input type="hidden" name="codPractica" value="55512">
            <select name="tutorDestinatario">
              <option value="12">Docente Titular</option>
              <option value="14">Docente Adjunto</option>
            </select>
            <input type="text" name="enlace" placeholder="Enlace">
            <textarea name="observaciones"></textarea>
            <input type="file" name="archivo">
          </form>
        </div>
      ''';

      final detail = parsePortafolioEntregasDetalleHtml(
        html,
        '119341',
        '55512',
      );

      expect(detail.submissionForm.canSubmit, isTrue);
      expect(detail.submissionForm.tutors.length, equals(2));
      expect(detail.submissionForm.tutors.first.id, equals('12'));
      expect(
        detail.submissionForm.tutors.first.name,
        equals('Docente Titular'),
      );
    });

    test('parseForoMensajesHtml extrae flags de canPostMessage y mención nativa de respuesta', () {
      const html = '''
        <div class="w3-container">
          <h1>Tema: Dudas sobre Unidad 2</h1>
          <span class="descripcion">Espacio para consultas</span>
          <button class="botonNuevoMensaje w3-button">Nuevo mensaje</button>

          <ul class="foro-mensajes">
            <li class="foro-mensaje" id="idMensaje-7701" data-idmensajepadre="7701">
              <div><strong>Nelson Moret</strong></div>
              <span class="w3-text-gray">Alumno/a</span>
              <div class="foro-contenido-mensaje">Hola a todos</div>
              <button class="btnMostrarDivRespuesta" data-idusuario="881" data-nombreusuario="Nelson">Responder</button>
            </li>
          </ul>
        </div>
      ''';

      final thread = parseForoMensajesHtml(html, '119341', '10');

      expect(thread.canPostMessage, isTrue);
      expect(thread.messages.length, equals(1));
      expect(thread.messages.first.replyMentionName, equals('Nelson'));
    });

    test('parsePortafolioEntregasDetalleHtml deduplica opciones vacías o repetidas de tutores', () {
      const html = '''
        <div class="practica-detalle">
          <form id="formNuevaEntrega" method="post">
            <select name="tutorDestinatario">
              <option value="">Seleccione tutor destinatario</option>
              <option value="0">Todos los docentes de la comisión</option>
              <option value="12">Profesor A</option>
              <option value="12">Profesor A (repetido)</option>
            </select>
            <input type="file" name="archivo">
          </form>
        </div>
      ''';

      final detail = parsePortafolioEntregasDetalleHtml(html, '119341', '100');
      expect(detail.submissionForm.canSubmit, isTrue);
      // Solo deben quedar '0' (deduplicado de '' y '0') y '12' (deduplicado de '12')
      expect(detail.submissionForm.tutors.length, equals(2));
      expect(
        detail.submissionForm.tutors.map((t) => t.id).toSet().length,
        equals(2),
      );
    });
  });
}
