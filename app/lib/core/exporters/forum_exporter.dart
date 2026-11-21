import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/miel_models.dart';

/// Sanitiza una cadena de texto para utilizarla como nombre de archivo o carpeta
/// de forma segura en Windows, macOS, Linux y Android.
String sanitizeFileName(String input, {int maxLength = 100}) {
  var sanitized = input.trim();
  if (sanitized.isEmpty) return 'sin_nombre';

  // Caracteres prohibidos en Windows y sistemas POSIX
  sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  // Colapsar espacios consecutivos
  sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

  // Eliminar puntos o espacios al inicio y al final (problemáticos en Windows)
  sanitized = sanitized.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');

  if (sanitized.isEmpty) return 'sin_nombre';

  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength).trim();
  }

  return sanitized;
}

/// Decodifica entidades HTML tanto nominales como numéricas.
String decodeHtmlEntities(String text) {
  if (text.isEmpty) return '';

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&aacute;': 'á',
    '&eacute;': 'é',
    '&iacute;': 'í',
    '&oacute;': 'ó',
    '&uacute;': 'ú',
    '&Aacute;': 'Á',
    '&Eacute;': 'É',
    '&Iacute;': 'Í',
    '&Oacute;': 'Ó',
    '&Uacute;': 'Ú',
    '&ntilde;': 'ñ',
    '&Ntilde;': 'Ñ',
    '&middot;': '·',
    '&bull;': '•',
    '&hellip;': '…',
    '&ndash;': '-',
    '&mdash;': '—',
    '&deg;': '°',
    '&plusmn;': '±',
    '&times;': '×',
    '&divide;': '÷',
  };

  var result = text;
  entities.forEach((entity, char) {
    result = result.replaceAll(entity, char);
  });

  // Entidades numéricas decimales y hexadecimales
  result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1)!);
    return code != null ? String.fromCharCode(code) : match.group(0)!;
  });

  result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    final code = int.tryParse(match.group(1)!, radix: 16);
    return code != null ? String.fromCharCode(code) : match.group(0)!;
  });

  return result;
}

/// Convierte el cuerpo HTML de un mensaje de MIeL en Markdown limpio y legible,
/// apto tanto para lectura humana como para procesamiento con modelos de IA.
String htmlToCleanMarkdown(String rawHtml) {
  if (rawHtml.trim().isEmpty) return '';

  var md = rawHtml;

  // Saltos de línea y párrafos
  md = md.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  md = md.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
  md = md.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');

  // Formato de texto básico
  md = md.replaceAllMapped(
    RegExp(r'<(?:strong|b)[^>]*>(.*?)</(?:strong|b)>', caseSensitive: false, dotAll: true),
    (m) => '**${m.group(1)}**',
  );
  md = md.replaceAllMapped(
    RegExp(r'<(?:em|i)[^>]*>(.*?)</(?:em|i)>', caseSensitive: false, dotAll: true),
    (m) => '*${m.group(1)}*',
  );
  md = md.replaceAllMapped(
    RegExp(r'<u[^>]*>(.*?)</u>', caseSensitive: false, dotAll: true),
    (m) => m.group(1) ?? '',
  );

  // Menciones nativas de MIeL (.tagUsuario)
  md = md.replaceAllMapped(
    RegExp(r'<strong[^>]*class="[^"]*tagUsuario[^"]*"[^>]*>(.*?)</strong>', caseSensitive: false, dotAll: true),
    (m) => m.group(1)?.trim() ?? '',
  );

  // Listas
  md = md.replaceAllMapped(
    RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true),
    (m) => '\n- ${m.group(1)?.trim()}',
  );
  md = md.replaceAll(RegExp(r'</?(?:ul|ol)[^>]*>', caseSensitive: false), '\n');

  // Enlaces
  md = md.replaceAllMapped(
    RegExp(r'<a[^>]+href="([^"]*)"[^>]*>(.*?)</a>', caseSensitive: false, dotAll: true),
    (m) {
      final href = m.group(1) ?? '';
      var text = (m.group(2) ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
      return text.isNotEmpty ? '[$text]($href)' : href;
    },
  );

  // Eliminar el resto de tags HTML (div, span, font, etc.)
  md = md.replaceAll(RegExp(r'<[^>]+>'), '');

  // Decodificar entidades
  md = decodeHtmlEntities(md);

  // Normalizar saltos de línea repetidos
  md = md.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return md.trim();
}

