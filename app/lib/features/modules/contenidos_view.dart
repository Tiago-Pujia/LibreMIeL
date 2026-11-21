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

/// Vista nativa de lectura del módulo **Contenidos** (`Archivos`, `Glosario` y `Preguntas frecuentes`)
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

  String? _selectedGlossaryLetter;
  String _glossaryQuery = '';
  String _faqQuery = '';

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
          child: switch (widget.sectionIndex) {
            1 => _buildGlosarioSection(context, isCompact),
            2 => _buildFaqSection(context, isCompact),
            _ => _buildArchivosSection(context, isCompact),
          },
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
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: 'Actualizar',
                icon: Icons.refresh,
                onPressed: () =>
                    ref.invalidate(contenidosPageProvider(idComision)),
              ),
              MielActionButton(
                label: 'Abrir en MIeL',
                icon: Icons.open_in_new,
                onPressed: () => openMielExternalUrl(webUrl),
              ),
            ],
          ),
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
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 250,
          child: Column(
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
          ),
        ),
        SizedBox(
          width: isCompact ? double.infinity : 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Palabra clave:',
                style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: palette.inputBackground,
                          hintText: 'Filtrar por título, módulo o descripción…',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: palette.textMuted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: palette.inputBorder),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: palette.primary),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: const Color(0xFF616161),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2),
                    ),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _searchQuery = _searchController.text),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(2),
                      ),
                      child: const SizedBox(
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16, color: Colors.white),
                              SizedBox(width: 5),
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleContentItemAction(context, item),
          hoverColor: palette.cardHover.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_expandedDescriptions.contains(
                                      item.idElemento,
                                    )) {
                                      _expandedDescriptions.remove(
                                        item.idElemento,
                                      );
                                    } else {
                                      _expandedDescriptions.add(
                                        item.idElemento,
                                      );
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(3),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.uploadDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Text(
                      item.sizeLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContentItemAction(
    BuildContext context,
    ContentItem item,
  ) async {
    if (item.url.isEmpty) return;

    if (item.isExternal) {
      setState(() => _locallyDownloadedIds.add(item.idElemento));
      await openMielExternalUrl(item.url);
      try {
        final reader = await ref.read(mielInteractiveReaderProvider.future);
        await reader.markExternalContentDownloaded(
          item.idComision,
          item.idElemento,
        );
      } catch (_) {}
      return;
    }

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
    );
  }

  Widget _buildGlosarioSection(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/contenido/glosario/comision/$idComision';
    final glosarioAsync = ref.watch(
      contenidosGlosarioProvider((
        idComision: idComision,
        letra: _selectedGlossaryLetter,
      )),
    );

    const letters = [
      'Todos',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'Ñ',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '#',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Glosario',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: TextField(
            onChanged: (v) => setState(() => _glossaryQuery = v),
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.inputBackground,
              hintText: 'Buscar término en el glosario…',
              hintStyle: TextStyle(fontSize: 13, color: palette.textMuted),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: palette.textMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.inputBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.primary),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        glosarioAsync.when(
          loading: () =>
              const MielModuleLoadingView(message: 'Consultando glosario…'),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudo cargar el glosario: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(
              contenidosGlosarioProvider((
                idComision: idComision,
                letra: _selectedGlossaryLetter,
              )),
            ),
          ),
          data: (data) {
            final q = normalizeText(_glossaryQuery);
            final entries = data.entries.where((e) {
              if (q.isEmpty) return true;
              return normalizeText('${e.term} ${e.definition}').contains(q);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final letter in letters)
                      _buildLetterButton(
                        palette,
                        letter: letter,
                        isSelected:
                            (_selectedGlossaryLetter ?? 'Todos') == letter,
                        isEnabled:
                            letter == 'Todos' ||
                            data.enabledLetters.isEmpty ||
                            data.enabledLetters.contains(letter),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const MielModuleEmptyView(
                    message: 'No se encontraron términos.',
                    icon: Icons.import_contacts,
                  )
                else
                  for (final entry in entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.term,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: palette.linkAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.definition,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLetterButton(
    MielPalette palette, {
    required String letter,
    required bool isSelected,
    required bool isEnabled,
  }) {
    final bg = isSelected ? palette.primary : palette.buttonSecondaryBackground;
    final fg = isSelected
        ? Colors.white
        : (isEnabled ? palette.textPrimary : palette.textMuted);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: isEnabled
              ? () => setState(
                  () => _selectedGlossaryLetter = letter == 'Todos'
                      ? null
                      : letter,
                )
              : null,
          borderRadius: BorderRadius.circular(2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/contenido/faq/comision/$idComision';
    final faqAsync = ref.watch(contenidosFaqProvider(idComision));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Preguntas frecuentes',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: TextField(
            onChanged: (v) => setState(() => _faqQuery = v),
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.inputBackground,
              hintText: 'Buscar en preguntas frecuentes…',
              hintStyle: TextStyle(fontSize: 13, color: palette.textMuted),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: palette.textMuted,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.inputBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: palette.primary),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        faqAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando preguntas frecuentes…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar las preguntas frecuentes: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(contenidosFaqProvider(idComision)),
          ),
          data: (items) {
            final q = normalizeText(_faqQuery);
            final filtered = items.where((f) {
              if (q.isEmpty) return true;
              return normalizeText('${f.question} ${f.answer}').contains(q);
            }).toList();

            if (filtered.isEmpty) {
              return const MielModuleEmptyView(
                message: 'No se encontraron preguntas frecuentes.',
                icon: Icons.help_outline,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final faq in filtered)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.cardBackground,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq.question,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          faq.answer,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
