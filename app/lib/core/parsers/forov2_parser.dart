import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro del listado de temas `GET /forov2/temas/comision/{idComision}`.
/// Este endpoint es de solo lectura y no altera los badges de no leídos en MIEL.
List<ForumTopicSummary> parseForoTemasHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final topics = <ForumTopicSummary>[];
  final seenIds = <String>{};

  for (final block in doc.querySelectorAll('.foro-tema')) {
    final link = block.querySelector('a[href*="/forov2/mensajes/comision/"]');
    if (link == null) continue;

    final href = link.attributes['href'] ?? '';
    final idTema = RegExp(r'/tema/(\d+)').firstMatch(href)?.group(1) ?? '';
    if (idTema.isEmpty || !seenIds.add(idTema)) continue;

    // Título (clonando para no arrastrar el texto del badge mobile)
    final titleContainer =
        block.querySelector('.w3-medium strong') ??
        block.querySelector('strong');
    final title = cleanWhitespace(titleContainer?.text ?? 'Tema #$idTema');

    final description = cleanWhitespace(
      block.querySelector('.w3-padding-4')?.text ?? '',
    );

    // Badge de no leídos (prioriza .badge-icono o el primer .w3-badge del bloque)
    final badgeEl =
        block.querySelector('.badge-icono') ?? block.querySelector('.w3-badge');
    final unreadBadge = parseBadgeCount(badgeEl?.text);

    final fullText = cleanWhitespace(block.text);
    final countMatch = RegExp(
      r'(\d+)\s+mensajes?',
      caseSensitive: false,
    ).firstMatch(fullText);
    final messageCount = countMatch != null
        ? (int.tryParse(countMatch.group(1)!) ?? 0)
        : 0;

    final lastMsgMatch = RegExp(
      r'[ÚUúu]ltimo mensaje\s+([0-9]{2}/[0-9]{2}/[0-9]{4}(?:\s+[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)?)',
    ).firstMatch(fullText);
    final lastMessageDate = lastMsgMatch?.group(1)?.trim() ?? '';

    final isClosed =
        block
            .querySelectorAll('[title]')
            .any(
              (e) =>
                  normalizeText(e.attributes['title'] ?? '')
                      .contains('tema vencido'),
            ) ||
        normalizeText(fullText).contains('speaker_notes_off') ||
        normalizeText(fullText).contains('tema vencido');

    topics.add(
      ForumTopicSummary(
        idTema: idTema,
        idComision: idComision,
        title: title,
        description: description,
        messageCount: messageCount,
        lastMessageDate: lastMessageDate,
        unreadBadge: unreadBadge,
        isClosed: isClosed,
        url: resolveMielUrl(href),
      ),
    );
  }

  return topics;
}

