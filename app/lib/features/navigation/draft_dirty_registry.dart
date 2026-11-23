import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/miel_theme.dart';

/// Registro centralizado y reactivo de formularios con borradores no guardados (Fase 12).
class DraftDirtyRegistry extends ChangeNotifier {
  final Map<String, ({String label, bool isDirty})> _entries =
      <String, ({String label, bool isDirty})>{};

  void setDirty(
    String ownerKey, {
    required bool isDirty,
    String label = 'este formulario',
  }) {
    final existing = _entries[ownerKey];
    if (existing != null &&
        existing.isDirty == isDirty &&
        existing.label == label) {
      return;
    }
    if (!isDirty) {
      _entries.remove(ownerKey);
    } else {
      _entries[ownerKey] = (label: label, isDirty: true);
    }
    notifyListeners();
  }

  void clearOwner(String ownerKey) {
    if (_entries.remove(ownerKey) != null) {
      notifyListeners();
    }
  }

  void clearAll() {
    if (_entries.isNotEmpty) {
      _entries.clear();
      notifyListeners();
    }
  }

  bool get hasDirtyDrafts => _entries.values.any((e) => e.isDirty);

  List<String> get dirtyLabels => _entries.values
      .where((e) => e.isDirty)
      .map((e) => e.label)
      .toSet()
      .toList();
}

final draftDirtyRegistryProvider = Provider<DraftDirtyRegistry>((ref) {
  final registry = DraftDirtyRegistry();
  ref.onDispose(registry.dispose);
  return registry;
});

/// Muestra un diálogo de confirmación si existen cambios sin guardar en
/// algún formulario activo. Retorna `true` si es seguro navegar/descartar,
/// o `false` si el usuario prefiere quedarse y seguir editando.
Future<bool> confirmDiscardDirtyDraftsIfNeeded(
  BuildContext context,
  DraftDirtyRegistry registry,
) async {
  if (!registry.hasDirtyDrafts) return true;

  final labels = registry.dirtyLabels;
  final labelText = labels.isNotEmpty
      ? labels.join(', ')
      : 'el formulario abierto';

  final palette = MielPalette.of(context);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: palette.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette.cardBorder),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: palette.badgeRed,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '¿Descartar cambios?',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Tenés texto o adjuntos sin enviar en $labelText.\n'
          'Si continuás ahora, se descartarán los cambios.',
          style: TextStyle(color: palette.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Seguir editando',
              style: TextStyle(
                color: palette.linkAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.badgeRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            onPressed: () {
              registry.clearAll();
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Descartar y continuar'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
