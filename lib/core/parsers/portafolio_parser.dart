import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro de `GET /portafolio/practicas/comision/{idComision}`.
List<PortfolioPractice> parsePortafolioPracticasHtml(
  String rawHtml,
  String idComision,
) {
  final doc = html_parser.parse(rawHtml);
  final practices = <PortfolioPractice>[];
  final seenIds = <String>{};

  for (final row in doc.querySelectorAll('table.w3-table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) continue;

    final detailLink = row.querySelector('a[href*="/portafolio/entregas/"]');
    final promptLink = cells[0].querySelector(
      'a[href*="/contenido/event/descargarElemento/"]',
    );

    final detailHref = detailLink?.attributes['href'] ?? '';
    final promptHref = promptLink?.attributes['href'] ?? '';

    final idFromDetail =
        RegExp(r'/id/(\d+)').firstMatch(detailHref)?.group(1) ?? '';
    final idFromPrompt =
        RegExp(r'/id/(\d+)').firstMatch(promptHref)?.group(1) ?? '';
    final idPractica = idFromDetail.isNotEmpty ? idFromDetail : idFromPrompt;
    if (idPractica.isEmpty || !seenIds.add(idPractica)) continue;

    // Primera celda: "Módulo<br><a ...>Nombre práctica</a>"
    final firstParts = cells[0].innerHtml.split(
      RegExp(r'<br\s*/?>', caseSensitive: false),
    );
    var moduleName = '';
    var title = '';
    if (firstParts.length >= 2) {
      moduleName = cleanWhitespace(
        html_parser.parseFragment(firstParts.first).text ?? '',
      );
      title = cleanWhitespace(
        html_parser.parseFragment(firstParts.skip(1).join(' ')).text ?? '',
      );
    } else {
      title = cleanWhitespace(cells[0].text);
    }
    if (title.isEmpty) {
      title = promptLink != null
          ? cleanWhitespace(promptLink.text)
          : 'Práctica #$idPractica';
    }

    String cellText(int index) {
      if (index >= cells.length) return '';
      final txt = cleanWhitespace(cells[index].text);
      return txt == '---' ? '' : txt;
    }

    // Orden estándar de columnas:
    // 0: Práctica | 1: Entrega | 2: F. vencim. | 3: Detalle entregas | 4: F. entrega | 5: F. correc. | 6: Estado | 7: Nota
    final deliveryType = cellText(1);
    final dueDate = cellText(2);
    final deliveryDate = cellText(4);
    final correctionDate = cellText(5);
    final status = cellText(6);
    final grade = cellText(7);

    practices.add(
      PortfolioPractice(
        idPractica: idPractica,
        idComision: idComision,
        moduleName: moduleName,
        title: title,
        deliveryType: deliveryType,
        dueDate: dueDate,
        deliveryDate: deliveryDate,
        correctionDate: correctionDate,
        status: status,
        grade: grade,
        detailUrl: resolveMielUrl(detailHref),
        promptDownloadUrl: resolveMielUrl(promptHref),
      ),
    );
  }

  return practices;
}

/// Parser puro de devoluciones docentes en `GET /portafolio/entregas/comision/{id}/id/{idPractica}`.
List<PortfolioCorrection> parsePortafolioCorreccionesHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final corrections = <PortfolioCorrection>[];

  for (final block in doc.querySelectorAll('div.correccion')) {
    var dateTime = '';
    var status = '';
    var grade = '';
    var observations = '';
    var correctedBy = '';

    for (final row in block.querySelectorAll('.w3-row')) {
      final label = normalizeText(
        row.querySelector('.m3, .w3-col:first-child')?.text ?? '',
      );
      final rawVal = cleanWhitespace(
        row.querySelector('.m9, .w3-col:last-child')?.text ?? '',
      );
      final val = rawVal == '---' ? '' : rawVal;

      if (label.startsWith('fecha')) {
        dateTime = val;
      } else if (label.startsWith('estado')) {
        status = val;
      } else if (label.startsWith('calificacion') || label.startsWith('nota')) {
        grade = val;
      } else if (label.startsWith('observaciones')) {
        observations = val;
      } else if (label.startsWith('corregido por')) {
        correctedBy = val;
      }
    }

    if (dateTime.isNotEmpty ||
        status.isNotEmpty ||
        grade.isNotEmpty ||
        observations.isNotEmpty) {
      corrections.add(
        PortfolioCorrection(
          dateTime: dateTime,
          status: status,
          grade: grade,
          observations: observations,
          correctedBy: correctedBy,
        ),
      );
    }
  }

  return corrections;
}
