/// Utilidades puras de normalización de texto y resolución de URLs de MIEL.
library;

const String kMielBaseUrl = 'https://miel.unlam.edu.ar';

const Map<String, String> _diacriticMap = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
};

/// Normaliza cadenas removiendo tildes, colapsando espacios y convirtiendo a minúsculas.
String normalizeText(String input) {
  final lower = input.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_diacriticMap[ch] ?? ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Limpia saltos de línea y espacios redundantes preservando el texto legible.
String cleanWhitespace(String input) {
  return input.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Resuelve una URL relativa de MIEL a URL absoluta.
String resolveMielUrl(String? rawHref) {
  if (rawHref == null) return '';
  final trimmed = rawHref.trim();
  if (trimmed.isEmpty || trimmed.startsWith('javascript:')) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '$kMielBaseUrl$trimmed';
  }
  return '$kMielBaseUrl/$trimmed';
}

/// Parsea un entero positivo de un texto de badge (retorna 0 si no es numérico).
int parseBadgeCount(String? raw) {
  if (raw == null) return 0;
  final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
  return digits == null ? 0 : (int.tryParse(digits) ?? 0);
}
