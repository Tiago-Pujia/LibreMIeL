import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LibreMielApp()));
}

class LibreMielApp extends ConsumerWidget {
  const LibreMielApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);

    return MaterialApp(
      title: 'LibreMIEL',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD98A00),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD98A00),
          brightness: Brightness.dark,
        ),
      ),
      home: session.isChecking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : session.isAuthenticated
          ? const HomeShell()
          : const LoginScreen(),
    );
  }
}