/// Prefija cada línea con `> ` para formatear citas en Markdown.
String _citeMarkdown(String text) {
  if (text.isEmpty) return '';
  return text.split('\n').map((l) => l.trim().isNotEmpty ? '> $l' : '>').join('\n');
}

/// Genera el contenido Markdown de un hilo completo de foro.
String generateForumMarkdown(
  ForumThreadData thread, {
  required String subjectName,
  required String commissionCode,
  bool hasLocalAttachments = true,
}) {
  final lines = <String>[];
  final dateFormatted = DateTime.now().toLocal().toString().split('.').first;

  lines.add('# Tema: ${thread.title}');
  lines.add('');
  final codDisplay = commissionCode.isNotEmpty ? commissionCode : 'Comisión ${thread.idComision}';
  lines.add('- **Materia:** $subjectName ($codDisplay)');
  lines.add('- **Comisión ID:** ${thread.idComision}');
  lines.add('- **Tema ID:** ${thread.idTema}');
  lines.add('- **Total de Mensajes:** ${thread.messages.length}');
  lines.add('- **Fecha de Respaldo:** $dateFormatted');
  if (thread.description.isNotEmpty) {
    lines.add('- **Descripción:** ${thread.description}');
  }
  lines.add('');
  lines.add('---');
  lines.add('');

  for (final m in thread.messages) {
    final roleText = m.role.isNotEmpty ? ' (${m.role})' : '';
    final dateText = m.date.isNotEmpty ? '*Fecha: ${m.date}*' : '';

    final allAttachments = [...m.fileAttachments, ...m.imageAttachments];
    var attachmentsMd = '';
    if (allAttachments.isNotEmpty) {
      final links = allAttachments.map((a) {
        final ref = hasLocalAttachments ? 'adjuntos/${a.fileName}' : a.downloadUrl;
        return '- [${a.fileName}]($ref)';
      });
      attachmentsMd = '\n\n**Adjuntos:**\n${links.join('\n')}';
    }

    final bodyMd = htmlToCleanMarkdown(m.bodyHtml.isNotEmpty ? m.bodyHtml : m.bodyText);
    final fullMessageText = (bodyMd + attachmentsMd).trim();

    if (m.isReply) {
      final header = '> #### [Respuesta #${m.id} a #${m.parentId}] ${m.authorName}$roleText\n'
          '${dateText.isNotEmpty ? '> $dateText\n>' : '>'}';
      final citedBody = _citeMarkdown(fullMessageText);
      lines.add(header);
      lines.add(citedBody);
      lines.add('');
    } else {
      lines.add('### [Mensaje #${m.id}] ${m.authorName}$roleText');
      if (dateText.isNotEmpty) lines.add(dateText);
      lines.add('');
      lines.add(fullMessageText);
      lines.add('');
      lines.add('---');
      lines.add('');
    }
  }

  return '${lines.join('\n').trim()}\n';
}

/// Genera el objeto JSON estructurado con el árbol completo de mensajes del tema.
Map<String, dynamic> generateForumJson(
  ForumThreadData thread, {
  required String subjectName,
  required String commissionCode,
}) {
  return {
    'materia': subjectName,
    'codigoComision': commissionCode,
    'idComision': thread.idComision,
    'idTema': thread.idTema,
    'tituloTema': thread.title,
    'descripcion': thread.description,
    'extraidoEn': DateTime.now().toUtc().toIso8601String(),
    'totalMensajes': thread.messages.length,
    'mensajes': thread.messages.map((m) {
      final allAttachments = [...m.fileAttachments, ...m.imageAttachments];
      return {
        'id': m.id,
        'parentId': m.parentId,
        'esRespuesta': m.isReply,
        'autor': m.authorName,
        'autorId': m.authorId,
        'rol': m.role,
        'fecha': m.date,
        'meGusta': m.likesCount,
        'contenidoHtml': m.bodyHtml,
        'contenidoMarkdown': htmlToCleanMarkdown(m.bodyHtml.isNotEmpty ? m.bodyHtml : m.bodyText),
        'adjuntos': allAttachments.map((a) => {
          'tipo': a.isImage ? 'imagen' : a.fileType,
          'nombreArchivo': a.fileName,
          'urlOriginal': a.downloadUrl,
          'rutaLocal': 'adjuntos/${a.fileName}',
        }).toList(),
      };
    }).toList(),
  };
}

