import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';

/// Descriptor de cada sub-opción del menú lateral de un módulo en MIeL.
class MielModuleSection {
  const MielModuleSection({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// Secciones exactas del menú lateral (`#menu-lateral`) relevadas de MIeL por herramienta.
List<MielModuleSection> mielSectionsForTool(MielToolKind tool) {
  switch (tool) {
    case MielToolKind.contenidos:
      return const [
        MielModuleSection(
          id: 'archivos',
          label: 'Archivos',
          icon: Icons.folder,
        ),
        MielModuleSection(
          id: 'glosario',
          label: 'Glosario',
          icon: Icons.import_contacts,
        ),
        MielModuleSection(
          id: 'faq',
          label: 'Preguntas frecuentes',
          icon: Icons.help,
        ),
      ];
    case MielToolKind.portafolio:
      return const [
        MielModuleSection(
          id: 'practicas',
          label: 'Prácticas',
          icon: Icons.assignment,
        ),
        MielModuleSection(
          id: 'enviados',
          label: 'Archivos enviados',
          icon: Icons.file_upload,
        ),
        MielModuleSection(id: 'grupos', label: 'Mis grupos', icon: Icons.group),
        MielModuleSection(
          id: 'notas',
          label: 'Asistencia, notas y cert.',
          icon: Icons.spellcheck,
        ),
        MielModuleSection(
          id: 'competencias',
          label: 'Competencias',
          icon: Icons.emoji_objects,
        ),
      ];
    case MielToolKind.mensajeria:
      return const [
        MielModuleSection(
          id: 'nuevo',
          label: 'Nuevo mensaje',
          icon: Icons.mode_edit,
        ),
        MielModuleSection(
          id: 'entrada',
          label: 'Bandeja de entrada',
          icon: Icons.inbox,
        ),
        MielModuleSection(
          id: 'salida',
          label: 'Bandeja de salida',
          icon: Icons.send,
        ),
        MielModuleSection(
          id: 'borradores',
          label: 'Borradores',
          icon: Icons.drafts,
        ),
        MielModuleSection(
          id: 'favoritos',
          label: 'Favoritos',
          icon: Icons.star,
        ),
      ];
    case MielToolKind.foro:
      return const [
        MielModuleSection(
          id: 'temas',
          label: 'Temas abiertos',
          icon: Icons.forum,
        ),
      ];
    case MielToolKind.evaluacion:
      return const [
        MielModuleSection(
          id: 'evaluaciones',
          label: 'Evaluaciones',
          icon: Icons.assignment_turned_in,
        ),
        MielModuleSection(
          id: 'resultados',
          label: 'Resultados',
          icon: Icons.fact_check,
        ),
      ];
    case MielToolKind.chat:
      return const [
        MielModuleSection(
          id: 'salas',
          label: 'Salas de chat',
          icon: Icons.chat,
        ),
      ];
    case MielToolKind.autoguia:
      return const [
        MielModuleSection(
          id: 'recorrido',
          label: 'Autoguía',
          icon: Icons.auto_stories,
        ),
      ];
    case MielToolKind.encuestas:
      return const [
        MielModuleSection(
          id: 'encuestas',
          label: 'Encuestas',
          icon: Icons.note_alt,
        ),
      ];
  }
}

/// Índice de la sección activa por defecto al entrar a un módulo de MIeL.
int defaultSectionIndexForTool(MielToolKind tool) {
  if (tool == MielToolKind.mensajeria) return 1; // Bandeja de entrada
  return 0;
}

/// Vista borrador de la Fase 2 para cualquier módulo de una materia.
///
/// Jamás realiza peticiones HTTP adicionales contra MIeL: muestra únicamente el
/// esqueleto visual fiel al módulo junto con snapshots y alertas ya cacheados en SQLite.
class ModuleDraftView extends ConsumerWidget {
  const ModuleDraftView({
    super.key,
    required this.subject,
    required this.tool,
    required this.sectionIndex,
    required this.onBackHome,
  });

  final Subject subject;
  final MielToolKind tool;
  final int sectionIndex;
  final VoidCallback onBackHome;

  Future<void> _openInMielWeb() async {
    final uri = Uri.parse(
      '$kMielBaseUrl${tool.pathForCommission(subject.idComision)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _phase2Description() {
    switch (tool) {
      case MielToolKind.contenidos:
        return 'En la Fase 2 podrás explorar carpetas, filtrar teoría/prácticas y descargar archivos directamente desde LibreMIEL.';
      case MielToolKind.portafolio:
        return 'En la Fase 2 podrás ver consignas, fechas de vencimiento, estado de entregas y devoluciones docentes desde esta tabla.';
      case MielToolKind.mensajeria:
        return 'En la Fase 2 podrás leer tus mensajes de entrada/salida con formato nativo y redactar consultas (Fase 3).';
      case MielToolKind.foro:
        return 'En la Fase 2 podrás leer hilos completos, respuestas anidadas de docentes y exportar debates a Markdown.';
      case MielToolKind.evaluacion:
        return 'En la Fase 2 podrás consultar evaluaciones habilitadas, horarios y estado de entrega.';
      case MielToolKind.chat:
        return 'Módulo reservado para consulta de salas y accesos rápidos a MIeL.';
      case MielToolKind.autoguia:
        return 'En la Fase 2 podrás recorrer las unidades de la autoguía de la materia.';
      case MielToolKind.encuestas:
        return 'Acceso rápido a encuestas activas de la comisión en MIeL web.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final sections = mielSectionsForTool(tool);
    final safeIdx = sectionIndex.clamp(0, sections.length - 1);
    final activeSection = sections[safeIdx];
    final snapshotKey = tool.snapshotModuleKey;
    final snapshots = snapshotKey == null
        ? const <SnapshotEntry>[]
        : (ref
                  .watch(
                    subjectSnapshotsProvider((
                      idComision: subject.idComision,
                      module: snapshotKey,
                    )),
                  )
                  .value ??
              const <SnapshotEntry>[]);

    final badgeCount = subject.badgeFor(tool);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título h1 Light igual a MIeL ("Archivos", "Prácticas", "Bandeja de Entrada", etc.)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      activeSection.label,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 8),
                    MielRedBadge(
                      count: badgeCount,
                      backgroundColor: palette.badgeRed,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Banner borrador Fase 2 (estilo .w3-pale-yellow de MIeL)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.paleYellowBackground,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: palette.paleYellowBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'BORRADOR · FASE 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${subject.name} · ${tool.fullLabel}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_phase2Description()} Esta vista previa usa solo datos locales '
                      'en caché y no envía peticiones a MIeL (tus contadores de no leídos siguen intactos).',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openInMielWeb,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text('Abrir ${tool.fullLabel} en MIeL'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onBackHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.inputBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          icon: const Icon(Icons.home, size: 16),
                          label: const Text('Volver a Materias activas'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Previsualización estructural fiel al módulo de MIeL
              _buildModulePreview(context, palette, snapshots, isCompact),

              const SizedBox(height: 24),
              Divider(color: palette.divider, height: 1),
              const SizedBox(height: 14),
              Text(
                'LibreMIEL · Vista en modo borrador (Fase 2 en desarrollo)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModulePreview(
    BuildContext context,
    MielPalette palette,
    List<SnapshotEntry> snapshots,
    bool isCompact,
  ) {
    switch (tool) {
      case MielToolKind.contenidos:
        return _ContenidosDraftPreview(
          palette: palette,
          snapshots: snapshots,
          isCompact: isCompact,
        );
      case MielToolKind.portafolio:
        return _PortafolioDraftPreview(palette: palette, snapshots: snapshots);
      case MielToolKind.mensajeria:
        return _MensajeriaDraftPreview(palette: palette, snapshots: snapshots);
      case MielToolKind.foro:
        return _ForoDraftPreview(palette: palette, snapshots: snapshots);
      case MielToolKind.evaluacion:
        return _GenericDraftPreview(
          palette: palette,
          snapshots: snapshots,
          emptyLabel:
              'Aún no hay evaluaciones en caché local para esta comisión. '
              'Cuando el Ciclo 2 detecte evaluaciones habilitadas aparecerán aquí.',
          itemIcon: Icons.assignment_turned_in,
        );
      case MielToolKind.autoguia:
      case MielToolKind.chat:
      case MielToolKind.encuestas:
        return _GenericDraftPreview(
          palette: palette,
          snapshots: const [],
          emptyLabel:
              'Módulo en borrador. Usá "Abrir ${tool.fullLabel} en MIeL" para acceder desde el navegador.',
          itemIcon: tool.icon,
        );
    }
  }
}

/// Esqueleto fiel de Contenidos (`/contenido/archivos/`) visto en `modulo_contenidos_dark.png`.
class _ContenidosDraftPreview extends StatelessWidget {
  const _ContenidosDraftPreview({
    required this.palette,
    required this.snapshots,
    required this.isCompact,
  });

  final MielPalette palette;
  final List<SnapshotEntry> snapshots;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de filtros fiel a MIeL ("Tipo de archivo" + "Palabra clave" + "Buscar")
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: isCompact ? double.infinity : 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de archivo:',
                    style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: palette.inputBackground,
                      border: Border.all(color: palette.inputBorder),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '-- Todos --',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: palette.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: isCompact ? double.infinity : 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Palabra clave:',
                    style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: palette.inputBackground,
                            border: Border.all(color: palette.inputBorder),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(2),
                            ),
                          ),
                          child: Text(
                            'Disponible en Fase 2…',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: palette.textMuted.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Buscar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carpetas desplegables (.desplegarModulo)
        if (snapshots.isEmpty) ...[
          for (final placeholder in const [
            'Material teórico y apuntes (vista borrador)',
            'Guías de trabajos prácticos (vista borrador)',
            'Enlaces y bibliografía (vista borrador)',
          ]) ...[
            _FolderAccordionBar(palette: palette, title: placeholder),
            const SizedBox(height: 10),
          ],
        ] else ...[
          Text(
            'Elementos detectados en caché local (${snapshots.length})',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.linkAccent,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in snapshots.take(25)) ...[
            _FolderAccordionBar(
              palette: palette,
              title: entry.summary.isNotEmpty
                  ? entry.summary
                  : 'Elemento #${entry.itemId}',
              subtitle: _formatDate(entry.updatedAt),
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _FolderAccordionBar extends StatelessWidget {
  const _FolderAccordionBar({
    required this.palette,
    required this.title,
    this.subtitle,
    this.icon = Icons.folder,
  });

  final MielPalette palette;
  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: palette.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Esqueleto fiel de Portafolio (`/portafolio/practicas/`) con tabla bordeada.
class _PortafolioDraftPreview extends StatelessWidget {
  const _PortafolioDraftPreview({
    required this.palette,
    required this.snapshots,
  });

  final MielPalette palette;
  final List<SnapshotEntry> snapshots;

  @override
  Widget build(BuildContext context) {
    return _MielDraftTable(
      palette: palette,
      headers: const [
        'Práctica',
        'Vencimiento',
        'Estado / Nota',
        'Sincronizado',
      ],
      rows: [for (final s in snapshots) _parsePortfolioRow(s)],
      emptyMessage: 'Sin prácticas sincronizadas todavía en caché local. Se cargan automáticamente en el Ciclo 2.',
    );
  }

  List<String> _parsePortfolioRow(SnapshotEntry s) {
    // fingerprint: '$dueDate|$deliveryDate|$correctionDate|$status|$grade'
    final parts = s.fingerprint.split('|');
    final due = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : '—';
    final status = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : '—';
    final grade = parts.length > 4 && parts[4].isNotEmpty
        ? ' · Nota: ${parts[4]}'
        : '';
    return [
      s.summary.isNotEmpty ? s.summary : 'Práctica #${s.itemId}',
      due,
      '$status$grade',
      _formatDate(s.updatedAt),
    ];
  }
}

/// Esqueleto fiel de Mensajería (`/mensajeria/entrada/`).
class _MensajeriaDraftPreview extends StatelessWidget {
  const _MensajeriaDraftPreview({
    required this.palette,
    required this.snapshots,
  });

  final MielPalette palette;
  final List<SnapshotEntry> snapshots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DraftToolbarChip(
              palette: palette,
              icon: Icons.mode_edit,
              label: 'Redactar (Fase 3)',
              primary: true,
            ),
            _DraftToolbarChip(
              palette: palette,
              icon: Icons.search,
              label: 'Filtrar (Fase 2)',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MielDraftTable(
          palette: palette,
          headers: const ['Resumen / Asunto', 'Estado', 'Registrado'],
          rows: [
            for (final s in snapshots.take(25))
              [
                s.summary.isNotEmpty ? s.summary : 'Mensaje #${s.itemId}',
                s.fingerprint.contains('unread') ? 'No leído' : 'En caché',
                _formatDate(s.updatedAt),
              ],
          ],
          emptyMessage: 'Aún no hay mensajes en caché local para esta materia. Aparecerán cuando se sincronicen avisos.',
        ),
      ],
    );
  }
}

/// Esqueleto fiel de Foros (`/forov2/temas/`).
class _ForoDraftPreview extends StatelessWidget {
  const _ForoDraftPreview({required this.palette, required this.snapshots});

  final MielPalette palette;
  final List<SnapshotEntry> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return _GenericDraftPreview(
        palette: palette,
        snapshots: const [],
        emptyLabel:
            'Todavía no hay temas de foro cacheados para esta materia. '
            'Cuando el sincronizador detecte temas aparecerán listados aquí.',
        itemIcon: Icons.forum,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in snapshots.take(30)) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.forum, size: 28, color: palette.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.summary.isNotEmpty ? s.summary : 'Tema #${s.itemId}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatForoMeta(s),
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _formatForoMeta(SnapshotEntry s) {
    // fingerprint: '$messageCount|$lastMessageDate|$unreadBadge|$isClosed'
    final parts = s.fingerprint.split('|');
    final msgs = parts.isNotEmpty ? parts[0] : '0';
    final date = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '—';
    return '$msgs mensaje(s) · Última actividad: $date';
  }
}

class _GenericDraftPreview extends StatelessWidget {
  const _GenericDraftPreview({
    required this.palette,
    required this.snapshots,
    required this.emptyLabel,
    required this.itemIcon,
  });

  final MielPalette palette;
  final List<SnapshotEntry> snapshots;
  final String emptyLabel;
  final IconData itemIcon;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Icon(itemIcon, size: 32, color: palette.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                emptyLabel,
                style: TextStyle(fontSize: 13.5, color: palette.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in snapshots) ...[
          _FolderAccordionBar(
            palette: palette,
            icon: itemIcon,
            title: s.summary.isNotEmpty ? s.summary : 'Ítem #${s.itemId}',
            subtitle: _formatDate(s.updatedAt),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MielDraftTable extends StatelessWidget {
  const _MielDraftTable({
    required this.palette,
    required this.headers,
    required this.rows,
    required this.emptyMessage,
  });

  final MielPalette palette;
  final List<String> headers;
  final List<List<String>> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.divider),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: palette.cardBackground,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  Expanded(
                    flex: i == 0 ? 3 : 2,
                    child: Text(
                      headers[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: palette.divider, height: 1),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                emptyMessage,
                style: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
            )
          else
            for (var r = 0; r < rows.length; r++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    for (var c = 0; c < rows[r].length; c++)
                      Expanded(
                        flex: c == 0 ? 3 : 2,
                        child: Text(
                          rows[r][c],
                          style: TextStyle(
                            fontSize: 13,
                            color: c == 0
                                ? palette.textPrimary
                                : palette.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (r < rows.length - 1)
                Divider(color: palette.divider, height: 1),
            ],
        ],
      ),
    );
  }
}

class _DraftToolbarChip extends StatelessWidget {
  const _DraftToolbarChip({
    required this.palette,
    required this.icon,
    required this.label,
    this.primary = false,
  });

  final MielPalette palette;
  final IconData icon;
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? palette.primary : palette.buttonSecondaryBackground,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: primary ? Colors.white : palette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: primary ? Colors.white : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$d/$m $hh:$mm';
}
