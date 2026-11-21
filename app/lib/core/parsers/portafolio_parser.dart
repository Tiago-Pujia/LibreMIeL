import 'package:html/dom.dart';
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
  return _extractCorrectionsFromDoc(doc);
}

List<PortfolioCorrection> _extractCorrectionsFromDoc(Document doc) {
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

/// Parser puro del detalle completo de entregas y correcciones
/// `GET /portafolio/entregas/comision/{idComision}/id/{idPractica}`.
PortfolioPracticeDetail parsePortafolioEntregasDetalleHtml(
  String rawHtml,
  String idComision,
  String idPractica,
) {
  final doc = html_parser.parse(rawHtml);
  final corrections = _extractCorrectionsFromDoc(doc);
  final deliveries = <PortfolioDelivery>[];

  // Cabecera de consigna y modalidad
  var headerTitle = '';
  var promptDownloadUrl = '';
  var deliveryModeLabel = '';

  final promptEl = doc.querySelector(
    'a[href*="/contenido/event/descargarElemento/"]',
  );
  if (promptEl != null) {
    promptDownloadUrl = resolveMielUrl(promptEl.attributes['href']);
    final parentClone = promptEl.parent?.clone(true);
    if (parentClone != null) {
      parentClone
          .querySelector('a[href*="/contenido/event/descargarElemento/"]')
          ?.remove();
      headerTitle = cleanWhitespace(parentClone.text)
          .replaceAll(RegExp(r'[·\-]\s*$'), '')
          .trim();
    }
  }

  for (final sec in doc.querySelectorAll('.w3-section, p, div')) {
    final txt = cleanWhitespace(sec.text);
    final norm = normalizeText(txt);
    if (norm.startsWith('entrega ') && txt.length < 80) {
      deliveryModeLabel = txt;
      break;
    }
  }

  for (final block in doc.querySelectorAll('div.entrega')) {
    var title = '';
    var dateTime = '';
    var fileName = '';
    var downloadUrl = '';
    var isGroupDelivery = false;
    var groupName = '';
    final members = <String>[];
    var message = '';

    final firstStrong = block.querySelector('strong');
    if (firstStrong != null &&
        normalizeText(firstStrong.text).contains('entrega')) {
      title = cleanWhitespace(firstStrong.text);
    }

    for (final row in block.querySelectorAll('.w3-row')) {
      final cols = row.querySelectorAll('.w3-col');
      if (cols.length < 2) continue;
      final label = normalizeText(cols.first.text);
      final valCol = cols.last;
      final rawVal = cleanWhitespace(valCol.text);
      final val = rawVal == '---' ? '' : rawVal;

      if (label.startsWith('fecha')) {
        dateTime = val;
      } else if (label.startsWith('practica enviada') ||
          label.startsWith('archivo')) {
        final link = valCol.querySelector('a');
        if (link != null) {
          fileName = cleanWhitespace(link.text);
          downloadUrl = resolveMielUrl(link.attributes['href']);
        } else {
          fileName = val;
        }
      } else if (label.startsWith('entrega grupal')) {
        final normVal = normalizeText(val);
        isGroupDelivery = normVal.startsWith('si') || normVal.contains('grupo');
        final grpStrong = valCol.querySelector('strong');
        if (grpStrong != null) {
          groupName = cleanWhitespace(grpStrong.text);
        }
        final lines = valCol.innerHtml.split(
          RegExp(r'<br\s*/?>', caseSensitive: false),
        );
        for (final line in lines.skip(1)) {
          final mText = cleanWhitespace(
            html_parser.parseFragment(line).text ?? '',
          ).replaceFirst(RegExp(r'^-\s*'), '').trim();
          if (mText.isNotEmpty) {
            members.add(mText);
          }
        }
      } else if (label.startsWith('mensaje')) {
        message = val;
      }
    }

    deliveries.add(
      PortfolioDelivery(
        title: title.isEmpty ? 'ENTREGA #${deliveries.length + 1}' : title,
        dateTime: dateTime,
        fileName: fileName,
        downloadUrl: downloadUrl,
        isGroupDelivery: isGroupDelivery,
        groupName: groupName,
        members: members,
        message: message,
      ),
    );
  }

  // Metadatos del formulario de entrega (#formNuevaEntrega) para Fase 3
  final formEl = doc.querySelector('#formNuevaEntrega');
  PortfolioSubmissionFormMeta submissionForm =
      const PortfolioSubmissionFormMeta();
  if (formEl != null) {
    final tutors = <PortfolioTutorOption>[];
    final seenIds = <String>{};
    for (final opt in formEl.querySelectorAll(
      'select[name="tutorDestinatario"] option',
    )) {
      final rawId = (opt.attributes['value'] ?? '').trim();
      final name = cleanWhitespace(opt.text);
      if (name.isEmpty) continue;
      // Normalizar id vacío o "0" para representar a todos los docentes
      final id = (rawId.isEmpty || rawId == '0') ? '0' : rawId;
      if (seenIds.add(id)) {
        tutors.add(PortfolioTutorOption(id: id, name: name));
      }
    }
    if (tutors.isEmpty) {
      tutors.add(
        const PortfolioTutorOption(
          id: '0',
          name: 'Todos los docentes de la comisión',
        ),
      );
    }
    final allowsLink = formEl.querySelector('input[name="enlace"]') != null;
    submissionForm = PortfolioSubmissionFormMeta(
      canSubmit: true,
      tutors: tutors,
      allowsLink: allowsLink,
      requiresFile: !allowsLink,
      maxSizeMb: 40,
    );
  }

  return PortfolioPracticeDetail(
    idComision: idComision,
    idPractica: idPractica,
    headerTitle: headerTitle.isEmpty ? 'Práctica #$idPractica' : headerTitle,
    promptDownloadUrl: promptDownloadUrl,
    deliveryModeLabel: deliveryModeLabel,
    corrections: corrections,
    deliveries: deliveries,
    submissionForm: submissionForm,
  );
}

/// Parser puro de `GET /portafolio/archivosEnviados/comision/{idComision}`.
List<PortfolioSentFile> parsePortafolioArchivosEnviadosHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final files = <PortfolioSentFile>[];

  for (final row in doc.querySelectorAll('table.w3-table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 4) continue;

    var fileType = 'archivo';
    for (final icon in cells[0].querySelectorAll('i')) {
      for (final cls in icon.classes) {
        if (cls.startsWith('icon-file-')) {
          fileType = cls.replaceFirst('icon-file-', '');
        }
      }
    }

    final graySpan = cells[1].querySelector('.w3-text-gray, .w3-text-grey');
    final fileName = cleanWhitespace(graySpan?.text ?? '');
    final titleClone = cells[1].clone(true);
    titleClone.querySelector('.w3-text-gray, .w3-text-grey')?.remove();
    final practiceTitle = cleanWhitespace(titleClone.text);

    final dateTime = cells.length >= 3 ? cleanWhitespace(cells[2].text) : '';
    final sizeLabel = cells.length >= 4 ? cleanWhitespace(cells[3].text) : '';
    final dlLink = row.querySelector(
      'a[href*="/portafolio/event/descargarEntrega/"], a[href*="descargar"]',
    );
    final rawHref = dlLink?.attributes['href'] ?? '';
    final idEntrega =
        RegExp(r'/id/(\d+)').firstMatch(rawHref)?.group(1) ??
        '${files.length + 1}';

    files.add(
      PortfolioSentFile(
        idEntrega: idEntrega,
        practiceTitle: practiceTitle.isEmpty ? fileName : practiceTitle,
        fileName: fileName.isEmpty ? practiceTitle : fileName,
        fileType: fileType,
        dateTime: dateTime,
        sizeLabel: sizeLabel,
        downloadUrl: resolveMielUrl(rawHref),
      ),
    );
  }

  return files;
}

/// Parser puro de `GET /portafolio/grupos/comision/{idComision}`.
List<PortfolioGroup> parsePortafolioGruposHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final groups = <PortfolioGroup>[];

  for (final row in doc.querySelectorAll('table.w3-table tbody tr')) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 2) continue;

    final name = cleanWhitespace(cells[0].text);
    if (name.isEmpty) continue;

    final members = <String>[];
    final memberDivs = cells[1].querySelectorAll('div, li');
    if (memberDivs.isNotEmpty) {
      for (final div in memberDivs) {
        final m = cleanWhitespace(div.text);
        if (m.isNotEmpty) members.add(m);
      }
    } else {
      for (final part in cells[1].innerHtml.split(
        RegExp(r'<br\s*/?>', caseSensitive: false),
      )) {
        final m = cleanWhitespace(html_parser.parseFragment(part).text ?? '');
        if (m.isNotEmpty) members.add(m);
      }
    }

    final msgLink = row.querySelector('a[href*="/mensajeria/redactar/"]');
    final msgHref = msgLink?.attributes['href'] ?? '';
    final idGrupo =
        RegExp(r'/grupo/(\d+)').firstMatch(msgHref)?.group(1) ??
        '${groups.length + 1}';

    groups.add(
      PortfolioGroup(
        idGrupo: idGrupo,
        name: name,
        members: members,
        messageUrl: resolveMielUrl(msgHref),
      ),
    );
  }

  return groups;
}