/// Genera un documento HTML offline autocontenido y estilizado con la estética de LibreMIeL.
String generateForumHtml(
  ForumThreadData thread, {
  required String subjectName,
  required String commissionCode,
  bool hasLocalAttachments = true,
}) {
  final buffer = StringBuffer();
  final dateFormatted = DateTime.now().toLocal().toString().split('.').first;
  final codDisplay = commissionCode.isNotEmpty ? commissionCode : 'Comisión ${thread.idComision}';

  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html lang="es">');
  buffer.writeln('<head>');
  buffer.writeln('  <meta charset="UTF-8">');
  buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
  buffer.writeln('  <title>${htmlEscape.convert(thread.title)} — LibreMIeL</title>');
  buffer.writeln('  <style>');
  buffer.writeln('''
    :root {
      --primary: #009674;
      --primary-dark: #128268;
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --text: #1e293b;
      --text-muted: #64748b;
      --border: #e2e8f0;
      --badge-teacher-bg: #e6f4f1;
      --badge-teacher-text: #007a5e;
      --badge-student-bg: #f1f5f9;
      --badge-student-text: #475569;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #0f172a;
        --card-bg: #1e293b;
        --text: #f1f5f9;
        --text-muted: #94a3b8;
        --border: #334155;
        --badge-teacher-bg: #134e48;
        --badge-teacher-text: #5eead4;
        --badge-student-bg: #334155;
        --badge-student-text: #cbd5e1;
      }
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.6;
      margin: 0;
      padding: 24px;
    }
    .container {
      max-width: 900px;
      margin: 0 auto;
    }
    .header-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .header-card h1 {
      margin: 0 0 12px 0;
      color: var(--primary);
      font-size: 1.75rem;
    }
    .meta-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
      font-size: 0.9rem;
      color: var(--text-muted);
    }
    .message-item {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 20px;
      margin-bottom: 16px;
      box-shadow: 0 1px 2px rgba(0,0,0,0.04);
    }
    .message-reply {
      margin-left: 28px;
      border-left: 4px solid var(--primary);
      background-color: var(--card-bg);
    }
    .message-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 12px;
      flex-wrap: wrap;
      gap: 8px;
    }
    .author-info {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .author-name {
      font-weight: 600;
      font-size: 1rem;
    }
    .role-badge {
      font-size: 0.75rem;
      padding: 2px 8px;
      border-radius: 9999px;
      font-weight: 500;
    }
    .role-teacher {
      background-color: var(--badge-teacher-bg);
      color: var(--badge-teacher-text);
    }
    .role-student {
      background-color: var(--badge-student-bg);
      color: var(--badge-student-text);
    }
    .message-date {
      font-size: 0.85rem;
      color: var(--text-muted);
    }
    .message-body {
      font-size: 0.95rem;
      word-break: break-word;
    }
    .message-body p { margin-top: 0; }
    .attachments-box {
      margin-top: 14px;
      padding-top: 12px;
      border-top: 1px dashed var(--border);
      font-size: 0.85rem;
    }
    .attachment-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 6px;
      color: var(--primary);
      text-decoration: none;
      margin-right: 8px;
      margin-top: 6px;
    }
    .attachment-pill:hover {
      text-decoration: underline;
    }
    .footer {
      text-align: center;
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid var(--border);
    }
  ''');
  buffer.writeln('  </style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('  <div class="container">');

  // Header Card
  buffer.writeln('    <div class="header-card">');
  buffer.writeln('      <h1>${htmlEscape.convert(thread.title)}</h1>');
  buffer.writeln('      <div class="meta-grid">');
  buffer.writeln('        <div><strong>Materia:</strong> ${htmlEscape.convert(subjectName)} (${htmlEscape.convert(codDisplay)})</div>');
  buffer.writeln('        <div><strong>Comisión ID:</strong> ${htmlEscape.convert(thread.idComision)}</div>');
  buffer.writeln('        <div><strong>Tema ID:</strong> ${htmlEscape.convert(thread.idTema)}</div>');
  buffer.writeln('        <div><strong>Mensajes:</strong> ${thread.messages.length}</div>');
  buffer.writeln('        <div><strong>Respaldo:</strong> $dateFormatted</div>');
  if (thread.description.isNotEmpty) {
    buffer.writeln('        <div style="grid-column: 1 / -1;"><strong>Descripción:</strong> ${htmlEscape.convert(thread.description)}</div>');
  }
  buffer.writeln('      </div>');
  buffer.writeln('    </div>');

  // Mensajes
  for (final m in thread.messages) {
    final isTeacher = m.isTeacher;
    final roleCls = isTeacher ? 'role-teacher' : 'role-student';
    final replyCls = m.isReply ? 'message-reply' : '';

    buffer.writeln('    <div class="message-item $replyCls" id="m-${m.id}">');
    buffer.writeln('      <div class="message-header">');
    buffer.writeln('        <div class="author-info">');
    buffer.writeln('          <span class="author-name">${htmlEscape.convert(m.authorName)}</span>');
    if (m.role.isNotEmpty) {
      buffer.writeln('          <span class="role-badge $roleCls">${htmlEscape.convert(m.role)}</span>');
    }
    if (m.isReply && m.parentId != m.id) {
      buffer.writeln('          <span style="font-size: 0.75rem; color: var(--text-muted);">(en respuesta a #${m.parentId})</span>');
    }
    buffer.writeln('        </div>');
    if (m.date.isNotEmpty) {
      buffer.writeln('        <span class="message-date">${htmlEscape.convert(m.date)}</span>');
    }
    buffer.writeln('      </div>');

    // Body: si tenemos bodyHtml usamos el HTML sanitized o fallback
    buffer.writeln('      <div class="message-body">');
    if (m.bodyHtml.isNotEmpty) {
      buffer.writeln(m.bodyHtml);
    } else {
      buffer.writeln('<p>${htmlEscape.convert(m.bodyText).replaceAll('\n', '<br>')}</p>');
    }
    buffer.writeln('      </div>');

    // Adjuntos
    final allAttachments = [...m.fileAttachments, ...m.imageAttachments];
    if (allAttachments.isNotEmpty) {
      buffer.writeln('      <div class="attachments-box">');
      buffer.writeln('        <strong>Adjuntos:</strong><br>');
      for (final a in allAttachments) {
        final ref = hasLocalAttachments ? 'adjuntos/${a.fileName}' : a.downloadUrl;
        buffer.writeln('        <a class="attachment-pill" href="${htmlEscape.convert(ref)}" target="_blank">📎 ${htmlEscape.convert(a.fileName)}</a>');
      }
      buffer.writeln('      </div>');
    }

    buffer.writeln('    </div>');
  }

  buffer.writeln('    <div class="footer">');
  buffer.writeln('      Generado localmente por <strong>LibreMIeL</strong> — Cliente alternativo para MIeL (UNLaM).');
  buffer.writeln('    </div>');
  buffer.writeln('  </div>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}

/// Guarda en disco un tema de foro en los formatos especificados.
Future<Map<String, String>> saveForumTopicFiles({
  required Directory targetTopicDir,
  required ForumThreadData thread,
  required String subjectName,
  required String commissionCode,
  String? rawHtml,
  bool exportMarkdown = true,
  bool exportJson = true,
  bool exportHtml = true,
  bool hasLocalAttachments = true,
}) async {
  if (!await targetTopicDir.exists()) {
    await targetTopicDir.create(recursive: true);
  }

  final baseName = sanitizeFileName('${thread.idTema} - ${thread.title}');
  final writtenFiles = <String, String>{};

  if (exportMarkdown) {
    final md = generateForumMarkdown(
      thread,
      subjectName: subjectName,
      commissionCode: commissionCode,
      hasLocalAttachments: hasLocalAttachments,
    );
    final file = File(p.join(targetTopicDir.path, '$baseName.md'));
    await file.writeAsString(md, encoding: utf8);
    writtenFiles['md'] = file.path;
  }

  if (exportJson) {
    final jsonMap = generateForumJson(
      thread,
      subjectName: subjectName,
      commissionCode: commissionCode,
    );
    final file = File(p.join(targetTopicDir.path, '$baseName.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonMap), encoding: utf8);
    writtenFiles['json'] = file.path;
  }

  if (exportHtml) {
    final html = generateForumHtml(
      thread,
      subjectName: subjectName,
      commissionCode: commissionCode,
      hasLocalAttachments: hasLocalAttachments,
    );
    final file = File(p.join(targetTopicDir.path, '$baseName.html'));
    await file.writeAsString(html, encoding: utf8);
    writtenFiles['html'] = file.path;
  }

  if (rawHtml != null && rawHtml.isNotEmpty) {
    final file = File(p.join(targetTopicDir.path, '$baseName.raw.html'));
    await file.writeAsString(rawHtml, encoding: utf8);
    writtenFiles['rawHtml'] = file.path;
  }

  return writtenFiles;
}