/// Parser puro de un hilo completo `GET /forov2/mensajes/comision/{idComision}/tema/{idTema}`.
ForumThreadData parseForoMensajesHtml(
  String rawHtml,
  String idComision,
  String idTema,
) {
  final doc = html_parser.parse(rawHtml);

  // Extraer var usuarioId = '123456'; del JS inline
  final uidMatch = RegExp(r'''var\s+usuarioId\s*=\s*['"](\d+)['"]''')
      .firstMatch(rawHtml);
  final currentUserId = uidMatch?.group(1) ?? '';

  final rawH1 = cleanWhitespace(doc.querySelector('h1')?.text ?? '');
  final title = rawH1
      .replaceFirst(RegExp(r'^Tema:\s*', caseSensitive: false), '')
      .trim();

  final messages = <ForumMessageItem>[];

  for (final li in doc.querySelectorAll('li.foro-mensaje, li.foro-respuesta')) {
    final rawId = li.id; // ej: idMensaje-6193115
    final id = rawId.replaceFirst(RegExp(r'^idMensaje-'), '').trim();
    if (id.isEmpty) continue;

    final parentId =
        li.attributes['data-idmensajepadre']?.trim() ??
        li.attributes['data-idMensajePadre']?.trim() ??
        id;
    final isReply = li.classes.contains('foro-respuesta');

    // Autor
    final authorEl =
        li.querySelector('div > strong') ?? li.querySelector('strong');
    final authorName = cleanWhitespace(authorEl?.text ?? 'Desconocido');

    // Rol (Tutor/a, Docente, Alumno/a)
    var role = '';
    for (final gray in li.querySelectorAll('.w3-text-gray')) {
      final clone = gray.clone(true);
      for (final icon in clone.querySelectorAll('i')) {
        icon.remove();
      }
      final candidate = cleanWhitespace(clone.text);
      if (candidate.isNotEmpty) {
        role = candidate;
        break;
      }
    }
    final normRole = normalizeText(role);
    final isTeacher =
        normRole.contains('tutor') || normRole.contains('docente');

    // ID del autor desde .btnMostrarDivRespuesta[data-idusuario]
    final replyBtn = li.querySelector('.btnMostrarDivRespuesta');
    final authorId =
        replyBtn?.attributes['data-idusuario']?.trim() ??
        replyBtn?.attributes['data-idUsuario']?.trim() ??
        '';

    // Fecha "Enviado el DD/MM/YYYY HH:MM..."
    final dateMatch = RegExp(
      r'Enviado el\s+([0-9]{2}/[0-9]{2}/[0-9]{4}(?:\s+[0-9]{2}:[0-9]{2}(?::[0-9]{2})?)?)',
      caseSensitive: false,
    ).firstMatch(li.text);
    final date = dateMatch?.group(1)?.trim() ?? '';

    // Cuerpo del mensaje y menciones .tagUsuario
    final contentEl = li.querySelector('.foro-contenido-mensaje');
    final bodyText = cleanWhitespace(contentEl?.text ?? '');
    final mentionedUserIds = <String>{};
    final mentionedMessageIds = <String>{};

    if (contentEl != null) {
      for (final tag in contentEl.querySelectorAll('.tagUsuario')) {
        final taggedUid =
            tag.attributes['data-idusuario']?.trim() ??
            tag.attributes['data-idUsuario']?.trim() ??
            '';
        final taggedMsgId =
            tag.attributes['data-idmensaje']?.trim() ??
            tag.attributes['data-idMensaje']?.trim() ??
            '';
        if (taggedUid.isNotEmpty) mentionedUserIds.add(taggedUid);
        if (taggedMsgId.isNotEmpty) mentionedMessageIds.add(taggedMsgId);
      }
    }

    messages.add(
      ForumMessageItem(
        id: id,
        parentId: parentId,
        isReply: isReply,
        authorName: authorName,
        authorId: authorId,
        role: role,
        isTeacher: isTeacher,
        date: date,
        bodyText: bodyText,
        mentionedUserIds: mentionedUserIds,
        mentionedMessageIds: mentionedMessageIds,
      ),
    );
  }

  return ForumThreadData(
    idComision: idComision,
    idTema: idTema,
    title: title.isEmpty ? 'Tema #$idTema' : title,
    currentUserId: currentUserId,
    messages: messages,
  );
}

/// Determina si un mensaje de foro representa una respuesta de un docente (`Tutor/a`)
/// dirigida al usuario autenticado, aplicando las 3 reglas documentadas en `docs/04`.
bool isTeacherReplyToCurrentUser(
  ForumMessageItem message,
  ForumThreadData thread,
) {
  if (!message.isTeacher) return false;
  final uid = thread.currentUserId;
  if (uid.isEmpty || message.authorId == uid) return false;

  // Regla 1: Mención explícita .tagUsuario[data-idusuario="{usuarioId}"]
  if (message.mentionedUserIds.contains(uid)) {
    return true;
  }

  // Mapa de mensajes propios del usuario en este tema
  final ownMessageIds = <String>{};
  final ownThreadParentIds = <String>{};
  for (final m in thread.messages) {
    if (m.authorId == uid) {
      ownMessageIds.add(m.id);
      ownThreadParentIds.add(m.parentId);
    }
  }

  // Regla 2: .tagUsuario[data-idmensaje] apunta a un mensaje del usuario
  if (message.mentionedMessageIds.any(ownMessageIds.contains)) {
    return true;
  }

  // Regla 3: Pertenece a un hilo (data-idmensajepadre) iniciado o intervenido por el usuario
  if (message.isReply && ownThreadParentIds.contains(message.parentId)) {
    return true;
  }

  return false;
}
