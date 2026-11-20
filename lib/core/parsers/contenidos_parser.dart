import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /contenido/archivos/comision/{idComision}`.
///
/// Captura IDs estables (`/id/{idElemento}` o `data-id-archivo`), fecha `F. subida`,
/// resaltado de novedad (`w3-pale-yellow` en el primer GET) y estado de descarga
/// (`w3-text-theme` vs `w3-text-dark-gray`).
List<ContentItem> parseContenidosHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final items = <ContentItem>[];
  final seenIds = <String>{};

  final moduleHeaders = doc.querySelectorAll('.desplegarModulo');
  if (moduleHeaders.isNotEmpty) {
    for (final header in moduleHeaders) {
      // Quitar el texto del badge rojo si está presente dentro del encabezado del módulo
      final headerClone = header.clone(true);
      for (final badge in headerClone.querySelectorAll('.w3-badge')) {
        badge.remove();
      }
      final moduleName = cleanWhitespace(headerClone.text);
      final contentContainer = header.nextElementSibling;
      if (contentContainer == null) continue;

      _extractRowsFromContainer(
        contentContainer,
        idComision: idComision,
        moduleName: moduleName.isEmpty ? 'General' : moduleName,
        items: items,
        seenIds: seenIds,
      );
    }
  }

  // Fallback si la vista no usa acordeones .desplegarModulo
  if (items.isEmpty) {
    _extractRowsFromContainer(
      doc.body ?? doc.documentElement,
      idComision: idComision,
      moduleName: 'General',
      items: items,
      seenIds: seenIds,
    );
  }

  return items;
}

void _extractRowsFromContainer(
  Element? container, {
  required String idComision,
  required String moduleName,
  required List<ContentItem> items,
  required Set<String> seenIds,
}) {
  if (container == null) return;

  for (final row in container.querySelectorAll('tbody tr')) {
    final downloadLink =
        row.querySelector('a.btnDescargar') ??
        row.querySelector('a[data-id-archivo]') ??
        row.querySelector('a[href*="descargarElemento"]');
    if (downloadLink == null) continue;

    final rawHref = downloadLink.attributes['href'] ?? '';
    final idFromAttr = downloadLink.attributes['data-id-archivo']?.trim() ?? '';
    final idFromHref = RegExp(r'/id/(\d+)').firstMatch(rawHref)?.group(1) ?? '';
    final idElemento = idFromAttr.isNotEmpty ? idFromAttr : idFromHref;
    if (idElemento.isEmpty || !seenIds.add(idElemento)) continue;

    final cells = row.querySelectorAll('td');
    final isHighlightedNew = row.classes.contains('w3-pale-yellow');
    final isExternal =
        downloadLink.classes.contains('btnMarcarDescargado') ||
        !rawHref.contains('/contenido/event/descargarElemento/');

    // Ícono de estado de descarga dentro de a.btnDescargar > i
    final iconEl = downloadLink.querySelector('i');
    final isDownloaded =
        iconEl != null && iconEl.classes.contains('w3-text-theme');

    // Tipo de archivo por ícono en la fila
    var fileType = isExternal ? 'link' : 'archivo';
    for (final el in row.querySelectorAll('i, span, a')) {
      for (final cls in el.classes) {
        if (cls.startsWith('icon-file-')) {
          fileType = cls.replaceFirst('icon-file-', '');
          break;
        } else if (cls == 'popup-video') {
          fileType = 'youtube';
        } else if (cls == 'popup-mp4') {
          fileType = 'video';
        }
      }
    }

    // Extraer título limpio (sin el div oculto de descripción)
    var title = '';
    if (cells.length >= 2) {
      final titleCell = cells[1].clone(true);
      for (final hidden in titleCell.querySelectorAll(
        '.w3-hide, .verDescripcion',
      )) {
        hidden.remove();
      }
      title = cleanWhitespace(titleCell.text);
    }
    if (title.isEmpty) {
      title = cleanWhitespace(
        downloadLink.attributes['title'] ?? downloadLink.text,
      );
    }
    if (title.isEmpty) {
      title = 'Elemento #$idElemento';
    }

    // Detectar fecha DD/MM/YYYY, tamaño y tipo de lectura en las celdas restantes
    var uploadDate = '';
    var sizeLabel = '';
    var readingType = '';
    for (var i = 2; i < cells.length; i++) {
      final txt = cleanWhitespace(cells[i].text);
      if (txt.isEmpty) continue;
      if (uploadDate.isEmpty && RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(txt)) {
        uploadDate = txt;
      } else if (sizeLabel.isEmpty &&
          RegExp(
            r'^\d+(?:[.,]\d+)?\s*(?:B|KB|MB|GB)$',
            caseSensitive: false,
          ).hasMatch(txt)) {
        sizeLabel = txt;
      } else if (readingType.isEmpty &&
          (normalizeText(txt).contains('obligatoria') ||
              normalizeText(txt).contains('opcional') ||
              normalizeText(txt).contains('complementaria'))) {
        readingType = txt;
      }
    }

    items.add(
      ContentItem(
        idElemento: idElemento,
        idComision: idComision,
        moduleName: moduleName,
        title: title,
        uploadDate: uploadDate,
        url: resolveMielUrl(rawHref),
        fileType: fileType,
        readingType: readingType,
        sizeLabel: sizeLabel,
        isExternal: isExternal,
        isHighlightedNew: isHighlightedNew,
        isDownloaded: isDownloaded,
      ),
    );
  }
}
