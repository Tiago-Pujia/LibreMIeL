import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/exporters/content_exporter.dart';
import 'package:libremiel/core/exporters/forum_exporter.dart';
import 'package:libremiel/core/models/miel_models.dart';

void main() {
  group('Fase 4 — Sanitización y Exporters (Foros y Contenidos)', () {
    test('sanitizeFileName limpia caracteres ilegales en Windows/Linux/macOS', () {
      expect(sanitizeFileName('  TP N°1: Algoritmos / C++ ? * <hola> |  '), equals('TP N°1_ Algoritmos _ C++ _ _ _hola_ _'));
      expect(sanitizeFileName('...archivo.pdf...'), equals('archivo.pdf'));
      expect(sanitizeFileName('   '), equals('sin_nombre'));
      expect(sanitizeFileName(''), equals('sin_nombre'));

      final longName = 'A' * 200;
      final sanitizedLong = sanitizeFileName(longName, maxLength: 50);
      expect(sanitizedLong.length, equals(50));
    });

    test('htmlToCleanMarkdown convierte HTML de MIeL a Markdown legible y preserva menciones', () {
      const html = '''
        <p>Hola <strong>Juan</strong>,<br>
        ¿Pudiste ver el archivo adjunto?</p>
        <p>Revisá el siguiente link: <a href="https://example.com/guia">Guía de ejercicios</a></p>
        <strong class="tagUsuario" data-idUsuario="123" data-idMensaje="456">@Prof. Pérez</strong>&nbsp;muchas gracias!
        <ul>
          <li>Punto 1</li>
          <li>Punto 2</li>
        </ul>
      ''';

      final md = htmlToCleanMarkdown(html);
      expect(md, contains('Hola **Juan**'));
      expect(md, contains('[Guía de ejercicios](https://example.com/guia)'));
      expect(md, contains('@Prof. Pérez'));
      expect(md, contains('- Punto 1'));
      expect(md, contains('- Punto 2'));
    });

    test('generateForumMarkdown genera estructura idéntica a ExtraerForosMIeL con citas e hilos', () {
      const thread = ForumThreadData(
        idComision: '119341',
        idTema: '8801',
        title: 'Dudas sobre el Trabajo Práctico N° 2',
        description: 'Espacio de consultas para el TP 2',
        currentUserId: '12345',
        messages: [
          ForumMessageItem(
            id: '101',
            parentId: '101',
            isReply: false,
            authorName: 'Martín Gómez',
            authorId: '551',
            role: 'Alumno/a',
            isTeacher: false,
            date: '10/05/2026 14:30',
            bodyText: 'Buenas tardes, ¿en el ejercicio 3 se puede usar recursión?',
            bodyHtml: '<p>Buenas tardes, ¿en el ejercicio 3 se puede usar recursión?</p>',
            fileAttachments: [
              MielAttachment(
                fileName: 'ejercicio3_codigo.cpp',
                downloadUrl: 'https://miel.unlam.edu.ar/forov2/event/descargar/...',
                fileType: 'cpp',
              ),
            ],
          ),
          ForumMessageItem(
            id: '102',
            parentId: '101',
            isReply: true,
            authorName: 'Lic. Laura Fernández',
            authorId: '882',
            role: 'Tutor/a',
            isTeacher: true,
            date: '10/05/2026 15:10',
            bodyText: 'Hola Martín. Sí, es válido usar recursión siempre que se especifique el caso base.',
            bodyHtml: '<p>Hola Martín. Sí, es válido usar recursión siempre que se especifique el caso base.</p>',
          ),
        ],
      );

      final md = generateForumMarkdown(
        thread,
        subjectName: 'Programación Avanzada',
        commissionCode: 'Comisión 119341',
        hasLocalAttachments: true,
      );

      expect(md, contains('# Tema: Dudas sobre el Trabajo Práctico N° 2'));
      expect(md, contains('- **Materia:** Programación Avanzada (Comisión 119341)'));
      expect(md, contains('### [Mensaje #101] Martín Gómez (Alumno/a)'));
      expect(md, contains('[ejercicio3_codigo.cpp](adjuntos/ejercicio3_codigo.cpp)'));
      expect(md, contains('> #### [Respuesta #102 a #101] Lic. Laura Fernández (Tutor/a)'));
      expect(md, contains('> Hola Martín. Sí, es válido usar recursión'));
    });

    test('generateForumJson genera un árbol estructurado de mensajes', () {
      const thread = ForumThreadData(
        idComision: '119341',
        idTema: '8801',
        title: 'Dudas sobre TP 2',
        currentUserId: '12345',
        messages: [
          ForumMessageItem(
            id: '101',
            parentId: '101',
            isReply: false,
            authorName: 'Martín',
            authorId: '551',
            role: 'Alumno/a',
            isTeacher: false,
            date: '10/05/2026',
            bodyText: 'Texto plano',
          ),
        ],
      );

      final json = generateForumJson(
        thread,
        subjectName: 'Programación',
        commissionCode: 'COM-1',
      );

      expect(json['materia'], equals('Programación'));
      expect(json['idTema'], equals('8801'));
      expect(json['totalMensajes'], equals(1));
      final msgs = json['mensajes'] as List;
      expect(msgs.length, equals(1));
      expect(msgs.first['autor'], equals('Martín'));
    });

    test('generateForumHtml genera documento autocontenido con estilos y etiquetas de rol', () {
      const thread = ForumThreadData(
        idComision: '119341',
        idTema: '8801',
        title: 'Dudas sobre TP 2',
        currentUserId: '12345',
        messages: [
          ForumMessageItem(
            id: '101',
            parentId: '101',
            isReply: false,
            authorName: 'Profe Titular',
            authorId: '881',
            role: 'Tutor/a',
            isTeacher: true,
            date: '10/05/2026',
            bodyText: 'Aviso importante',
            bodyHtml: '<p>Aviso importante</p>',
          ),
        ],
      );

      final html = generateForumHtml(
        thread,
        subjectName: 'Programación',
        commissionCode: 'COM-1',
      );

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<title>Dudas sobre TP 2 — LibreMIeL</title>'));
      expect(html, contains('Profe Titular'));
      expect(html, contains('role-teacher'));
      expect(html, contains('LibreMIeL'));
    });

    test('generateExternalLinksIndexMarkdown y generateContentsSummaryMarkdown organizan contenidos', () {
      const item1 = ContentItem(
        idElemento: 'e1',
        idComision: '119341',
        moduleName: 'Unidad 1',
        title: 'Clase Grabada en YouTube',
        uploadDate: '01/03/2026',
        url: 'https://youtube.com/watch?v=12345',
        isExternal: true,
        description: 'Grabación de la clase inaugural',
      );

      const item2 = ContentItem(
        idElemento: 'e2',
        idComision: '119341',
        moduleName: 'Unidad 1',
        title: 'Apunte Teórico N° 1.pdf',
        uploadDate: '01/03/2026',
        url: 'https://miel.unlam.edu.ar/contenido/event/descargar/...',
        isExternal: false,
        sizeLabel: '3.4 MB',
      );

      const content = ContentPageData(
        idComision: '119341',
        sections: [
          ContentSection(
            title: 'Unidad 1 — Introducción',
            isCollapsibleFolder: true,
            submodules: [
              ContentSubmodule(
                title: 'Material Teórico',
                items: [item1, item2],
              ),
            ],
          ),
        ],
        allItems: [item1, item2],
      );

      final linksMd = generateExternalLinksIndexMarkdown(
        content,
        subjectName: 'Sistemas Operativos',
        commissionCode: 'Comisión 119341',
      );

      expect(linksMd, contains('# Enlaces Externos y Recursos Web'));
      expect(linksMd, contains('Clase Grabada en YouTube'));
      expect(linksMd, contains('https://youtube.com/watch?v=12345'));
      expect(linksMd, isNot(contains('Apunte Teórico N° 1.pdf')));

      final summaryMd = generateContentsSummaryMarkdown(
        content,
        subjectName: 'Sistemas Operativos',
        commissionCode: 'Comisión 119341',
      );

      expect(summaryMd, contains('# Índice de Contenidos — Sistemas Operativos'));
      expect(summaryMd, contains('Unidad 1 — Introducción'));
      expect(summaryMd, contains('Apunte Teórico N° 1.pdf'));
      expect(summaryMd, contains('3.4 MB'));
    });
  });
}
