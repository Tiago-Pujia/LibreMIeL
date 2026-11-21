import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/models/miel_models.dart';

typedef SupportDirResolver = Future<Directory> Function();

/// Almacén persistente local de credenciales para **Sesión Permanente** (Fase 5).
///
/// Combina el llavero nativo del sistema operativo (Android Keystore, Windows
/// Credential Manager, macOS Keychain, Linux `libsecret`) con un archivo `.env`
/// privado (`MIEL_USUARIO` / `MIEL_CLAVE`, permisos estrictos `0600`) dentro del
/// directorio privado de soporte de la aplicación (nunca dentro del repositorio).
///
/// Las credenciales se persisten automáticamente al iniciar sesión y únicamente se
/// eliminan cuando el usuario pulsa explícitamente **Cerrar sesión**.
class SecureCredentialsStore {
  SecureCredentialsStore({
    FlutterSecureStorage? storage,
    SupportDirResolver? supportDirResolver,
    bool? enableLocalEnvFile,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _supportDirResolver =
           supportDirResolver ?? getApplicationSupportDirectory,
       _enableLocalEnvFile = enableLocalEnvFile ?? !kIsWeb;

  final FlutterSecureStorage _storage;
  final SupportDirResolver _supportDirResolver;
  final bool _enableLocalEnvFile;

  static const String _keyUser = 'libremiel_usuario';
  static const String _keyPass = 'libremiel_clave';
  static const String _envFileName = '.env';
  static const String _envUserKey = 'MIEL_USUARIO';
  static const String _envPassKey = 'MIEL_CLAVE';
  // Archivos legados de versiones previas (migrados automáticamente a .env).
  static const String _legacyDataFile = '.creds.dat';
  static const String _legacyKeyFile = '.creds.key';

  bool _usedEnvFallbackOnly = false;
  bool _hasKeyringCopy = false;

  bool get usingEnvFallbackOnly => _usedEnvFallbackOnly;

  String get storageBackendLabel {
    if (_usedEnvFallbackOnly) {
      return 'Archivo .env local privado (chmod 600 — sesión permanente)';
    }
    if (!kIsWeb && Platform.isLinux) {
      return _hasKeyringCopy
          ? 'Llavero del sistema (libsecret) + .env local (0600)'
          : 'Llavero del sistema (libsecret) + .env local';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'Android Keystore + .env privado de la app';
    }
    if (!kIsWeb && Platform.isWindows) {
      return 'Windows Credential Manager + .env local privado';
    }
    if (!kIsWeb && Platform.isMacOS) {
      return 'macOS Keychain + .env local (0600)';
    }
    return 'Almacenamiento local seguro (sesión permanente)';
  }

  /// Devuelve la ruta del archivo `.env` privado en el directorio de soporte local.
  Future<String?> getEnvFilePath() async {
    if (!_enableLocalEnvFile) return null;
    try {
      final dir = await _supportDirResolver();
      return p.join(dir.path, _envFileName);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(MielCredentials credentials) async {
    var savedInKeyring = false;
    try {
      await _storage.write(key: _keyUser, value: credentials.username.trim());
      await _storage.write(key: _keyPass, value: credentials.password);
      savedInKeyring = true;
    } catch (_) {
      savedInKeyring = false;
    }

    var savedInEnv = false;
    if (_enableLocalEnvFile) {
      try {
        await _saveEnvFile(credentials);
        savedInEnv = true;
      } catch (_) {
        savedInEnv = false;
      }
    }

    if (!savedInKeyring && !savedInEnv) {
      throw const FileSystemException(
        'No se pudieron guardar las credenciales en el llavero ni en el archivo .env local.',
      );
    }

    _hasKeyringCopy = savedInKeyring;
    _usedEnvFallbackOnly = !savedInKeyring && savedInEnv;
    await _clearLegacyFiles();
  }

  Future<MielCredentials?> read() async {
    // 1. Intentar leer desde el llavero nativo del SO
    try {
      final user = await _storage.read(key: _keyUser);
      final pass = await _storage.read(key: _keyPass);
      if (user != null && user.isNotEmpty && pass != null && pass.isNotEmpty) {
        final creds = MielCredentials(username: user, password: pass);
        _hasKeyringCopy = true;
        _usedEnvFallbackOnly = false;
        // Asegurar sincronía con el archivo .env local privado para sesión permanente.
        if (_enableLocalEnvFile) {
          await _ensureEnvFileSynced(creds);
        }
        return creds;
      }
    } catch (_) {
      // Llavero no disponible o bloqueado: continuar con el .env local privado.
    }

    // 2. Leer desde el archivo .env privado de la aplicación
    if (_enableLocalEnvFile) {
      final envCreds = await _readEnvFile();
      if (envCreds != null) {
        _hasKeyringCopy = false;
        _usedEnvFallbackOnly = true;
        return envCreds;
      }

      // 3. Migrar automáticamente desde formato legado (.creds.dat/.creds.key) si existía
      final legacy = await _readLegacyFiles();
      if (legacy != null) {
        await save(legacy);
        return legacy;
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
    await _clearEnvFile();
    await _clearLegacyFiles();
    _hasKeyringCopy = false;
    _usedEnvFallbackOnly = false;
  }

  Future<void> _ensureEnvFileSynced(MielCredentials creds) async {
    try {
      final existing = await _readEnvFile();
      if (existing != null &&
          existing.username == creds.username &&
          existing.password == creds.password) {
        return;
      }
      await _saveEnvFile(creds);
    } catch (_) {
      // No interrumpir lectura exitosa del llavero si falla la copia secundaria.
    }
  }

  Future<void> _saveEnvFile(MielCredentials credentials) async {
    final dir = await _supportDirResolver();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final envFile = File(p.join(dir.path, _envFileName));
    final content = StringBuffer()
      ..writeln(
        '# LibreMIeL — Sesión permanente local (permisos 0600, no compartir)',
      )
      ..writeln('$_envUserKey=${jsonEncode(credentials.username.trim())}')
      ..writeln('$_envPassKey=${jsonEncode(credentials.password)}');

    await envFile.writeAsString(content.toString(), flush: true);
    await _chmod600(envFile.path);
  }

  Future<MielCredentials?> _readEnvFile() async {
    try {
      final dir = await _supportDirResolver();
      final envFile = File(p.join(dir.path, _envFileName));
      if (!envFile.existsSync()) return null;

      final lines = await envFile.readAsLines();
      final parsed = parseDotEnvLines(lines);
      final user = (parsed[_envUserKey] ?? '').trim();
      final pass = parsed[_envPassKey] ?? '';
      if (user.isEmpty || pass.isEmpty) return null;
      return MielCredentials(username: user, password: pass);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearEnvFile() async {
    if (!_enableLocalEnvFile) return;
    try {
      final dir = await _supportDirResolver();
      final envFile = File(p.join(dir.path, _envFileName));
      if (envFile.existsSync()) {
        await envFile.delete();
      }
    } catch (_) {
      // Ignorar errores de limpieza.
    }
  }

  Future<MielCredentials?> _readLegacyFiles() async {
    try {
      final dir = await _supportDirResolver();
      final dataFile = File(p.join(dir.path, _legacyDataFile));
      final keyFile = File(p.join(dir.path, _legacyKeyFile));
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
      final user = (map['u'] as String? ?? '').trim();
      final pass = map['p'] as String? ?? '';
      if (user.isEmpty || pass.isEmpty) return null;
      return MielCredentials(username: user, password: pass);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLegacyFiles() async {
    if (!_enableLocalEnvFile) return;
    try {
      final dir = await _supportDirResolver();
      for (final name in [_legacyDataFile, _legacyKeyFile]) {
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
    if (!kIsWeb && (Platform.isLinux || Platform.isMacOS)) {
      try {
        await Process.run('chmod', ['600', filePath]);
      } catch (_) {}
    }
  }
}

/// Parsea líneas de un archivo `.env` soportando comentarios, `export` y valores
/// entrecomillados con escapes JSON o comillas simples.
Map<String, String> parseDotEnvLines(Iterable<String> lines) {
  final result = <String, String>{};
  for (final rawLine in lines) {
    var line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('export ')) {
      line = line.substring('export '.length).trim();
    }
    final eqIndex = line.indexOf('=');
    if (eqIndex <= 0) continue;

    final key = line.substring(0, eqIndex).trim();
    var value = line.substring(eqIndex + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is String) {
          value = decoded;
        }
      } catch (_) {
        value = value.substring(1, value.length - 1);
      }
    } else if (value.length >= 2 &&
        value.startsWith("'") &&
        value.endsWith("'")) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}
