import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';
import '../../core/storage/app_database.dart';
import '../navigation/navigation_history_entry.dart';
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
    this.mensajeriaState,
    this.onMensajeriaStateChanged,
    this.selectedPortafolioPractice,
    this.hasControlledPortafolioPractice = false,
    this.onSelectPortafolioPractice,
    this.scrollController,
    this.inPageFindQuery = '',
    this.nativeSearchFocusNode,
    this.findFocusTick = 0,
  });

  final Subject subject;
  final MielToolKind tool;
  final int sectionIndex;
  final int sectionResetTick;
  final String? selectedForoTopicId;
  final ValueChanged<String?> onSelectForoTopic;

  final MensajeriaViewRouteState? mensajeriaState;
  final ValueChanged<MensajeriaViewRouteState>? onMensajeriaStateChanged;

  final PortfolioPractice? selectedPortafolioPractice;
  final bool hasControlledPortafolioPractice;
  final ValueChanged<PortfolioPractice?>? onSelectPortafolioPractice;

  final ScrollController? scrollController;
  final String inPageFindQuery;
  final FocusNode? nativeSearchFocusNode;
  final int findFocusTick;

  @override
  Widget build(BuildContext context) {
    switch (tool) {
      case MielToolKind.contenidos:
        return ContenidosView(
          subject: subject,
          sectionIndex: sectionIndex,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
          searchFocusNode: nativeSearchFocusNode,
          findFocusTick: findFocusTick,
        );
      case MielToolKind.portafolio:
        return PortafolioView(
          subject: subject,
          sectionIndex: sectionIndex,
          sectionResetTick: sectionResetTick,
          controlledSelectedPractice: selectedPortafolioPractice,
          hasControlledPractice: hasControlledPortafolioPractice,
          onSelectPractice: onSelectPortafolioPractice,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
        );
      case MielToolKind.mensajeria:
        return MensajeriaView(
          subject: subject,
          sectionIndex: sectionIndex,
          sectionResetTick: sectionResetTick,
          controlledRouteState: mensajeriaState,
          onRouteStateChanged: onMensajeriaStateChanged,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
          searchFocusNode: nativeSearchFocusNode,
          findFocusTick: findFocusTick,
        );
      case MielToolKind.foro:
        return ForoView(
          subject: subject,
          selectedTopicId: selectedForoTopicId,
          onSelectTopic: onSelectForoTopic,
          externalScrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
          searchFocusNode: nativeSearchFocusNode,
          findFocusTick: findFocusTick,
        );
      case MielToolKind.evaluacion:
        return EvaluacionView(
          subject: subject,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
        );
      case MielToolKind.encuestas:
        return EncuestasView(
          subject: subject,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
        );
      case MielToolKind.autoguia:
      case MielToolKind.chat:
        return AutoguiaView(
          subject: subject,
          scrollController: scrollController,
          inPageFindQuery: inPageFindQuery,
        );
    }
  }
}