/// Parser puro de `GET /portafolio/notas/comision/{idComision}`
/// (Asistencia, notas de evaluación y certificados).
PortfolioGradesData parsePortafolioNotasHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final attendance = <AttendanceEntry>[];
  final evaluationGrades = <EvaluationGradeEntry>[];
  final certificates = <CertificateItem>[];

  // 1. Tarjetas de asistencia: div.asistencia-alumno
  for (final card in doc.querySelectorAll('.asistencia-alumno')) {
    final childDivs = card.children.where((c) => c.localName == 'div').toList();
    if (childDivs.length >= 2) {
      final date = cleanWhitespace(childDivs[0].text);
      final statusEl = childDivs[1];
      final status = cleanWhitespace(statusEl.text);
      final normalizedStatus = normalizeText(status);
      final isPresent =
          statusEl.classes.contains('w3-green') ||
          normalizedStatus.contains('presente');
      final isJustified =
          !isPresent &&
          (statusEl.classes.contains('w3-blue') ||
              normalizedStatus.contains('justific'));
      final modality = childDivs.length >= 3
          ? cleanWhitespace(childDivs[2].text)
          : '';
      if (date.isNotEmpty) {
        attendance.add(
          AttendanceEntry(
            date: date,
            status: status.isEmpty
                ? (isPresent
                      ? 'Presente'
                      : (isJustified ? 'Justificado' : 'Ausente'))
                : status,
            isPresent: isPresent,
            isJustified: isJustified,
            modality: modality,
          ),
        );
      }
    }
  }

  // 2. Tablas de notas o certificados si existen
  for (final table in doc.querySelectorAll('table.w3-table')) {
    for (final row in table.querySelectorAll('tbody tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.isEmpty) continue;
      final certLink = row.querySelector('a[href*="certificado"], a.link');
      if (certLink != null &&
          normalizeText(certLink.attributes['href'] ?? '')
              .contains('certificado')) {
        certificates.add(
          CertificateItem(
            title: cleanWhitespace(cells[0].text),
            date: cells.length >= 2 ? cleanWhitespace(cells[1].text) : '',
            downloadUrl: resolveMielUrl(certLink.attributes['href']),
          ),
        );
      } else if (cells.length >= 2) {
        evaluationGrades.add(
          EvaluationGradeEntry(
            title: cleanWhitespace(cells[0].text),
            date: cells.length >= 3 ? cleanWhitespace(cells[1].text) : '',
            grade: cleanWhitespace(cells.last.text),
            status: cells.length >= 4 ? cleanWhitespace(cells[2].text) : '',
          ),
        );
      }
    }
  }

  return PortfolioGradesData(
    attendance: attendance,
    evaluationGrades: evaluationGrades,
    certificates: certificates,
  );
}

