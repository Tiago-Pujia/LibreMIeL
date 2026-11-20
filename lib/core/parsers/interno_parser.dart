import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro del panel principal `GET /principal/interno/`.
InternoOverview parseInternoHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);

  // Nombre del usuario desde .nombreUsuario (toma la primera línea antes de <br>)
  var studentName = 'Estudiante';
  final userEl = doc.querySelector('.nombreUsuario');
  if (userEl != null) {
    final firstLine = userEl.innerHtml
        .split(RegExp(r'<br\s*/?>', caseSensitive: false))
        .first;
    final parsed = cleanWhitespace(
      html_parser.parseFragment(firstLine).text ?? '',
    );
    if (parsed.isNotEmpty) {
      studentName = parsed;
    }
  }

  // Contador inyectado en <title> o script inline $("title").text("(N) ...")
  var unreadTitleMessages = 0;
  final titleText = doc.querySelector('title')?.text ?? '';
  final titleMatch = RegExp(r'^\((\d+)\)').firstMatch(titleText.trim());
  if (titleMatch != null) {
    unreadTitleMessages = int.tryParse(titleMatch.group(1)!) ?? 0;
  } else {
    final scriptMatch = RegExp(
      r'\$\(["'
      "'"
      r']title["'
      "'"
      r']\)\.text\(["'
      "'"
      r']\((\d+)\)\s*["'
      "'"
      r']',
    ).firstMatch(rawHtml);
    if (scriptMatch != null) {
      unreadTitleMessages = int.tryParse(scriptMatch.group(1)!) ?? 0;
    }
  }

  // Badge global de Novedades en menú lateral (<nav>)
  var globalNovedadesBadge = 0;
  for (final link in doc.querySelectorAll(
    'nav a[href*="/principal/novedades"]',
  )) {
    final badgeEl = link.querySelector('.w3-badge');
    if (badgeEl != null) {
      globalNovedadesBadge = parseBadgeCount(badgeEl.text);
      break;
    }
  }

  // Tarjetas de comisiones (.materia-bloque[data-id])
  final subjects = <MielSubjectBadgeSummary>[];
  final seenIds = <String>{};

  for (final block in doc.querySelectorAll('.materia-bloque')) {
    final idComision = block.attributes['data-id']?.trim() ?? '';
    if (idComision.isEmpty || !seenIds.add(idComision)) continue;

    final name = cleanWhitespace(
      block.querySelector('.materia-titulo')?.text ?? '',
    );
    if (name.isEmpty) continue;

    final isHidden = block.classes.contains('materia-bloque-oculta');

    // Código de comisión (ej. "Com: 01-2900")
    var commissionCode = '';
    for (final small in block.querySelectorAll('.w3-small')) {
      final comMatch = RegExp(r'Com:\s*([^\s<]+)').firstMatch(small.text);
      if (comMatch != null) {
        commissionCode = comMatch.group(1)!.trim();
        break;
      }
    }

    var contenidosBadge = 0;
    var mensajesBadge = 0;
    var foroBadge = 0;
    var hasContenidos = false;
    var hasPortafolio = false;
    var hasMensajeria = false;
    var hasForo = false;
    var hasEvaluacion = false;
    var hasChat = false;
    var hasAutoguia = false;
    var hasEncuestas = false;

    for (final link in block.querySelectorAll(
      '.materia-herramientas a, a[href]',
    )) {
      final href = (link.attributes['href'] ?? '').toLowerCase();
      final badge = parseBadgeCount(link.querySelector('.w3-badge')?.text);

      if (href.contains('/contenido/')) {
        hasContenidos = true;
        if (badge > contenidosBadge) contenidosBadge = badge;
      } else if (href.contains('/portafolio/')) {
        hasPortafolio = true;
      } else if (href.contains('/mensajeria/')) {
        hasMensajeria = true;
        if (badge > mensajesBadge) mensajesBadge = badge;
      } else if (href.contains('/forov2/')) {
        hasForo = true;
        if (badge > foroBadge) foroBadge = badge;
      } else if (href.contains('/evaluacion/')) {
        hasEvaluacion = true;
      } else if (href.contains('/chat/')) {
        hasChat = true;
      } else if (href.contains('/autoguia/')) {
        hasAutoguia = true;
      } else if (href.contains('/encuesta/')) {
        hasEncuestas = true;
      }
    }

    subjects.add(
      MielSubjectBadgeSummary(
        idComision: idComision,
        name: name,
        commissionCode: commissionCode,
        isHidden: isHidden,
        contenidosBadge: contenidosBadge,
        mensajesBadge: mensajesBadge,
        foroBadge: foroBadge,
        hasContenidos: hasContenidos,
        hasPortafolio: hasPortafolio,
        hasMensajeria: hasMensajeria,
        hasForo: hasForo,
        hasEvaluacion: hasEvaluacion,
        hasChat: hasChat,
        hasAutoguia: hasAutoguia,
        hasEncuestas: hasEncuestas,
      ),
    );
  }

  return InternoOverview(
    studentName: studentName,
    globalNovedadesBadge: globalNovedadesBadge,
    unreadTitleMessages: unreadTitleMessages,
    subjects: subjects,
  );
}
