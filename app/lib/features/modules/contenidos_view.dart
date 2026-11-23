import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/parsers/text_normalizer.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/miel_rich_text.dart';
import 'widgets/module_state_views.dart';

/// Vista nativa de lectura del módulo **Contenidos** (`Archivos`)
/// fiel a MIeL (`2025.2.0`).
class ContenidosView extends ConsumerStatefulWidget {
  const ContenidosView({
    super.key,
    required this.subject,
    required this.sectionIndex,
  });

  final Subject subject;
  final int sectionIndex;

  @override
  ConsumerState<ContenidosView> createState() => _ContenidosViewState();
}

class _ContenidosViewState extends ConsumerState<ContenidosView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter =
      '0'; // 0: Todos, T: Teoría, P: Prácticas, E: Enlaces

  final Set<String> _expandedFolders = <String>{};
  final Set<String> _expandedDescriptions = <String>{};
  final Set<String> _locallyDownloadedIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: _buildArchivosSection(context, isCompact),
        );
      },
    );
  }

  Widget _buildArchivosSection(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/contenido/archivos/comision/$idComision';
    final pageAsync = ref.watch(contenidosPageProvider(idComision));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Archivos',
          badgeCount: widget.subject.lastContenidosBadge,
        ),
        const SizedBox(height: 14),

        // Barra de filtros fiel a form#formBuscarArchivos ("Tipo de archivo:" + "Palabra clave:" + "Buscar")
        _buildFilterBar(palette, isCompact),
        const SizedBox(height: 18),

        pageAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Cargando contenidos de la materia…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar los contenidos: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(contenidosPageProvider(idComision)),
          ),
          data: (pageData) =>
              _buildContentPageBody(context, palette, pageData, isCompact),
        ),
      ],
    );
  }

  Widget _buildFilterBar(MielPalette palette, bool isCompact) {
    final tipoField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de archivo:',
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTypeFilter,
              isExpanded: true,
              dropdownColor: palette.dropdownBackground,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
              items: const [
                DropdownMenuItem(value: '0', child: Text('-- Todos --')),
                DropdownMenuItem(value: 'T', child: Text('Teoría')),
                DropdownMenuItem(value: 'P', child: Text('Prácticas')),
                DropdownMenuItem(value: 'E', child: Text('Enlaces')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTypeFilter = val);
                }
              },
            ),
          ),
        ),
      ],
    );

    final palabraClaveField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Palabra clave:',
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        MielSearchBarField(
          controller: _searchController,
          query: _searchQuery,
          hintText: 'Filtrar por título, módulo o descripción…',
          onChanged: (v) => setState(() => _searchQuery = v),
          onSubmitted: () =>
              setState(() => _searchQuery = _searchController.text),
          onCleared: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tipoField, const SizedBox(height: 12), palabraClaveField],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: 240, child: tipoField),
        const SizedBox(width: 16),
        Expanded(child: palabraClaveField),
      ],
    );
  }

  bool _matchesItemFilter(ContentItem item) {
    if (_selectedTypeFilter == 'E') {
      if (!item.isExternal &&
          item.fileType != 'explore' &&
          item.fileType != 'link' &&
          item.fileType != 'youtube') {
        return false;
      }
    } else if (_selectedTypeFilter == 'P') {
      final combined = normalizeText(
        '${item.moduleName} ${item.submoduleName} ${item.title}',
      );
      final isPractice =
          combined.contains('practic') ||
          combined.contains('guia') ||
          combined.contains('tp') ||
          combined.contains('ejercic') ||
          combined.contains('entrega');
      if (!isPractice) return false;
    } else if (_selectedTypeFilter == 'T') {
      if (item.isExternal) return false;
      final combined = normalizeText(
        '${item.moduleName} ${item.submoduleName} ${item.title}',
      );
      final isPracticeOnly =
          combined.contains('trabajo practico') ||
          combined.contains('guia de ejercicios');
      if (isPracticeOnly) return false;
    }

    final q = normalizeText(_searchQuery);
    if (q.isEmpty) return true;
    final haystack = normalizeText(
      '${item.title} ${item.moduleName} ${item.submoduleName} ${item.description} ${item.uploadDate}',
    );
    return haystack.contains(q);
  }

  Widget _buildContentPageBody(
    BuildContext context,
    MielPalette palette,
    ContentPageData pageData,
    bool isCompact,
  ) {
    if (pageData.allItems.isEmpty) {
      return const MielModuleEmptyView(
        message: 'No se encontraron archivos en este curso.',
        icon: Icons.folder_open,
      );
    }

    final hasActiveSearch =
        _searchQuery.trim().isNotEmpty || _selectedTypeFilter != '0';
    final visibleSections = <Widget>[];

    for (var sIdx = 0; sIdx < pageData.sections.length; sIdx++) {
      final section = pageData.sections[sIdx];
      final filteredSubmodules = <ContentSubmodule>[];
      for (final sub in section.submodules) {
        final matchingItems = sub.items.where(_matchesItemFilter).toList();
        if (matchingItems.isNotEmpty) {
          filteredSubmodules.add(
            ContentSubmodule(
              title: sub.title,
              description: sub.description,
              items: matchingItems,
            ),
          );
        }
      }
      if (filteredSubmodules.isEmpty) continue;

      if (section.isCollapsibleFolder) {
        final folderKey = '${section.title}#$sIdx';
        final isExpanded =
            hasActiveSearch || _expandedFolders.contains(folderKey);

        visibleSections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(3),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_expandedFolders.contains(folderKey)) {
                          _expandedFolders.remove(folderKey);
                        } else {
                          _expandedFolders.add(folderKey);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(3),
                    hoverColor: palette.cardHover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? Icons.folder_open : Icons.folder,
                            size: 22,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          if (section.unreadBadge > 0) ...[
                            MielRedBadge(
                              count: section.unreadBadge,
                              backgroundColor: palette.badgeRed,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                            color: palette.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildSubmodulesTable(
                      context,
                      palette,
                      filteredSubmodules,
                      isCompact,
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        visibleSections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildSubmodulesTable(
              context,
              palette,
              filteredSubmodules,
              isCompact,
            ),
          ),
        );
      }
    }

    if (visibleSections.isEmpty) {
      return const MielModuleEmptyView(
        message:
            'Ningún archivo coincide con el filtro o palabra clave ingresada.',
        icon: Icons.search_off,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visibleSections,
    );
  }

  Widget _buildSubmodulesTable(
    BuildContext context,
    MielPalette palette,
    List<ContentSubmodule> submodules,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sub in submodules) ...[
          // Encabezado del submódulo (thead > tr > th)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.divider, width: 1.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sub.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Tipo lectura',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'F. subida',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Text(
                      'Tamaño',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                SizedBox(
                  width: 78,
                  child: Text(
                    'Descargar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de archivos (tbody > tr)
          for (final item in sub.items)
            _buildContentRow(context, palette, item, isCompact),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildContentRow(
    BuildContext context,
    MielPalette palette,
    ContentItem item,
    bool isCompact,
  ) {
    final isDownloaded =
        item.isDownloaded || _locallyDownloadedIds.contains(item.idElemento);
    final isDescExpanded =
        _expandedDescriptions.contains(item.idElemento) ||
        (_searchQuery.trim().isNotEmpty &&
            normalizeText(item.description)
                .contains(normalizeText(_searchQuery)));

    final rowBg = item.isHighlightedNew
        ? palette.paleYellowBackground
        : Colors.transparent;

    return MielHoverRow(
      backgroundColor: rowBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MielFileTypeIcon(fileType: item.fileType, size: 22),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (item.description.isNotEmpty)
                      Tooltip(
                        message: isDescExpanded
                            ? 'Ocultar descripción'
                            : 'Ver descripción',
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_expandedDescriptions.contains(
                                  item.idElemento,
                                )) {
                                  _expandedDescriptions.remove(item.idElemento);
                                } else {
                                  _expandedDescriptions.add(item.idElemento);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              child: Icon(
                                Icons.more_horiz,
                                size: 19,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isCompact)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (item.readingType.isNotEmpty) item.readingType,
                        if (item.uploadDate.isNotEmpty) item.uploadDate,
                        if (item.sizeLabel.isNotEmpty) item.sizeLabel,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                if (item.description.isNotEmpty && isDescExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MielRichText(
                      htmlContent: item.description,
                      fallbackPlainText: item.description,
                      highlightQuery: _searchQuery,
                      baseFontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
          if (!isCompact) ...[
            SizedBox(
              width: 120,
              child: Text(
                item.readingType,
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                item.uploadDate,
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
              ),
            ),
            SizedBox(
              width: 95,
              child: Text(
                item.sizeLabel,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
              ),
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Center(
              child: Tooltip(
                message: item.isExternal
                    ? (isDownloaded
                          ? 'Abrir enlace externo (ya visitado)'
                          : 'Abrir enlace externo')
                    : (isDownloaded
                          ? 'Descargar archivo (ya descargado)'
                          : 'Descargar archivo'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleContentItemAction(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        item.isExternal ? Icons.link : Icons.file_download,
                        size: 22,
                        color: isDownloaded
                            ? palette.linkAccent
                            : palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContentItemAction(
    BuildContext context,
    ContentItem item,
  ) async {
    if (item.url.isEmpty) return;

    final serverStatus = ref.read(appSessionProvider).serverStatus;
    final isOffline = serverStatus != MielServerStatus.online;

    if (item.isExternal) {
      if (serverStatus == MielServerStatus.deviceOffline) {
        showMielStatusToast(
          context,
          message: 'Sin conexión a internet: no se puede abrir el enlace externo ahora.',
          isError: true,
        );
        return;
      }
      setState(() => _locallyDownloadedIds.add(item.idElemento));
      await openMielExternalUrl(item.url);
      if (!isOffline) {
        try {
          final reader = await ref.read(mielInteractiveReaderProvider.future);
          await reader.markExternalContentDownloaded(
            item.idComision,
            item.idElemento,
          );
        } catch (_) {}
      }
      return;
    }

    // Integración con Fase 4 (DownloadedResources): si hay copia local en disco y estamos offline, abrirla directo
    final db = ref.read(databaseProvider);
    final localRec = await db.getDownloadedResource(
      idComision: item.idComision,
      module: 'contenidos',
      resourceId: item.idElemento,
    );
    final hasLocalFile =
        localRec != null &&
        localRec.localPath.isNotEmpty &&
        File(localRec.localPath).existsSync();

    if (isOffline) {
      if (hasLocalFile) {
        final opened = await ref
            .read(fileDownloadServiceProvider)
            .openDownloadedFile(localRec.localPath);
        if (context.mounted) {
          showMielStatusToast(
            context,
            message: opened
                ? 'Abriendo copia local: ${localRec.title}'
                : 'No se pudo abrir el archivo local (${localRec.localPath}).',
            isError: !opened,
          );
        }
      } else if (context.mounted) {
        showMielStatusToast(
          context,
          message: 'Este archivo no fue descargado previamente y requiere que MIeL vuelva a estar en línea.',
          isError: true,
        );
      }
      return;
    }

    if (!context.mounted) return;
    await triggerMielFileDownload(
      context,
      ref,
      url: item.url,
      fallbackFileName: item.title,
      onDownloaded: () {
        if (mounted) {
          setState(() => _locallyDownloadedIds.add(item.idElemento));
        }
      },
      onDownloadedResult: (result) async {
        try {
          await db.recordDownloadedResource(
            idComision: item.idComision,
            module: 'contenidos',
            resourceId: item.idElemento,
            title: item.title.isNotEmpty ? item.title : result.fileName,
            localPath: result.filePath,
            fileSize: BigInt.from(result.bytesWritten),
          );
        } catch (_) {}
      },
    );
  }
}
