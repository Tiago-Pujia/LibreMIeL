import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/features/navigation/draft_dirty_registry.dart';

void main() {
  group('DraftDirtyRegistry Tests (Fase 12)', () {
    late ProviderContainer container;
    late DraftDirtyRegistry registry;

    setUp(() {
      container = ProviderContainer();
      registry = container.read(draftDirtyRegistryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('Inicia vacío y hasDirtyDrafts es false', () {
      expect(registry.hasDirtyDrafts, false);
      expect(registry.dirtyLabels, isEmpty);
    });

    test('Registra y desmarca estado sucio de un propietario', () {
      registry.setDirty('composer_1', isDirty: true, label: 'nuevo mensaje');
      expect(registry.hasDirtyDrafts, true);
      expect(registry.dirtyLabels, contains('nuevo mensaje'));

      registry.setDirty('composer_1', isDirty: false, label: 'nuevo mensaje');
      expect(registry.hasDirtyDrafts, false);
      expect(registry.dirtyLabels, isEmpty);
    });

    test('Maneja múltiples formularios sucios concurrentes', () {
      registry.setDirty('composer', isDirty: true, label: 'redacción');
      registry.setDirty(
        'foro_reply',
        isDirty: true,
        label: 'respuesta en foro',
      );
      registry.setDirty(
        'portfolio_task',
        isDirty: true,
        label: 'entrega de TP',
      );

      expect(registry.hasDirtyDrafts, true);
      expect(registry.dirtyLabels.length, 3);
      expect(registry.dirtyLabels, contains('redacción'));
      expect(registry.dirtyLabels, contains('respuesta en foro'));
      expect(registry.dirtyLabels, contains('entrega de TP'));

      registry.clearOwner('foro_reply');
      expect(registry.hasDirtyDrafts, true);
      expect(registry.dirtyLabels.length, 2);
      expect(registry.dirtyLabels, isNot(contains('respuesta en foro')));

      registry.clearAll();
      expect(registry.hasDirtyDrafts, false);
      expect(registry.dirtyLabels, isEmpty);
    });
  });
}
