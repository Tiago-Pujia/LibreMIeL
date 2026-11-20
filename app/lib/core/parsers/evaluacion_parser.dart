import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /evaluacion/evaluaciones/comision/{idComision}`.
List<EvaluationItem> parseEvaluacionesHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final evaluations = <EvaluationItem>[];
  final seenIds = <String>{};

  for (final row in doc.querySelectorAll('table.w3-table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) continue;

    final enterBtn = row.querySelector('a.botonIngresar');
    final type = cleanWhitespace(cells[0].text);
    final title = cleanWhitespace(cells[1].text);
    if (title.isEmpty) continue;

    final idFromBtn = enterBtn?.attributes['data-id']?.trim() ?? '';
    final id = idFromBtn.isNotEmpty ? idFromBtn : normalizeText('$type-$title');
    if (!seenIds.add(id)) continue;

    final enabledText = normalizeText(cells[2].text);
    final enabledTitle = normalizeText(
      cells[2].querySelector('[title]')?.attributes['title'] ?? '',
    );
    final isEnabled =
        !enabledTitle.contains('no habilitado') &&
        !enabledText.contains('no habilitado') &&
        (enterBtn != null || enabledTitle.contains('habilitado'));

    final status = cleanWhitespace(cells[3].text);
    final requiresPassword = enterBtn?.attributes['data-tc'] == '1';

    evaluations.add(
      EvaluationItem(
        id: id,
        idComision: idComision,
        type: type,
        title: title,
        isEnabled: isEnabled,
        status: status,
        requiresPassword: requiresPassword,
      ),
    );
  }

  return evaluations;
}
