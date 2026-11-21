import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/miel_models.dart';
/// Genera un índice en Markdown con todos los enlaces externos y recursos web
/// de la materia (videos, Google Drive, enlaces a sitios) agrupados por sección y módulo.
String generateExternalLinksIndexMarkdown(
  ContentPageData content, {
  required String subjectName,
  required String commissionCode,
}) {
  final lines = <String>[];
  final dateFormatted = DateTime.now().toLocal().toString().split('.').first;
  final codDisplay = commissionCode.isNotEmpty ? commissionCode : 'Comisión ${content.idComision}';

  lines.add('# Enlaces Externos y Recursos Web');
  lines.add('');
  lines.add('- **Materia:** $subjectName ($codDisplay)');
  lines.add('- **Comisión ID:** ${content.idComision}');
  lines.add('- **Fecha de Respaldo:** $dateFormatted');
  lines.add('');
  lines.add('Este documento recopila todos los enlaces externos, videos, carpetas en la nube y recursos web que no son archivos descargables directos en MIeL.');
  lines.add('');
  lines.add('---');
  lines.add('');

  var foundAny = false;

  for (final section in content.sections) {
    var sectionHasLinks = false;
    final sectionBuffer = <String>[];

    for (final sub in section.submodules) {
      final externalItems = sub.items.where((i) => i.isExternal).toList();
      if (externalItems.isNotEmpty) {
        sectionHasLinks = true;
        foundAny = true;
        sectionBuffer.add('### ${sub.title.isNotEmpty ? sub.title : "Recursos"}');
        sectionBuffer.add('');
        for (final item in externalItems) {
          final desc = item.description.isNotEmpty ? ' — *${item.description}*' : '';
          sectionBuffer.add('- [${item.title}](${item.url})$desc');
        }
        sectionBuffer.add('');
      }
    }

    if (sectionHasLinks) {
      lines.add('## ${section.title}');
      lines.add('');
      lines.addAll(sectionBuffer);
    }
  }

  if (!foundAny) {
    lines.add('*No se encontraron enlaces externos en esta materia. Todos los elementos son archivos directos.*');
    lines.add('');
  }

  return '${lines.join('\n').trim()}\n';
}

/// Genera un índice completo en Markdown con todo el árbol de contenidos de la materia,
/// detallando módulos, submódulos, archivos binarios y enlaces externos.
String generateContentsSummaryMarkdown(
  ContentPageData content, {
  required String subjectName,
  required String commissionCode,
}) {
  final lines = <String>[];
  final dateFormatted = DateTime.now().toLocal().toString().split('.').first;
  final codDisplay = commissionCode.isNotEmpty ? commissionCode : 'Comisión ${content.idComision}';

  lines.add('# Índice de Contenidos — $subjectName');
  lines.add('');
  lines.add('- **Materia:** $subjectName ($codDisplay)');
  lines.add('- **Comisión ID:** ${content.idComision}');
  lines.add('- **Total de Secciones:** ${content.sections.length}');
  lines.add('- **Fecha de Generación:** $dateFormatted');
  lines.add('');
  lines.add('---');
  lines.add('');

  for (final section in content.sections) {
    lines.add('## 📁 ${section.title}');
    lines.add('');

    for (final sub in section.submodules) {
      lines.add('### 📂 ${sub.title.isNotEmpty ? sub.title : "Archivos"}');
      lines.add('');

      if (sub.items.isEmpty) {
        lines.add('*(Sin archivos en esta sección)*');
        lines.add('');
        continue;
      }

      lines.add('| Nombre | Tipo | Tamaño | Enlace / Archivo |');
      lines.add('| :--- | :---: | :---: | :--- |');

      for (final item in sub.items) {
        final icon = item.isExternal ? '🔗' : '📄';
        final sizeText = item.sizeLabel.isNotEmpty ? item.sizeLabel : '—';
        final pathOrUrl = item.isExternal
            ? '[Abrir enlace](${item.url})'
            : item.title;
        lines.add('| $icon ${item.title} | ${item.fileType} | $sizeText | $pathOrUrl |');
      }
      lines.add('');
    }
    lines.add('---');
    lines.add('');
  }

  return '${lines.join('\n').trim()}\n';
}

/// Guarda en disco los archivos de índice de contenidos de la materia.
Future<void> saveContentIndexFiles({
  required Directory targetDir,
  required ContentPageData content,
  required String subjectName,
  required String commissionCode,
}) async {
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  // 1. Índice general de contenidos
  final summaryMd = generateContentsSummaryMarkdown(
    content,
    subjectName: subjectName,
    commissionCode: commissionCode,
  );
  final summaryFile = File(p.join(targetDir.path, 'indice_contenidos.md'));
  await summaryFile.writeAsString(summaryMd, encoding: utf8);

  // 2. Índice de enlaces externos
  final linksMd = generateExternalLinksIndexMarkdown(
    content,
    subjectName: subjectName,
    commissionCode: commissionCode,
  );
  final linksFile = File(p.join(targetDir.path, 'enlaces_externos.md'));
  await linksFile.writeAsString(linksMd, encoding: utf8);
}
