import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /evaluacion/evaluaciones/comision/{idComision}`.
///
/// Soporta tanto la tabla oficial de 6 columnas (`Tipo | Título | Habilitado | Candado | Estado | Opciones`)
/// como variantes compactas de 5 columnas.
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

    final enabledCell = cells[2];
    final enabledText = normalizeText(enabledCell.text);
    final enabledTitle = normalizeText(
      enabledCell
              .querySelector('[title], [data-tippy-content]')
              ?.attributes['title'] ??
          enabledCell
              .querySelector('[data-tippy-content]')
              ?.attributes['data-tippy-content'] ??
          '',
    );
    final hasGreenCircle = enabledCell.querySelector('.w3-green') != null;
    final isEnabled =
        !enabledTitle.contains('no habilitado') &&
        !enabledText.contains('no habilitado') &&
        (hasGreenCircle ||
            enterBtn != null ||
            enabledTitle.contains('habilitado'));

    final requiresPassword = enterBtn?.attributes['data-tc'] == '1';
    var isLockOpen = !requiresPassword;
    for (final icon in row.querySelectorAll('i.material-icons')) {
      final glyph = cleanWhitespace(icon.text);
      if (glyph == 'lock') isLockOpen = false;
      if (glyph == 'lock_open') isLockOpen = !requiresPassword;
    }

    final statusCellIndex = cells.length >= 6 ? 4 : 3;
    var status = cleanWhitespace(cells[statusCellIndex].text);
    if (status == 'lock' || status == 'lock_open') {
      status = cells.length > statusCellIndex + 1
          ? cleanWhitespace(cells[statusCellIndex + 1].text)
          : '';
    }

    evaluations.add(
      EvaluationItem(
        id: id,
        idComision: idComision,
        type: type,
        title: title,
        isEnabled: isEnabled,
        status: status,
        requiresPassword: requiresPassword,
        isLockOpen: isLockOpen,
      ),
    );
  }

  return evaluations;
}
