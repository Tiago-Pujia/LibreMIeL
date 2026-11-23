import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_providers.dart';
import '../../../core/models/miel_models.dart';
import '../../../core/theme/miel_theme.dart';

/// Banner global persistente que informa al estudiante cuando los servidores
/// de MIeL están caídos o el equipo está sin conexión a internet (Fase 9).
class MielStatusBanner extends ConsumerWidget {
  const MielStatusBanner({super.key});

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final status = session.serverStatus;

    if (status == MielServerStatus.online) {
      return const SizedBox.shrink();
    }

    final palette = MielPalette.of(context);
    final isMielDown = status == MielServerStatus.mielDown;

    final bannerBg = isMielDown
        ? (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF332200)
              : const Color(0xFFFFF8E1))
        : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E2836)
              : const Color(0xFFE3F2FD));

    final bannerBorder = isMielDown
        ? const Color(0xFFFFB300)
        : const Color(0xFF64B5F6);

    final iconColor = isMielDown
        ? const Color(0xFFF57C00)
        : const Color(0xFF1976D2);

    final title = isMielDown
        ? 'Los servidores de MIeL no responden'
        : 'Sin conexión a internet';

    final lastSync = session.lastOnlineSuccessAt ?? session.lastSyncAt;
    final lastSyncText = lastSync != null
        ? ' · Última actualización: ${_formatDateTime(lastSync)}'
        : '';

    final subtitle = session.offlineModeEnabled
        ? (isMielDown
              ? 'Estás viendo copias locales guardadas en tu equipo$lastSyncText.'
              : 'Estás en modo sin conexión consultando datos locales$lastSyncText.')
        : (isMielDown
              ? 'Solo se muestran datos básicos sincronizados. Activá el Modo sin conexión en Ajustes para conservar copias locales$lastSyncText.'
              : 'Activá el Modo sin conexión en Ajustes para consultar copias locales sin internet$lastSyncText.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(color: bannerBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMielDown ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: session.isSyncing
                ? null
                : () => ref.read(appSessionProvider.notifier).retryConnection(),
            icon: session.isSyncing
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  )
                : Icon(Icons.refresh, size: 16, color: iconColor),
            label: Text(
              session.isSyncing ? 'Reintentando…' : 'Reintentar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
