import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro del modal `GET /principal/cursoDetalles/id/{idComision}`.
/// Extrae la lista completa de docentes asignados (`Tutor/a`) para cruzar con Mensajería.
CourseDetails parseCursoDetallesHtml(String rawHtml, String idComision) {
  final doc = html_parser.parse(rawHtml);
  final teachers = <CourseTeacher>[];
  final seen = <String>{};

  void addTeacher(String rawName, String role) {
    final cleaned = cleanWhitespace(rawName)
        .replaceAll(
          RegExp(r'\(\s*(?:Tutor/a|Docente)\s*\)', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'(?:[-·•:]\s*|\s+)(?:Tutor/a|Docente)\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^[·•:\-\s]+|[·•:\-\s]+$'), '')
        .trim();
    if (cleaned.length < 3) return;
    final norm = normalizeText(cleaned);
    if (norm.isEmpty || !seen.add(norm)) return;
    teachers.add(
      CourseTeacher(name: cleaned, normalizedName: norm, role: role),
    );
  }

  // 1. Filas o elementos de lista que indican explícitamente rol Tutor/a o Docente
  for (final el in doc.querySelectorAll('li, tr, p, div')) {
    // Evitar contenedores gigantes que envuelven todo el modal
    if (el.children.length > 6) continue;
    final text = cleanWhitespace(el.text);
    if (text.isEmpty || text.length > 160) continue;

    final lower = normalizeText(text);
    if (lower.contains('tutor/a') ||
        lower.contains('(docente)') ||
        lower.contains('- docente')) {
      final strong = el.querySelector('strong, b');
      if (strong != null && cleanWhitespace(strong.text).isNotEmpty) {
        addTeacher(strong.text, 'Tutor/a');
      } else {
        // Caso: "APELLIDO, NOMBRE (Tutor/a)" o "APELLIDO, NOMBRE - Tutor/a"
        final beforeRole = text
            .split(
              RegExp(
                r'(?:\(|[-·•]\s*)(?:tutor/a|docente)',
                caseSensitive: false,
              ),
            )
            .first;
        if (cleanWhitespace(beforeRole).isNotEmpty) {
          addTeacher(beforeRole, 'Tutor/a');
        }
      }
    }
  }

  // 2. Fallback: enlaces de destinatarios en /mensajeria/redactar/comision/{id} con data-type="tutor"
  for (final tutorLink in doc.querySelectorAll('a[data-type="tutor"]')) {
    addTeacher(tutorLink.text, 'Tutor/a');
  }

  var term = '';
  var modality = '';
  var classroom = '';

  for (final row in doc.querySelectorAll('tr, .w3-row, p')) {
    final text = cleanWhitespace(row.text);
    if (text.length > 160) continue;
    final lower = normalizeText(text);
    if (lower.startsWith('cuatrimestre:') || lower.startsWith('periodo:')) {
      term = cleanWhitespace(text.split(':').skip(1).join(':'));
    } else if (lower.startsWith('modalidad:')) {
      modality = cleanWhitespace(text.split(':').skip(1).join(':'));
    } else if (lower.startsWith('aula:')) {
      classroom = cleanWhitespace(text.split(':').skip(1).join(':'));
    }
  }

  return CourseDetails(
    idComision: idComision,
    teachers: teachers,
    term: term,
    modality: modality,
    classroom: classroom,
  );
}
