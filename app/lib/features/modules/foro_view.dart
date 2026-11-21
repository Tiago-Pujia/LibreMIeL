import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';
import '../../core/parsers/text_normalizer.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/miel_rich_text.dart';
import 'widgets/module_state_views.dart';

/// Vista nativa de lectura del módulo **Foros (`forov2`)** (`Temas abiertos` y lector
/// completo de hilos con respuestas anidadas, colapsado de comentarios anteriores,
/// `@menciones` interactivas, imágenes autenticadas con zoom y descarga de adjuntos)
/// fiel a MIeL (`2025.2.0`).
class ForoView extends ConsumerStatefulWidget {
  const ForoView({
    super.key,
    required this.subject,
    required this.selectedTopicId,
    required this.onSelectTopic,
  });

  final Subject subject;
  final String? selectedTopicId;
  final ValueChanged<String?> onSelectTopic;

  @override
  ConsumerState<ForoView> createState() => _ForoViewState();
}

class _ForoViewState extends ConsumerState<ForoView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _threadSearchQuery = '';
  bool _reverseOrder = false;
  final Set<String> _expandedThreadRootIds = <String>{};
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  final Map<String, int> _topicUnreadBadges = <String, int>{};
  final Set<String> _locallyReadTopicIds = <String>{};

  String? _flashedMessageId;
  Timer? _flashTimer;

  @override
  void didUpdateWidget(covariant ForoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTopicId != widget.selectedTopicId ||
        oldWidget.subject.idComision != widget.subject.idComision) {
      _threadSearchQuery = '';
      _searchController.clear();
      _reverseOrder = false;
      _expandedThreadRootIds.clear();
      _messageKeys.clear();
      _flashedMessageId = null;
      if (widget.selectedTopicId != null) {
        _locallyReadTopicIds.add(widget.selectedTopicId!);
      }
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  GlobalKey _keyForMessage(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToAndFlashMessage(String targetMessageId, String rootId) {
    if (!_expandedThreadRootIds.contains(rootId)) {
      setState(() => _expandedThreadRootIds.add(rootId));
    }
    setState(() => _flashedMessageId = targetMessageId);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _flashedMessageId = null);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _messageKeys[targetMessageId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 36),
          child: widget.selectedTopicId == null
              ? _buildTemasAbiertosList(context, isCompact)
              : _buildThreadView(context, widget.selectedTopicId!, isCompact),
        );
      },
    );
  }

  // --- Vista 1: Temas abiertos (/forov2/temas/comision/{id}) ---

  Widget _buildTemasAbiertosList(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/forov2/temas/comision/$idComision';
    final temasAsync = ref.watch(foroTemasProvider(idComision));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final publicIndigo = isDark
        ? const Color(0xFF7887D6)
        : const Color(0xFF3F51B5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Temas abiertos',
          badgeCount: widget.subject.lastForoBadge,
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: 'Actualizar',
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(foroTemasProvider(idComision)),
              ),
              MielActionButton(
                label: 'Abrir en MIeL',
                icon: Icons.open_in_new,
                onPressed: () => openMielExternalUrl(webUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        temasAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando temas del foro…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar los temas del foro: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(foroTemasProvider(idComision)),
          ),
          data: (topics) {
            if (topics.isEmpty) {
              return const MielModuleEmptyView(
                message: 'No hay temas abiertos en el foro de esta comisión.',
                icon: Icons.forum_outlined,
              );
            }

            for (final t in topics) {
              _topicUnreadBadges[t.idTema] = t.unreadBadge;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final topic in topics)
                  _buildTopicRow(
                    palette: palette,
                    topic: topic,
                    publicIndigo: publicIndigo,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopicRow({
    required MielPalette palette,
    required ForumTopicSummary topic,
    required Color publicIndigo,
  }) {
    final effectiveUnread = _locallyReadTopicIds.contains(topic.idTema)
        ? 0
        : topic.unreadBadge;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _locallyReadTopicIds.add(topic.idTema);
            widget.onSelectTopic(topic.idTema);
          },
          hoverColor: palette.cardHover.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        topic.isClosed
                            ? Icons.speaker_notes_off
                            : Icons.message,
                        size: 33,
                        color: topic.isClosed
                            ? palette.textMuted
                            : palette.textSecondary,
                      ),
                      if (effectiveUnread > 0)
                        Positioned(
                          top: 18,
                          left: 22,
                          child: MielRedBadge(
                            count: effectiveUnread,
                            backgroundColor: palette.badgeRed,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (topic.description.isNotEmpty || topic.isPublic) ...[
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: palette.textPrimary,
                            ),
                            children: [
                              if (topic.isPublic) ...[
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.group,
                                      size: 16,
                                      color: publicIndigo,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Tema público - ',
                                  style: TextStyle(
                                    color: publicIndigo,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              TextSpan(text: topic.description),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        topic.lastMessageDate.isNotEmpty
                            ? '${topic.messageCount} ${topic.messageCount == 1 ? "mensaje" : "mensajes"} · Último mensaje ${topic.lastMessageDate}'
                            : '${topic.messageCount} mensajes',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Vista 2: Hilo completo (/forov2/mensajes/comision/{id}/tema/{idTema}) ---

  Widget _buildThreadView(BuildContext context, String idTema, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl =
        '$kMielBaseUrl/forov2/mensajes/comision/$idComision/tema/$idTema';
    final unreadForTopic = _topicUnreadBadges[idTema] ?? 0;

    final threadAsync = ref.watch(
      foroMensajesProvider((
        idComision: idComision,
        idTema: idTema,
        unreadBadge: unreadForTopic,
      )),
    );

    return threadAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MielModuleHeader(
            title: 'Tema #$idTema',
            trailing: MielActionButton(
              label: 'Volver',
              onPressed: () => widget.onSelectTopic(null),
            ),
          ),
          const MielModuleLoadingView(message: 'Cargando mensajes del tema…'),
        ],
      ),
      error: (err, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MielModuleHeader(
            title: 'Tema #$idTema',
            trailing: MielActionButton(
              label: 'Volver',
              onPressed: () => widget.onSelectTopic(null),
            ),
          ),
          const SizedBox(height: 16),
          MielModuleErrorView(
            message: 'No se pudo cargar el hilo del foro: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(
              foroMensajesProvider((
                idComision: idComision,
                idTema: idTema,
                unreadBadge: 0,
              )),
            ),
          ),
        ],
      ),
      data: (thread) => _buildThreadContent(
        context,
        palette: palette,
        thread: thread,
        webUrl: webUrl,
        isCompact: isCompact,
      ),
    );
  }

  Widget _buildThreadContent(
    BuildContext context, {
    required MielPalette palette,
    required ForumThreadData thread,
    required String webUrl,
    required bool isCompact,
  }) {
    final threadGroups = _groupMessagesIntoThreads(thread.messages);
    final q = normalizeText(_threadSearchQuery);

    final visibleGroups = threadGroups.where((g) {
      if (q.isEmpty) return true;
      for (final m in g.allMessages) {
        if (normalizeText('${m.authorName} ${m.bodyText}').contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();

    final orderedGroups = _reverseOrder
        ? visibleGroups.reversed.toList()
        : visibleGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera: Tema: {Título} + Volver | Ir al final | Nuevo mensaje
        MielModuleHeader(
          title: 'Tema: ${thread.title}',
          trailing: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              MielActionButton(
                label: 'Volver',
                onPressed: () => widget.onSelectTopic(null),
              ),
              MielActionButton(
                label: 'Ir al final',
                icon: Icons.arrow_downward,
                onPressed: _scrollToBottom,
              ),
              MielActionButton(
                label: 'Nuevo mensaje',
                icon: Icons.edit,
                primary: true,
                onPressed: () => openMielExternalUrl(webUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Descripción a la izquierda + Último mensaje / N Mensajes a la derecha
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                thread.description,
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (thread.lastMessageDate.isNotEmpty)
                  Text(
                    'Último mensaje ${thread.lastMessageDate}',
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                Text(
                  '${thread.totalMessagesCount} ${thread.totalMessagesCount == 1 ? "Mensaje" : "Mensajes"}',
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Barra de búsqueda local (#textoBuscar) + botón Invertir orden (#btnOrdenarPorFecha)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: isCompact ? double.infinity : 540,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _threadSearchQuery = v),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: palette.inputBackground,
                          hintText: 'Ingrese el texto buscado...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          suffixIcon: _threadSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: palette.textMuted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _threadSearchQuery = '');
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
                      onTap: () => setState(
                        () => _threadSearchQuery = _searchController.text,
                      ),
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
            ),
            MielActionButton(
              label: 'Invertir orden',
              icon: Icons.import_export,
              onPressed: () => setState(() => _reverseOrder = !_reverseOrder),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (orderedGroups.isEmpty)
          MielModuleEmptyView(
            message: _threadSearchQuery.trim().isNotEmpty
                ? 'Ningún mensaje del tema coincide con "$_threadSearchQuery".'
                : 'Aún no hay mensajes publicados en este tema.',
            icon: Icons.chat_bubble_outline,
          )
        else
          for (final group in orderedGroups)
            _buildThreadGroupWidget(
              context,
              palette: palette,
              group: group,
              webUrl: webUrl,
              isCompact: isCompact,
            ),
      ],
    );
  }

  List<_ForumThreadGroup> _groupMessagesIntoThreads(
    List<ForumMessageItem> messages,
  ) {
    final groups = <_ForumThreadGroup>[];
    final byParent = <String, _ForumThreadGroup>{};

    for (final msg in messages) {
      if (!msg.isReply || !byParent.containsKey(msg.parentId)) {
        final existing = byParent[msg.parentId];
        if (existing != null && msg.isReply) {
          existing.replies.add(msg);
        } else {
          final g = _ForumThreadGroup(root: msg, replies: <ForumMessageItem>[]);
          groups.add(g);
          byParent[msg.id] = g;
          if (msg.parentId.isNotEmpty) {
            byParent.putIfAbsent(msg.parentId, () => g);
          }
        }
      } else {
        byParent[msg.parentId]!.replies.add(msg);
      }
    }
    return groups;
  }

  Widget _buildThreadGroupWidget(
    BuildContext context, {
    required MielPalette palette,
    required _ForumThreadGroup group,
    required String webUrl,
    required bool isCompact,
  }) {
    final rootId = group.root.id;
    final totalReplies = group.replies.length;
    final hasSearch = _threadSearchQuery.trim().isNotEmpty;
    // Regla oficial de verMasComentarios.js: deja visibles las últimas 3 respuestas
    final canCollapse = totalReplies > 3 && !hasSearch;
    final isExpanded = !canCollapse || _expandedThreadRootIds.contains(rootId);
    final hiddenCount = canCollapse ? totalReplies - 3 : 0;
    final visibleReplies = isExpanded
        ? group.replies
        : group.replies.sublist(totalReplies - 3);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // Mensaje raíz (li.foro-mensaje.w3-leftbar.w3-border-theme: borde izquierdo 4px)
          _buildSingleForumMessage(
            context,
            palette: palette,
            message: group.root,
            rootId: rootId,
            webUrl: webUrl,
            isCompact: isCompact,
            isReply: false,
          ),

          // Barra li.li-ver-mas ("Ver comentarios anteriores (N)" / "Ocultar comentarios anteriores")
          if (canCollapse)
            Padding(
              padding: EdgeInsets.only(
                left: isCompact ? 18 : 60,
                top: 8,
                bottom: 4,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  border: Border(
                    left: BorderSide(color: palette.primary, width: 4),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_expandedThreadRootIds.contains(rootId)) {
                          _expandedThreadRootIds.remove(rootId);
                        } else {
                          _expandedThreadRootIds.add(rootId);
                        }
                      });
                    },
                    hoverColor: palette.cardHover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isExpanded ? Icons.unfold_less : Icons.unfold_more,
                            size: 18,
                            color: palette.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpanded
                                ? 'Ocultar comentarios anteriores'
                                : 'Ver comentarios anteriores ($hiddenCount)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Respuestas anidadas (li.foro-respuesta.w3-border-left.w3-border-theme)
          for (final reply in visibleReplies)
            Padding(
              padding: EdgeInsets.only(left: isCompact ? 18 : 60, top: 6),
              child: _buildSingleForumMessage(
                context,
                palette: palette,
                message: reply,
                rootId: rootId,
                webUrl: webUrl,
                isCompact: isCompact,
                isReply: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleForumMessage(
    BuildContext context, {
    required MielPalette palette,
    required ForumMessageItem message,
    required String rootId,
    required String webUrl,
    required bool isCompact,
    required bool isReply,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tutorOrange = isDark
        ? const Color(0xFFEBB850)
        : const Color(0xFFFF9800);
    final isFlashed = _flashedMessageId == message.id;

    return AnimatedContainer(
      key: _keyForMessage(message.id),
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isFlashed ? palette.paleYellowBackground : Colors.transparent,
        border: Border(
          left: BorderSide(color: palette.primary, width: isReply ? 1.5 : 4.0),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorMetadataBlock(
                  palette: palette,
                  message: message,
                  tutorOrange: tutorOrange,
                  isReply: isReply,
                  showAvatar: true,
                ),
                const SizedBox(height: 10),
                _buildMessageBodyBlock(
                  context,
                  palette: palette,
                  message: message,
                  rootId: rootId,
                  webUrl: webUrl,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isReply ? 20 : 24,
                  backgroundColor: message.isTeacher
                      ? const Color(0xFF4F90C4)
                      : palette.textMuted.withValues(alpha: 0.45),
                  child: Icon(
                    Icons.person,
                    size: isReply ? 22 : 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 225,
                  child: _buildAuthorMetadataBlock(
                    palette: palette,
                    message: message,
                    tutorOrange: tutorOrange,
                    isReply: isReply,
                    showAvatar: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMessageBodyBlock(
                    context,
                    palette: palette,
                    message: message,
                    rootId: rootId,
                    webUrl: webUrl,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAuthorMetadataBlock({
    required MielPalette palette,
    required ForumMessageItem message,
    required Color tutorOrange,
    required bool isReply,
    required bool showAvatar,
  }) {
    final metadataColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.authorName,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        if (message.role.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isTeacher) ...[
                Icon(Icons.school, size: 17, color: tutorOrange),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  message.role,
                  style: TextStyle(fontSize: 12.5, color: palette.textMuted),
                ),
              ),
            ],
          ),
        ],
        if (message.date.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Enviado el ${message.date}',
            style: TextStyle(fontSize: 12.5, color: palette.textMuted),
          ),
        ],
      ],
    );

    if (!showAvatar) return metadataColumn;

    return Row(
      children: [
        CircleAvatar(
          radius: isReply ? 18 : 20,
          backgroundColor: message.isTeacher
              ? const Color(0xFF4F90C4)
              : palette.textMuted.withValues(alpha: 0.45),
          child: const Icon(Icons.person, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(child: metadataColumn),
      ],
    );
  }

  Widget _buildMessageBodyBlock(
    BuildContext context, {
    required MielPalette palette,
    required ForumMessageItem message,
    required String rootId,
    required String webUrl,
  }) {
    final likeText = message.likesCount > 0
        ? 'Me gusta (${message.likesCount})'
        : 'Me gusta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cuerpo enriquecido (div.foro-contenido-mensaje.contrastify)
        MielRichText(
          htmlContent: message.bodyHtml,
          fallbackPlainText: message.bodyText,
          highlightQuery: _threadSearchQuery,
          onTapMention: (_, msgId) => _scrollToAndFlashMessage(msgId, rootId),
        ),

        // Imágenes adjuntas (img.foroImgAdjuntos)
        if (message.imageAttachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final img in message.imageAttachments)
                MielAuthenticatedImage(
                  imageUrl: img.downloadUrl,
                  fileName: img.fileName,
                ),
            ],
          ),
        ],

        // Archivos adjuntos (Archivo adjunto: nombre.pdf)
        if (message.fileAttachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final file in message.fileAttachments)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  MielFileTypeIcon(fileType: file.fileType, size: 22),
                  Text(
                    'Archivo adjunto:',
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                  InkWell(
                    onTap: () => triggerMielFileDownload(
                      context,
                      ref,
                      url: file.downloadUrl,
                      fallbackFileName: file.fileName,
                    ),
                    child: Text(
                      file.fileName,
                      style: TextStyle(fontSize: 13, color: palette.linkAccent),
                    ),
                  ),
                ],
              ),
            ),
        ],

        const SizedBox(height: 12),

        // Pie del mensaje: Responder · Me gusta (N)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            InkWell(
              onTap: () => openMielExternalUrl(webUrl),
              child: Text(
                'Responder',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.linkAccent,
                ),
              ),
            ),
            Text(
              '·',
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            Text(
              likeText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.linkAccent,
              ),
            ),
            if (message.likesCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.remove_red_eye,
                  size: 16,
                  color: palette.linkAccent,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ForumThreadGroup {
  const _ForumThreadGroup({required this.root, required this.replies});

  final ForumMessageItem root;
  final List<ForumMessageItem> replies;

  List<ForumMessageItem> get allMessages => <ForumMessageItem>[
    root,
    ...replies,
  ];
}
