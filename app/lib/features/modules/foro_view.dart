import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/parsers/text_normalizer.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/libremiel_brand.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/miel_rich_text.dart';
import 'widgets/module_state_views.dart';
import '../downloads/bulk_download_sheet.dart';

/// Vista nativa de lectura y participación del módulo **Foros (`forov2`)**
/// (`Temas abiertos`, publicar nuevos hilos, respuestas anidadas con `@menciones`,
/// Me gusta interactivo, imágenes autenticadas con zoom y descarga de adjuntos)
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
  final TextEditingController _newMessageController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  String _threadSearchQuery = '';
  bool _reverseOrder = false;
  final Set<String> _expandedThreadRootIds = <String>{};
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  final Map<String, int> _topicUnreadBadges = <String, int>{};
  final Set<String> _locallyReadTopicIds = <String>{};

  bool _showNewMessageComposer = false;
  String? _newMessageAttachmentPath;
  String? _newMessageAttachmentName;
  bool _postingNewMessage = false;

  ForumMessageItem? _replyTargetMessage;
  String? _replyAttachmentPath;
  String? _replyAttachmentName;
  bool _postingReply = false;

  bool _markingAllTopicsRead = false;
  final Map<String, ({int count, bool liked})> _localLikes =
      <String, ({int count, bool liked})>{};
  final Set<String> _likeInFlightIds = <String>{};

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
      _showNewMessageComposer = false;
      _newMessageController.clear();
      _newMessageAttachmentPath = null;
      _newMessageAttachmentName = null;
      _replyTargetMessage = null;
      _replyController.clear();
      _replyAttachmentPath = null;
      _replyAttachmentName = null;
      _localLikes.clear();
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
    _newMessageController.dispose();
    _replyController.dispose();
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

  Future<void> _handleMarkAllTopicsRead(String idComision) async {
    setState(() => _markingAllTopicsRead = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.markAllForoTopicsRead(idComision),
      );
      await ref
          .read(databaseProvider)
          .decrementForoBadge(idComision, widget.subject.lastForoBadge);
      if (!mounted) return;
      setState(() => _markingAllTopicsRead = false);
      ref.invalidate(foroTemasProvider(idComision));
      showMielStatusToast(
        context,
        message: 'Todos los temas fueron marcados como leídos.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _markingAllTopicsRead = false);
      showMielStatusToast(
        context,
        message: 'No se pudo marcar todos como leídos: $e',
        isError: true,
      );
    }
  }

  Future<void> _handleToggleLike(ForumMessageItem message) async {
    if (_likeInFlightIds.contains(message.id)) return;
    final current = _localLikes[message.id] ??
        (count: message.likesCount, liked: false);
    final nextLiked = !current.liked;
    final nextCount =
        (current.count + (nextLiked ? 1 : -1)).clamp(0, 99999);

    setState(() {
      _likeInFlightIds.add(message.id);
      _localLikes[message.id] = (count: nextCount, liked: nextLiked);
    });

    try {
      final serverCount = await runMielWriteWithAuth(
        ref,
        (w) => w.toggleForoLike(
          idComision: widget.subject.idComision,
          idMensaje: message.id,
          currentlyLiked: current.liked,
        ),
      );
      if (!mounted) return;
      setState(() {
        _likeInFlightIds.remove(message.id);
        _localLikes[message.id] = (count: serverCount, liked: nextLiked);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likeInFlightIds.remove(message.id);
        _localLikes[message.id] = current;
      });
      showMielStatusToast(
        context,
        message: 'No se pudo actualizar Me gusta: $e',
        isError: true,
      );
    }
  }

  Future<void> _handlePostNewMessage(String idTema) async {
    final text = _newMessageController.text.trim();
    if (text.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Escribí un mensaje antes de publicar.',
        isError: true,
      );
      return;
    }

    setState(() => _postingNewMessage = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.postForoNewMessage(
          idComision: widget.subject.idComision,
          idTema: idTema,
          bodyPlainText: text,
          attachmentPath: _newMessageAttachmentPath,
        ),
      );
      if (!mounted) return;
      setState(() {
        _postingNewMessage = false;
        _showNewMessageComposer = false;
        _newMessageController.clear();
        _newMessageAttachmentPath = null;
        _newMessageAttachmentName = null;
      });
      ref.invalidate(
        foroMensajesProvider((
          idComision: widget.subject.idComision,
          idTema: idTema,
          unreadBadge: 0,
        )),
      );
      showMielStatusToast(context, message: 'Mensaje publicado en el foro.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _postingNewMessage = false);
      showMielStatusToast(
        context,
        message: 'No se pudo publicar el mensaje: $e',
        isError: true,
      );
    }
  }

  Future<void> _handlePostReply({
    required String idTema,
    required String rootId,
    required ForumMessageItem target,
  }) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Escribí una respuesta antes de enviar.',
        isError: true,
      );
      return;
    }

    setState(() => _postingReply = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (w) => w.postForoReply(
          idComision: widget.subject.idComision,
          idTema: idTema,
          rootParentMessageId: rootId,
          bodyPlainText: text,
          mentionUserId:
              target.authorId.isNotEmpty ? target.authorId : null,
          mentionMessageId: target.id,
          mentionUserName: target.replyMentionName.isNotEmpty
              ? target.replyMentionName
              : target.authorName,
          attachmentPath: _replyAttachmentPath,
        ),
      );
      if (!mounted) return;
      setState(() {
        _postingReply = false;
        _replyTargetMessage = null;
        _replyController.clear();
        _replyAttachmentPath = null;
        _replyAttachmentName = null;
      });
      ref.invalidate(
        foroMensajesProvider((
          idComision: widget.subject.idComision,
          idTema: idTema,
          unreadBadge: 0,
        )),
      );
      showMielStatusToast(context, message: 'Respuesta publicada.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _postingReply = false);
      showMielStatusToast(
        context,
        message: 'No se pudo enviar la respuesta: $e',
        isError: true,
      );
    }
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
              if (widget.subject.lastForoBadge > 0)
                MielActionButton(
                  label: _markingAllTopicsRead
                      ? 'Marcando…'
                      : 'Marcar todos leídos',
                  icon: Icons.done_all,
                  onPressed: _markingAllTopicsRead
                      ? null
                      : () => _handleMarkAllTopicsRead(idComision),
                ),
              MielActionButton(
                label: 'Exportar foros',
                icon: Icons.download_for_offline_outlined,
                onPressed: () => showBulkDownloadDialog(
                  context,
                  initialSubject: widget.subject,
                ),
              ),
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

    return _ForumTopicTile(
      palette: palette,
      topic: topic,
      effectiveUnread: effectiveUnread,
      publicIndigo: publicIndigo,
      onTap: () {
        _locallyReadTopicIds.add(topic.idTema);
        widget.onSelectTopic(topic.idTema);
      },
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
        // Cabecera: Tema: {Título} + Volver | Ir al final | Nuevo mensaje | Abrir en MIeL
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
              if (thread.canPostMessage)
                MielActionButton(
                  label: _showNewMessageComposer
                      ? 'Cerrar redacción'
                      : 'Nuevo mensaje',
                  icon: _showNewMessageComposer ? Icons.close : Icons.edit,
                  primary: !_showNewMessageComposer,
                  onPressed: () => setState(
                    () => _showNewMessageComposer = !_showNewMessageComposer,
                  ),
                ),
              MielActionButton(
                label: 'Abrir en MIeL',
                icon: Icons.open_in_new,
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
        if (isCompact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MielSearchBarField(
                controller: _searchController,
                query: _threadSearchQuery,
                hintText: 'Ingrese el texto buscado...',
                onChanged: (v) => setState(() => _threadSearchQuery = v),
                onSubmitted: () =>
                    setState(() => _threadSearchQuery = _searchController.text),
                onCleared: () {
                  _searchController.clear();
                  setState(() => _threadSearchQuery = '');
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: MielActionButton(
                  label: 'Invertir orden',
                  icon: Icons.import_export,
                  onPressed: () =>
                      setState(() => _reverseOrder = !_reverseOrder),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: MielSearchBarField(
                  controller: _searchController,
                  query: _threadSearchQuery,
                  hintText: 'Ingrese el texto buscado...',
                  onChanged: (v) => setState(() => _threadSearchQuery = v),
                  onSubmitted: () => setState(
                    () => _threadSearchQuery = _searchController.text,
                  ),
                  onCleared: () {
                    _searchController.clear();
                    setState(() => _threadSearchQuery = '');
                  },
                ),
              ),
              const SizedBox(width: 14),
              MielActionButton(
                label: 'Invertir orden',
                icon: Icons.import_export,
                onPressed: () => setState(() => _reverseOrder = !_reverseOrder),
              ),
            ],
          ),
        const SizedBox(height: 16),

        if (_showNewMessageComposer) ...[
          _buildNewMessageComposer(context, palette, thread),
          const SizedBox(height: 16),
        ],

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
              idTema: thread.idTema,
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
    required String idTema,
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
            idTema: idTema,
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
                idTema: idTema,
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
    required String idTema,
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
                  idTema: idTema,
                  webUrl: webUrl,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MielAvatar(
                  avatarUrl: message.authorAvatarUrl,
                  radius: isReply ? 20 : 24,
                  fallbackBackgroundColor: message.isTeacher
                      ? const Color(0xFF4F90C4)
                      : palette.textMuted.withValues(alpha: 0.45),
                  fallbackIconSize: isReply ? 22 : 26,
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
                    idTema: idTema,
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
        MielAvatar(
          avatarUrl: message.authorAvatarUrl,
          radius: isReply ? 18 : 20,
          fallbackBackgroundColor: message.isTeacher
              ? const Color(0xFF4F90C4)
              : palette.textMuted.withValues(alpha: 0.45),
          fallbackIconSize: 20,
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
    required String idTema,
    required String webUrl,
  }) {
    final likeData =
        _localLikes[message.id] ?? (count: message.likesCount, liked: false);
    final likeText =
        likeData.count > 0 ? 'Me gusta (${likeData.count})' : 'Me gusta';

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
                  MielHoverLink(
                    text: file.fileName,
                    fontSize: 13,
                    onTap: () => triggerMielFileDownload(
                      context,
                      ref,
                      url: file.downloadUrl,
                      fallbackFileName: file.fileName,
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
            MielHoverLink(
              text: 'Responder',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              onTap: () {
                setState(() {
                  if (_replyTargetMessage?.id == message.id) {
                    _replyTargetMessage = null;
                  } else {
                    _replyTargetMessage = message;
                    _replyController.clear();
                    _replyAttachmentPath = null;
                    _replyAttachmentName = null;
                  }
                });
              },
            ),
            Text(
              '·',
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            MielHoverLink(
              text: likeText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: likeData.liked ? palette.linkAccent : palette.textPrimary,
              hoverColor: palette.linkAccent,
              onTap: () => _handleToggleLike(message),
            ),
            if (likeData.count > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 15,
                  color: likeData.liked ? palette.linkAccent : palette.textMuted,
                ),
              ),
          ],
        ),
        if (_replyTargetMessage?.id == message.id) ...[
          const SizedBox(height: 10),
          _buildInlineReplyComposer(
            context,
            palette,
            message,
            rootId,
            idTema,
          ),
        ],
      ],
    );
  }

  Widget _buildNewMessageComposer(
    BuildContext context,
    MielPalette palette,
    ForumThreadData thread,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, size: 20, color: palette.linkAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Publicar nuevo mensaje en "${thread.title}"',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                icon: Icon(Icons.close, size: 18, color: palette.textMuted),
                onPressed: _postingNewMessage
                    ? null
                    : () => setState(() => _showNewMessageComposer = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.inputBackground,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: palette.inputBorder),
            ),
            child: TextField(
              controller: _newMessageController,
              enabled: !_postingNewMessage,
              minLines: 3,
              maxLines: 8,
              style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
              decoration: InputDecoration.collapsed(
                hintText: 'Escribí tu mensaje para el foro…',
                hintStyle: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_newMessageAttachmentName != null) ...[
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(
                    _newMessageAttachmentName!,
                    style: TextStyle(fontSize: 12, color: palette.textPrimary),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: _postingNewMessage
                      ? null
                      : () => setState(() {
                            _newMessageAttachmentPath = null;
                            _newMessageAttachmentName = null;
                          }),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('Adjuntar archivo (máx 5 MB)'),
                onPressed: _postingNewMessage
                    ? null
                    : () async {
                        final picked = await pickValidatedMielAttachment(
                          context,
                          maxSizeMb: kMielMaxUploadMbForum,
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _newMessageAttachmentPath = picked.path;
                            _newMessageAttachmentName = picked.name;
                          });
                        }
                      },
              ),
              const Spacer(),
              TextButton(
                onPressed: _postingNewMessage
                    ? null
                    : () => setState(() => _showNewMessageComposer = false),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _postingNewMessage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_postingNewMessage ? 'Publicando…' : 'Publicar'),
                onPressed: _postingNewMessage
                    ? null
                    : () => _handlePostNewMessage(thread.idTema),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineReplyComposer(
    BuildContext context,
    MielPalette palette,
    ForumMessageItem target,
    String rootId,
    String idTema,
  ) {
    final mention = target.replyMentionName.isNotEmpty
        ? target.replyMentionName
        : target.authorName;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.linkAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 16, color: palette.linkAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Respondiendo a @$mention',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: palette.textMuted),
                onPressed: _postingReply
                    ? null
                    : () => setState(() {
                          _replyTargetMessage = null;
                        }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.inputBackground,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: palette.inputBorder),
            ),
            child: TextField(
              controller: _replyController,
              enabled: !_postingReply,
              minLines: 2,
              maxLines: 6,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
              decoration: InputDecoration.collapsed(
                hintText: 'Escribí tu respuesta…',
                hintStyle: TextStyle(fontSize: 12.5, color: palette.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_replyAttachmentName != null) ...[
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.attach_file, size: 14),
                  label: Text(
                    _replyAttachmentName!,
                    style: TextStyle(fontSize: 11.5, color: palette.textPrimary),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: _postingReply
                      ? null
                      : () => setState(() {
                            _replyAttachmentPath = null;
                            _replyAttachmentName = null;
                          }),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file, size: 14),
                label: const Text('Adjunto (máx 5 MB)'),
                onPressed: _postingReply
                    ? null
                    : () async {
                        final picked = await pickValidatedMielAttachment(
                          context,
                          maxSizeMb: kMielMaxUploadMbForum,
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _replyAttachmentPath = picked.path;
                            _replyAttachmentName = picked.name;
                          });
                        }
                      },
              ),
              const Spacer(),
              TextButton(
                onPressed: _postingReply
                    ? null
                    : () => setState(() {
                          _replyTargetMessage = null;
                        }),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _postingReply
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 14),
                label: Text(_postingReply ? 'Enviando…' : 'Responder'),
                onPressed: _postingReply
                    ? null
                    : () => _handlePostReply(
                          idTema: idTema,
                          rootId: rootId,
                          target: target,
                        ),
              ),
            ],
          ),
        ],
      ),
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

