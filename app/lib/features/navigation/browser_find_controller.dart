import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado inmutable de la barra de búsqueda en página (`Ctrl + F`).
@immutable
class BrowserFindState {
  const BrowserFindState({this.isOpen = false, this.query = ''});

  final bool isOpen;
  final String query;

  BrowserFindState copyWith({bool? isOpen, String? query}) {
    return BrowserFindState(
      isOpen: isOpen ?? this.isOpen,
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrowserFindState &&
        other.isOpen == isOpen &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(isOpen, query);
}

/// Controlador Riverpod de búsqueda en página (Fase 12).
class BrowserFindController extends Notifier<BrowserFindState> {
  @override
  BrowserFindState build() {
    return const BrowserFindState();
  }

  void open({String? initialQuery}) {
    state = state.copyWith(isOpen: true, query: initialQuery ?? state.query);
  }

  void close() {
    state = const BrowserFindState(isOpen: false, query: '');
  }

  void toggle() {
    if (state.isOpen) {
      close();
    } else {
      open();
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }
}

final browserFindProvider =
    NotifierProvider<BrowserFindController, BrowserFindState>(
      BrowserFindController.new,
    );
