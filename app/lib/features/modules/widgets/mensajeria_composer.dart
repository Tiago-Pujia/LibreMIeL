import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/miel_models.dart';
import '../../../core/network/miel_client.dart';
import '../../../core/parsers/text_normalizer.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/miel_theme.dart';
import '../module_providers.dart';
import 'module_state_views.dart';

/// Compositor nativo de **Nuevo mensaje / Borrador** (`POST /mensajeria/event/enviarMensaje/comision/{id}`).
class MensajeriaComposePanel extends ConsumerStatefulWidget {
  const MensajeriaComposePanel({super.key, required this.subject, this.onSent});

  final Subject subject;
  final VoidCallback? onSent;

  @override
  ConsumerState<MensajeriaComposePanel> createState() =>
      _MensajeriaComposePanelState();
}

class _MensajeriaComposePanelState
    extends ConsumerState<MensajeriaComposePanel> {
  final TextEditingController _recipientSearchController =
      TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final List<ComposeRecipientOption> _selectedRecipients =
      <ComposeRecipientOption>[];
  String _recipientQuery = '';
  String? _attachmentPath;
  String? _attachmentName;
  bool _submitting = false;
  bool _initializedDefaults = false;

  @override
  void didUpdateWidget(covariant MensajeriaComposePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.idComision != widget.subject.idComision) {
      _selectedRecipients.clear();
      _recipientSearchController.clear();
      _subjectController.clear();
      _bodyController.clear();
      _recipientQuery = '';
      _attachmentPath = null;
      _attachmentName = null;
      _initializedDefaults = false;
    }
  }

  @override
  void dispose() {
    _recipientSearchController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _toggleRecipient(ComposeRecipientOption option) {
    setState(() {
      final idx = _selectedRecipients.indexWhere(
        (r) => r.uniqueKey == option.uniqueKey,
      );
      if (idx >= 0) {
        _selectedRecipients.removeAt(idx);
      } else {
        _selectedRecipients.add(option);
      }
    });
  }

  Future<void> _pickAttachment() async {
    final picked = await pickValidatedMielAttachment(
      context,
      maxSizeMb: kMielMaxUploadMbLarge,
    );
    if (picked != null && mounted) {
      setState(() {
        _attachmentPath = picked.path;
        _attachmentName = picked.name;
      });
    }
  }

  Future<void> _submit({required bool saveAsDraft}) async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Ingresá un asunto para el mensaje.',
        isError: true,
      );
      return;
    }
    if (body.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Escribí el contenido del mensaje.',
        isError: true,
      );
      return;
    }
    if (!saveAsDraft && _selectedRecipients.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Seleccioná al menos un destinatario antes de enviar.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (writer) => writer.sendMensajeriaMessage(
          idComision: widget.subject.idComision,
          recipients: List<ComposeRecipientOption>.of(_selectedRecipients),
          subject: subject,
          bodyPlainText: body,
          saveAsDraft: saveAsDraft,
          attachmentPath: _attachmentPath,
        ),
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectedRecipients.clear();
        _subjectController.clear();
        _bodyController.clear();
        _attachmentPath = null;
        _attachmentName = null;
      });

      final targetBox = saveAsDraft
          ? MensajeriaBoxKind.borradores
          : MensajeriaBoxKind.salida;
      ref.invalidate(
        mensajeriaBandejaProvider((
          idComision: widget.subject.idComision,
          box: targetBox,
          page: 1,
        )),
      );

      showMielStatusToast(
        context,
        message: saveAsDraft
            ? 'Borrador guardado correctamente en MIeL.'
            : 'Mensaje enviado correctamente.',
      );
      widget.onSent?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMielStatusToast(
        context,
        message: 'No se pudo enviar el mensaje: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final formAsync = ref.watch(mensajeriaRedactarFormProvider(idComision));
    final composeUrl = '$kMielBaseUrl/mensajeria/redactar/comision/$idComision';

    return formAsync.when(
      loading: () => const MielModuleLoadingView(
        message: 'Cargando destinatarios de la comisión…',
      ),
      error: (err, _) => MielModuleErrorView(
        message: 'No se pudo cargar el formulario de redacción: $err',
        mielWebUrl: composeUrl,
        onRetry: () =>
            ref.invalidate(mensajeriaRedactarFormProvider(idComision)),
      ),
      data: (formData) {
        if (!_initializedDefaults) {
          _initializedDefaults = true;
          if (formData.preselectedRecipients.isNotEmpty &&
              _selectedRecipients.isEmpty) {
            _selectedRecipients.addAll(formData.preselectedRecipients);
          }
          if (formData.initialSubject.isNotEmpty &&
              _subjectController.text.isEmpty) {
            _subjectController.text = formData.initialSubject;
          }
          if (formData.initialBodyText.isNotEmpty &&
              _bodyController.text.isEmpty) {
            _bodyController.text = formData.initialBodyText;
          }
        }

        final normQuery = normalizeText(_recipientQuery);
        final filteredRecipients = formData.recipients.where((r) {
          if (normQuery.isEmpty) return true;
          return normalizeText(r.displayName).contains(normQuery) ||
              normalizeText(r.roleLabel).contains(normQuery);
        }).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Destinatarios
              Text(
                'Destinatarios:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              if (_selectedRecipients.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final rec in _selectedRecipients)
                      InputChip(
                        label: Text(
                          rec.roleLabel.isNotEmpty
                              ? '${rec.displayName} (${rec.roleLabel})'
                              : rec.displayName,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textPrimary,
                          ),
                        ),
                        backgroundColor: palette.primary.withValues(
                          alpha: 0.14,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 15),
                        onDeleted: _submitting
                            ? null
                            : () => _toggleRecipient(rec),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _recipientSearchController,
                enabled: !_submitting,
                onChanged: (v) => setState(() => _recipientQuery = v),
                style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar docentes o compañeros para agregar…',
                  hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.person_search,
                    size: 18,
                    color: palette.textMuted,
                  ),
                  filled: true,
                  fillColor: palette.inputBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 165),
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: palette.divider),
                ),
                child: filteredRecipients.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No se encontraron destinatarios coincidentes.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredRecipients.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: palette.divider),
                        itemBuilder: (context, index) {
                          final rec = filteredRecipients[index];
                          final selected = _selectedRecipients.any(
                            (s) => s.uniqueKey == rec.uniqueKey,
                          );
                          final isTutor =
                              rec.contactType == 'tutor' ||
                              rec.contactType == 'tutores';
                          return InkWell(
                            onTap: _submitting
                                ? null
                                : () => _toggleRecipient(rec),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 18,
                                    color: selected
                                        ? palette.primary
                                        : palette.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isTutor
                                        ? Icons.school
                                        : rec.contactType == 'grupo'
                                        ? Icons.group
                                        : Icons.person_outline,
                                    size: 16,
                                    color: isTutor
                                        ? palette.linkAccent
                                        : palette.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      rec.displayName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (rec.roleLabel.isNotEmpty)
                                    Text(
                                      rec.roleLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 14),
              Text(
                'Asunto:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _subjectController,
                enabled: !_submitting,
                style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Asunto del mensaje…',
                  hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: palette.inputBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Text(
                'Mensaje:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyController,
                enabled: !_submitting,
                minLines: 6,
                maxLines: 14,
                style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Escribí tu mensaje aquí…',
                  hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: palette.inputBackground,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: palette.inputBorder),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  MielActionButton(
                    label: _attachmentName == null
                        ? 'Adjuntar archivo (máx. 40 MB)'
                        : 'Cambiar adjunto',
                    icon: Icons.attach_file,
                    onPressed: _submitting ? null : _pickAttachment,
                  ),
                  if (_attachmentName != null)
                    InputChip(
                      avatar: const Icon(Icons.insert_drive_file, size: 16),
                      label: Text(
                        _attachmentName!,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 15),
                      onDeleted: _submitting
                          ? null
                          : () => setState(() {
                              _attachmentPath = null;
                              _attachmentName = null;
                            }),
                    ),
                ],
              ),

              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  MielActionButton(
                    label: _submitting ? 'Enviando…' : 'Enviar mensaje',
                    icon: Icons.send,
                    primary: true,
                    onPressed: _submitting
                        ? null
                        : () => _submit(saveAsDraft: false),
                  ),
                  MielActionButton(
                    label: 'Guardar borrador',
                    icon: Icons.save_outlined,
                    onPressed: _submitting
                        ? null
                        : () => _submit(saveAsDraft: true),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Panel nativo de respuesta rápida dentro de `verEntrada` (`POST /mensajeria/event/enviarRespuesta/comision/{id}`).
class MensajeriaReplyPanel extends ConsumerStatefulWidget {
  const MensajeriaReplyPanel({
    super.key,
    required this.detail,
    required this.onReplied,
    required this.onCancel,
  });

  final MessageDetail detail;
  final VoidCallback onReplied;
  final VoidCallback onCancel;

  @override
  ConsumerState<MensajeriaReplyPanel> createState() =>
      _MensajeriaReplyPanelState();
}

class _MensajeriaReplyPanelState extends ConsumerState<MensajeriaReplyPanel> {
  final TextEditingController _bodyController = TextEditingController();
  final List<ComposeRecipientOption> _selectedRecipients =
      <ComposeRecipientOption>[];
  String? _attachmentPath;
  String? _attachmentName;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final def = widget.detail.replyDefaultRecipient;
    if (def != null) {
      _selectedRecipients.add(def);
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picked = await pickValidatedMielAttachment(
      context,
      maxSizeMb: kMielMaxUploadMbLarge,
    );
    if (picked != null && mounted) {
      setState(() {
        _attachmentPath = picked.path;
        _attachmentName = picked.name;
      });
    }
  }

  Future<void> _sendReply() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Escribí el texto de tu respuesta.',
        isError: true,
      );
      return;
    }
    if (_selectedRecipients.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Seleccioná al menos un destinatario para responder.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (writer) => writer.sendMensajeriaReply(
          idComision: widget.detail.idComision,
          respondsToMessageId: widget.detail.idMensaje,
          recipients: List<ComposeRecipientOption>.of(_selectedRecipients),
          bodyPlainText: body,
          attachmentPath: _attachmentPath,
        ),
      );
      if (!mounted) return;
      showMielStatusToast(context, message: 'Respuesta enviada correctamente.');
      widget.onReplied();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMielStatusToast(
        context,
        message: 'No se pudo enviar la respuesta: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final available = widget.detail.replyAvailableRecipients;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.primary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.reply, size: 18, color: palette.linkAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Responder a ${widget.detail.senderName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar respuesta',
                onPressed: _submitting ? null : widget.onCancel,
                icon: Icon(Icons.close, size: 18, color: palette.textMuted),
              ),
            ],
          ),
          if (_selectedRecipients.isNotEmpty || available.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final rec in _selectedRecipients)
                  InputChip(
                    label: Text(
                      rec.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textPrimary,
                      ),
                    ),
                    backgroundColor: palette.primary.withValues(alpha: 0.14),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: _submitting
                        ? null
                        : () => setState(() => _selectedRecipients.remove(rec)),
                  ),
                if (available.isNotEmpty)
                  PopupMenuButton<ComposeRecipientOption>(
                    tooltip: 'Agregar destinatario',
                    enabled: !_submitting,
                    onSelected: (opt) {
                      if (_selectedRecipients.every(
                        (s) => s.uniqueKey != opt.uniqueKey,
                      )) {
                        setState(() => _selectedRecipients.add(opt));
                      }
                    },
                    itemBuilder: (_) => [
                      for (final opt in available)
                        PopupMenuItem<ComposeRecipientOption>(
                          value: opt,
                          child: Text(
                            opt.roleLabel.isNotEmpty
                                ? '${opt.displayName} (${opt.roleLabel})'
                                : opt.displayName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    child: Chip(
                      avatar: Icon(
                        Icons.person_add_alt,
                        size: 15,
                        color: palette.linkAccent,
                      ),
                      label: Text(
                        'Agregar destinatario',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.linkAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            enabled: !_submitting,
            minLines: 4,
            maxLines: 10,
            style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Escribí tu respuesta…',
              hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
              filled: true,
              fillColor: palette.inputBackground,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: palette.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: palette.inputBorder),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: _submitting ? 'Enviando…' : 'Enviar respuesta',
                icon: Icons.send,
                primary: true,
                onPressed: _submitting ? null : _sendReply,
              ),
              MielActionButton(
                label: _attachmentName == null
                    ? 'Adjuntar (máx. 40 MB)'
                    : 'Cambiar adjunto',
                icon: Icons.attach_file,
                onPressed: _submitting ? null : _pickAttachment,
              ),
              if (_attachmentName != null)
                InputChip(
                  label: Text(
                    _attachmentName!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: _submitting
                      ? null
                      : () => setState(() {
                          _attachmentPath = null;
                          _attachmentName = null;
                        }),
                ),
              MielActionButton(
                label: 'Cancelar',
                onPressed: _submitting ? null : widget.onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
