import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/miel_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';
import 'module_providers.dart';
import 'widgets/module_state_views.dart';

/// Vista nativa de lectura del módulo **Evaluación** (`05_evaluacion_dark.png`)
/// fiel a MIeL (`2025.2.0`).
class EvaluacionView extends ConsumerWidget {
  const EvaluacionView({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final idComision = subject.idComision;
    final webUrl = '$kMielBaseUrl/evaluacion/evaluaciones/comision/$idComision';
    final evalsAsync = ref.watch(evaluacionesListProvider(idComision));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabledGreen = isDark
        ? const Color(0xFF59A15B)
        : const Color(0xFF4CAF50);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final hPad = isCompact ? 16.0 : 26.0;

        TextStyle headerStyle() => TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MielModuleHeader(
                title: 'Evaluaciones',
                trailing: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MielActionButton(
                      label: 'Actualizar',
                      icon: Icons.refresh,
                      onPressed: () =>
                          ref.invalidate(evaluacionesListProvider(idComision)),
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
              evalsAsync.when(
                loading: () => const MielModuleLoadingView(
                  message: 'Consultando evaluaciones de la materia…',
                ),
                error: (err, _) => MielModuleErrorView(
                  message: 'No se pudieron cargar las evaluaciones: $err',
                  mielWebUrl: webUrl,
                  onRetry: () =>
                      ref.invalidate(evaluacionesListProvider(idComision)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const MielModuleEmptyView(
                      message: 'No hay evaluaciones ni autoevaluaciones publicadas en esta comisión.',
                      icon: Icons.assignment_turned_in_outlined,
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
                            bottom: BorderSide(
                              color: palette.divider,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isCompact ? 105 : 130,
                              child: Text('Tipo', style: headerStyle()),
                            ),
                            Expanded(
                              child: Text('Título', style: headerStyle()),
                            ),
                            if (!isCompact)
                              SizedBox(
                                width: 115,
                                child: Text(
                                  'Habilitado',
                                  textAlign: TextAlign.center,
                                  style: headerStyle(),
                                ),
                              ),
                            const SizedBox(width: 40),
                            if (!isCompact)
                              SizedBox(
                                width: 110,
                                child: Text('Estado', style: headerStyle()),
                              ),
                            SizedBox(
                              width: 90,
                              child: Text('Opciones', style: headerStyle()),
                            ),
                          ],
                        ),
                      ),
                      for (final ev in items)
                        MielHoverRow(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: isCompact ? 105 : 130,
                                child: Text(
                                  ev.type,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ev.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    if (isCompact && ev.status.isNotEmpty)
                                      Text(
                                        ev.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isCompact)
                                SizedBox(
                                  width: 115,
                                  child: Center(
                                    child: Tooltip(
                                      message: ev.isEnabled
                                          ? 'Habilitado para rendir'
                                          : 'No habilitado',
                                      child: Container(
                                        width: 17,
                                        height: 17,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ev.isEnabled
                                              ? enabledGreen
                                              : palette.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 40,
                                child: Tooltip(
                                  message: ev.requiresPassword
                                      ? 'Requiere clave'
                                      : 'Abierto',
                                  child: Icon(
                                    ev.requiresPassword || !ev.isLockOpen
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    size: 20,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              if (!isCompact)
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    ev.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 90,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: MielHoverLink(
                                    text: '[Ingresar]',
                                    fontSize: 13,
                                    onTap: () => openMielExternalUrl(webUrl),
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
          ),
        );
      },
    );
  }
}

/// Vista nativa de lectura del módulo **Encuestas**.
class EncuestasView extends ConsumerWidget {
  const EncuestasView({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final idComision = subject.idComision;
    final webUrl = '$kMielBaseUrl/encuesta/encuestas/comision/$idComision';
    final surveysAsync = ref.watch(encuestasListProvider(idComision));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MielModuleHeader(
                title: 'Encuestas y formularios',
                trailing: MielActionButton(
                  label: 'Abrir en MIeL',
                  icon: Icons.open_in_new,
                  onPressed: () => openMielExternalUrl(webUrl),
                ),
              ),
              const SizedBox(height: 16),
              surveysAsync.when(
                loading: () => const MielModuleLoadingView(
                  message: 'Consultando encuestas y formularios…',
                ),
                error: (err, _) => MielModuleErrorView(
                  message: 'No se pudieron cargar las encuestas: $err',
                  mielWebUrl: webUrl,
                  onRetry: () =>
                      ref.invalidate(encuestasListProvider(idComision)),
                ),
                data: (surveys) {
                  if (surveys.isEmpty) {
                    return Text(
                      'No hay encuestas o formularios disponibles.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: palette.textPrimary,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final s in surveys)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                color: palette.linkAccent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    if (s.status.isNotEmpty)
                                      Text(
                                        s.status,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              MielActionButton(
                                label: 'Completar en MIeL',
                                primary: true,
                                onPressed: () => openMielExternalUrl(s.url),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vista nativa de lectura del módulo **Autoguía**.
class AutoguiaView extends ConsumerWidget {
  const AutoguiaView({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final idComision = subject.idComision;
    final webUrl = '$kMielBaseUrl/autoguia/modulos/comision/$idComision';
    final autoguiaAsync = ref.watch(autoguiaListProvider(idComision));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MielModuleHeader(
                title: 'Autoguía',
                trailing: MielActionButton(
                  label: 'Abrir en MIeL',
                  icon: Icons.open_in_new,
                  onPressed: () => openMielExternalUrl(webUrl),
                ),
              ),
              const SizedBox(height: 16),
              autoguiaAsync.when(
                loading: () => const MielModuleLoadingView(
                  message: 'Consultando unidades de la autoguía…',
                ),
                error: (err, _) => MielModuleErrorView(
                  message: 'No se pudo cargar la autoguía: $err',
                  mielWebUrl: webUrl,
                  onRetry: () =>
                      ref.invalidate(autoguiaListProvider(idComision)),
                ),
                data: (modules) {
                  if (modules.isEmpty) {
                    return MielModuleEmptyView(
                      message: 'No se encontraron módulos de autoguía activos para esta comisión.',
                      icon: Icons.auto_stories_outlined,
                      action: MielActionButton(
                        label: 'Abrir Autoguía en MIeL web',
                        icon: Icons.open_in_new,
                        primary: true,
                        onPressed: () => openMielExternalUrl(webUrl),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final m in modules)
                        Container(
                          width: isCompact ? double.infinity : 300,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.cardBackground,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${m.progressPercent}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (m.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  m.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              MielActionButton(
                                label: 'Ver módulo',
                                icon: Icons.open_in_new,
                                primary: true,
                                onPressed: () => openMielExternalUrl(m.url),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
