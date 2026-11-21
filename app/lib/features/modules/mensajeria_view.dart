import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/parsers/mensajeria_parser.dart';
import '../../core/parsers/text_normalizer.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/mensajeria_composer.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/miel_rich_text.dart';
import 'widgets/module_state_views.dart';

/// Vista nativa de lectura y escritura del módulo **Mensajería** (`Nuevo mensaje`,
/// `Bandeja de entrada`, `Bandeja de salida`, `Borradores`, `Favoritos`, bandeja
/// unificada, lector `verEntrada` y respuestas) fiel a MIeL (`2025.2.0`).
class MensajeriaView extends ConsumerStatefulWidget {
  const MensajeriaView({
    super.key,
    required this.subject,
    required this.sectionIndex,
    this.sectionResetTick = 0,
  });

  final Subject subject;
  final int sectionIndex;
  final int sectionResetTick;

  @override
  ConsumerState<MensajeriaView> createState() => _MensajeriaViewState();
}

class _MensajeriaViewState extends ConsumerState<MensajeriaView> {
  InboxMessageSummary? _selectedMessage;
  int _currentPage = 1;
  bool _showFilters = false;
  bool _unifiedCrossSubjectMode = false;
  bool _inlineComposeMode = false;
  bool _showReplyPanel = false;
  bool _markingAllRead = false;

  String _filterSenderQuery = '';
  String _filterSubjectQuery = '';
  String _filterReadState = '0'; // 0: Todos, 1: Leídos, 2: No leídos
  String _filterAttachmentState = '0'; // 0: Todos, 1: Sí, 2: No

  final Map<String, bool> _localUnreadOverrides = <String, bool>{};
  final Map<String, bool> _localFavoriteOverrides = <String, bool>{};
  final Set<String> _locallyDeletedDraftKeys = <String>{};

