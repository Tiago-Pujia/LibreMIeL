import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /contenido/archivos/comision/{idComision}` que devuelve la
/// lista plana de elementos para `SyncEngine` y snapshots.
List<ContentItem> parseContenidosHtml(String rawHtml, String idComision) {
  return parseContenidosPageHtml(rawHtml, idComision).allItems;
}

/// Parser puro estructurado de `GET /contenido/archivos/comision/{idComision}`
/// para la vista nativa de lectura (Fase 2).
///
/// Soporta:
/// - Carpetas plegables `div.desplegarModulo` + `div.w3-accordion-content`
/// - Tablas directas fuera de acordeones con múltiples pares alternados `<thead>` + `<tbody>`
/// - Descripciones ocultas (`i.verDescripcion` + `div.w3-hide`)
/// - Enlaces externos (`btnMarcarDescargado`), videos y archivos alojados en MIeL.
ContentPageData parseContenidosPageHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final sections = <ContentSection>[];
  final allItems = <ContentItem>[];
  final seenIds = <String>{};
  final processedTables = <Element>{};

  // 1. Procesar carpetas plegables (.desplegarModulo + .w3-accordion-content)
  for (final header in doc.querySelectorAll('.desplegarModulo')) {
    final badgeEl = header.querySelector('.w3-badge');
    final unreadBadge = parseBadgeCount(badgeEl?.text);

    var folderDescription = '';
    final hiddenDescEl = header.querySelector('.w3-hide');
    if (hiddenDescEl != null) {
      folderDescription = cleanWhitespace(hiddenDescEl.text);
    }

    final headerClone = header.clone(true);
    for (final extra in headerClone.querySelectorAll(
      '.w3-badge, .w3-hide, i.material-icons',
    )) {
      extra.remove();
    }
    final rawFolderTitle = cleanWhitespace(headerClone.text);
    final folderTitle = rawFolderTitle.isEmpty ? 'General' : rawFolderTitle;

    final contentContainer = header.nextElementSibling;
    if (contentContainer == null) continue;

    final tables = contentContainer.querySelectorAll('table');
    final submodules = <ContentSubmodule>[];

    if (tables.isNotEmpty) {
      for (final table in tables) {
        processedTables.add(table);
        submodules.addAll(
          _extractSubmodulesFromTable(
            table,
            idComision: idComision,
            defaultModuleName: folderTitle,
            allItems: allItems,
            seenIds: seenIds,
          ),
        );
      }
    } else {
      final directItems = <ContentItem>[];
      _extractRowsFromContainer(
        contentContainer,
        idComision: idComision,
        moduleName: folderTitle,
        submoduleName: '',
        items: directItems,
        allItems: allItems,
        seenIds: seenIds,
      );
      if (directItems.isNotEmpty) {
        submodules.add(
          ContentSubmodule(title: folderTitle, items: directItems),
        );
      }
    }

    if (submodules.isNotEmpty) {
      sections.add(
        ContentSection(
          title: folderTitle,
          description: folderDescription,
          isCollapsibleFolder: true,
          unreadBadge: unreadBadge,
          submodules: submodules,
        ),
      );
    }
  }

  // 2. Procesar tablas planas fuera de .desplegarModulo (ej. Módulo 00, Módulo 01...)
  final directSubmodules = <ContentSubmodule>[];
  for (final table in doc.querySelectorAll('table.w3-table, table')) {
    if (processedTables.contains(table)) continue;
    // Ignorar si está dentro de un .w3-accordion-content ya procesado
    var parent = table.parent;
    var insideProcessedAccordion = false;
    while (parent != null) {
      if (parent.classes.contains('w3-accordion-content')) {
        insideProcessedAccordion = true;
        break;
      }
      parent = parent.parent;
    }
    if (insideProcessedAccordion) continue;

    processedTables.add(table);
    directSubmodules.addAll(
      _extractSubmodulesFromTable(
        table,
        idComision: idComision,
        defaultModuleName: 'Contenidos del curso',
        allItems: allItems,
        seenIds: seenIds,
      ),
    );
  }

  if (directSubmodules.isNotEmpty) {
    sections.add(
      ContentSection(
        title: directSubmodules.length == 1
            ? directSubmodules.first.title
            : 'Módulos de la materia',
        isCollapsibleFolder: false,
        submodules: directSubmodules,
      ),
    );
  }

  // 3. Fallback si hubiera filas tr sueltas sin table estándar
  if (allItems.isEmpty) {
    final fallbackItems = <ContentItem>[];
    _extractRowsFromContainer(
      doc.body ?? doc.documentElement,
      idComision: idComision,
      moduleName: 'General',
      submoduleName: '',
      items: fallbackItems,
      allItems: allItems,
      seenIds: seenIds,
    );
    if (fallbackItems.isNotEmpty) {
      sections.add(
        ContentSection(
          title: 'General',
          isCollapsibleFolder: false,
          submodules: [
            ContentSubmodule(title: 'General', items: fallbackItems),
          ],
        ),
      );
    }
  }

  return ContentPageData(
    idComision: idComision,
    sections: sections,
    allItems: allItems,
  );
}

List<ContentSubmodule> _extractSubmodulesFromTable(
  Element table, {
  required String idComision,
  required String defaultModuleName,
  required List<ContentItem> allItems,
  required Set<String> seenIds,
}) {
  final submodules = <ContentSubmodule>[];
  var currentSubTitle = '';
  var currentSubDesc = '';

  // MIeL renderiza pares alternados <thead> + <tbody> dentro de un mismo <table>
  final directChildren = table.children;
  final hasDirectTheadOrTbody = directChildren.any(
    (c) => c.localName == 'thead' || c.localName == 'tbody',
  );

  if (hasDirectTheadOrTbody) {
    for (final child in directChildren) {
      if (child.localName == 'thead') {
        final firstTh = child.querySelector('th');
        if (firstTh != null) {
          final descEl = firstTh.querySelector('.w3-hide');
          currentSubDesc = descEl != null ? cleanWhitespace(descEl.text) : '';
          final thClone = firstTh.clone(true);
          for (final hidden in thClone.querySelectorAll(
            '.w3-hide, .verDescripcion, i.material-icons',
          )) {
            hidden.remove();
          }
          final candidate = cleanWhitespace(thClone.text);
          final norm = normalizeText(candidate);
          if (candidate.isNotEmpty &&
              norm != 'archivo' &&
              norm != 'nombre' &&
              norm != 'titulo') {
            currentSubTitle = candidate;
          }
        }
      } else if (child.localName == 'tbody') {
        final effectiveModule = currentSubTitle.isNotEmpty
            ? currentSubTitle
            : defaultModuleName;
        final subItems = <ContentItem>[];
        _extractRowsFromContainer(
          child,
          idComision: idComision,
          moduleName: defaultModuleName == 'Contenidos del curso'
              ? effectiveModule
              : defaultModuleName,
          submoduleName: currentSubTitle,
          items: subItems,
          allItems: allItems,
          seenIds: seenIds,
        );
        if (subItems.isNotEmpty) {
          submodules.add(
            ContentSubmodule(
              title: effectiveModule,
              description: currentSubDesc,
              items: subItems,
            ),
          );
        }
      }
    }
  } else {
    final subItems = <ContentItem>[];
    _extractRowsFromContainer(
      table,
      idComision: idComision,
      moduleName: defaultModuleName,
      submoduleName: '',
      items: subItems,
      allItems: allItems,
      seenIds: seenIds,
    );
    if (subItems.isNotEmpty) {
      submodules.add(
        ContentSubmodule(title: defaultModuleName, items: subItems),
      );
    }
  }

  return submodules;
}

void _extractRowsFromContainer(
  Element? container, {
  required String idComision,
  required String moduleName,
  required String submoduleName,
  required List<ContentItem> items,
  required List<ContentItem> allItems,
  required Set<String> seenIds,
}) {
  if (container == null) return;

  final rows = container.localName == 'tbody'
      ? container.querySelectorAll('tr')
      : container.querySelectorAll('tbody tr, tr');

  for (final row in rows) {
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
    var fileType = isExternal ? 'explore' : 'archivo';
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

    // Extraer título limpio y descripción oculta (.w3-hide)
    var title = '';
    var description = '';
    if (cells.length >= 2) {
      final descEl = cells[1].querySelector('.w3-hide');
      if (descEl != null) {
        description = cleanWhitespace(descEl.text);
      }
      final titleCell = cells[1].clone(true);
      for (final hidden in titleCell.querySelectorAll(
        '.w3-hide, .verDescripcion, i.material-icons',
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

    final dataLink = downloadLink.attributes['data-link']?.trim() ?? '';
    final resolvedUrl = dataLink.isNotEmpty
        ? resolveMielUrl(dataLink)
        : resolveMielUrl(rawHref);

    final item = ContentItem(
      idElemento: idElemento,
      idComision: idComision,
      moduleName: moduleName,
      submoduleName: submoduleName,
      title: title,
      description: description,
      uploadDate: uploadDate,
      url: resolvedUrl,
      fileType: fileType,
      readingType: readingType,
      sizeLabel: sizeLabel,
      isExternal: isExternal,
      isHighlightedNew: isHighlightedNew,
      isDownloaded: isDownloaded,
    );
    items.add(item);
    allItems.add(item);
  }
}

/// Parser puro de `GET /contenido/glosario/comision/{idComision}`.
GlossaryPageData parseContenidosGlosarioHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final enabledLetters = <String>{};
  var activeLetter = 'Todos';

  for (final el in doc.querySelectorAll('.letra-filtro')) {
    final label = cleanWhitespace(el.text);
    if (label.isEmpty) continue;
    final isDisabled =
        el.classes.contains('w3-disabled') || el.attributes['disabled'] != null;
    if (!isDisabled) {
      enabledLetters.add(label);
    }
    if (el.classes.contains('w3-theme') ||
        el.classes.contains('w3-dark-grey') ||
        el.classes.contains('active')) {
      activeLetter = label;
    }
  }

  final entries = <GlossaryEntry>[];
  // MIeL puede renderizar términos en filas de tabla, dl/dt/dd o bloques .w3-section / .glosario-termino
  for (final row in doc.querySelectorAll('table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length >= 2) {
      final term = cleanWhitespace(cells[0].text);
      final def = cleanWhitespace(cells[1].text);
      if (term.isNotEmpty && def.isNotEmpty) {
        entries.add(GlossaryEntry(term: term, definition: def));
      }
    }
  }

  if (entries.isEmpty) {
    for (final block in doc.querySelectorAll(
      '.glosario-termino, .termino-bloque, main .w3-panel, main .w3-card',
    )) {
      final strong = block.querySelector('strong, h3, h4');
      if (strong == null) continue;
      final term = cleanWhitespace(strong.text);
      final clone = block.clone(true);
      clone.querySelector('strong, h3, h4')?.remove();
      final def = cleanWhitespace(clone.text);
      if (term.isNotEmpty && def.isNotEmpty) {
        entries.add(GlossaryEntry(term: term, definition: def));
      }
    }
  }

  return GlossaryPageData(
    activeLetter: activeLetter,
    enabledLetters: enabledLetters,
    entries: entries,
  );
}

/// Parser puro de `GET /contenido/faq/comision/{idComision}`.
List<FaqItem> parseContenidosFaqHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final items = <FaqItem>[];

  // Caso 1: Acordeones o bloques con pregunta en strong/h3/h4/.desplegarFaq
  for (final header in doc.querySelectorAll(
    '.desplegarFaq, .desplegarModulo, .faq-pregunta',
  )) {
    final q = cleanWhitespace(header.text);
    final next = header.nextElementSibling;
    final a = cleanWhitespace(next?.text ?? '');
    if (q.isNotEmpty && a.isNotEmpty) {
      items.add(FaqItem(question: q, answer: a));
    }
  }

  // Caso 2: Tabla o bloques con strong + párrafo
  if (items.isEmpty) {
    for (final row in doc.querySelectorAll('table tbody tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        final q = cleanWhitespace(cells[0].text);
        final a = cleanWhitespace(cells[1].text);
        if (q.isNotEmpty && a.isNotEmpty) {
          items.add(FaqItem(question: q, answer: a));
        }
      }
    }
  }

  return items;
}