/// Fila interactiva de tema de foro: clickeable en toda su superficie,
/// con cursor `SystemMouseCursors.click`, resaltado de fondo y subrayado del título en hover.
class _ForumTopicTile extends StatefulWidget {
  const _ForumTopicTile({
    required this.palette,
    required this.topic,
    required this.effectiveUnread,
    required this.publicIndigo,
    required this.onTap,
  });

  final MielPalette palette;
  final ForumTopicSummary topic;
  final int effectiveUnread;
  final Color publicIndigo;
  final VoidCallback onTap;

  @override
  State<_ForumTopicTile> createState() => _ForumTopicTileState();
}

class _ForumTopicTileState extends State<_ForumTopicTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final topic = widget.topic;
    final titleColor = _hovered ? palette.linkAccent : palette.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? palette.cardHover.withValues(alpha: 0.45)
                : Colors.transparent,
            border: Border(bottom: BorderSide(color: palette.divider)),
          ),
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
                      topic.isClosed ? Icons.speaker_notes_off : Icons.message,
                      size: 33,
                      color: topic.isClosed
                          ? palette.textMuted
                          : palette.textSecondary,
                    ),
                    if (widget.effectiveUnread > 0)
                      Positioned(
                        top: 18,
                        left: 22,
                        child: MielRedBadge(
                          count: widget.effectiveUnread,
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
                        color: titleColor,
                        decoration: _hovered
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: titleColor,
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
                                    color: widget.publicIndigo,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: 'Tema público - ',
                                style: TextStyle(
                                  color: widget.publicIndigo,
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
    );
  }
}
