import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro del modal `GET /principal/cursoDetalles/id/{idComision}`.
/// Extrae metadatos oficiales del curso y la lista de docentes asignados (`Tutor/a`) con fotos de perfil.
CourseDetails parseCursoDetallesHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final teachers = <CourseTeacher>[];
  final seen = <String>{};

  void addTeacher(String rawName, String role, {String avatarUrl = ''}) {
    var cleanedAvatar = avatarUrl.trim();
    if (cleanedAvatar.isNotEmpty && !cleanedAvatar.startsWith('http')) {
      if (cleanedAvatar.startsWith('/')) {
        cleanedAvatar = 'https://miel.unlam.edu.ar$cleanedAvatar';
      } else {
        cleanedAvatar = 'https://miel.unlam.edu.ar/$cleanedAvatar';
      }
    }

    final cleaned = cleanWhitespace(rawName)
        .replaceAll(
          RegExp(
            r'\(\s*(?:Tutor/a|Docente|Coordinador/a)\s*\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'(?:[-·•:]\s*|\s+)(?:Tutor/a|Docente|Coordinador/a)\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^[·•:\-\s]+|[·•:\-\s]+$'), '')
        .trim();
    if (cleaned.length < 3) return;

    final lower = normalizeText(cleaned);
    if (lower.startsWith('docentes asignados') ||
        lower == 'docentes' ||
        lower == 'tutor/a' ||
        lower == 'coordinador/a') {
      return;
    }

    final norm = normalizeText(cleaned);
    if (norm.isEmpty || !seen.add(norm)) return;
    teachers.add(
      CourseTeacher(
        name: cleaned,
        normalizedName: norm,
        role: role.isEmpty ? 'Tutor/a' : role,
        avatarUrl: cleanedAvatar,
      ),
    );
  }

  // 1. Estructura oficial de MIeL: bloques `.w3-rest` con nombre y rol, precedidos por img de avatar
  for (final rest in doc.querySelectorAll('.w3-rest')) {
    final nameDiv = rest.querySelector('div:first-child');
    final roleDiv = rest.querySelector('.w3-small, div:nth-child(2)');
    final rawName = cleanWhitespace(nameDiv?.text ?? '');
    final role = cleanWhitespace(roleDiv?.text ?? 'Tutor/a');

    final parent = rest.parent;
    final img = parent?.querySelector('img') ?? rest.querySelector('img');
    final avatarUrl = img?.attributes['src']?.trim() ?? '';

    addTeacher(rawName, role, avatarUrl: avatarUrl);
  }

  // 2. Fallback si no hay bloques `.w3-rest` (ej. HTML simplificado o sintético)
  if (teachers.isEmpty) {
    for (final li in doc.querySelectorAll('li')) {
      final text = cleanWhitespace(li.text);
      if (text.isEmpty || text.length > 160) continue;
      final lower = normalizeText(text);
      if (lower.contains('tutor/a') ||
          lower.contains('(docente)') ||
          lower.contains('- docente')) {
        final strong = li.querySelector('strong, b');
        final rawName =
            strong != null && cleanWhitespace(strong.text).isNotEmpty
            ? strong.text
            : text
                  .split(
                    RegExp(
                      r'(?:\(|[-·•]\s*)(?:tutor/a|docente)',
                      caseSensitive: false,
                    ),
                  )
                  .first;
        final img = li.querySelector('img');
        addTeacher(
          rawName,
          'Tutor/a',
          avatarUrl: img?.attributes['src']?.trim() ?? '',
        );
      }
    }
  }

  // 3. Fallback adicional: enlaces de destinatarios con data-type="tutor"
  if (teachers.isEmpty) {
    for (final tutorLink in doc.querySelectorAll('a[data-type="tutor"]')) {
      addTeacher(tutorLink.text, 'Tutor/a');
    }
  }

  final courseTitle = cleanWhitespace(
    doc.querySelector('header h5, header .w3-container, h5')?.text ?? '',
  );
  var courseCode = '';
  var commission = '';
  var term = '';
  var modality = '';
  var modalityHelpUrl = '';
  var classroom = '';
  var classroomSubtext = '';
  var department = '';

  for (final row in doc.querySelectorAll('.w3-row-padding, tr')) {
    final cols = row.children;
    if (cols.length < 2) continue;
    final label = normalizeText(cleanWhitespace(cols[0].text));
    final valCol = cols[1];

    if (label.startsWith('codigo de curso') ||
        label.startsWith('codigo de materia')) {
      courseCode = cleanWhitespace(valCol.text);
    } else if (label.startsWith('comision')) {
      commission = cleanWhitespace(valCol.text);
      final termMatch = RegExp(r'\(([^)]+)\)').firstMatch(commission);
      if (termMatch != null && term.isEmpty) {
        term = cleanWhitespace(termMatch.group(1)!);
      }
    } else if (label.startsWith('modalidad')) {
      final helpLink = valCol.querySelector('a');
      modalityHelpUrl = helpLink?.attributes['href']?.trim() ?? '';
      if (helpLink != null) {
        final textParts = <String>[];
        for (final node in valCol.nodes) {
          if (node != helpLink) {
            textParts.add(node.text ?? '');
          }
        }
        modality = cleanWhitespace(textParts.join(' '));
      } else {
        modality = cleanWhitespace(valCol.text);
      }
    } else if (label.startsWith('aula')) {
      final sub = valCol.querySelector('.cursiva, .w3-small, em, i');
      if (sub != null) {
        classroomSubtext = cleanWhitespace(sub.text);
        final textParts = <String>[];
        for (final node in valCol.nodes) {
          if (node != sub) {
            textParts.add(node.text ?? '');
          }
        }
        classroom = cleanWhitespace(textParts.join(' '));
      } else {
        classroom = cleanWhitespace(valCol.text);
      }
    } else if (label.startsWith('departamento')) {
      department = cleanWhitespace(valCol.text);
    } else if (label.startsWith('cuatrimestre') ||
        label.startsWith('periodo')) {
      term = cleanWhitespace(valCol.text);
    }
  }

  // Fallback para layouts basados en párrafos planos
  if (courseCode.isEmpty && commission.isEmpty && department.isEmpty) {
    for (final p in doc.querySelectorAll('p, .w3-row')) {
      final text = cleanWhitespace(p.text);
      final lower = normalizeText(text);
      if (lower.startsWith('cuatrimestre:') || lower.startsWith('periodo:')) {
        term = cleanWhitespace(text.split(':').skip(1).join(':'));
      } else if (lower.startsWith('modalidad:')) {
        modality = cleanWhitespace(text.split(':').skip(1).join(':'));
      } else if (lower.startsWith('aula:')) {
        classroom = cleanWhitespace(text.split(':').skip(1).join(':'));
      } else if (lower.startsWith('codigo de curso:') ||
          lower.startsWith('codigo de materia:')) {
        courseCode = cleanWhitespace(text.split(':').skip(1).join(':'));
      } else if (lower.startsWith('comision:')) {
        commission = cleanWhitespace(text.split(':').skip(1).join(':'));
      } else if (lower.startsWith('departamento:')) {
        department = cleanWhitespace(text.split(':').skip(1).join(':'));
      }
    }
  }

  return CourseDetails(
    idComision: idComision,
    teachers: teachers,
    courseTitle: courseTitle,
    courseCode: courseCode,
    commission: commission,
    term: term,
    modality: modality,
    modalityHelpUrl: modalityHelpUrl,
    classroom: classroom,
    classroomSubtext: classroomSubtext,
    department: department,
  );
}
