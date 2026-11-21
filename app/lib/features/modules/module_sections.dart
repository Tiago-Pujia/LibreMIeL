import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';

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

/// Secciones exactas del menú lateral (`#menu-lateral`) relevadas de MIeL (`2025.2.0`) por herramienta.
List<MielModuleSection> mielSectionsForTool(MielToolKind tool) {
  switch (tool) {
    case MielToolKind.contenidos:
      return const [
        MielModuleSection(
          id: 'archivos',
          label: 'Archivos',
          icon: Icons.folder,
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
          icon: Icons.check_box,
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
          icon: Icons.check_box,
        ),
      ];
  }
}

/// Índice de la sección activa por defecto al entrar a un módulo de MIeL.
int defaultSectionIndexForTool(MielToolKind tool) {
  if (tool == MielToolKind.mensajeria) return 1; // Bandeja de entrada
  return 0;
}
