import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/parsers/miel_perfil_parser.dart';
import '../../core/theme/miel_theme.dart';
import '../modules/widgets/module_state_views.dart';

/// Diálogo de visualización y modificación del perfil personal en MIeL (`/perfil/datos/`).
class MielProfileDialog extends ConsumerStatefulWidget {
  const MielProfileDialog({super.key});

  @override
  ConsumerState<MielProfileDialog> createState() => _MielProfileDialogState();
}

class _MielProfileDialogState extends ConsumerState<MielProfileDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  MielUserProfile? _profile;

  // Controladores de texto
  late final TextEditingController _dniController;
  late final TextEditingController _fechaNacimientoController;
  late final TextEditingController _emailController;
  late final TextEditingController _correoInstitucionalController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _localidadController;
  late final TextEditingController _provinciaController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _paisController;

  // Controladores de cambio de contraseña
  late final TextEditingController _claveAnteriorController;
  late final TextEditingController _claveNuevaController;
  late final TextEditingController _claveNueva2Controller;
  bool _isChangingPassword = false;
  bool _showSecuritySection = false;

  String _selectedCarreraId = '0';
  String _selectedSexo = '';

  String? _newAvatarPath;
  Uint8List? _newAvatarBytes;
  String? _newAvatarFileName;
  bool _removeAvatarRequested = false;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _dniController = TextEditingController();
    _fechaNacimientoController = TextEditingController();
    _emailController = TextEditingController();
    _correoInstitucionalController = TextEditingController();
    _telefonoController = TextEditingController();
    _direccionController = TextEditingController();
    _localidadController = TextEditingController();
    _provinciaController = TextEditingController();
    _codigoPostalController = TextEditingController();
    _paisController = TextEditingController();

    _claveAnteriorController = TextEditingController();
    _claveNuevaController = TextEditingController();
    _claveNueva2Controller = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _fechaNacimientoController.dispose();
    _emailController.dispose();
    _correoInstitucionalController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _localidadController.dispose();
    _provinciaController.dispose();
    _codigoPostalController.dispose();
    _paisController.dispose();

    _claveAnteriorController.dispose();
    _claveNuevaController.dispose();
    _claveNueva2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reader = await ref.read(mielInteractiveReaderProvider.future);
      final rawHtml = await reader.fetchPerfilHtml();
      final profile = parsePerfilHtml(rawHtml);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _selectedCarreraId = profile.carreraId;
        _selectedSexo = profile.sexo;

        _dniController.text = profile.dni;
        _fechaNacimientoController.text = profile.fechaNacimiento;
        _emailController.text = profile.email;
        _correoInstitucionalController.text = profile.correoInstitucional;
        _telefonoController.text = profile.telefono;
        _direccionController.text = profile.direccion;
        _localidadController.text = profile.localidad;
        _provinciaController.text = profile.provincia;
        _codigoPostalController.text = profile.codigoPostal;
        _paisController.text = profile.pais;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar el perfil de MIeL. Verificá tu conexión o estado de sesión.';
      });
    }
  }

  Future<void> _pickAvatar() async {
    const typeGroup = XTypeGroup(
      label: 'Imágenes',
      extensions: ['jpg', 'jpeg', 'png'],
      mimeTypes: ['image/jpeg', 'image/png'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _newAvatarBytes = bytes;
      _newAvatarPath = file.path.isNotEmpty ? file.path : null;
      _newAvatarFileName = file.name;
      _removeAvatarRequested = false;
    });
  }

  void _removeAvatar() {
    setState(() {
      _newAvatarBytes = null;
      _newAvatarPath = null;
      _newAvatarFileName = null;
      _removeAvatarRequested = true;
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final writer = await ref.read(mielWriterProvider.future);

      if (_removeAvatarRequested && _newAvatarBytes == null) {
        try {
          await writer.deleteAvatar();
        } catch (_) {}
      }

      final updated = _profile!.copyWith(
        carreraId: _selectedCarreraId,
        dni: _dniController.text.trim(),
        sexo: _selectedSexo,
        fechaNacimiento: _fechaNacimientoController.text.trim(),
        email: _emailController.text.trim(),
        correoInstitucional: _correoInstitucionalController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        localidad: _localidadController.text.trim(),
        provincia: _provinciaController.text.trim(),
        codigoPostal: _codigoPostalController.text.trim(),
        pais: _paisController.text.trim(),
      );

      await writer.updatePerfil(
        profile: updated,
        newAvatarPath: _newAvatarPath,
        newAvatarBytes: _newAvatarBytes,
        newAvatarFileName: _newAvatarFileName,
      );

      if (!mounted) return;
      showMielStatusToast(
        context,
        message: 'Datos personales guardados exitosamente en MIeL.',
      );

      // Refrescar sincronización en segundo plano para actualizar avatar si cambió
      ref.read(appSessionProvider.notifier).syncNow(includeCycle2: false);

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showMielStatusToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _submitPasswordChange() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isChangingPassword = true);
    try {
      final writer = await ref.read(mielWriterProvider.future);
      await writer.changePassword(
        claveAnterior: _claveAnteriorController.text,
        claveNueva: _claveNuevaController.text,
      );

      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _claveAnteriorController.clear();
        _claveNuevaController.clear();
        _claveNueva2Controller.clear();
        _showSecuritySection = false;
      });

      showMielStatusToast(
        context,
        message: 'Contraseña actualizada exitosamente en MIeL.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      showMielStatusToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MielPalette.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 640;

    return Dialog(
      backgroundColor: palette.cardBackground,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera institucional
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Mi Perfil de MIeL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido dinámico
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: palette.badgeRed,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProfile,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildProfileForm(palette, isCompact),
            ),

            // Barra inferior de acciones
            if (!_isLoading && _errorMessage == null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.pageBackground,
                  border: Border(top: BorderSide(color: palette.divider)),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(MielPalette palette, bool isCompact) {
    final profile = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección Avatar + Nombre
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.pageBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.divider),
              ),
              child: Row(
                children: [
                  _buildAvatarPreview(palette),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.nombreCompleto.isNotEmpty
                              ? profile.nombreCompleto
                              : 'Estudiante',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usuario: ${profile.usuario.isNotEmpty ? profile.usuario : profile.dni}',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: palette.linkAccent,
                              ),
                              onPressed: _pickAvatar,
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                size: 16,
                              ),
                              label: const Text('Cambiar foto'),
                            ),
                            if ((_newAvatarBytes != null ||
                                    profile.hasCustomAvatar) &&
                                !_removeAvatarRequested)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: palette.badgeRed,
                                ),
                                onPressed: _removeAvatar,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: const Text('Eliminar foto'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sección Datos Académicos y Personales
            _buildSectionHeader('Datos Académicos y Personales', palette),
            const SizedBox(height: 12),

            // Selector de Carrera
            DropdownButtonFormField<String>(
              initialValue:
                  profile.carrerasDisponibles.any(
                    (c) => c.id == _selectedCarreraId,
                  )
                  ? _selectedCarreraId
                  : (profile.carrerasDisponibles.isNotEmpty
                        ? profile.carrerasDisponibles.first.id
                        : '0'),
              decoration: _inputDecoration('Carrera', palette),
              isExpanded: true,
              items: profile.carrerasDisponibles.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: palette.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCarreraId = val);
              },
            ),

            const SizedBox(height: 14),

            // Fila: DNI y Género
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _dniController,
                    decoration: _inputDecoration('DNI', palette),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSexo,
                    decoration: _inputDecoration('Género', palette),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Seleccionar')),
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                      DropdownMenuItem(value: 'F', child: Text('Femenino')),
                      DropdownMenuItem(value: 'O', child: Text('Otro')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSexo = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Fecha de Nacimiento
            TextFormField(
              controller: _fechaNacimientoController,
              decoration: _inputDecoration(
                'Fecha de Nacimiento (DD/MM/AAAA)',
                palette,
                hintText: 'ej. 15/05/2000',
              ),
              keyboardType: TextInputType.datetime,
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                  if (!regex.hasMatch(val.trim())) {
                    return 'Formato requerido: DD/MM/AAAA';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Sección Contacto
            _buildSectionHeader('Información de Contacto', palette),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(
                'Email Personal (Obligatorio)',
                palette,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El correo personal es obligatorio.';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Ingresá un correo electrónico válido.';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _correoInstitucionalController,
              decoration: _inputDecoration(
                'Email Institucional (@unlam o @alumno.unlam)',
                palette,
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _telefonoController,
              decoration: _inputDecoration('Teléfono de Contacto', palette),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 20),

            // Sección Domicilio
            _buildSectionHeader('Domicilio', palette),
            const SizedBox(height: 12),

            TextFormField(
              controller: _direccionController,
              decoration: _inputDecoration(
                'Dirección (Calle y Número)',
                palette,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _localidadController,
                    decoration: _inputDecoration('Localidad', palette),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _provinciaController,
                    decoration: _inputDecoration('Provincia', palette),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codigoPostalController,
                    decoration: _inputDecoration('Código Postal', palette),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _paisController,
                    decoration: _inputDecoration('País', palette),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección Seguridad / Contraseña
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: palette.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showSecuritySection,
                onExpansionChanged: (exp) =>
                    setState(() => _showSecuritySection = exp),
                leading: Icon(Icons.lock_outline, color: palette.linkAccent),
                title: Text(
                  'Seguridad: Cambiar contraseña',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _claveAnteriorController,
                          obscureText: true,
                          decoration: _inputDecoration(
                            'Contraseña actual',
                            palette,
                          ),
                          validator: (val) {
                            if (_showSecuritySection &&
                                (val == null || val.isEmpty)) {
                              return 'Ingresá tu contraseña actual';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _claveNuevaController,
                          obscureText: true,
                          decoration: _inputDecoration(
                            'Nueva contraseña (mínimo 8 caracteres)',
                            palette,
                          ),
                          validator: (val) {
                            if (_showSecuritySection) {
                              if (val == null || val.length < 8) {
                                return 'La clave debe tener al menos 8 caracteres';
                              }
                              if (val == _claveAnteriorController.text) {
                                return 'La nueva clave debe ser diferente a la actual';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _claveNueva2Controller,
                          obscureText: true,
                          decoration: _inputDecoration(
                            'Repetir nueva contraseña',
                            palette,
                          ),
                          validator: (val) {
                            if (_showSecuritySection) {
                              if (val != _claveNuevaController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.primaryDark,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isChangingPassword
                                ? null
                                : _submitPasswordChange,
                            icon: _isChangingPassword
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.key, size: 16),
                            label: const Text('Actualizar contraseña'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview(MielPalette palette) {
    if (_newAvatarBytes != null) {
      return ClipOval(
        child: Image.memory(
          _newAvatarBytes!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_removeAvatarRequested) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.divider,
        ),
        child: Icon(Icons.person, size: 36, color: palette.textMuted),
      );
    }

    return MielAvatar(
      avatarUrl: _profile?.avatarUrl ?? '',
      radius: 32,
      fallbackIconSize: 36,
    );
  }

  Widget _buildSectionHeader(String title, MielPalette palette) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: palette.linkAccent,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    MielPalette palette, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(fontSize: 13, color: palette.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: palette.linkAccent, width: 1.5),
      ),
    );
  }
}
