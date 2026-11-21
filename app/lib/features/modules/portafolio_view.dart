import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models/miel_models.dart';
import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/miel_file_icon.dart';
import 'widgets/module_state_views.dart';

/// Vista nativa de lectura del módulo **Portafolio** (`Prácticas`, `Entrega de prácticas`,
/// `Archivos enviados`, `Mis grupos`, `Asistencia, notas y cert.` y `Competencias`)
/// fiel a MIeL (`2025.2.0`).
class PortafolioView extends ConsumerStatefulWidget {
  const PortafolioView({
    super.key,
    required this.subject,
    required this.sectionIndex,
  });

  final Subject subject;
  final int sectionIndex;

  @override
  ConsumerState<PortafolioView> createState() => _PortafolioViewState();
}

class _PortafolioViewState extends ConsumerState<PortafolioView> {
  PortfolioPractice? _selectedPractice;

  @override
  void didUpdateWidget(covariant PortafolioView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionIndex != widget.sectionIndex ||
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
            4 => _buildCompetenciasTab(context),
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
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MielActionButton(
                label: 'Actualizar',
                icon: Icons.refresh,
                onPressed: () =>
                    ref.invalidate(portafolioPracticasProvider(idComision)),
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
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.divider)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedPractice = p),
                hoverColor: palette.cardHover.withValues(alpha: 0.45),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
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
                            if (p.promptDownloadUrl.isNotEmpty)
                              InkWell(
                                onTap: () => triggerMielFileDownload(
                                  context,
                                  ref,
                                  url: p.promptDownloadUrl,
                                  fallbackFileName: p.title,
                                ),
                                child: Text(
                                  p.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.linkAccent,
                                  ),
                                ),
                              )
                            else
                              Text(
                                p.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.textPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 95,
                        child: Text(
                          p.deliveryType.isEmpty ? '---' : p.deliveryType,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 95,
                        child: Text(
                          p.dueDate.isEmpty ? '---' : p.dueDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 135,
                        child: Text(
                          '[ENTREGAR / VER]',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.linkAccent,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 95,
                        child: Text(
                          p.deliveryDate.isEmpty ? '---' : p.deliveryDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 95,
                        child: Text(
                          p.correctionDate.isEmpty ? '---' : p.correctionDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
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
              ),
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
                Text(
                  p.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
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
              InkWell(
                onTap: () => triggerMielFileDownload(
                  context,
                  ref,
                  url: practice.promptDownloadUrl,
                  fallbackFileName: practice.title,
                ),
                child: Text(
                  '[Descargar]',
                  style: TextStyle(fontSize: 13.5, color: palette.linkAccent),
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

        // Panel Nueva entrega (en Fase 2 es de solo lectura con acceso directo a MIeL web)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva entrega',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'La Fase 2 de LibreMIEL es de lectura segura. Para adjuntar y enviar una nueva entrega '
                'de esta práctica, abrila directamente en MIeL.',
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              MielActionButton(
                label: 'Enviar práctica en MIeL',
                icon: Icons.open_in_new,
                primary: true,
                onPressed: () => openMielExternalUrl(webUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        detailAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando historial de entregas y devoluciones…',
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
            if (detail.corrections.isEmpty && detail.deliveries.isEmpty) {
              return const MielModuleEmptyView(
                message: 'Aún no se registran entregas ni correcciones para esta práctica.',
                icon: Icons.history,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final corr in detail.corrections)
                  _buildCorrectionBlock(palette, corr, isCompact),
                for (final deliv in detail.deliveries)
                  _buildDeliveryBlock(context, palette, deliv, isCompact),
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
                ? InkWell(
                    onTap: () => triggerMielFileDownload(
                      context,
                      ref,
                      url: deliv.downloadUrl,
                      fallbackFileName: deliv.fileName,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 18,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            deliv.fileName,
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.linkAccent,
                            ),
                          ),
                        ),
                      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Prácticas: Archivos enviados',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
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
                for (final f in files)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: palette.divider),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: f.downloadUrl.isNotEmpty
                            ? () => triggerMielFileDownload(
                                context,
                                ref,
                                url: f.downloadUrl,
                                fallbackFileName: f.fileName,
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              MielFileTypeIcon(fileType: f.fileType, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.practiceTitle,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    if (f.fileName != f.practiceTitle)
                                      Text(
                                        f.fileName,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isCompact) ...[
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    f.dateTime,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
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
                              const SizedBox(width: 16),
                              Icon(
                                Icons.file_download,
                                size: 22,
                                color: palette.linkAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Mis grupos',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
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
                              InkWell(
                                onTap: () => openMielExternalUrl(g.messageUrl),
                                child: Text(
                                  '[Enviar mensaje]',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: palette.linkAccent,
                                  ),
                                ),
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
    final absentColor = isDark
        ? const Color(0xFFEA4A3E)
        : const Color(0xFFF44336);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Asistencia, notas y certificados',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
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
                                color: a.isPresent ? presentColor : absentColor,
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

  // --- Pestaña 4: Competencias ---

  Widget _buildCompetenciasTab(BuildContext context) {
    final palette = MielPalette.of(context);
    final idComision = widget.subject.idComision;
    final webUrl = '$kMielBaseUrl/portafolio/competencias/comision/$idComision';
    final compAsync = ref.watch(portafolioCompetenciasProvider(idComision));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MielModuleHeader(
          title: 'Competencias',
          trailing: MielActionButton(
            label: 'Abrir en MIeL',
            icon: Icons.open_in_new,
            onPressed: () => openMielExternalUrl(webUrl),
          ),
        ),
        const SizedBox(height: 16),
        compAsync.when(
          loading: () => const MielModuleLoadingView(
            message: 'Consultando evaluación por competencias…',
          ),
          error: (err, _) => MielModuleErrorView(
            message: 'No se pudieron cargar las competencias: $err',
            mielWebUrl: webUrl,
            onRetry: () =>
                ref.invalidate(portafolioCompetenciasProvider(idComision)),
          ),
          data: (comp) {
            if (!comp.isEnabled || comp.rows.isEmpty) {
              return Text(
                comp.emptyMessage.isNotEmpty ? comp.emptyMessage : 'Esta materia no tiene habilitada la evaluación por competencias.',
                style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in comp.rows)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: palette.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r.level,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.linkAccent,
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
