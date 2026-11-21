import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de la bandeja `GET /mensajeria/entrada/comision/{idComision}`.
///
/// Opera exclusivamente sobre el listado (no requiere abrir `/verEntrada/...`),
/// preservando el estado "no leído" del estudiante en MIeL web.
List<InboxMessageSummary> parseMensajeriaEntradaHtml(
  String rawHtml,
  String idComision,
) {
  return parseMensajeriaBandejaHtml(rawHtml, idComision).messages;
}

/// Parser puro completo de bandejas de Mensajería (`entrada`, `salida`, `borradores`, `favoritos`).
MessageBoxPageData parseMensajeriaBandejaHtml(
  String rawHtml,
  String idComision, {
  bool isOutbox = false,
}) {
  final doc = html_parser.parse(rawHtml);
  final messages = <InboxMessageSummary>[];
  final seenIds = <String>{};

  final pageMatch = RegExp(
    r'P[áa]gina\s+(\d+)\s+de\s+(\d+)',
    caseSensitive: false,
  ).firstMatch(doc.body?.text ?? rawHtml);
  final currentPage = pageMatch != null
      ? (int.tryParse(pageMatch.group(1)!) ?? 1)
      : 1;
  final totalPages = pageMatch != null
      ? (int.tryParse(pageMatch.group(2)!) ?? 1)
      : 1;

  final unreadGenMatch = RegExp(
    r'cantidadMensajesGeneralesNoLeidos\s*=\s*(\d+)',
  ).firstMatch(rawHtml);
  final unreadPracMatch = RegExp(
    r'cantidadMensajesPracticasNoLeidos\s*=\s*(\d+)',
  ).firstMatch(rawHtml);
  final unreadGeneralCount = unreadGenMatch != null
      ? (int.tryParse(unreadGenMatch.group(1)!) ?? 0)
      : 0;
  final unreadPracticesCount = unreadPracMatch != null
      ? (int.tryParse(unreadPracMatch.group(1)!) ?? 0)
      : 0;

  var candidateRows = doc.querySelectorAll(
    'tr.mensaje-no-leido, tr.mensaje-leido',
  );
  if (candidateRows.isEmpty) {
    candidateRows = doc.querySelectorAll(
      'table.tabla-mensajes tbody tr, table.w3-table tbody tr',
    );
  }

  for (final row in candidateRows) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) continue;

    final readBtn = row.querySelector('.botonLeido');
    final favBtn = row.querySelector('.botonFavorito');
    final viewLink =
        row.querySelector('a.verMensaje') ??
        row.querySelector('a[href*="verEntrada"]') ??
        row.querySelector('a[href*="verSalida"]') ??
        row.querySelector('a[href*="/mensajeria/redactar/"]');
    final detailHref = viewLink?.attributes['href'] ?? '';

    final idFromRead = readBtn?.attributes['data-id']?.trim() ?? '';
    final idFromFav = favBtn?.attributes['data-id']?.trim() ?? '';
    final idFromHref =
        RegExp(r'/(?:id|borrador|recibido)/(\d+)')
            .firstMatch(detailHref)
            ?.group(1) ??
        '';
    final idMensaje = idFromRead.isNotEmpty
        ? idFromRead
        : (idFromFav.isNotEmpty ? idFromFav : idFromHref);
    if (idMensaje.isEmpty || !seenIds.add(idMensaje)) continue;

    final isUnread =
        !isOutbox &&
        (row.classes.contains('mensaje-no-leido') ||
            readBtn?.attributes['data-estado'] == '0');
    final isPracticeMessage = readBtn?.attributes['data-practica'] == '1';

    final favIconText = cleanWhitespace(favBtn?.querySelector('i')?.text ?? '');
    final isFavorite =
        favBtn?.attributes['data-estado'] == '1' || favIconText == 'star';

    var isReplied = false;
    var readByRecipient = false;
    for (final icon in row.querySelectorAll('i.material-icons')) {
      final glyph = cleanWhitespace(icon.text);
      if (glyph == 'reply') isReplied = true;
      if (glyph == 'done' || glyph == 'done_all') readByRecipient = true;
    }

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

    var readDate = '';
    if (cells.length >= 6) {
      final readClone = cells[5].clone(true);
      for (final hidden in readClone.querySelectorAll('.w3-hide')) {
        hidden.remove();
      }
      readDate = cleanWhitespace(readClone.text);
    }

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
        isFavorite: isFavorite,
        isReplied: isReplied,
        isOutbox: isOutbox || detailHref.contains('/verSalida/'),
        readByRecipient: readByRecipient || readDate.isNotEmpty,
      ),
    );
  }

  return MessageBoxPageData(
    idComision: idComision,
    currentPage: currentPage,
    totalPages: totalPages,
    unreadGeneralCount: unreadGeneralCount,
    unreadPracticesCount: unreadPracticesCount,
    messages: messages,
  );
}