  @override
  void didUpdateWidget(covariant MensajeriaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex ||
        oldWidget.sectionResetTick != widget.sectionResetTick ||
        oldWidget.subject.idComision != widget.subject.idComision) {
      _selectedMessage = null;
      _currentPage = 1;
      _showFilters = false;
      _inlineComposeMode = false;
      _showReplyPanel = false;
      if (widget.sectionIndex != 1) {
        _unifiedCrossSubjectMode = false;
      }
    }
  }

  MensajeriaBoxKind _activeBoxKind() {
    switch (widget.sectionIndex) {
      case 2:
        return MensajeriaBoxKind.salida;
      case 3:
        return MensajeriaBoxKind.borradores;
      case 4:
        return MensajeriaBoxKind.favoritos;
      default:
        return MensajeriaBoxKind.entrada;
    }
  }

  String _boxSlug(MensajeriaBoxKind box) {
    switch (box) {
      case MensajeriaBoxKind.entrada:
        return 'entrada';
      case MensajeriaBoxKind.salida:
        return 'salida';
      case MensajeriaBoxKind.borradores:
        return 'borradores';
      case MensajeriaBoxKind.favoritos:
        return 'favoritos';
    }
  }

  String _boxTitle(MensajeriaBoxKind box) {
    switch (box) {
      case MensajeriaBoxKind.entrada:
        return _unifiedCrossSubjectMode
            ? 'Bandeja de Entrada · Todas las materias'
            : 'Bandeja de Entrada';
      case MensajeriaBoxKind.salida:
        return 'Bandeja de Salida';
      case MensajeriaBoxKind.borradores:
        return 'Borradores';
      case MensajeriaBoxKind.favoritos:
        return 'Favoritos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 740;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: widget.sectionIndex == 0 || _inlineComposeMode
              ? _buildNuevoMensajeSection(context)
              : _selectedMessage != null
              ? _buildMessageDetailView(context, _selectedMessage!, isCompact)
              : _buildMessageBoxSection(context, isCompact),
        );
      },
    );
  }

  // --- Sección 0: Nuevo mensaje (Fase 3 — Compositor nativo) ---

  Widget _buildNuevoMensajeSection(BuildContext context) {
    final composeUrl =
        '$kMielBaseUrl/mensajeria/redactar/comision/${widget.subject.idComision}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Nuevo mensaje',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_inlineComposeMode)
                MielActionButton(
                  label: 'Volver a la bandeja',
                  icon: Icons.arrow_back,
                  onPressed: () => setState(() => _inlineComposeMode = false),
                ),
              MielActionButton(
                label: 'Abrir en MIeL',
                icon: Icons.open_in_new,
                onPressed: () => openMielExternalUrl(composeUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MensajeriaComposePanel(
          subject: widget.subject,
          onSent: () {
            if (_inlineComposeMode && mounted) {
              setState(() => _inlineComposeMode = false);
            }
          },
        ),
      ],
    );
  }

  // --- Bandejas: Entrada, Salida, Borradores, Favoritos ---

  Widget _buildMessageBoxSection(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final box = _activeBoxKind();
    final idComision = widget.subject.idComision;
    final composeUrl = '$kMielBaseUrl/mensajeria/redactar/comision/$idComision';
    final teachers =
        ref.watch(subjectTeachersProvider(idComision)).value ?? const [];
    final teacherNames = teachers.map((t) => t.normalizedName).toSet();

    if (_unifiedCrossSubjectMode && box == MensajeriaBoxKind.entrada) {
      final unifiedAsync = ref.watch(mensajeriaUnifiedInboxProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBoxHeader(
            palette: palette,
            box: box,
            currentPage: 1,
            totalPages: 1,
            composeUrl: composeUrl,
            onRefresh: () => ref.invalidate(mensajeriaUnifiedInboxProvider),
          ),
          if (_showFilters) ...[
            const SizedBox(height: 12),
            _buildFilterPanel(palette, isCompact),
          ],
          const SizedBox(height: 16),
          unifiedAsync.when(
            loading: () => const MielModuleLoadingView(
              message: 'Consultando bandejas de entrada de todas tus materias activas…',
            ),
            error: (err, _) => MielModuleErrorView(
              message: 'No se pudo cargar la bandeja unificada: $err',
              onRetry: () => ref.invalidate(mensajeriaUnifiedInboxProvider),
            ),
            data: (messages) => _buildMessagesTable(
              context,
              palette: palette,
              messages: messages,
              box: box,
              teacherNames: teacherNames,
              isCompact: isCompact,
              showSubjectColumn: true,
            ),
          ),
        ],
      );
    }

    final boxKey = (idComision: idComision, box: box, page: _currentPage);
    final pageAsync = ref.watch(mensajeriaBandejaProvider(boxKey));

    return pageAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBoxHeader(
            palette: palette,
            box: box,
            currentPage: _currentPage,
            totalPages: 1,
            composeUrl: composeUrl,
            onRefresh: () => ref.invalidate(mensajeriaBandejaProvider(boxKey)),
          ),
          const MielModuleLoadingView(message: 'Cargando bandeja de mensajes…'),
        ],
      ),
      error: (err, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBoxHeader(
            palette: palette,
            box: box,
            currentPage: _currentPage,
            totalPages: 1,
            composeUrl: composeUrl,
            onRefresh: () => ref.invalidate(mensajeriaBandejaProvider(boxKey)),
          ),
          const SizedBox(height: 16),
          MielModuleErrorView(
            message: 'No se pudo cargar la bandeja de mensajes: $err',
            mielWebUrl: '$kMielBaseUrl/mensajeria/entrada/comision/$idComision',
            onRetry: () => ref.invalidate(mensajeriaBandejaProvider(boxKey)),
          ),
        ],
      ),
      data: (pageData) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBoxHeader(
            palette: palette,
            box: box,
            currentPage: pageData.currentPage,
            totalPages: pageData.totalPages,
            composeUrl: composeUrl,
            onRefresh: () => ref.invalidate(mensajeriaBandejaProvider(boxKey)),
          ),
          if (_showFilters) ...[
            const SizedBox(height: 12),
            _buildFilterPanel(palette, isCompact),
          ],
          const SizedBox(height: 16),
          _buildMessagesTable(
            context,
            palette: palette,
            messages: pageData.messages,
            box: box,
            teacherNames: teacherNames,
            isCompact: isCompact,
            showSubjectColumn: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBoxHeader({
    required MielPalette palette,
    required MensajeriaBoxKind box,
    required int currentPage,
    required int totalPages,
    required String composeUrl,
    required VoidCallback onRefresh,
  }) {
    return MielModuleHeader(
      title: _boxTitle(box),
      badgeCount: box == MensajeriaBoxKind.entrada && !_unifiedCrossSubjectMode
          ? widget.subject.lastMensajesBadge
          : 0,
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!_unifiedCrossSubjectMode) ...[
            Text(
              'Página $currentPage de $totalPages',
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            if (totalPages > 1) ...[
              IconButton(
                tooltip: 'Página anterior',
                onPressed: currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ],
          if (box == MensajeriaBoxKind.entrada &&
              !_unifiedCrossSubjectMode &&
              widget.subject.lastMensajesBadge > 0)
            MielActionButton(
              label: _markingAllRead ? 'Marcando…' : 'Marcar todos leídos',
              icon: Icons.done_all,
              onPressed: _markingAllRead
                  ? null
                  : () => _handleMarkAllRead(onRefresh),
            ),
          if (box == MensajeriaBoxKind.entrada)
            MielActionButton(
              label: _unifiedCrossSubjectMode
                  ? 'Solo esta materia'
                  : 'Todas las materias',
              icon: _unifiedCrossSubjectMode ? Icons.filter_1 : Icons.all_inbox,
              onPressed: () => setState(
                () => _unifiedCrossSubjectMode = !_unifiedCrossSubjectMode,
              ),
            ),
          MielActionButton(
            label: 'Filtrar',
            icon: Icons.search,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          MielActionButton(
            label: 'Redactar',
            icon: Icons.mode_edit,
            primary: true,
            onPressed: () => setState(() => _inlineComposeMode = true),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkAllRead(VoidCallback onRefresh) async {
    setState(() => _markingAllRead = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (writer) => writer.markAllMensajeriaRead(widget.subject.idComision),
      );
      await ref
          .read(databaseProvider)
          .decrementMensajesBadge(
            widget.subject.idComision,
            delta: widget.subject.lastMensajesBadge > 0
                ? widget.subject.lastMensajesBadge
                : 999,
          );
      if (!mounted) return;
      setState(() => _markingAllRead = false);
      onRefresh();
      showMielStatusToast(
        context,
        message: 'Todos los mensajes fueron marcados como leídos.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingAllRead = false);
      showMielStatusToast(
        context,
        message: 'No se pudo marcar todos como leídos: $e',
        isError: true,
      );
    }
  }

  Future<void> _toggleFavorite(InboxMessageSummary msg, bool currentFav) async {
    final msgKey = '${msg.idComision}:${msg.idMensaje}';
    final newFav = !currentFav;
    setState(() => _localFavoriteOverrides[msgKey] = newFav);

    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.toggleMensajeriaFavorite(
          idComision: msg.idComision,
          idMensaje: msg.idMensaje,
          currentlyFavorite: currentFav,
          buzonActual: _boxSlug(_activeBoxKind()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _localFavoriteOverrides[msgKey] = currentFav);
      showMielStatusToast(
        context,
        message: 'No se pudo actualizar favorito: $e',
        isError: true,
      );
    }
  }

  Future<void> _toggleRead(InboxMessageSummary msg, bool currentUnread) async {
    final msgKey = '${msg.idComision}:${msg.idMensaje}';
    final newUnread = !currentUnread;
    setState(() => _localUnreadOverrides[msgKey] = newUnread);

    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.toggleMensajeriaRead(
          idComision: msg.idComision,
          idMensaje: msg.idMensaje,
          currentlyRead: !currentUnread,
          buzonActual: _boxSlug(_activeBoxKind()),
        ),
      );
      if (currentUnread) {
        await ref
            .read(databaseProvider)
            .decrementMensajesBadge(msg.idComision);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _localUnreadOverrides[msgKey] = currentUnread);
      showMielStatusToast(
        context,
        message: 'No se pudo actualizar estado de lectura: $e',
        isError: true,
      );
    }
  }

  Future<void> _handleDeleteDraft(InboxMessageSummary msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final pal = MielPalette.of(ctx);
        return AlertDialog(
          backgroundColor: pal.cardBackground,
          title: Text(
            'Eliminar borrador',
            style: TextStyle(color: pal.textPrimary),
          ),
          content: Text(
            '¿Seguro que querés eliminar el borrador "${msg.subject}"?',
            style: TextStyle(color: pal.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pal.badgeRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final msgKey = '${msg.idComision}:${msg.idMensaje}';
    setState(() => _locallyDeletedDraftKeys.add(msgKey));

    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.deleteMensajeriaDraft(
          idComision: msg.idComision,
          idMensaje: msg.idMensaje,
        ),
      );
      if (!mounted) return;
      showMielStatusToast(context, message: 'Borrador eliminado.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _locallyDeletedDraftKeys.remove(msgKey));
      showMielStatusToast(
        context,
        message: 'No se pudo eliminar el borrador: $e',
        isError: true,
      );
    }
  }

  Widget _buildFilterPanel(MielPalette palette, bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrar mensajes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: palette.textMuted),
                onPressed: () => setState(() => _showFilters = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterTextField(
                  palette: palette,
                  label: 'Usuario / Remitente:',
                  hint: 'Ej: apellido del docente…',
                  onChanged: (v) => setState(() => _filterSenderQuery = v),
                ),
                const SizedBox(height: 10),
                _buildFilterTextField(
                  palette: palette,
                  label: 'Asunto:',
                  hint: 'Palabra clave en el asunto…',
                  onChanged: (v) => setState(() => _filterSubjectQuery = v),
                ),
                const SizedBox(height: 10),
                _buildReadFilterColumn(palette),
                const SizedBox(height: 10),
                _buildAttachmentFilterColumn(palette),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFilterTextField(
                    palette: palette,
                    label: 'Usuario / Remitente:',
                    hint: 'Ej: apellido del docente…',
                    onChanged: (v) => setState(() => _filterSenderQuery = v),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 4,
                  child: _buildFilterTextField(
                    palette: palette,
                    label: 'Asunto:',
                    hint: 'Palabra clave en el asunto…',
                    onChanged: (v) => setState(() => _filterSubjectQuery = v),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(width: 170, child: _buildReadFilterColumn(palette)),
                const SizedBox(width: 14),
                SizedBox(
                  width: 170,
                  child: _buildAttachmentFilterColumn(palette),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                MielActionButton(
                  label: 'Limpiar filtros',
                  onPressed: () {
                    setState(() {
                      _filterSenderQuery = '';
                      _filterSubjectQuery = '';
                      _filterReadState = '0';
                      _filterAttachmentState = '0';
                    });
                  },
                ),
                MielActionButton(
                  label: 'Cerrar',
                  icon: Icons.check,
                  primary: true,
                  onPressed: () => setState(() => _showFilters = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField({
    required MielPalette palette,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.inputBackground,
            border: Border.all(color: palette.inputBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12.5, color: palette.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadFilterColumn(MielPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leído:',
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        _buildFilterDropdown(
          palette: palette,
          value: _filterReadState,
          items: const [
            DropdownMenuItem(value: '0', child: Text('-- Todos --')),
            DropdownMenuItem(value: '1', child: Text('Sí (leídos)')),
            DropdownMenuItem(value: '2', child: Text('No (no leídos)')),
          ],
          onChanged: (v) => setState(() => _filterReadState = v),
        ),
      ],
    );
  }

  Widget _buildAttachmentFilterColumn(MielPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archivo adjunto:',
          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        _buildFilterDropdown(
          palette: palette,
          value: _filterAttachmentState,
          items: const [
            DropdownMenuItem(value: '0', child: Text('-- Todos --')),
            DropdownMenuItem(value: '1', child: Text('Sí')),
            DropdownMenuItem(value: '2', child: Text('No')),
          ],
          onChanged: (v) => setState(() => _filterAttachmentState = v),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required MielPalette palette,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.inputBackground,
        border: Border.all(color: palette.inputBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: palette.dropdownBackground,
          style: TextStyle(fontSize: 13, color: palette.textPrimary),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  bool _matchesMessageFilter(InboxMessageSummary msg) {
    final msgKey = '${msg.idComision}:${msg.idMensaje}';
    if (_locallyDeletedDraftKeys.contains(msgKey)) return false;

    final effectiveUnread = _localUnreadOverrides[msgKey] ?? msg.isUnread;

    if (_filterReadState == '1' && effectiveUnread) return false;
    if (_filterReadState == '2' && !effectiveUnread) return false;
    if (_filterAttachmentState == '1' && !msg.hasAttachment) return false;
    if (_filterAttachmentState == '2' && msg.hasAttachment) return false;

    if (_activeBoxKind() == MensajeriaBoxKind.favoritos) {
      final effectiveFav = _localFavoriteOverrides[msgKey] ?? msg.isFavorite;
      if (!effectiveFav) return false;
    }

    final senderQ = normalizeText(_filterSenderQuery);
    if (senderQ.isNotEmpty &&
        !normalizeText(msg.senderName).contains(senderQ)) {
      return false;
    }

    final subjQ = normalizeText(_filterSubjectQuery);
    if (subjQ.isNotEmpty &&
        !normalizeText('${msg.subject} ${msg.subjectNameLabel}')
            .contains(subjQ)) {
      return false;
    }

    return true;
  }

  Widget _buildMessagesTable(
    BuildContext context, {
    required MielPalette palette,
    required List<InboxMessageSummary> messages,
    required MensajeriaBoxKind box,
    required Set<String> teacherNames,
    required bool isCompact,
    required bool showSubjectColumn,
  }) {
    final filtered = messages.where(_matchesMessageFilter).toList();
    if (filtered.isEmpty) {
      final emptyMsg = switch (box) {
        MensajeriaBoxKind.favoritos =>
          'No se encontraron mensajes guardados en favoritos.',
        MensajeriaBoxKind.borradores => 'No tenés borradores guardados.',
        MensajeriaBoxKind.salida =>
          'No hay mensajes enviados en esta comisión.',
        MensajeriaBoxKind.entrada =>
          'No se encontraron mensajes en la bandeja.',
      };
      return MielModuleEmptyView(
        message: emptyMsg,
        icon: box == MensajeriaBoxKind.favoritos
            ? Icons.star_border
            : Icons.inbox_outlined,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final replyPurple = isDark
        ? const Color(0xFFCA84D6)
        : const Color(0xFF9C27B0);
    final starBlue = isDark ? const Color(0xFF72A0C5) : const Color(0xFF2196F3);
    final readGreen = isDark
        ? const Color(0xFF9AC89C)
        : const Color(0xFF4CAF50);

    TextStyle headerStyle() => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCompact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.divider, width: 1.2),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 95, child: Text('Fecha', style: headerStyle())),
                SizedBox(
                  width: 220,
                  child: Text(
                    box == MensajeriaBoxKind.salida
                        ? 'Destinatario'
                        : 'Remitente',
                    style: headerStyle(),
                  ),
                ),
                const SizedBox(width: 34),
                Expanded(child: Text('Asunto', style: headerStyle())),
                const SizedBox(width: 90),
                SizedBox(width: 95, child: Text('Leído', style: headerStyle())),
              ],
            ),
          ),
        for (final msg in filtered)
          _buildMessageRow(
            context,
            palette: palette,
            msg: msg,
            box: box,
            isTeacherSender: isSenderTeacher(msg.senderName, teacherNames),
            isCompact: isCompact,
            showSubjectColumn: showSubjectColumn,
            replyPurple: replyPurple,
            starBlue: starBlue,
            readGreen: readGreen,
          ),
      ],
    );
  }

  Widget _buildMessageRow(
    BuildContext context, {
    required MielPalette palette,
    required InboxMessageSummary msg,
    required MensajeriaBoxKind box,
    required bool isTeacherSender,
    required bool isCompact,
    required bool showSubjectColumn,
    required Color replyPurple,
    required Color starBlue,
    required Color readGreen,
  }) {
    final msgKey = '${msg.idComision}:${msg.idMensaje}';
    final isUnread = _localUnreadOverrides[msgKey] ?? msg.isUnread;
    final isFavorite = _localFavoriteOverrides[msgKey] ?? msg.isFavorite;
    final weight = isUnread ? FontWeight.w700 : FontWeight.w400;

    void openMessage() {
      setState(() {
        _localUnreadOverrides[msgKey] = false;
        _selectedMessage = msg;
      });
    }

    return MielHoverRow(
      backgroundColor: isUnread ? palette.unreadBackground : Colors.transparent,
      border: Border(
        left: isUnread
            ? BorderSide(color: palette.unreadBorder, width: 4)
            : BorderSide.none,
        bottom: BorderSide(color: palette.divider),
      ),
      child: isCompact
          ? _buildCompactRowContent(
              palette: palette,
              msg: msg,
              box: box,
              isUnread: isUnread,
              isFavorite: isFavorite,
              isTeacherSender: isTeacherSender,
              showSubjectColumn: showSubjectColumn,
              replyPurple: replyPurple,
              starBlue: starBlue,
              onOpen: openMessage,
            )
          : Row(
              children: [
                SizedBox(
                  width: 95,
                  child: Text(
                    msg.date,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: weight,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          msg.senderName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: weight,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      if (isTeacherSender) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Tutor/a de la comisión',
                          child: Icon(
                            Icons.school,
                            size: 15,
                            color: palette.linkAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: msg.hasAttachment
                      ? Tooltip(
                          message: 'Contiene archivo adjunto',
                          child: Icon(
                            Icons.attach_file,
                            size: 19,
                            color: palette.textMuted,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (showSubjectColumn &&
                          msg.subjectNameLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Text(
                            msg.subjectNameLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: MielHoverLink(
                          text: msg.subject,
                          onTap: openMessage,
                          fontSize: 13,
                          fontWeight: weight,
                          color: isUnread
                              ? palette.linkAccent
                              : palette.textPrimary,
                          hoverColor: palette.linkAccent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (msg.isReplied)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Tooltip(
                            message: 'Respondido',
                            child: Icon(
                              Icons.reply,
                              size: 19,
                              color: replyPurple,
                            ),
                          ),
                        ),
                      if (box == MensajeriaBoxKind.salida)
                        if (msg.readByRecipient)
                          Tooltip(
                            message: 'Leído por el destinatario',
                            child: Icon(Icons.done, size: 19, color: readGreen),
                          )
                        else
                          const SizedBox.shrink()
                      else if (box == MensajeriaBoxKind.borradores) ...[
                        Tooltip(
                          message: 'Eliminar borrador',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _handleDeleteDraft(msg),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 19,
                                color: palette.badgeRed,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Tooltip(
                          message: isFavorite
                              ? 'Quitar de favoritos'
                              : 'Marcar como favorito',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _toggleFavorite(msg, isFavorite),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                size: 19,
                                color: isFavorite ? starBlue : palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: isUnread
                              ? 'Marcar como leído'
                              : 'Marcar como no leído',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _toggleRead(msg, isUnread),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isUnread ? Icons.markunread : Icons.drafts,
                                size: 19,
                                color: isUnread
                                    ? palette.textPrimary
                                    : palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 95,
                  child: Text(
                    isUnread ? '' : msg.readDate,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompactRowContent({
    required MielPalette palette,
    required InboxMessageSummary msg,
    required MensajeriaBoxKind box,
    required bool isUnread,
    required bool isFavorite,
    required bool isTeacherSender,
    required bool showSubjectColumn,
    required Color replyPurple,
    required Color starBlue,
    required VoidCallback onOpen,
  }) {
    final weight = isUnread ? FontWeight.w700 : FontWeight.w400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                msg.senderName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: weight,
                  color: palette.textSecondary,
                ),
              ),
            ),
            if (isTeacherSender)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.school, size: 14, color: palette.linkAccent),
              ),
            Text(
              msg.date,
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            if (msg.hasAttachment)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.attach_file,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            Expanded(
              child: MielHoverLink(
                text: showSubjectColumn && msg.subjectNameLabel.isNotEmpty
                    ? '[${msg.subjectNameLabel}] ${msg.subject}'
                    : msg.subject,
                onTap: onOpen,
                fontSize: 13.5,
                fontWeight: weight,
                color: isUnread ? palette.linkAccent : palette.textPrimary,
                hoverColor: palette.linkAccent,
              ),
            ),
            if (msg.isReplied) Icon(Icons.reply, size: 17, color: replyPurple),
            if (box == MensajeriaBoxKind.borradores)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleDeleteDraft(msg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    Icons.delete_outline,
                    size: 17,
                    color: palette.badgeRed,
                  ),
                ),
              )
            else if (box != MensajeriaBoxKind.salida) ...[
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleFavorite(msg, isFavorite),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    size: 17,
                    color: isFavorite ? starBlue : palette.textMuted,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleRead(msg, isUnread),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    isUnread ? Icons.markunread : Icons.drafts,
                    size: 17,
                    color: isUnread ? palette.textPrimary : palette.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- Lector de detalle de mensaje: verEntrada / verSalida (03_mensajeria_ver_dark.png) ---

  Widget _buildMessageDetailView(
    BuildContext context,
    InboxMessageSummary summary,
    bool isCompact,
  ) {
    final palette = MielPalette.of(context);
    final detailAsync = ref.watch(
      mensajeriaDetalleProvider((
        idComision: summary.idComision,
        idMensaje: summary.idMensaje,
        detailUrl: summary.detailUrl,
        wasUnread: summary.isUnread,
      )),
    );
    final webUrl = summary.detailUrl.isNotEmpty
        ? summary.detailUrl
        : '$kMielBaseUrl/mensajeria/verEntrada/comision/${summary.idComision}/pag/1/from/entrada/id/${summary.idMensaje}';

    return detailAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MielModuleHeader(
            title: summary.subject,
            trailing: MielActionButton(
              label: 'Volver',
              primary: true,
              onPressed: () => setState(() => _selectedMessage = null),
            ),
          ),
          const MielModuleLoadingView(message: 'Abriendo mensaje…'),
        ],
      ),
      error: (err, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MielModuleHeader(
            title: summary.subject,
            trailing: MielActionButton(
              label: 'Volver',
              primary: true,
              onPressed: () => setState(() => _selectedMessage = null),
            ),
          ),
          const SizedBox(height: 16),
          MielModuleErrorView(
            message: 'No se pudo cargar el contenido del mensaje: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(
              mensajeriaDetalleProvider((
                idComision: summary.idComision,
                idMensaje: summary.idMensaje,
                detailUrl: summary.detailUrl,
                wasUnread: false,
              )),
            ),
          ),
        ],
      ),
      data: (detail) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MielModuleHeader(
            title: detail.subject,
            trailing: MielActionButton(
              label: 'Volver',
              primary: true,
              onPressed: () => setState(() => _selectedMessage = null),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCompact) ...[
                MielAvatar(
                  avatarUrl: detail.senderAvatarUrl,
                  radius: 25,
                  fallbackBackgroundColor: const Color(0xFF4F90C4),
                  fallbackIconSize: 28,
                ),
                const SizedBox(width: 15),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // De: NOMBRE · Tutor/a
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'De: ${detail.senderName}',
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (detail.senderRole.isNotEmpty)
                          Text(
                            ' · ${detail.senderRole}',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Para: N personas •••
                    if (detail.recipientsSummary.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              detail.recipientsSummary,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                          if (detail.recipientsPopupUrl.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Ver destinatarios',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _openRecipientsDialog(
                                    context,
                                    palette,
                                    detail.recipientsPopupUrl,
                                  ),
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
                        ],
                      ),

                    // Fecha y hora
                    if (detail.dateTime.isNotEmpty)
                      Text(
                        detail.dateTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Cuerpo del mensaje (div.w3-section.contrastify)
                    MielRichText(
                      htmlContent: detail.bodyHtml,
                      fallbackPlainText: detail.bodyPlainText,
                    ),

                    // Archivos adjuntos
                    if (detail.attachments.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final att in detail.attachments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              MielFileTypeIcon(
                                fileType: att.fileType,
                                size: 22,
                              ),
                              Text(
                                'Descargar archivo:',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                              MielHoverLink(
                                text: att.fileName,
                                fontSize: 13.5,
                                onTap: () => triggerMielFileDownload(
                                  context,
                                  ref,
                                  url: att.downloadUrl,
                                  fallbackFileName: att.fileName,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],

                    const SizedBox(height: 22),

                    if (_showReplyPanel) ...[
                      const SizedBox(height: 20),
                      MensajeriaReplyPanel(
                        detail: detail,
                        onReplied: () {
                          if (mounted) {
                            setState(() => _showReplyPanel = false);
                          }
                        },
                        onCancel: () {
                          if (mounted) {
                            setState(() => _showReplyPanel = false);
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 22),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MielActionButton(
                          label: _showReplyPanel
                              ? 'Ocultar respuesta'
                              : 'Responder',
                          icon: Icons.reply,
                          primary: true,
                          onPressed: () => setState(
                            () => _showReplyPanel = !_showReplyPanel,
                          ),
                        ),
                        MielActionButton(
                          label: 'Abrir en MIeL',
                          icon: Icons.open_in_new,
                          onPressed: () => openMielExternalUrl(webUrl),
                        ),
                        MielActionButton(
                          label: 'Reenviar en MIeL',
                          icon: Icons.forward,
                          onPressed: () => openMielExternalUrl(
                            '$kMielBaseUrl/mensajeria/redactar/comision/${detail.idComision}/recibido/${detail.idMensaje}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRecipientsDialog(
    BuildContext context,
    MielPalette palette,
    String popupUrl,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Consumer(
        builder: (context, ref, _) {
          final recAsync = ref.watch(mensajeriaDestinatariosProvider(popupUrl));
          return Dialog(
            backgroundColor: palette.cardBackground,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Destinatarios del mensaje',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: recAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No se pudieron cargar destinatarios: $err',
                        ),
                      ),
                      data: (recipients) {
                        if (recipients.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No se especificaron destinatarios.'),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(14),
                          itemCount: recipients.length,
                          separatorBuilder: (_, _) =>
                              Divider(color: palette.divider, height: 1),
                          itemBuilder: (_, idx) {
                            final r = recipients[idx];
                            final isTutor =
                                r.roleType == 'tutor' ||
                                r.roleType == 'tutores';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    isTutor ? Icons.school : Icons.person,
                                    size: 18,
                                    color: isTutor
                                        ? const Color(0xFFEBB850)
                                        : palette.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      r.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
