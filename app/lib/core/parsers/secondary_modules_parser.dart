import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /encuesta/encuestas/comision/{idComision}`.
List<SurveyItem> parseEncuestasHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final items = <SurveyItem>[];
  final seenIds = <String>{};

  for (final row in doc.querySelectorAll('table.w3-table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.isEmpty) continue;

    final link = row.querySelector('a');
    final href = link?.attributes['href'] ?? '';
    final title = cleanWhitespace(cells[0].text);
    if (title.isEmpty) continue;

    final idFromHref = RegExp(r'/id/(\d+)').firstMatch(href)?.group(1) ?? '';
    final id = idFromHref.isNotEmpty ? idFromHref : normalizeText(title);
    if (!seenIds.add(id)) continue;

    final status = cells.length >= 2 ? cleanWhitespace(cells[1].text) : '';
    items.add(
      SurveyItem(
        id: id,
        idComision: idComision,
        title: title,
        status: status,
        url: href.isNotEmpty
            ? resolveMielUrl(href)
            : '$kMielBaseUrl/encuesta/encuestas/comision/$idComision',
        isAvailable:
            link != null || !normalizeText(status).contains('finalizad'),
      ),
    );
  }

  return items;
}

/// Parser puro de `GET /autoguia/modulos/comision/{idComision}` (o `/autoguia/index/...`).
List<AutoguiaModule> parseAutoguiaHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final modules = <AutoguiaModule>[];
  final seenIds = <String>{};

  for (final card in doc.querySelectorAll(
    '.autoguia-card, .modulo-autoguia, main .w3-card',
  )) {
    final titleEl = card.querySelector('h2, h3, h4, strong');
    final title = cleanWhitespace(titleEl?.text ?? '');
    if (title.isEmpty) continue;

    final link = card.querySelector('a');
    final href = link?.attributes['href'] ?? '';
    final id = normalizeText(title);
    if (!seenIds.add(id)) continue;

    final pctEl = card.querySelector('.porcentaje');
    final pctDigits = RegExp(r'\d+').firstMatch(pctEl?.text ?? '')?.group(0);
    final progress = pctDigits != null ? (int.tryParse(pctDigits) ?? 0) : 0;

    final descEl = card.querySelector('p');
    final description = cleanWhitespace(descEl?.text ?? '');

    modules.add(
      AutoguiaModule(
        id: id,
        idComision: idComision,
        title: title,
        description: description,
        progressPercent: progress.clamp(0, 100),
        url: href.isNotEmpty
            ? resolveMielUrl(href)
            : '$kMielBaseUrl/autoguia/modulos/comision/$idComision',
      ),
    );
  }

  return modules;
}
