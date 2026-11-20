import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models/miel_models.dart';

/// Almacén seguro local de credenciales usando el llavero nativo del SO
/// (Android Keystore, Windows Credential Manager, macOS Keychain, Linux libsecret).
class SecureCredentialsStore {
  SecureCredentialsStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _keyUser = 'libremiel_usuario';
  static const String _keyPass = 'libremiel_clave';

  Future<void> save(MielCredentials credentials) async {
    await _storage.write(key: _keyUser, value: credentials.username.trim());
    await _storage.write(key: _keyPass, value: credentials.password);
  }

  Future<MielCredentials?> read() async {
    final user = await _storage.read(key: _keyUser);
    final pass = await _storage.read(key: _keyPass);
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      return null;
    }
    return MielCredentials(username: user, password: pass);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyPass);
  }
}
