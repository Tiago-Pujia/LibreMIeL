import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/theme/miel_theme.dart';
import '../../platform/updater/update_models.dart';
import '../../platform/updater/updater_controller.dart';
import '../updates/update_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MielPalette.of(context);
    final session = ref.watch(appSessionProvider);
    final controller = ref.read(appSessionProvider.notifier);
    final updater = ref.watch(updaterProvider);
    final updaterNotifier = ref.read(updaterProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final hPad = isCompact ? 16.0 : 26.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajustes',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),

                // Inicio con el sistema
                _SectionHeader(title: 'Inicio del sistema', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: session.autostartSupported
                      ? SwitchListTile(
                          secondary: Icon(
                            Icons.power_settings_new,
                            color: palette.linkAccent,
                          ),
                          title: const Text(
                            'Ejecutar LibreMIeL al iniciar el sistema',
                          ),
                          subtitle: Text(
                            'Inicia la aplicación automáticamente al encender tu equipo '
                            'para recibir notificaciones en segundo plano.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                          value: session.launchAtStartup,
                          onChanged: controller.updateLaunchAtStartup,
                        )
                      : ListTile(
                          leading: Icon(
                            Icons.power_settings_new,
                            color: palette.linkAccent,
                          ),
                          title: const Text(
                            'Inicio automático en segundo plano',
                          ),
                          subtitle: Text(
                            'En Android, la sincronización periódica se reanuda '
                            'automáticamente tras reiniciar el dispositivo.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                ),
                if (!kIsWeb && Platform.isAndroid) ...[
                  const SizedBox(height: 8),
                  _MielPanel(
                    palette: palette,
                    child: ListTile(
                      leading: Icon(
                        Icons.battery_charging_full,
                        color: palette.linkAccent,
                      ),
                      title: const Text('Optimización de batería en Android'),
                      subtitle: Text(
                        'Para recibir notificaciones con la app cerrada, configurá la batería de LibreMIeL en "Sin restricciones" (especialmente en dispositivos Samsung / Xiaomi).',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Sincronización
                _SectionHeader(title: 'Sincronización', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.schedule,
                          color: palette.linkAccent,
                        ),
                        title: const Text(
                          'Frecuencia de comprobación (Ciclo 1)',
                        ),
                        subtitle: Text(
                          'En Android el mínimo del sistema es 15 min para cuidar la batería.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        trailing: DropdownButton<int>(
                          value:
                              const [
                                15,
                                30,
                                60,
                              ].contains(session.syncIntervalMinutes)
                              ? session.syncIntervalMinutes
                              : 15,
                          dropdownColor: palette.dropdownBackground,
                          items: const [
                            DropdownMenuItem(
                              value: 15,
                              child: Text('Cada 15 min'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('Cada 30 min'),
                            ),
                            DropdownMenuItem(
                              value: 60,
                              child: Text('Cada 60 min'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) controller.updateSyncInterval(v);
                          },
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.assignment_turned_in,
                          color: palette.linkAccent,
                        ),
                        title: const Text('Monitorear Evaluaciones abiertas'),
                        subtitle: Text(
                          'Revisa periódicamente la sección Evaluación en materias que la habilitan.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        value: session.monitorEvaluaciones,
                        onChanged: controller.updateMonitorEvaluaciones,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Comportamiento en Foros
                _SectionHeader(
                  title: 'Comportamiento en Foros',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: RadioGroup<ForumSyncMode>(
                    groupValue: session.forumSyncMode,
                    onChanged: (mode) {
                      if (mode != null) controller.updateForumSyncMode(mode);
                    },
                    child: Column(
                      children: [
                        RadioListTile<ForumSyncMode>(
                          value: ForumSyncMode.mentionsAndReplies,
                          activeColor: palette.primary,
                          title: const Text(
                            'Solo si te etiquetan o responden (por defecto)',
                          ),
                          subtitle: Text(
                            'Te avisa únicamente cuando te etiquetan (@mención) o responden a tus mensajes o temas. Foro general desactivado.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                        Divider(height: 1, color: palette.divider),
                        RadioListTile<ForumSyncMode>(
                          value: ForumSyncMode.teacherReplies,
                          activeColor: palette.primary,
                          title: const Text('Solo respuestas de docentes'),
                          subtitle: Text(
                            'Te avisa exclusivamente cuando un docente (Tutor/a) te responde o etiqueta.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                        Divider(height: 1, color: palette.divider),
                        RadioListTile<ForumSyncMode>(
                          value: ForumSyncMode.nonInvasive,
                          activeColor: palette.primary,
                          title: const Text('Actividad general en foros'),
                          subtitle: Text(
                            'Te avisa ante cualquier actividad o tema nuevo en el foro (foro general activado). '
                            'Conserva intactos los contadores de no leídos en MIeL web.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Actualizaciones (Fase 8)
                _SectionHeader(title: 'Actualizaciones', palette: palette),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.system_update_alt,
                          color: palette.linkAccent,
                        ),
                        title: Text(
                          updater.currentVersion.isNotEmpty
                              ? 'Versión instalada: v${updater.currentVersion}'
                              : 'Versión instalada: comprobando…',
                        ),
                        subtitle: Text(
                          updater.hasUpdate && updater.availableRelease != null
                              ? 'Disponible v${updater.availableRelease!.version} — Tocá para actualizar.'
                              : (updater.lastCheckedAt != null
                                    ? 'Última comprobación: ${_formatDateTime(updater.lastCheckedAt!)}'
                                    : 'Aún no se comprobó la versión.'),
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: updater.hasUpdate
                            ? () => UpdateDialog.show(context)
                            : null,
                        trailing: updater.isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : updater.hasUpdate
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  updater.isReadyToInstall
                                      ? 'Lista para instalar'
                                      : '¡Nueva versión!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Divider(height: 1, color: palette.divider),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.autorenew,
                          color: palette.linkAccent,
                        ),
                        title: const Text(
                          'Buscar actualizaciones automáticamente',
                        ),
                        subtitle: Text(
                          'Consulta en segundo plano (máximo una vez cada 24 h) si hay nuevas versiones en GitHub Releases.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        value: updater.isAutoCheckEnabled,
                        onChanged: (v) =>
                            updaterNotifier.setAutoCheckEnabled(v),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(Icons.search, color: palette.linkAccent),
                        title: const Text('Buscar actualizaciones ahora'),
                        subtitle: Text(
                          updater.status == UpdateStatus.upToDate
                              ? 'Estás usando la versión más reciente.'
                              : updater.status == UpdateStatus.error &&
                                    updater.errorMessage != null
                              ? updater.errorMessage!
                              : 'Comprueba manualmente contra GitHub Releases.',
                          style: TextStyle(
                            color: updater.status == UpdateStatus.error
                                ? palette.badgeRed
                                : (updater.status == UpdateStatus.upToDate
                                      ? palette.primary
                                      : palette.textMuted),
                          ),
                        ),
                        onTap: updater.isChecking
                            ? null
                            : () async {
                                if (updater.isReadyToInstall) {
                                  UpdateDialog.show(context);
                                  return;
                                }
                                await updaterNotifier.checkForUpdates(
                                  manual: true,
                                );
                                if (context.mounted) {
                                  final latestState = ref.read(updaterProvider);
                                  if (latestState.hasUpdate ||
                                      latestState.status ==
                                          UpdateStatus.upToDate) {
                                    UpdateDialog.show(context);
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Modo sin conexión y contingencia
                _SectionHeader(
                  title: 'Modo sin conexión y contingencia',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          Icons.cloud_off_rounded,
                          color: palette.linkAccent,
                        ),
                        title: const Text('Modo sin conexión'),
                        subtitle: Text(
                          'Guarda copias locales de las secciones que consultás para seguir usándolas si MIeL se cae o no tenés internet.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        value: session.offlineModeEnabled,
                        onChanged: controller.updateOfflineModeEnabled,
                      ),
                      Divider(height: 1, color: palette.divider),
                      SwitchListTile(
                        secondary: Icon(
                          Icons.cloud_done_outlined,
                          color: palette.linkAccent,
                        ),
                        title: const Text(
                          'Avisar cuando MIeL vuelva a estar en línea',
                        ),
                        subtitle: Text(
                          'Envía una notificación nativa al restablecerse los servidores de MIeL tras una caída.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        value: session.notifyOnMielRecovery,
                        onChanged: controller.updateNotifyOnMielRecovery,
                      ),
                      if (session.offlineModeEnabled) ...[
                        Divider(height: 1, color: palette.divider),
                        SwitchListTile(
                          secondary: Icon(
                            Icons.download_for_offline_outlined,
                            color: palette.linkAccent,
                          ),
                          title: const Text('Precarga segura de solo lectura'),
                          subtitle: Text(
                            'Precarga comisiones y listados seguros en cada sincronización sin alterar badges ni efectos colaterales de MIeL.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                          value: session.offlinePrefetchSafeModules,
                          onChanged:
                              controller.updateOfflinePrefetchSafeModules,
                        ),
                        Divider(height: 1, color: palette.divider),
                        ListTile(
                          leading: Icon(
                            Icons.storage_outlined,
                            color: palette.linkAccent,
                          ),
                          title: const Text(
                            'Límite de almacenamiento del caché',
                          ),
                          subtitle: Text(
                            'Purga automáticamente las páginas e imágenes menos consultadas al superar la cuota.',
                            style: TextStyle(color: palette.textMuted),
                          ),
                          trailing: DropdownButton<int>(
                            value:
                                const [
                                  50,
                                  100,
                                  250,
                                  500,
                                ].contains(session.offlineCacheMaxMb)
                                ? session.offlineCacheMaxMb
                                : 100,
                            dropdownColor: palette.dropdownBackground,
                            items: const [
                              DropdownMenuItem(value: 50, child: Text('50 MB')),
                              DropdownMenuItem(
                                value: 100,
                                child: Text('100 MB'),
                              ),
                              DropdownMenuItem(
                                value: 250,
                                child: Text('250 MB'),
                              ),
                              DropdownMenuItem(
                                value: 500,
                                child: Text('500 MB'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                controller.updateOfflineCacheMaxMb(v);
                              }
                            },
                          ),
                        ),
                        Divider(height: 1, color: palette.divider),
                        _OfflineCacheStatsTile(
                          palette: palette,
                          controller: controller,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Cuenta y Datos Locales
                _SectionHeader(
                  title: 'Cuenta y Datos Locales',
                  palette: palette,
                ),
                const SizedBox(height: 8),
                _MielPanel(
                  palette: palette,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.key_outlined,
                          color: palette.linkAccent,
                        ),
                        title: const Text('Sesión permanente y credenciales'),
                        subtitle: Text(
                          '${ref.read(credentialsStoreProvider).storageBackendLabel}\n'
                          'Se reconecta automáticamente al abrir LibreMIeL; solo cierra sesión cuando vos lo pedís.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        isThreeLine: true,
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(Icons.sync, color: palette.linkAccent),
                        title: const Text(
                          'Forzar sincronización completa ahora',
                        ),
                        subtitle: Text(
                          'Ejecuta Ciclo 1 (panel) y Ciclo 2 (Portafolio/Evaluación).',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: session.isSyncing
                            ? null
                            : () => controller.syncNow(
                                includeCycle2: true,
                                ignoreAuthPause: true,
                              ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(Icons.logout, color: palette.badgeRed),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: palette.badgeRed),
                        ),
                        subtitle: Text(
                          'Elimina credenciales del llavero y detiene alertas.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: () => controller.logout(wipeLocalData: false),
                      ),
                      Divider(height: 1, color: palette.divider),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: palette.badgeRed,
                        ),
                        title: Text(
                          'Cerrar sesión y borrar historial local',
                          style: TextStyle(color: palette.badgeRed),
                        ),
                        subtitle: Text(
                          'Limpia también snapshots, materias y novedades guardadas.',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        onTap: () => controller.logout(wipeLocalData: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});

  final String title;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: palette.linkAccent,
      ),
    );
  }
}

class _MielPanel extends StatelessWidget {
  const _MielPanel({required this.palette, required this.child});

  final MielPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: child,
    );
  }
}

String _formatDateTime(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}

class _OfflineCacheStatsTile extends ConsumerStatefulWidget {
  const _OfflineCacheStatsTile({
    required this.palette,
    required this.controller,
  });

  final MielPalette palette;
  final AppSessionController controller;

  @override
  ConsumerState<_OfflineCacheStatsTile> createState() =>
      _OfflineCacheStatsTileState();
}

class _OfflineCacheStatsTileState
    extends ConsumerState<_OfflineCacheStatsTile> {
  double _cacheMb = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final db = ref.read(databaseProvider);
    final mediaService = ref.read(offlineMediaServiceProvider);
    final pageBytes = await db.getOfflineCacheTotalBytes();
    final mediaBytes = await mediaService.getTotalCachedMediaBytes();
    final totalMb = (pageBytes + mediaBytes) / (1024 * 1024);
    if (mounted) {
      setState(() {
        _cacheMb = totalMb;
        _loading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await widget.controller.clearOfflineCache();
    await _loadCacheSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se vació el caché local de navegación sin conexión.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final sizeText = _loading
        ? 'Calculando peso…'
        : '${_cacheMb.toStringAsFixed(1)} MB de ${session.offlineCacheMaxMb} MB';

    return ListTile(
      leading: Icon(
        Icons.cleaning_services_outlined,
        color: widget.palette.linkAccent,
      ),
      title: Text('Espacio en disco ocupado: $sizeText'),
      subtitle: Text(
        'Páginas HTML, datos estructurados e imágenes cacheadas localmente.',
        style: TextStyle(color: widget.palette.textMuted),
      ),
      trailing: OutlinedButton(
        onPressed: _loading ? null : _clearCache,
        child: const Text('Vaciar caché'),
      ),
    );
  }
}
