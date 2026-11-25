import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/miel_models.dart';
import '../../../core/theme/miel_theme.dart';
import '../../navigation/draft_dirty_registry.dart';
import '../module_providers.dart';
import 'module_state_views.dart';

/// Panel nativo de **Nueva entrega** en Portafolio (`POST /portafolio/event/nuevaEntrega/comision/{id}`)
/// con validación de archivo/enlace y confirmación explícita previa al envío.
class PortafolioSubmissionCard extends ConsumerStatefulWidget {
  const PortafolioSubmissionCard({
    super.key,
    required this.idComision,
    required this.idPractica,
    required this.practiceTitle,
    required this.formMeta,
    required this.webUrl,
    required this.onSubmitted,
    this.deliveryType = '',
  });

  final String idComision;
  final String idPractica;
  final String practiceTitle;
  final PortfolioSubmissionFormMeta formMeta;
  final String webUrl;
  final VoidCallback onSubmitted;
  final String deliveryType;

  @override
  ConsumerState<PortafolioSubmissionCard> createState() =>
      _PortafolioSubmissionCardState();
}

class _PortafolioSubmissionCardState
    extends ConsumerState<PortafolioSubmissionCard> {
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  late String _selectedTutorId;
  late bool _isGroupDelivery;
  String? _selectedGroupId;
  String? _attachmentPath;
  String? _attachmentName;
  bool _submitting = false;

  String get _dirtyKey =>
      'portafolio_submission_${widget.idComision}_${widget.idPractica}';

  @override
  void initState() {
    super.initState();
    _selectedTutorId = widget.formMeta.tutors.isNotEmpty
        ? widget.formMeta.tutors.first.id
        : '0';
    final isGrupal = widget.formMeta.isGroupDefault ||
        widget.formMeta.allowsGroup ||
        widget.deliveryType.toLowerCase().contains('grupal');
    _isGroupDelivery = isGrupal;
    _observationsController.addListener(_syncDirtyState);
    _linkController.addListener(_syncDirtyState);
  }

  void _syncDirtyState() {
    final isDirty =
        _observationsController.text.trim().isNotEmpty ||
        _linkController.text.trim().isNotEmpty ||
        _attachmentPath != null;
    ref
        .read(draftDirtyRegistryProvider)
        .setDirty(
          _dirtyKey,
          isDirty: isDirty,
          label: 'la entrega de ${widget.practiceTitle}',
        );
  }

  @override
  void didUpdateWidget(covariant PortafolioSubmissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idPractica != widget.idPractica ||
        oldWidget.idComision != widget.idComision) {
      ref
          .read(draftDirtyRegistryProvider)
          .clearOwner(
            'portafolio_submission_${oldWidget.idComision}_${oldWidget.idPractica}',
          );
      _observationsController.clear();
      _linkController.clear();
      _attachmentPath = null;
      _attachmentName = null;
      _selectedTutorId = widget.formMeta.tutors.isNotEmpty
          ? widget.formMeta.tutors.first.id
          : '0';
      final isGrupal = widget.formMeta.isGroupDefault ||
          widget.formMeta.allowsGroup ||
          widget.deliveryType.toLowerCase().contains('grupal');
      _isGroupDelivery = isGrupal;
      _selectedGroupId = null;
    }
  }

  DraftDirtyRegistry? _dirtyRegistry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dirtyRegistry = ref.read(draftDirtyRegistryProvider);
  }

  @override
  void dispose() {
    _observationsController.removeListener(_syncDirtyState);
    _linkController.removeListener(_syncDirtyState);
    _dirtyRegistry?.clearOwner(_dirtyKey);
    _observationsController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await pickValidatedMielAttachment(
      context,
      maxSizeMb: widget.formMeta.maxSizeMb,
    );
    if (picked != null && mounted) {
      setState(() {
        _attachmentPath = picked.path;
        _attachmentName = picked.name;
      });
      _syncDirtyState();
    }
  }

  Future<void> _confirmAndSubmit({
    required String validTutorId,
    required List<PortfolioGroupOption> availableGroups,
    required String validGroupId,
  }) async {
    final hasFile = _attachmentPath != null && _attachmentPath!.isNotEmpty;
    final link = _linkController.text.trim();
    final hasLink = widget.formMeta.allowsLink && link.isNotEmpty;

    if (!hasFile && !hasLink) {
      showMielStatusToast(
        context,
        message: widget.formMeta.allowsLink
            ? 'Adjuntá un archivo o pegá un enlace válido para entregar.'
            : 'Seleccioná el archivo de tu práctica antes de entregar.',
        isError: true,
      );
      return;
    }

    if (hasLink) {
      final uri = Uri.tryParse(link);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        showMielStatusToast(
          context,
          message: 'El enlace debe comenzar con http:// o https://.',
          isError: true,
        );
        return;
      }
    }

    final tutorLabel = widget.formMeta.tutors
        .where((t) => t.id == validTutorId)
        .map((t) => t.name)
        .firstOrNull;

    final groupLabel = _isGroupDelivery
        ? (availableGroups
                .where((g) => g.id == validGroupId)
                .map((g) => g.name)
                .firstOrNull ??
            'Grupo seleccionado')
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar entrega en MIeL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Práctica: ${widget.practiceTitle}'),
            const SizedBox(height: 6),
            if (tutorLabel != null) Text('Docente destinatario: $tutorLabel'),
            if (hasFile) Text('Archivo: $_attachmentName'),
            if (hasLink) Text('Enlace: $link'),
            if (_isGroupDelivery && groupLabel != null)
              Text('Entrega grupal: $groupLabel'),
            const SizedBox(height: 10),
            const Text(
              'Esta acción registrará la entrega directamente en MIeL UNLaM.',
              style: TextStyle(fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Enviar entrega'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await runMielWriteWithAuth(
        ref,
        (writer) => writer.submitPortafolioEntrega(
          idComision: widget.idComision,
          idPractica: widget.idPractica,
          tutorDestinatarioId: validTutorId,
          observations: _observationsController.text.trim(),
          externalLink: hasLink ? link : null,
          attachmentPath: hasFile ? _attachmentPath : null,
          isGroupDelivery: _isGroupDelivery,
          groupId: _isGroupDelivery ? validGroupId : null,
          groupCheckboxName: widget.formMeta.groupCheckboxName,
          groupCheckboxValue: widget.formMeta.groupCheckboxValue,
          groupSelectName: widget.formMeta.groupSelectName,
        ),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _observationsController.clear();
        _linkController.clear();
        _attachmentPath = null;
        _attachmentName = null;
      });
      ref.read(draftDirtyRegistryProvider).clearOwner(_dirtyKey);
      showMielStatusToast(
        context,
        message: 'Entrega enviada correctamente a MIeL.',
      );
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMielStatusToast(
        context,
        message: 'No se pudo enviar la entrega: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final rawTutors = widget.formMeta.tutors.isNotEmpty
        ? widget.formMeta.tutors
        : const [
            PortfolioTutorOption(
              id: '0',
              name: 'Todos los docentes de la comisión',
            ),
          ];

    // Deduplicación estricta por id para evitar que DropdownButton tire aserción si MIeL repite valores
    final uniqueTutors = <String, PortfolioTutorOption>{};
    for (final t in rawTutors) {
      final safeId = t.id.isEmpty ? '0' : t.id;
      uniqueTutors.putIfAbsent(
        safeId,
        () => PortfolioTutorOption(id: safeId, name: t.name),
      );
    }
    if (uniqueTutors.isEmpty) {
      uniqueTutors['0'] = const PortfolioTutorOption(
        id: '0',
        name: 'Todos los docentes de la comisión',
      );
    }
    final tutors = uniqueTutors.values.toList();
    final validTutorId = tutors.any((t) => t.id == _selectedTutorId)
        ? _selectedTutorId
        : tutors.first.id;

    final groupsAsync = ref.watch(portafolioGruposProvider(widget.idComision));
    final registeredGroups = groupsAsync.asData?.value ?? const [];

    final availableGroups = <PortfolioGroupOption>[
      if (widget.formMeta.groups.isNotEmpty)
        ...widget.formMeta.groups
      else if (registeredGroups.isNotEmpty)
        for (final g in registeredGroups)
          PortfolioGroupOption(id: g.idGrupo, name: g.name)
      else
        const PortfolioGroupOption(id: '0', name: 'Mi grupo'),
    ];

    final validGroupId = availableGroups.any((g) => g.id == _selectedGroupId)
        ? _selectedGroupId!
        : availableGroups.first.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nueva entrega',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              MielHoverLink(
                text: 'Abrir en MIeL',
                fontSize: 12.5,
                leadingIcon: Icons.open_in_new,
                leadingIconSize: 14,
                onTap: () => openMielExternalUrl(widget.webUrl),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Docente destinatario
          Text(
            'Docente destinatario:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: palette.inputBackground,
              border: Border.all(color: palette.inputBorder),
              borderRadius: BorderRadius.circular(2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: validTutorId,
                isExpanded: true,
                dropdownColor: palette.dropdownBackground,
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
                items: [
                  for (final t in tutors)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: _submitting
                    ? null
                    : (v) {
                        if (v != null) setState(() => _selectedTutorId = v);
                      },
              ),
            ),
          ),

          // 2. Mensaje
          const SizedBox(height: 12),
          Text(
            'Mensaje / observaciones (opcional):',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _observationsController,
            enabled: !_submitting,
            minLines: 3,
            maxLines: 6,
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Comentarios para el docente…',
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

          // 3. Cargar archivo
          const SizedBox(height: 12),
          Text(
            'Archivo de entrega (máx. ${widget.formMeta.maxSizeMb} MB):',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: _attachmentName == null
                    ? 'Cargar archivo (hasta ${widget.formMeta.maxSizeMb} MB)'
                    : 'Cambiar archivo',
                icon: Icons.attach_file,
                onPressed: _submitting ? null : _pickFile,
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

          if (widget.formMeta.allowsLink) ...[
            const SizedBox(height: 12),
            Text(
              'Enlace externo (opcional si subís archivo):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _linkController,
              enabled: !_submitting,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://…',
                hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
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
          ],

          // 4. Entrega grupal
          const SizedBox(height: 14),
          InkWell(
            onTap: _submitting
                ? null
                : () => setState(() => _isGroupDelivery = !_isGroupDelivery),
            borderRadius: BorderRadius.circular(3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _isGroupDelivery,
                    onChanged: _submitting
                        ? null
                        : (val) => setState(
                              () => _isGroupDelivery = val ?? false,
                            ),
                    activeColor: palette.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Entrega grupal (práctica realizada por varios alumnos).',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Grupo
          if (_isGroupDelivery) ...[
            const SizedBox(height: 10),
            Text(
              'Grupo:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: palette.inputBackground,
                border: Border.all(color: palette.inputBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: validGroupId,
                  isExpanded: true,
                  dropdownColor: palette.dropdownBackground,
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  items: [
                    for (final g in availableGroups)
                      DropdownMenuItem(value: g.id, child: Text(g.name)),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => _selectedGroupId = v);
                          }
                        },
                ),
              ),
            ),
          ],

          // 6. Enviar entrega
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: MielActionButton(
              label: _submitting ? 'Enviando entrega…' : 'Enviar entrega',
              icon: Icons.send,
              primary: true,
              onPressed: _submitting
                  ? null
                  : () => _confirmAndSubmit(
                        validTutorId: validTutorId,
                        availableGroups: availableGroups,
                        validGroupId: validGroupId,
                      ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
