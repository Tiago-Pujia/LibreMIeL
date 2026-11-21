import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/downloads/bulk_download_manager.dart';
import '../../core/storage/app_database.dart';
import '../../core/theme/miel_theme.dart';
import '../../platform/file_download_service.dart';
import '../modules/widgets/module_state_views.dart';

/// Abre el diálogo o modal de respaldo offline / descarga masiva.
Future<void> showBulkDownloadDialog(
  BuildContext context, {
  Subject? initialSubject,
}) {
  final isMobile = MediaQuery.of(context).size.width < 640;
  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BulkDownloadDialogContent(
        initialSubject: initialSubject,
        isSheet: true,
      ),
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: _BulkDownloadDialogContent(
          initialSubject: initialSubject,
          isSheet: false,
        ),
      ),
    ),
  );
}

class _BulkDownloadDialogContent extends ConsumerStatefulWidget {
  const _BulkDownloadDialogContent({
    this.initialSubject,
    required this.isSheet,
  });

  final Subject? initialSubject;
  final bool isSheet;

  @override
  ConsumerState<_BulkDownloadDialogContent> createState() =>
      _BulkDownloadDialogContentState();
}

class _BulkDownloadDialogContentState
    extends ConsumerState<_BulkDownloadDialogContent> {
  BulkDownloadManager? _manager;
  StreamSubscription<BulkDownloadProgress>? _progressSub;
  BulkDownloadProgress _progress = const BulkDownloadProgress();

  String _destinationPath = '';
  bool _includeContenidos = true;
  bool _includeForos = true;
  bool _exportMarkdown = true;
  bool _exportJson = true;
  bool _exportHtml = true;
  static const bool _downloadForumAttachments = true;
  bool _incremental = true;

  bool _downloadAllSubjects = false;
  final Set<String> _selectedCommissionIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null) {
      _selectedCommissionIds.add(widget.initialSubject!.idComision);
    } else {
      _downloadAllSubjects = true;
    }
    _initDefaultDestination();
  }

  Future<void> _initDefaultDestination() async {
    const downloadService = FileDownloadService();
    final defaultDir = await downloadService.resolveDownloadsDirectory();
    final target = Directory(p.join(defaultDir.path, 'Respaldos'));
    if (mounted) {
      setState(() {
        _destinationPath = target.path;
      });
    }
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _manager?.dispose();
    super.dispose();
  }

  Future<void> _pickDestinationFolder() async {
    final selected = await getDirectoryPath(
      confirmButtonText: 'Seleccionar carpeta de respaldo',
    );
    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        _destinationPath = selected;
      });
    }
  }

  Future<void> _startDownload(List<Subject> allSubjects) async {
    final subjectsToBackup = _downloadAllSubjects
        ? allSubjects
        : allSubjects
              .where((s) => _selectedCommissionIds.contains(s.idComision))
              .toList();

    if (subjectsToBackup.isEmpty) {
      showMielStatusToast(
        context,
        message: 'Seleccioná al menos una materia para respaldar.',
        isError: true,
      );
      return;
    }

    if (!_includeContenidos && !_includeForos) {
      showMielStatusToast(
        context,
        message: 'Seleccioná al menos un módulo (Contenidos o Foros).',
        isError: true,
      );
      return;
    }

    final client = await ref.read(mielInteractiveReaderProvider.future);
    final database = ref.read(databaseProvider);

    _manager = BulkDownloadManager(
      client: client,
      database: database,
      ensureActiveSession: () async {
        await ref
            .read(appSessionProvider.notifier)
            .ensureActiveSession(forceRelogin: true);
      },
    );

    _progressSub = _manager!.progressStream.listen((prog) {
      if (mounted) {
        setState(() {
          _progress = prog;
        });
      }
    });

    final options = BulkDownloadOptions(
      subjects: subjectsToBackup,
      baseDirectory: _destinationPath,
      includeContenidos: _includeContenidos,
      includeForos: _includeForos,
      exportMarkdown: _exportMarkdown,
      exportJson: _exportJson,
      exportHtml: _exportHtml,
      downloadForumAttachments: _downloadForumAttachments,
      incremental: _incremental,
    );

    await _manager!.start(options);
  }

  Future<void> _openDestinationFolder() async {
    if (_destinationPath.isEmpty) return;
    final dir = Directory(_destinationPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    try {
      if (!kIsWeb) {
        if (Platform.isLinux) {
          await Process.run('xdg-open', [_destinationPath]);
          return;
        } else if (Platform.isMacOS) {
          await Process.run('open', [_destinationPath]);
          return;
        } else if (Platform.isWindows) {
          await Process.run('explorer.exe', [_destinationPath]);
          return;
        }
      }
      await launchUrl(Uri.directory(_destinationPath));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final allSubjects = subjectsAsync.value ?? const <Subject>[];

    final isRunning = _progress.isRunning;
    final isFinished = _progress.isFinished;

    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: widget.isSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.download_for_offline_rounded,
              color: palette.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Respaldo Offline de Materias',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Descarga organizada de contenidos y foros completos de MIeL.',
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          if (!isRunning)
            IconButton(
              icon: const Icon(Icons.close),
              color: palette.textSecondary,
              tooltip: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: widget.isSheet
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: isRunning || isFinished
                  ? _buildProgressView(palette, isDark)
                  : _buildConfigForm(palette, allSubjects),
            ),
          ),
          _buildFooterActions(palette, allSubjects),
        ],
      ),
    );
  }

  Widget _buildConfigForm(MielPalette palette, List<Subject> allSubjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Selector de Materias
        Text(
          'Materias a respaldar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: palette.inputBackground,
            border: Border.all(color: palette.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _downloadAllSubjects = false;
                    if (_selectedCommissionIds.isEmpty) {
                      if (widget.initialSubject != null) {
                        _selectedCommissionIds.add(
                          widget.initialSubject!.idComision,
                        );
                      } else {
                        _selectedCommissionIds.addAll(
                          allSubjects.map((s) => s.idComision),
                        );
                      }
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        !_downloadAllSubjects
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !_downloadAllSubjects
                            ? palette.primary
                            : palette.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.initialSubject != null
                              ? 'Solo esta materia (${widget.initialSubject!.name})'
                              : 'Materias seleccionadas (${_selectedCommissionIds.length}/${allSubjects.length})',
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
              if (!_downloadAllSubjects) ...[
                const Divider(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Elegí qué materias respaldar:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          MielHoverLink(
                            text: 'Todas',
                            fontSize: 11.5,
                            onTap: () {
                              setState(() {
                                _selectedCommissionIds
                                  ..clear()
                                  ..addAll(
                                    allSubjects.map((s) => s.idComision),
                                  );
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          MielHoverLink(
                            text: 'Ninguna',
                            fontSize: 11.5,
                            onTap: () {
                              setState(() {
                                _selectedCommissionIds.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.cardBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: allSubjects.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: palette.divider),
                      itemBuilder: (context, idx) {
                        final subj = allSubjects[idx];
                        final isChecked = _selectedCommissionIds.contains(
                          subj.idComision,
                        );
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: palette.primary,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          title: Text(
                            subj.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.textPrimary,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedCommissionIds.add(subj.idComision);
                              } else {
                                _selectedCommissionIds.remove(subj.idComision);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
              const Divider(height: 12),
              InkWell(
                onTap: () => setState(() => _downloadAllSubjects = true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _downloadAllSubjects
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _downloadAllSubjects
                            ? palette.primary
                            : palette.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Todas las materias activas (${allSubjects.length})',
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
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Módulos a respaldar
        Text(
          'Módulos incluidos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _includeContenidos,
          activeColor: palette.primary,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Contenidos (archivos, PDFs y carpetas de la cátedra)',
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
          ),
          subtitle: Text(
            'Genera además el índice de enlaces externos (YouTube, Drive, etc.)',
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
          onChanged: (val) {
            if (val != null) setState(() => _includeContenidos = val);
          },
        ),
        CheckboxListTile(
          value: _includeForos,
          activeColor: palette.primary,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Foros de debate (hilos, mensajes y respuestas)',
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
          ),
          onChanged: (val) {
            if (val != null) setState(() => _includeForos = val);
          },
        ),

        // Formatos de Foros
        if (_includeForos) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formatos de exportación de foros:',
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      selected: _exportMarkdown,
                      label: const Text('Markdown (.md)'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: _exportMarkdown
                            ? Colors.white
                            : palette.textPrimary,
                      ),
                      selectedColor: palette.primary,
                      checkmarkColor: Colors.white,
                      onSelected: (val) =>
                          setState(() => _exportMarkdown = val),
                    ),
                    FilterChip(
                      selected: _exportJson,
                      label: const Text('JSON (.json)'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: _exportJson ? Colors.white : palette.textPrimary,
                      ),
                      selectedColor: palette.primary,
                      checkmarkColor: Colors.white,
                      onSelected: (val) => setState(() => _exportJson = val),
                    ),
                    FilterChip(
                      selected: _exportHtml,
                      label: const Text('HTML Offline (.html)'),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: _exportHtml ? Colors.white : palette.textPrimary,
                      ),
                      selectedColor: palette.primary,
                      checkmarkColor: Colors.white,
                      onSelected: (val) => setState(() => _exportHtml = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // 3. Opciones avanzadas
        Text(
          'Opciones de descarga',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          value: _incremental,
          activeColor: palette.primary,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Modo incremental (omitir archivos ya descargados)',
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
          ),
          subtitle: Text(
            'Ahorra tiempo y ancho de banda al bajar solo material nuevo o modificado.',
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
          onChanged: (val) {
            if (val != null) setState(() => _incremental = val);
          },
        ),
        const SizedBox(height: 14),

        // 4. Carpeta de destino
        Text(
          'Carpeta de destino',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: palette.inputBackground,
            border: Border.all(color: palette.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, color: palette.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _destinationPath.isNotEmpty
                      ? _destinationPath
                      : 'Cargando carpeta...',
                  style: TextStyle(fontSize: 12, color: palette.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Examinar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primary,
                  side: BorderSide(color: palette.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: _pickDestinationFolder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressView(MielPalette palette, bool isDark) {
    final frac = _progress.progressFraction;
    final pct = (frac * 100).toInt();
    final mb = (_progress.totalBytesDownloaded / (1024 * 1024)).toStringAsFixed(
      1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_progress.isFinished) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Respaldo completado con éxito!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Todos los archivos y foros fueron organizados en la carpeta de destino.',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Barra de progreso
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _progress.isFinished
                  ? 'Resumen del respaldo'
                  : _progress.isPaused
                  ? 'Respaldo pausado'
                  : 'Descargando...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: palette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress.totalItems > 0 ? frac : null,
            minHeight: 10,
            backgroundColor: palette.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Ítem actual
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              if (_progress.isRunning && !_progress.isPaused)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.primary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _progress.currentItemLabel.isNotEmpty
                      ? _progress.currentItemLabel
                      : 'Procesando...',
                  style: TextStyle(fontSize: 12, color: palette.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Métricas
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                palette,
                'Completados',
                '${_progress.completedItems}',
                palette.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                palette,
                'Omitidos',
                '${_progress.skippedItems}',
                palette.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                palette,
                'Descargado',
                '$mb MB',
                palette.primary,
              ),
            ),
            if (_progress.failedItems > 0) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricBox(
                  palette,
                  'Errores',
                  '${_progress.failedItems}',
                  palette.badgeRed,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Ubicación
        Text(
          'Destino: $_destinationPath',
          style: TextStyle(fontSize: 11, color: palette.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    MielPalette palette,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(MielPalette palette, List<Subject> allSubjects) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = _progress.isRunning;
    final isFinished = _progress.isFinished;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: widget.isSheet
            ? null
            : const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isRunning) ...[
            OutlinedButton(
              onPressed: () => _manager?.cancel(),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.badgeRed,
                side: BorderSide(color: palette.badgeRed),
              ),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: Icon(
                _progress.isPaused ? Icons.play_arrow : Icons.pause,
                size: 18,
              ),
              label: Text(_progress.isPaused ? 'Reanudar' : 'Pausar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_progress.isPaused) {
                  _manager?.resume();
                } else {
                  _manager?.pause();
                }
              },
            ),
          ] else if (isFinished) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Abrir carpeta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.primary),
              ),
              onPressed: _openDestinationFolder,
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Iniciar Respaldo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _startDownload(allSubjects),
            ),
          ],
        ],
      ),
    );
  }
}
