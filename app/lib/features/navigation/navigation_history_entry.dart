import 'package:flutter/foundation.dart';

import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart' show kMielBaseUrl;

/// Secciones principales de alto nivel dentro del shell de LibreMIeL.
enum BrowserShellSection { home, novedades, ajustes, module }

/// Sub-estado de navegación interna dentro del lector de Mensajería.
@immutable
class MensajeriaViewRouteState {
  const MensajeriaViewRouteState({
    this.page = 1,
    this.unifiedCrossSubjectMode = false,
    this.inlineComposeMode = false,
    this.selectedMessage,
  });

  final int page;
  final bool unifiedCrossSubjectMode;
  final bool inlineComposeMode;
  final InboxMessageSummary? selectedMessage;

  String get locationKey {
    if (selectedMessage != null) {
      return 'msg:${selectedMessage!.idComision}:${selectedMessage!.idMensaje}';
    }
    if (inlineComposeMode) {
      return 'compose';
    }
    if (unifiedCrossSubjectMode) {
      return 'unified:pag$page';
    }
    return 'page:$page';
  }

  MensajeriaViewRouteState copyWith({
    int? page,
    bool? unifiedCrossSubjectMode,
    bool? inlineComposeMode,
    InboxMessageSummary? selectedMessage,
    bool clearSelectedMessage = false,
  }) {
    return MensajeriaViewRouteState(
      page: page ?? this.page,
      unifiedCrossSubjectMode:
          unifiedCrossSubjectMode ?? this.unifiedCrossSubjectMode,
      inlineComposeMode: inlineComposeMode ?? this.inlineComposeMode,
      selectedMessage: clearSelectedMessage
          ? null
          : (selectedMessage ?? this.selectedMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MensajeriaViewRouteState &&
        other.page == page &&
        other.unifiedCrossSubjectMode == unifiedCrossSubjectMode &&
        other.inlineComposeMode == inlineComposeMode &&
        other.selectedMessage?.idComision == selectedMessage?.idComision &&
        other.selectedMessage?.idMensaje == selectedMessage?.idMensaje;
  }

  @override
  int get hashCode => Object.hash(
    page,
    unifiedCrossSubjectMode,
    inlineComposeMode,
    selectedMessage?.idComision,
    selectedMessage?.idMensaje,
  );
}

/// Representa una ubicación navegable inmutable dentro de la app autenticada.
@immutable
class NavigationHistoryEntry {
  const NavigationHistoryEntry({
    required this.section,
    this.subjectId,
    this.tool = MielToolKind.contenidos,
    this.moduleSectionIndex = 0,
    this.foroTopicId,
    this.mensajeriaState = const MensajeriaViewRouteState(),
    this.portafolioPractice,
    this.novedadesModuleFilter,
    this.scrollOffset = 0.0,
  });

  const NavigationHistoryEntry.home({double scrollOffset = 0.0})
    : this(section: BrowserShellSection.home, scrollOffset: scrollOffset);

  const NavigationHistoryEntry.novedades({
    String? moduleFilter,
    double scrollOffset = 0.0,
  }) : this(
         section: BrowserShellSection.novedades,
         novedadesModuleFilter: moduleFilter,
         scrollOffset: scrollOffset,
       );

  const NavigationHistoryEntry.ajustes({double scrollOffset = 0.0})
    : this(section: BrowserShellSection.ajustes, scrollOffset: scrollOffset);

  const NavigationHistoryEntry.module({
    required String subjectId,
    required MielToolKind tool,
    int moduleSectionIndex = 0,
    String? foroTopicId,
    MensajeriaViewRouteState mensajeriaState = const MensajeriaViewRouteState(),
    PortfolioPractice? portafolioPractice,
    double scrollOffset = 0.0,
  }) : this(
         section: BrowserShellSection.module,
         subjectId: subjectId,
         tool: tool,
         moduleSectionIndex: moduleSectionIndex,
         foroTopicId: foroTopicId,
         mensajeriaState: mensajeriaState,
         portafolioPractice: portafolioPractice,
         scrollOffset: scrollOffset,
       );

  final BrowserShellSection section;
  final String? subjectId;
  final MielToolKind tool;
  final int moduleSectionIndex;
  final String? foroTopicId;
  final MensajeriaViewRouteState mensajeriaState;
  final PortfolioPractice? portafolioPractice;
  final String? novedadesModuleFilter;
  final double scrollOffset;

  /// Clave lógica determinista sin incluir [scrollOffset], para deduplicar
  /// entradas consecutivas y asociar entradas en el historial.
  String get locationKey {
    switch (section) {
      case BrowserShellSection.home:
        return 'home';
      case BrowserShellSection.novedades:
        return 'novedades:${novedadesModuleFilter ?? 'all'}';
      case BrowserShellSection.ajustes:
        return 'ajustes';
      case BrowserShellSection.module:
        final sId = subjectId ?? '0';
        final tName = tool.name;
        final foroKey = foroTopicId != null ? ':foro=$foroTopicId' : '';
        final msgKey = ':msg=${mensajeriaState.locationKey}';
        final pracKey = portafolioPractice != null
            ? ':prac=${portafolioPractice!.idPractica}'
            : '';
        return 'module:$sId:$tName:$moduleSectionIndex$foroKey$msgKey$pracKey';
    }
  }

  /// Retorna la URL oficial de MIeL correspondiente a esta pantalla para
  /// "Copiar enlace de MIeL" y "Abrir en navegador web".
  String canonicalMielUrl() {
    switch (section) {
      case BrowserShellSection.home:
      case BrowserShellSection.novedades:
        return '$kMielBaseUrl/principal/interno/';
      case BrowserShellSection.ajustes:
        return '$kMielBaseUrl/perfil/datos/';
      case BrowserShellSection.module:
        final sId = subjectId ?? '0';
        if (tool == MielToolKind.foro && foroTopicId != null) {
          return '$kMielBaseUrl/forov2/mensajes/comision/$sId/tema/$foroTopicId';
        }
        if (tool == MielToolKind.mensajeria) {
          if (mensajeriaState.selectedMessage != null) {
            final msg = mensajeriaState.selectedMessage!;
            if (msg.detailUrl.isNotEmpty) {
              return msg.detailUrl.startsWith('http')
                  ? msg.detailUrl
                  : '$kMielBaseUrl${msg.detailUrl.startsWith('/') ? '' : '/'}${msg.detailUrl}';
            }
            return '$kMielBaseUrl/mensajeria/verEntrada/comision/${msg.idComision}/pag/${mensajeriaState.page}/from/entrada/id/${msg.idMensaje}';
          }
          if (mensajeriaState.inlineComposeMode || moduleSectionIndex == 0) {
            return '$kMielBaseUrl/mensajeria/redactar/comision/$sId';
          }
          final boxSegment = switch (moduleSectionIndex) {
            2 => 'salida',
            3 => 'borradores',
            4 => 'favoritos',
            _ => 'entrada',
          };
          return '$kMielBaseUrl/mensajeria/$boxSegment/comision/$sId/pag/${mensajeriaState.page}';
        }
        if (tool == MielToolKind.portafolio) {
          if (portafolioPractice != null) {
            final p = portafolioPractice!;
            if (p.detailUrl.isNotEmpty) {
              return p.detailUrl.startsWith('http')
                  ? p.detailUrl
                  : '$kMielBaseUrl${p.detailUrl.startsWith('/') ? '' : '/'}${p.detailUrl}';
            }
            return '$kMielBaseUrl/portafolio/entregas/comision/$sId/id/${p.idPractica}';
          }
          final sectionSegment = switch (moduleSectionIndex) {
            1 => 'archivosEnviados',
            2 => 'misGrupos',
            3 => 'notas',
            _ => 'practicas',
          };
          return '$kMielBaseUrl/portafolio/$sectionSegment/comision/$sId';
        }
        return '$kMielBaseUrl${tool.pathForCommission(sId)}';
    }
  }

  NavigationHistoryEntry copyWith({
    BrowserShellSection? section,
    String? subjectId,
    MielToolKind? tool,
    int? moduleSectionIndex,
    String? foroTopicId,
    bool clearForoTopicId = false,
    MensajeriaViewRouteState? mensajeriaState,
    PortfolioPractice? portafolioPractice,
    bool clearPortafolioPractice = false,
    String? novedadesModuleFilter,
    double? scrollOffset,
  }) {
    return NavigationHistoryEntry(
      section: section ?? this.section,
      subjectId: subjectId ?? this.subjectId,
      tool: tool ?? this.tool,
      moduleSectionIndex: moduleSectionIndex ?? this.moduleSectionIndex,
      foroTopicId: clearForoTopicId ? null : (foroTopicId ?? this.foroTopicId),
      mensajeriaState: mensajeriaState ?? this.mensajeriaState,
      portafolioPractice: clearPortafolioPractice
          ? null
          : (portafolioPractice ?? this.portafolioPractice),
      novedadesModuleFilter:
          novedadesModuleFilter ?? this.novedadesModuleFilter,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationHistoryEntry &&
        other.section == section &&
        other.subjectId == subjectId &&
        other.tool == tool &&
        other.moduleSectionIndex == moduleSectionIndex &&
        other.foroTopicId == foroTopicId &&
        other.mensajeriaState == mensajeriaState &&
        other.portafolioPractice?.idPractica ==
            portafolioPractice?.idPractica &&
        other.novedadesModuleFilter == novedadesModuleFilter &&
        (other.scrollOffset - scrollOffset).abs() < 0.1;
  }

  @override
  int get hashCode => Object.hash(
    section,
    subjectId,
    tool,
    moduleSectionIndex,
    foroTopicId,
    mensajeriaState,
    portafolioPractice?.idPractica,
    novedadesModuleFilter,
  );
}
