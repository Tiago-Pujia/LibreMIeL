import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/models/miel_models.dart';

typedef SupportDirResolver = Future<Directory> Function();

/// Almacén seguro local de credenciales usando el llavero nativo del SO
/// (Android Keystore, Windows Credential Manager, macOS Keychain, Linux libsecret).
///
/// En entornos Linux sin `org.freedesktop.secrets` disponible o desbloqueado
/// (ej. KDE Plasma sin KWallet Secret Service, Hyprland, Sway o instalaciones mínimas),
/// degrada de forma segura a un archivo local con permisos estrictos `0600` (solo el usuario)
/// enmascarado con una clave aleatoria generada por `Random.secure()`.
class SecureCredentialsStore {
  SecureCredentialsStore({
    FlutterSecureStorage? storage,
    SupportDirResolver? supportDirResolver,
    bool? enableLinuxFileFallback,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _supportDirResolver =
           supportDirResolver ?? getApplicationSupportDirectory,
       _enableLinuxFileFallback =
           enableLinuxFileFallback ?? (!kIsWeb && Platform.isLinux);

  final FlutterSecureStorage _storage;
  final SupportDirResolver _supportDirResolver;
  final bool _enableLinuxFileFallback;

  static const String _keyUser = 'libremiel_usuario';
  static const String _keyPass = 'libremiel_clave';
  static const String _fallbackDataFile = '.creds.dat';
  static const String _fallbackKeyFile = '.creds.key';

  bool _usedFallback = false;

  bool get usingLinuxFallback => _usedFallback;

  String get storageBackendLabel {
    if (_usedFallback) {
      return 'Archivo local protegido (chmod 600 — sin org.freedesktop.secrets activo)';
    }
    if (!kIsWeb && Platform.isLinux) return 'Llavero del sistema (libsecret)';
    if (!kIsWeb && Platform.isAndroid) return 'Android Keystore';
    if (!kIsWeb && Platform.isWindows) return 'Windows Credential Manager';
    if (!kIsWeb && Platform.isMacOS) return 'macOS Keychain';
    return 'Almacenamiento seguro del sistema';
  }

  Future<void> save(MielCredentials credentials) async {
    try {
      await _storage.write(key: _keyUser, value: credentials.username.trim());
      await _storage.write(key: _keyPass, value: credentials.password);
      _usedFallback = false;
      await _clearFallbackFiles();
      return;
    } catch (_) {
      if (!_enableLinuxFileFallback) rethrow;
    }

    await _saveFallback(credentials);
    _usedFallback = true;
  }

  Future<MielCredentials?> read() async {
    try {
      final user = await _storage.read(key: _keyUser);
      final pass = await _storage.read(key: _keyPass);
      if (user != null && user.isNotEmpty && pass != null && pass.isNotEmpty) {
        _usedFallback = false;
        return MielCredentials(username: user, password: pass);
      }
    } catch (_) {
      // Si el llavero del sistema no está disponible o está bloqueado, intentar fallback en Linux.
    }

    if (_enableLinuxFileFallback) {
      final fallback = await _readFallback();
      if (fallback != null) {
        _usedFallback = true;
        return fallback;
      }
    }
    return null;
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyPass);
    } catch (_) {
      // Ignorar errores si el llavero no estaba disponible.
    }
    await _clearFallbackFiles();
    _usedFallback = false;
  }

  Future<void> _saveFallback(MielCredentials credentials) async {
    final dir = await _supportDirResolver();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final payload = utf8.encode(
      jsonEncode({'u': credentials.username.trim(), 'p': credentials.password}),
    );

    final rng = Random.secure();
    final keyBytes = List<int>.generate(
      payload.length,
      (_) => rng.nextInt(256),
    );
    final masked = List<int>.generate(
      payload.length,
      (i) => payload[i] ^ keyBytes[i],
    );

    final dataFile = File(p.join(dir.path, _fallbackDataFile));
    final keyFile = File(p.join(dir.path, _fallbackKeyFile));

    await keyFile.writeAsBytes(keyBytes, flush: true);
    await dataFile.writeAsBytes(masked, flush: true);
    await _chmod600(keyFile.path);
    await _chmod600(dataFile.path);
  }

  Future<MielCredentials?> _readFallback() async {
    try {
      final dir = await _supportDirResolver();
      final dataFile = File(p.join(dir.path, _fallbackDataFile));
      final keyFile = File(p.join(dir.path, _fallbackKeyFile));
      if (!dataFile.existsSync() || !keyFile.existsSync()) return null;

      final masked = await dataFile.readAsBytes();
      final keyBytes = await keyFile.readAsBytes();
      if (masked.isEmpty || masked.length != keyBytes.length) return null;

      final plain = List<int>.generate(
        masked.length,
        (i) => masked[i] ^ keyBytes[i],
      );
      final map = jsonDecode(utf8.decode(plain));
      if (map is! Map<String, dynamic>) return null;
      final user = map['u'] as String? ?? '';
      final pass = map['p'] as String? ?? '';
      if (user.isEmpty || pass.isEmpty) return null;
      return MielCredentials(username: user, password: pass);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearFallbackFiles() async {
    if (!_enableLinuxFileFallback) return;
    try {
      final dir = await _supportDirResolver();
      for (final name in [_fallbackDataFile, _fallbackKeyFile]) {
        final f = File(p.join(dir.path, name));
        if (f.existsSync()) {
          await f.delete();
        }
      }
    } catch (_) {
      // Ignorar errores de limpieza.
    }
  }

  Future<void> _chmod600(String filePath) async {
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['600', filePath]);
    }
  }
}
