import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app_providers.dart';
import 'core/theme/miel_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'platform/android_background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await Workmanager().initialize(libremielBackgroundCallbackDispatcher);
    } catch (_) {}
  }
  runApp(const ProviderScope(child: LibreMielApp()));
}

class LibreMielApp extends ConsumerWidget {
  const LibreMielApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);

    return MaterialApp(
      title: 'LibreMIeL',
      debugShowCheckedModeBanner: false,
      themeMode: session.themeMode,
      theme: buildMielLightTheme(),
      darkTheme: buildMielDarkTheme(),
      home: session.isChecking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : session.isAuthenticated
          ? const HomeShell()
          : const LoginScreen(),
    );
  }
}
