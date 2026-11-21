import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Extensiones prohibidas explícitamente por `helpers.js?2025.2.0` en MIeL.
const Set<String> kMielForbiddenUploadExtensions = <String>{
  'php',
  'php2',
  'php3',
  'php4',
  'php5',
  'php6',
  'php7',
  'php8',
  'html',
  'htm',
  'phtml',
  'pl',
  'py',
  'js',
  'jsp',
  'jsx',
  'ts',
  'tsx',
  'asp',
  'aspx',
  'shtml',
  'sh',
  'cgi',
  'htaccess',
};

/// Límite de tamaño de adjuntos en Mensajería y Portafolio (`filesize: 40`).
const int kMielMaxUploadMbLarge = 40;

/// Límite de tamaño de adjuntos en Foros `forov2` (`filesize: 5`).
const int kMielMaxUploadMbForum = 5;

/// Valida un archivo local antes de subirlo a MIeL (extensión permitida y tamaño máximo).
/// Devuelve `null` si es válido o un mensaje legible en español si debe rechazarse.
String? validateMielUploadFile({
  required String filePath,
  required int maxSizeMb,
  int? fileSizeBytes,
}) {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty) return 'Seleccioná un archivo válido.';

  final baseName = p.basename(trimmed);
  final rawExt = p.extension(baseName).replaceFirst('.', '').toLowerCase();
  final lowerName = baseName.toLowerCase();
  if (lowerName == '.htaccess' ||
      (rawExt.isNotEmpty && kMielForbiddenUploadExtensions.contains(rawExt))) {
    return 'Tipo de archivo no permitido por MIeL (.$rawExt).';
  }

  int bytes;
  if (fileSizeBytes != null) {
    bytes = fileSizeBytes;
  } else {
    final file = File(trimmed);
    if (!file.existsSync()) {
      return 'El archivo seleccionado ya no existe en disco.';
    }
    bytes = file.lengthSync();
  }

  final maxBytes = maxSizeMb * 1024 * 1024;
  if (bytes > maxBytes) {
    final sizeMb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return 'El archivo pesa $sizeMb MB y supera el límite de $maxSizeMb MB de MIeL.';
  }

  return null;
}

/// Escapa caracteres especiales HTML de forma segura.
String escapeMielHtml(String raw) {
  return raw
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

/// Construye la etiqueta oficial de `@mención` inyectada por MIeL `forov2`
/// antes de codificar el cuerpo de la respuesta en Base64.
String buildForoMentionPrefixHtml({
  required String authorUserId,
  required String messageId,
  required String mentionName,
}) {
  final cleanName = mentionName.trim().replaceFirst(RegExp(r'^@+'), '');
  if (cleanName.isEmpty) return '';
  final uid = escapeMielHtml(authorUserId.trim());
  final mid = escapeMielHtml(messageId.trim());
  final label = escapeMielHtml(cleanName);
  return '<strong style="cursor:pointer" class="tagUsuario" '
      'data-idUsuario="$uid" data-idMensaje="$mid">@$label</strong>&nbsp;';
}

/// Convierte texto plano escrito por el usuario en HTML de párrafos `<p>` compatible
/// con TinyMCE de MIeL, opcionalmente anteponiendo una etiqueta HTML de mención.
String plainTextToMielHtml(String plainText, {String? mentionPrefixHtml}) {
  final normalized = plainText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trim();
  final prefix = (mentionPrefixHtml ?? '').trim();

  if (normalized.isEmpty) {
    return prefix.isNotEmpty ? '<p>$prefix</p>' : '';
  }

  final paragraphs = normalized.split(RegExp(r'\n{2,}'));
  final buffer = StringBuffer();
  for (var i = 0; i < paragraphs.length; i++) {
    final escapedLines = paragraphs[i]
        .split('\n')
        .map(escapeMielHtml)
        .join('<br>');
    if (i == 0 && prefix.isNotEmpty) {
      buffer.write('<p>$prefix$escapedLines</p>');
    } else {
      buffer.write('<p>$escapedLines</p>');
    }
  }
  return buffer.toString();
}

/// Codifica HTML en UTF-8 → Base64 de forma idéntica a `base64encode()` de
/// `/vista/script/helpers.js?2025.2.0` en MIeL.
String encodeMielBase64Utf8(String htmlContent) {
  return base64Encode(utf8.encode(htmlContent));
}
