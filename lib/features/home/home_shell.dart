import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_providers.dart';
import '../feed/feed_screen.dart';
import '../settings/settings_screen.dart';
import '../subjects/subjects_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Novedades',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Materias',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Ajustes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    final pages = const [FeedScreen(), SubjectsScreen(), SettingsScreen()];

    final body = Column(
      children: [
        if (session.authPausedReason != null)
          MaterialBanner(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            content: Text(
              'Sincronización pausada: ${session.authPausedReason}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => ref.read(appSessionProvider.notifier).logout(),
                child: const Text('Actualizar clave'),
              ),
            ],
          ),
        Expanded(child: pages[_selectedIndex]),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.hive_rounded),
            const SizedBox(width: 8),
            const Text('LibreMIEL'),
            if (session.studentName.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '· ${session.studentName}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (session.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Revisar novedades ahora',
              icon: const Icon(Icons.sync),
              onPressed: () => ref
                  .read(appSessionProvider.notifier)
                  .syncNow(includeCycle2: true),
            ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.notifications_outlined),
                      selectedIcon: Icon(Icons.notifications),
                      label: Text('Novedades'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: Text('Materias'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Ajustes'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: _destinations,
            ),
    );
  }
}