/// Parser puro de `GET /portafolio/competencias/comision/{idComision}`.
PortfolioCompetenciesData parsePortafolioCompetenciasHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final rows = <CompetencyRow>[];

  final table = doc.querySelector(
    'table.tabla-competencias, .contenedor-tabla-competencias table',
  );
  if (table != null) {
    for (final tr in table.querySelectorAll('tbody tr')) {
      final cells = tr.querySelectorAll('td');
      if (cells.isEmpty) continue;
      rows.add(
        CompetencyRow(
          title: cleanWhitespace(cells[0].text),
          level: cells.length >= 2 ? cleanWhitespace(cells[1].text) : '',
          observations: cells.length >= 3 ? cleanWhitespace(cells[2].text) : '',
        ),
      );
    }
    return PortfolioCompetenciesData(isEnabled: true, rows: rows);
  }

  var emptyMsg = '';
  for (final p in doc.querySelectorAll('main p, p')) {
    final txt = cleanWhitespace(p.text);
    if (normalizeText(txt).contains('competencia')) {
      emptyMsg = txt;
      break;
    }
  }

  return PortfolioCompetenciesData(
    isEnabled: rows.isNotEmpty,
    emptyMessage: emptyMsg.isEmpty
        ? 'Esta materia no tiene habilitada la evaluación por competencias.'
        : emptyMsg,
    rows: rows,
  );
}
