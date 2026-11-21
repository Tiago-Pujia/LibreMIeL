import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/module_state_views.dart';
import 'widgets/portafolio_submission_card.dart';

/// Vista nativa de lectura del módulo **Portafolio** (`Prácticas`, `Entrega de prácticas`,
/// `Archivos enviados`, `Mis grupos` y `Asistencia, notas y cert.`)
/// fiel a MIeL (`2025.2.0`).
class PortafolioView extends ConsumerStatefulWidget {
  const PortafolioView({
    super.key,
    required this.subject,
    required this.sectionIndex,
    this.sectionResetTick = 0,
  });

  final Subject subject;
  final int sectionIndex;
  final int sectionResetTick;

  @override
  ConsumerState<PortafolioView> createState() => _PortafolioViewState();
}

class _PortafolioViewState extends ConsumerState<PortafolioView> {
  PortfolioPractice? _selectedPractice;

  @override
  void didUpdateWidget(covariant PortafolioView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex ||
        oldWidget.sectionResetTick != widget.sectionResetTick ||
        oldWidget.subject.idComision != widget.subject.idComision) {
      _selectedPractice = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: switch (widget.sectionIndex) {
            1 => _buildArchivosEnviadosTab(context, isCompact),
            2 => _buildGruposTab(context, isCompact),
            3 => _buildNotasAsistenciaTab(context, isCompact),
            _ =>
              _selectedPractice != null
                  ? _buildPracticeDetailView(
                      context,
                      _selectedPractice!,
                      isCompact,
                    )
                  : _buildPracticasTab(context, isCompact),
          },
        );
      },
    );
  }

  // --- Pestaña 0: Prácticas ---

  Widget _buildPracticasTab(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/portafolio/practicas/comision/$idComision';
    final practicesAsync = ref.watch(portafolioPracticasProvider(idComision));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Prácticas',
          trailing: MielActionButton(
            label: 'Actualizar',
            icon: Icons.refresh,
            onPressed: () =>
                ref.invalidate(portafolioPracticasProvider(idComision)),
          ),
        ),
        const SizedBox(height: 16),
        practicesAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Cargando prácticas del portafolio…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar las prácticas: $err',
            mielWebUrl: webUrl,
            onRetry: () =>
                ref.invalidate(portafolioPracticasProvider(idComision)),
          ),
          data: (practices) {
            if (practices.isEmpty) {
              return const MielModuleEmptyView(
                message: 'No hay prácticas publicadas en esta comisión.',
                icon: Icons.assignment_outlined,
              );
            }
            if (isCompact) {
              return _buildPracticasCompactList(context, palette, practices);
            }
            return _buildPracticasDesktopTable(context, palette, practices);
          },
        ),
      ],
    );
  }

  Widget _buildPracticasDesktopTable(
    BuildContext context,
    MielPalette palette,
    List<PortfolioPractice> practices,
  ) {
    TextStyle headerStyle() => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.divider, width: 1.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('Práctica', style: headerStyle())),
              SizedBox(width: 95, child: Text('Entrega', style: headerStyle())),
              SizedBox(
                width: 95,
                child: Text('F. vencim.', style: headerStyle()),
              ),
              SizedBox(
                width: 135,
                child: Text('Detalle entregas', style: headerStyle()),
              ),
              SizedBox(
                width: 95,
                child: Text('F. entrega', style: headerStyle()),
              ),
              SizedBox(
                width: 95,
                child: Text('F. correc.', style: headerStyle()),
              ),
              SizedBox(width: 110, child: Text('Estado', style: headerStyle())),
              SizedBox(width: 65, child: Text('Nota', style: headerStyle())),
            ],
          ),
        ),
        for (final p in practices)
          MielHoverRow(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.moduleName.isNotEmpty)
                        Text(
                          p.moduleName,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                      MielHoverLink(
                        text: p.title,
                        fontSize: 13,
                        color: p.promptDownloadUrl.isNotEmpty
                            ? palette.linkAccent
                            : palette.textPrimary,
                        hoverColor: palette.linkAccent,
                        onTap: () {
                          if (p.promptDownloadUrl.isNotEmpty) {
                            triggerMielFileDownload(
                              context,
                              ref,
                              url: p.promptDownloadUrl,
                              fallbackFileName: p.title,
                            );
                          } else {
                            setState(() => _selectedPractice = p);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    p.deliveryType.isEmpty ? '---' : p.deliveryType,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    p.dueDate.isEmpty ? '---' : p.dueDate,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 135,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MielHoverLink(
                      text: '[ENTREGAR / VER]',
                      fontSize: 13,
                      onTap: () => setState(() => _selectedPractice = p),
                    ),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    p.deliveryDate.isEmpty ? '---' : p.deliveryDate,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    p.correctionDate.isEmpty ? '---' : p.correctionDate,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    p.status.isEmpty ? '---' : p.status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: p.status.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    p.grade.isEmpty ? '---' : p.grade,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: p.grade.isNotEmpty
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPracticasCompactList(
    BuildContext context,
    MielPalette palette,
    List<PortfolioPractice> practices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in practices)
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
                if (p.moduleName.isNotEmpty)
                  Text(
                    p.moduleName,
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                MielHoverLink(
                  text: p.title,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: p.promptDownloadUrl.isNotEmpty
                      ? palette.linkAccent
                      : palette.textPrimary,
                  hoverColor: palette.linkAccent,
                  onTap: () {
                    if (p.promptDownloadUrl.isNotEmpty) {
                      triggerMielFileDownload(
                        context,
                        ref,
                        url: p.promptDownloadUrl,
                        fallbackFileName: p.title,
                      );
                    } else {
                      setState(() => _selectedPractice = p);
                    }
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (p.deliveryType.isNotEmpty)
                      Text(
                        'Modalidad: ${p.deliveryType}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: palette.textSecondary,
                        ),
                      ),
                    Text(
                      'Venc.: ${p.dueDate.isEmpty ? "---" : p.dueDate}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textSecondary,
                      ),
                    ),
                    Text(
                      'Estado: ${p.status.isEmpty ? "---" : p.status}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (p.grade.isNotEmpty)
                      Text(
                        'Nota: ${p.grade}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: palette.linkAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    MielActionButton(
                      label: 'ENTREGAR / VER',
                      primary: true,
                      onPressed: () => setState(() => _selectedPractice = p),
                    ),
                    if (p.promptDownloadUrl.isNotEmpty)
                      MielActionButton(
                        label: 'Descargar consigna',
                        icon: Icons.file_download,
                        onPressed: () => triggerMielFileDownload(
                          context,
                          ref,
                          url: p.promptDownloadUrl,
                          fallbackFileName: p.title,
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

  // --- Detalle de una Práctica: Entrega de prácticas (02_portafolio_entrega_dark.png) ---

  Widget _buildPracticeDetailView(
    BuildContext context,
    PortfolioPractice practice,
    bool isCompact,
  ) {
    final palette = MielPalette.of(context);
    final detailAsync = ref.watch(
      portafolioEntregasDetalleProvider((
        idComision: widget.subject.idComision,
        idPractica: practice.idPractica,
      )),
    );
    final webUrl = practice.detailUrl.isNotEmpty
        ? practice.detailUrl
        : '$kMielBaseUrl/portafolio/entregas/comision/${widget.subject.idComision}/id/${practice.idPractica}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Entrega de prácticas',
          trailing: MielActionButton(
            label: 'Volver',
            primary: true,
            onPressed: () => setState(() => _selectedPractice = null),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text(
              [
                if (practice.moduleName.isNotEmpty) practice.moduleName,
                practice.title,
              ].join(' - '),
              style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
            ),
            if (practice.promptDownloadUrl.isNotEmpty) ...[
              Text('·', style: TextStyle(color: palette.textMuted)),
              MielHoverLink(
                text: '[Descargar]',
                fontSize: 13.5,
                onTap: () => triggerMielFileDownload(
                  context,
                  ref,
                  url: practice.promptDownloadUrl,
                  fallbackFileName: practice.title,
                ),
              ),
            ],
          ],
        ),
        if (practice.deliveryType.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Entrega ${practice.deliveryType.toLowerCase()}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ],
        const SizedBox(height: 16),

        detailAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando entregas y formulario de envío…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudo cargar el detalle de entregas: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(
              portafolioEntregasDetalleProvider((
                idComision: widget.subject.idComision,
                idPractica: practice.idPractica,
              )),
            ),
          ),
          data: (detail) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (detail.submissionForm.canSubmit)
                  PortafolioSubmissionCard(
                    idComision: widget.subject.idComision,
                    idPractica: practice.idPractica,
                    practiceTitle: practice.title,
                    formMeta: detail.submissionForm,
                    webUrl: webUrl,
                    onSubmitted: () {
                      ref.invalidate(
                        portafolioEntregasDetalleProvider((
                          idComision: widget.subject.idComision,
                          idPractica: practice.idPractica,
                        )),
                      );
                      ref.invalidate(
                        portafolioPracticasProvider(widget.subject.idComision),
                      );
                      ref.invalidate(
                        portafolioArchivosEnviadosProvider(
                          widget.subject.idComision,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.cardBackground,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Esta práctica no tiene formulario de nueva entrega habilitado en este momento.',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                        MielActionButton(
                          label: 'Ver en MIeL',
                          icon: Icons.open_in_new,
                          onPressed: () => openMielExternalUrl(webUrl),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                if (detail.corrections.isEmpty && detail.deliveries.isEmpty)
                  const MielModuleEmptyView(
                    message: 'Aún no se registran entregas ni correcciones para esta práctica.',
                    icon: Icons.history,
                  )
                else ...[
                  for (final corr in detail.corrections)
                    _buildCorrectionBlock(palette, corr, isCompact),
                  for (final deliv in detail.deliveries)
                    _buildDeliveryBlock(context, palette, deliv, isCompact),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: MielActionButton(
                    label: 'Volver',
                    primary: true,
                    onPressed: () => setState(() => _selectedPractice = null),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCorrectionBlock(
    MielPalette palette,
    PortfolioCorrection corr,
    bool isCompact,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: palette.paleGreenBackground.withValues(alpha: 0.45),
        border: Border(top: BorderSide(color: palette.primary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CORRECCIÓN DOCENTE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.linkAccent,
            ),
          ),
          const SizedBox(height: 8),
          _buildGridField(
            palette,
            'Fecha y hora:',
            Text(
              corr.dateTime.isEmpty ? '---' : corr.dateTime,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Estado:',
            Text(
              corr.status.isEmpty ? '---' : corr.status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Calificación:',
            Text(
              corr.grade.isEmpty ? '---' : corr.grade,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.linkAccent,
              ),
            ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Observaciones:',
            SelectableText(
              corr.observations.isEmpty ? '---' : corr.observations,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Corregido por:',
            Text(
              corr.correctedBy.isEmpty ? '---' : corr.correctedBy,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBlock(
    BuildContext context,
    MielPalette palette,
    PortfolioDelivery deliv,
    bool isCompact,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.textMuted.withValues(alpha: 0.65)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deliv.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildGridField(
            palette,
            'Fecha y hora:',
            Text(
              deliv.dateTime.isEmpty ? '---' : deliv.dateTime,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Práctica enviada:',
            deliv.downloadUrl.isNotEmpty
                ? MielHoverLink(
                    text: deliv.fileName,
                    leadingIcon: Icons.attach_file,
                    leadingIconSize: 18,
                    leadingIconColor: palette.textMuted,
                    fontSize: 13,
                    onTap: () => triggerMielFileDownload(
                      context,
                      ref,
                      url: deliv.downloadUrl,
                      fallbackFileName: deliv.fileName,
                    ),
                  )
                : Text(
                    deliv.fileName.isEmpty ? '---' : deliv.fileName,
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Entrega grupal:',
            deliv.isGroupDelivery
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                          children: [
                            const TextSpan(text: 'SÍ'),
                            if (deliv.groupName.isNotEmpty) ...[
                              const TextSpan(text: ' - '),
                              TextSpan(
                                text: deliv.groupName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      for (final member in deliv.members)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '- $member',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  )
                : Text(
                    'NO',
                    style: TextStyle(fontSize: 13, color: palette.textPrimary),
                  ),
            isCompact,
          ),
          _buildGridField(
            palette,
            'Mensaje:',
            SelectableText(
              deliv.message.isEmpty ? '---' : deliv.message,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
            isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildGridField(
    MielPalette palette,
    String label,
    Widget valueWidget,
    bool isCompact,
  ) {
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.5, color: palette.textMuted),
            ),
            const SizedBox(height: 2),
            valueWidget,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: palette.textPrimary),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  // --- Pestaña 1: Archivos enviados ---

  Widget _buildArchivosEnviadosTab(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl =
        '$kMielBaseUrl/portafolio/archivosEnviados/comision/$idComision';
    final filesAsync = ref.watch(
      portafolioArchivosEnviadosProvider(idComision),
    );

    TextStyle headerStyle() => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MielModuleHeader(title: 'Prácticas: Archivos enviados'),
        const SizedBox(height: 16),
        filesAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando archivos enviados…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar los archivos enviados: $err',
            mielWebUrl: webUrl,
            onRetry: () =>
                ref.invalidate(portafolioArchivosEnviadosProvider(idComision)),
          ),
          data: (files) {
            if (files.isEmpty) {
              return const MielModuleEmptyView(
                message: 'Aún no ha enviado ningún archivo.',
                icon: Icons.file_upload_outlined,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera oficial MIeL: Archivo o enlace enviado | Fecha y hora | Tamaño | Descargar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.divider, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Archivo o enlace enviado',
                          style: headerStyle(),
                        ),
                      ),
                      if (!isCompact) ...[
                        SizedBox(
                          width: 170,
                          child: Text('Fecha y hora', style: headerStyle()),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Tamaño',
                            textAlign: TextAlign.right,
                            style: headerStyle(),
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Text(
                          'Descargar',
                          textAlign: TextAlign.center,
                          style: headerStyle(),
                        ),
                      ),
                    ],
                  ),
                ),

                for (final f in files)
                  MielHoverRow(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: MielFileTypeIcon(
                              fileType: f.fileType,
                              size: 22,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.practiceTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (f.fileName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    f.fileName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                              if (isCompact)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    [
                                      if (f.dateTime.isNotEmpty) f.dateTime,
                                      if (f.sizeLabel.isNotEmpty) f.sizeLabel,
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!isCompact) ...[
                          SizedBox(
                            width: 170,
                            child: Text(
                              f.dateTime,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              f.sizeLabel,
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
                          width: 90,
                          child: Center(
                            child: f.downloadUrl.isNotEmpty
                                ? Tooltip(
                                    message: 'Descargar archivo enviado',
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => triggerMielFileDownload(
                                          context,
                                          ref,
                                          url: f.downloadUrl,
                                          fallbackFileName: f.fileName,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.file_download,
                                            size: 22,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
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

  // --- Pestaña 2: Mis grupos ---

  Widget _buildGruposTab(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/portafolio/grupos/comision/$idComision';
    final groupsAsync = ref.watch(portafolioGruposProvider(idComision));

    TextStyle headerStyle() => TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: palette.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MielModuleHeader(title: 'Mis grupos'),
        const SizedBox(height: 16),
        groupsAsync.when(
          loading: () =>
              const MielModuleLoadingView(message: 'Consultando grupos…'),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar los grupos: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(portafolioGruposProvider(idComision)),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return const MielModuleEmptyView(
                message: 'No se le asignó ningún grupo en esta comisión.',
                icon: Icons.group_outlined,
              );
            }

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final g in groups)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.cardBackground,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (g.messageUrl.isNotEmpty)
                                MielHoverLink(
                                  text: '[Enviar mensaje]',
                                  fontWeight: FontWeight.w700,
                                  onTap: () =>
                                      openMielExternalUrl(g.messageUrl),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final member in g.members)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                member,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.divider, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('Nombre del grupo', style: headerStyle()),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text('Integrantes', style: headerStyle()),
                      ),
                      SizedBox(
                        width: 240,
                        child: Text('Opciones', style: headerStyle()),
                      ),
                    ],
                  ),
                ),
                for (final g in groups)
                  MielHoverRow(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            g.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final member in g.members)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    member,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 240,
                          child: g.messageUrl.isNotEmpty
                              ? MielHoverLink(
                                  text: '[Enviar mensaje]',
                                  fontWeight: FontWeight.w700,
                                  onTap: () =>
                                      openMielExternalUrl(g.messageUrl),
                                )
                              : const SizedBox.shrink(),
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

  // --- Pestaña 3: Asistencia, notas y certificados (02_portafolio_notas_dark.png) ---

  Widget _buildNotasAsistenciaTab(BuildContext context, bool isCompact) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/portafolio/notas/comision/$idComision';
    final notasAsync = ref.watch(portafolioNotasProvider(idComision));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presentColor = isDark
        ? const Color(0xFF59A15B)
        : const Color(0xFF4CAF50);
    final justifiedColor = isDark
        ? const Color(0xFF4F90C4)
        : const Color(0xFF2196F3);
    final absentColor = isDark
        ? const Color(0xFFEA4A3E)
        : const Color(0xFFF44336);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MielModuleHeader(title: 'Asistencia, notas y certificados'),
        const SizedBox(height: 18),
        notasAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando asistencia, notas y certificados…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudo cargar asistencia y notas: $err',
            mielWebUrl: webUrl,
            onRetry: () => ref.invalidate(portafolioNotasProvider(idComision)),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Asistencia
              Text(
                'Asistencia',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (data.attendance.isEmpty)
                Text(
                  'No hay registros de asistencia cargados en MIeL.',
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 14,
                  children: [
                    for (final a in data.attendance)
                      SizedBox(
                        width: 90,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.date,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: a.isPresent
                                    ? presentColor
                                    : (a.isJustified
                                          ? justifiedColor
                                          : absentColor),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                a.status,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.modality,
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

              const SizedBox(height: 26),

              // 2. Notas de evaluación y autoevaluación
              Text(
                'Notas de evaluación y autoevaluación',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              if (data.evaluationGrades.isEmpty)
                Text(
                  'No hay evaluaciones o autoevaluaciones realizadas en MIeL.',
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in data.evaluationGrades)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: palette.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (g.date.isNotEmpty) ...[
                              Text(
                                g.date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Text(
                              g.grade,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: palette.linkAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 26),

              // 3. Certificados
              Text(
                'Certificados',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              if (data.certificates.isEmpty)
                Text(
                  'No se encontraron certificados para este curso.',
                  style: TextStyle(fontSize: 13, color: palette.textPrimary),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final c in data.certificates)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.verified_outlined,
                          color: palette.linkAccent,
                        ),
                        title: Text(c.title),
                        subtitle: c.date.isNotEmpty ? Text(c.date) : null,
                        trailing: MielActionButton(
                          label: 'Descargar',
                          icon: Icons.file_download,
                          onPressed: () => triggerMielFileDownload(
                            context,
                            ref,
                            url: c.downloadUrl,
                            fallbackFileName: c.title,
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
}