/// Parser puro del detalle de un mensaje `GET /mensajeria/verEntrada/...` o `/verSalida/...`.
///
/// Solo debe invocarse cuando el usuario abre explícitamente un mensaje en Fase 2.
MessageDetail parseMensajeriaDetalleHtml(
  String rawHtml,
  String idComision,
  String idMensaje,
) {
  final doc = html_parser.parse(rawHtml);

  final subject = cleanWhitespace(doc.querySelector('h1')?.text ?? '');

  var senderName = '';
  var senderRole = '';
  final senderSpan = doc.querySelector(
    '.w3-rest span.w3-medium, span.w3-medium',
  );
  if (senderSpan != null) {
    senderName = cleanWhitespace(senderSpan.text)
        .replaceFirst(RegExp(r'^(?:De|Para):\s*', caseSensitive: false), '')
        .trim();
    final parentDiv = senderSpan.parent;
    if (parentDiv != null) {
      final roleSpan = parentDiv.querySelector(
        'span.w3-text-grey, span.w3-text-gray',
      );
      if (roleSpan != null) {
        senderRole = cleanWhitespace(roleSpan.text)
            .replaceFirst(RegExp(r'^[·\-]\s*'), '')
            .trim();
      }
    }
  }

  final normRole = normalizeText(senderRole);
  final isTeacher = normRole.contains('tutor') || normRole.contains('docente');

  var recipientsSummary = '';
  var recipientsPopupUrl = '';
  var dateTime = '';

  final popupLink = doc.querySelector('a.popup-destinatarios');
  if (popupLink != null) {
    recipientsPopupUrl = resolveMielUrl(
      popupLink.attributes['data-mfp-src'] ?? popupLink.attributes['href'],
    );
  }

  for (final div in doc.querySelectorAll(
    '.w3-rest > div.w3-text-grey, .w3-rest > div.w3-text-gray, div.w3-text-grey',
  )) {
    final clone = div.clone(true);
    for (final icon in clone.querySelectorAll('i.material-icons')) {
      icon.remove();
    }
    final txt = cleanWhitespace(clone.text);
    if (txt.isEmpty) continue;
    if (recipientsSummary.isEmpty && normalizeText(txt).startsWith('para:')) {
      recipientsSummary = txt;
    } else if (dateTime.isEmpty && RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(txt)) {
      dateTime = txt;
    }
  }

  final bodyContainer =
      doc.querySelector('div.contrastify') ??
      doc.querySelector('.w3-rest > div.w3-section');
  final bodyHtml = bodyContainer?.innerHtml.trim() ?? '';
  final bodyPlainText = cleanWhitespace(bodyContainer?.text ?? '');

  final attachments = <MielAttachment>[];
  for (final link in doc.querySelectorAll(
    'a[href*="/mensajeria/event/descargar/"]',
  )) {
    final href = link.attributes['href'] ?? '';
    if (href.isEmpty) continue;
    final name = cleanWhitespace(link.text);
    var fileType = 'archivo';
    final parent = link.parent;
    if (parent != null) {
      for (final icon in parent.querySelectorAll('i')) {
        for (final cls in icon.classes) {
          if (cls.startsWith('icon-file-')) {
            fileType = cls.replaceFirst('icon-file-', '');
          }
        }
      }
    }
    attachments.add(
      MielAttachment(
        fileName: name.isEmpty ? 'Adjunto' : name,
        downloadUrl: resolveMielUrl(href),
        fileType: fileType,
      ),
    );
  }

  final senderAvatarEl = doc.querySelector('.fotoRemitente');
  final senderAvatarUrl = extractBackgroundImageUrl(
    senderAvatarEl?.attributes['style'],
  );

  return MessageDetail(
    idComision: idComision,
    idMensaje: idMensaje,
    subject: subject.isEmpty ? '(Sin asunto)' : subject,
    senderName: senderName.isEmpty ? 'Remitente' : senderName,
    senderRole: senderRole,
    senderAvatarUrl: senderAvatarUrl,
    isTeacher: isTeacher,
    recipientsSummary: recipientsSummary,
    recipientsPopupUrl: recipientsPopupUrl,
    dateTime: dateTime,
    bodyHtml: bodyHtml,
    bodyPlainText: bodyPlainText,
    attachments: attachments,
  );
}

/// Parser puro de `GET /mensajeria/verDestinatariosEntrada/...`.
List<MessageRecipient> parseMensajeriaDestinatariosHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final recipients = <MessageRecipient>[];
  final seen = <String>{};

  for (final el in doc.querySelectorAll(
    'li, tr, .w3-tag, .w3-chip, .destinatario, div',
  )) {
    // Evitar contenedores padres grandes con muchos hijos
    if (el.children.length > 3) continue;
    final clone = el.clone(true);
    var roleType = 'alumno';
    for (final icon in clone.querySelectorAll('i.material-icons')) {
      final glyph = cleanWhitespace(icon.text);
      if (glyph == 'school') roleType = 'tutor';
      if (glyph == 'group') roleType = 'grupo';
      icon.remove();
    }
    if (el.classes.contains('w3-orange')) roleType = 'tutor';
    if (el.classes.contains('w3-green')) roleType = 'grupo';
    if (el.classes.contains('w3-red')) roleType = 'alumnos';

    final name = cleanWhitespace(clone.text);
    if (name.isEmpty ||
        name.length > 100 ||
        normalizeText(name) == 'destinatarios' ||
        normalizeText(name) == 'cerrar') {
      continue;
    }
    if (seen.add(name)) {
      recipients.add(MessageRecipient(name: name, roleType: roleType));
    }
  }

  return recipients;
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

/// Detecta los mensajes automáticos generados por MIeL al corregir una entrega en Portafolio.
bool isPortfolioCorrectionMessage(InboxMessageSummary message) {
  final norm = normalizeText(message.subject);
  return norm == 'correccion' || norm.startsWith('correccion ');
}
