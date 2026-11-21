import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';
import '../../core/storage/app_database.dart';
import 'contenidos_view.dart';
import 'foro_view.dart';
import 'mensajeria_view.dart';
import 'portafolio_view.dart';
import 'secondary_modules_view.dart';

/// Host principal de la **Fase 2 — Lectura** que despacha cada herramienta de MIeL
/// a su lector nativo correspondiente.
class ModuleReaderHost extends StatelessWidget {
  const ModuleReaderHost({
    super.key,
    required this.subject,
    required this.tool,
    required this.sectionIndex,
    required this.selectedForoTopicId,
    required this.onSelectForoTopic,
    this.sectionResetTick = 0,
  });

  final Subject subject;
  final MielToolKind tool;
  final int sectionIndex;
  final int sectionResetTick;
  final String? selectedForoTopicId;
  final ValueChanged<String?> onSelectForoTopic;

  @override
  Widget build(BuildContext context) {
    switch (tool) {
      case MielToolKind.contenidos:
        return ContenidosView(subject: subject, sectionIndex: sectionIndex);
      case MielToolKind.portafolio:
        return PortafolioView(
          subject: subject,
          sectionIndex: sectionIndex,
          sectionResetTick: sectionResetTick,
        );
      case MielToolKind.mensajeria:
        return MensajeriaView(
          subject: subject,
          sectionIndex: sectionIndex,
          sectionResetTick: sectionResetTick,
        );
      case MielToolKind.foro:
        return ForoView(
          subject: subject,
          selectedTopicId: selectedForoTopicId,
          onSelectTopic: onSelectForoTopic,
        );
      case MielToolKind.evaluacion:
        return EvaluacionView(subject: subject);
      case MielToolKind.encuestas:
        return EncuestasView(subject: subject);
      case MielToolKind.autoguia:
      case MielToolKind.chat:
        return AutoguiaView(subject: subject);
    }
  }
}
