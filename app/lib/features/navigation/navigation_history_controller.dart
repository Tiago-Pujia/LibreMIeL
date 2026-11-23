import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_database.dart' show Subject;
import 'navigation_history_entry.dart';

/// Estado inmutable de la pila de historial de navegación de LibreMIeL.
@immutable
class NavigationHistoryState {
  const NavigationHistoryState({
    this.entries = const <NavigationHistoryEntry>[
      NavigationHistoryEntry.home(),
    ],
    this.currentIndex = 0,
  });

  final List<NavigationHistoryEntry> entries;
  final int currentIndex;

  NavigationHistoryEntry get current =>
      (currentIndex >= 0 && currentIndex < entries.length)
      ? entries[currentIndex]
      : const NavigationHistoryEntry.home();

  bool get canGoBack => currentIndex > 0;

  bool get canGoForward => currentIndex < entries.length - 1;

  NavigationHistoryState copyWith({
    List<NavigationHistoryEntry>? entries,
    int? currentIndex,
  }) {
    return NavigationHistoryState(
      entries: entries ?? this.entries,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationHistoryState &&
        listEquals(other.entries, entries) &&
        other.currentIndex == currentIndex;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(entries), currentIndex);
}

/// Controlador Riverpod puro del historial lineal de navegación (Fase 12).
class NavigationHistoryController extends Notifier<NavigationHistoryState> {
  static const int maxEntries = 80;

  @override
  NavigationHistoryState build() {
    return const NavigationHistoryState();
  }

  /// Navega a un nuevo destino o actualiza el actual en el historial.
  void navigateTo(
    NavigationHistoryEntry next, {
    double? currentScrollOffset,
    bool replace = false,
  }) {
    final currentEntries = List<NavigationHistoryEntry>.from(state.entries);
    final curIdx = state.currentIndex;

    if (currentEntries.isNotEmpty &&
        curIdx >= 0 &&
        curIdx < currentEntries.length &&
        currentScrollOffset != null) {
      currentEntries[curIdx] = currentEntries[curIdx].copyWith(
        scrollOffset: currentScrollOffset,
      );
    }

    if (replace) {
      if (curIdx >= 0 && curIdx < currentEntries.length) {
        currentEntries[curIdx] = next;
        state = state.copyWith(entries: currentEntries);
      }
      return;
    }

    if (currentEntries.isNotEmpty &&
        curIdx >= 0 &&
        curIdx < currentEntries.length) {
      final cur = currentEntries[curIdx];
      if (cur.locationKey == next.locationKey) {
        currentEntries[curIdx] = next;
        state = state.copyWith(entries: currentEntries);
        return;
      }
    }

    // Truncar cualquier rama hacia adelante (estilo browser)
    final truncated = currentEntries.sublist(0, curIdx + 1);
    truncated.add(next);

    var nextIdx = truncated.length - 1;
    if (truncated.length > maxEntries) {
      final excess = truncated.length - maxEntries;
      truncated.removeRange(0, excess);
      nextIdx = truncated.length - 1;
    }

    state = NavigationHistoryState(entries: truncated, currentIndex: nextIdx);
  }

  /// Actualiza el `scrollOffset` de la entrada actual en memoria.
  void updateCurrentScrollOffset(double offset) {
    if (state.entries.isEmpty) return;
    final curIdx = state.currentIndex;
    if (curIdx < 0 || curIdx >= state.entries.length) return;

    final updated = List<NavigationHistoryEntry>.from(state.entries);
    updated[curIdx] = updated[curIdx].copyWith(scrollOffset: offset);
    state = state.copyWith(entries: updated);
  }

  void saveScrollOffset(double offset) => updateCurrentScrollOffset(offset);

  /// Actualiza en el lugar la entrada actual (por ejemplo, cambios transitorios).
  void updateCurrentInPlace(NavigationHistoryEntry updatedEntry) {
    if (state.entries.isEmpty) return;
    final curIdx = state.currentIndex;
    if (curIdx < 0 || curIdx >= state.entries.length) return;

    final updated = List<NavigationHistoryEntry>.from(state.entries);
    updated[curIdx] = updatedEntry;
    state = state.copyWith(entries: updated);
  }

  /// Retrocede un paso en el historial si es posible, retornando la entrada
  /// restaurada o `null` si ya está en la raíz.
  NavigationHistoryEntry? goBack({double? currentScrollOffset}) {
    if (!state.canGoBack) return null;

    final currentEntries = List<NavigationHistoryEntry>.from(state.entries);
    final curIdx = state.currentIndex;

    if (currentScrollOffset != null &&
        curIdx >= 0 &&
        curIdx < currentEntries.length) {
      currentEntries[curIdx] = currentEntries[curIdx].copyWith(
        scrollOffset: currentScrollOffset,
      );
    }

    final newIdx = curIdx - 1;
    state = NavigationHistoryState(
      entries: currentEntries,
      currentIndex: newIdx,
    );
    return currentEntries[newIdx];
  }

  /// Avanza un paso en el historial si es posible, retornando la entrada
  /// restaurada o `null` si ya está en el final de la pila.
  NavigationHistoryEntry? goForward({double? currentScrollOffset}) {
    if (!state.canGoForward) return null;

    final currentEntries = List<NavigationHistoryEntry>.from(state.entries);
    final curIdx = state.currentIndex;

    if (currentScrollOffset != null &&
        curIdx >= 0 &&
        curIdx < currentEntries.length) {
      currentEntries[curIdx] = currentEntries[curIdx].copyWith(
        scrollOffset: currentScrollOffset,
      );
    }

    final newIdx = curIdx + 1;
    state = NavigationHistoryState(
      entries: currentEntries,
      currentIndex: newIdx,
    );
    return currentEntries[newIdx];
  }

  /// Reinicia la pila a una única entrada (usado obligatoriamente en `logout()` y cambio de cuenta).
  void reset({NavigationHistoryEntry? initialEntry}) {
    state = NavigationHistoryState(
      entries: <NavigationHistoryEntry>[
        initialEntry ?? const NavigationHistoryEntry.home(),
      ],
      currentIndex: 0,
    );
  }

  /// Si la entrada actual apunta a una comisión que ya no existe (por poda
  /// o cambio de materias), degrada de forma segura a `home`.
  NavigationHistoryEntry sanitizeAgainstSubjects(List<Subject> subjects) {
    final cur = state.current;
    if (cur.section == BrowserShellSection.module && cur.subjectId != null) {
      final exists = subjects.any((s) => s.idComision == cur.subjectId);
      if (!exists) {
        const homeEntry = NavigationHistoryEntry.home();
        updateCurrentInPlace(homeEntry);
        return homeEntry;
      }
    }
    return cur;
  }
}

final navigationHistoryProvider =
    NotifierProvider<NavigationHistoryController, NavigationHistoryState>(
      NavigationHistoryController.new,
    );
