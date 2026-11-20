import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de la bandeja `GET /mensajeria/entrada/comision/{idComision}`.
///
/// Opera exclusivamente sobre el listado (no requiere abrir `/verEntrada/...`),
/// preservando el estado "no leído" del estudiante en MIEL web.
List<InboxMessageSummary> parseMensajeriaEntradaHtml(
  String rawHtml,
  String idComision,
) {
  final doc = html_parser.parse(rawHtml);
  final messages = <InboxMessageSummary>[];
  final seenIds = <String>{};

  for (final row in doc.querySelectorAll(
    'tr.mensaje-no-leido, tr.mensaje-leido',
  )) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) continue;

    final readBtn = row.querySelector('.botonLeido');
    final viewLink =
        row.querySelector('a.verMensaje') ??
        row.querySelector('a[href*="verEntrada"]');
    final detailHref = viewLink?.attributes['href'] ?? '';

    final idFromAttr = readBtn?.attributes['data-id']?.trim() ?? '';
    final idFromHref =
        RegExp(r'/id/(\d+)').firstMatch(detailHref)?.group(1) ?? '';
    final idMensaje = idFromAttr.isNotEmpty ? idFromAttr : idFromHref;
    if (idMensaje.isEmpty || !seenIds.add(idMensaje)) continue;

    final isUnread =
        row.classes.contains('mensaje-no-leido') ||
        readBtn?.attributes['data-estado'] == '0';
    final isPracticeMessage = readBtn?.attributes['data-practica'] == '1';

    final date = cleanWhitespace(cells[0].text);
    final senderName = cleanWhitespace(cells[1].text);
    final hasAttachment =
        cells[2].querySelector('i.material-icons') != null ||
        cells[2]
            .querySelectorAll('[title]')
            .any(
              (e) =>
                  normalizeText(e.attributes['title'] ?? '')
                      .contains('adjunto'),
            ) ||
        normalizeText(cells[2].text).contains('attachment');
    final subject = cleanWhitespace(viewLink?.text ?? cells[3].text);
    final readDate = cells.length >= 6 ? cleanWhitespace(cells[5].text) : '';

    messages.add(
      InboxMessageSummary(
        idMensaje: idMensaje,
        idComision: idComision,
        date: date,
        senderName: senderName,
        subject: subject.isEmpty ? '(Sin asunto)' : subject,
        hasAttachment: hasAttachment,
        isUnread: isUnread,
        isPracticeMessage: isPracticeMessage,
        readDate: readDate,
        detailUrl: resolveMielUrl(detailHref),
      ),
    );
  }

  return messages;
}

/// Determina si el remitente de un mensaje coincide con algún docente (`Tutor/a`) cacheado.
bool isSenderTeacher(
  String senderName,
  Iterable<String> normalizedTeacherNames,
) {
  final normalizedSender = normalizeText(senderName);
  if (normalizedSender.isEmpty) return false;
  for (final teacher in normalizedTeacherNames) {
    if (teacher == normalizedSender) return true;
  }
  return false;
}

/// Detecta los mensajes automáticos generados por MIEL al corregir una entrega en Portafolio.
bool isPortfolioCorrectionMessage(InboxMessageSummary message) {
  final norm = normalizeText(message.subject);
  return norm == 'correccion' || norm.startsWith('correccion ');
}
