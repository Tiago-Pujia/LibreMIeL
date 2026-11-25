import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_providers.dart';
import '../../core/models/miel_models.dart';
import '../../core/parsers/miel_perfil_parser.dart';
import '../../core/theme/miel_theme.dart';
import '../../platform/android_widget_service.dart';
import '../../platform/updater/update_models.dart';
import '../../platform/updater/updater_controller.dart';
import '../modules/widgets/module_state_views.dart';
import '../updates/update_dialog.dart';

/// Pestañas del menú lateral de "Mi perfil" de MIeL.
enum MielProfileTab {
  datosPersonales,
  seguridad,
  firmas,
  ajustesLibreMiel,
}

/// Pantalla completa de Configuración y Perfil de MIeL (`/perfil/datos/`),
/// replicando con exactitud la estética, barra lateral, campos y footer de MIeL oficial.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.initialTab = MielProfileTab.datosPersonales,
    this.onGoHome,
  });

  final MielProfileTab initialTab;
  final VoidCallback? onGoHome;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late MielProfileTab _selectedTab;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  MielUserProfile? _profile;

  // Controladores de texto de Datos Personales
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

  // Controladores de Seguridad (Cambio de contraseña)
  late final TextEditingController _claveAnteriorController;
  late final TextEditingController _claveNuevaController;
  late final TextEditingController _claveNueva2Controller;
  bool _isChangingPassword = false;

  // Controladores de Firmas Personalizadas
  late final TextEditingController _firma1Controller;
  late final TextEditingController _firma2Controller;
  late final TextEditingController _firma3Controller;
  bool _isSavingFirmas = false;

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
    _selectedTab = widget.initialTab;

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

    _firma1Controller = TextEditingController();
    _firma2Controller = TextEditingController();
    _firma3Controller = TextEditingController();

    if (_selectedTab == MielProfileTab.datosPersonales) {
      _loadProfile();
    } else {
      _isLoading = false;
    }
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

    _firma1Controller.dispose();
    _firma2Controller.dispose();
    _firma3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reader = await ref
          .read(mielInteractiveReaderProvider.future)
          .timeout(const Duration(seconds: 4));
      final rawHtml = await reader
          .fetchPerfilHtml()
          .timeout(const Duration(seconds: 6));
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
        _errorMessage =
            'No se pudo cargar el perfil de MIeL. Verificá tu conexión o estado de sesión.';
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
      setState(() => _isSaving = false);
      showMielStatusToast(
        context,
        message: 'Datos personales guardados exitosamente en MIeL.',
      );

      ref.read(appSessionProvider.notifier).syncNow(includeCycle2: false);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;

        if (_selectedTab == MielProfileTab.ajustesLibreMiel) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 28,
              20,
              isCompact ? 16 : 28,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _buildAjustesLibreMielTab(palette, isCompact),
            ),
          );
        }

        if (isCompact) {
          return Column(
            children: [
              _buildMobileTabBar(palette),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: _buildActiveTabContent(palette, true),
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menú lateral "Mi perfil" estilo MIeL
            _buildDesktopSidebar(palette),

            // Línea divisoria
            Container(width: 1, color: palette.divider),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: _buildActiveTabContent(palette, false),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // BARRA LATERAL (DESKTOP) Y TABS (MOBILE)
  // ===========================================================================

  Widget _buildDesktopSidebar(MielPalette palette) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Text(
              'Mi perfil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: palette.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _buildSidebarItem(
            tab: MielProfileTab.datosPersonales,
            icon: Icons.person,
            label: 'Datos personales',
            palette: palette,
          ),
          _buildSidebarItem(
            tab: MielProfileTab.seguridad,
            icon: Icons.lock,
            label: 'Seguridad',
            palette: palette,
          ),
          _buildSidebarItem(
            tab: MielProfileTab.firmas,
            icon: Icons.border_color,
            label: 'Firmas personalizadas',
            palette: palette,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required MielProfileTab tab,
    required IconData icon,
    required String label,
    required MielPalette palette,
  }) {
    final isSelected = _selectedTab == tab;

    return InkWell(
      onTap: () {
        setState(() => _selectedTab = tab);
        if (tab == MielProfileTab.datosPersonales && _profile == null && !_isLoading) {
          _loadProfile();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.buttonSecondaryBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? palette.textPrimary : palette.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? palette.textPrimary : palette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabBar(MielPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _buildMobileTabChip(
              tab: MielProfileTab.datosPersonales,
              label: 'Datos personales',
              icon: Icons.person,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _buildMobileTabChip(
              tab: MielProfileTab.seguridad,
              label: 'Seguridad',
              icon: Icons.lock,
              palette: palette,
            ),
            const SizedBox(width: 8),
            _buildMobileTabChip(
              tab: MielProfileTab.firmas,
              label: 'Firmas',
              icon: Icons.border_color,
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabChip({
    required MielProfileTab tab,
    required String label,
    required IconData icon,
    required MielPalette palette,
  }) {
    final isSelected = _selectedTab == tab;

    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : palette.textPrimary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: palette.primary,
      backgroundColor: palette.cardBackground,
      labelStyle: TextStyle(
        fontSize: 12.5,
        color: isSelected ? Colors.white : palette.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() => _selectedTab = tab);
        if (tab == MielProfileTab.datosPersonales && _profile == null && !_isLoading) {
          _loadProfile();
        }
      },
    );
  }

  // ===========================================================================
  // CONTENIDO DINÁMICO POR PESTAÑA
  // ===========================================================================

  Widget _buildActiveTabContent(MielPalette palette, bool isCompact) {
    switch (_selectedTab) {
      case MielProfileTab.datosPersonales:
        return _buildDatosPersonalesTab(palette, isCompact);
      case MielProfileTab.seguridad:
        return _buildSeguridadTab(palette, isCompact);
      case MielProfileTab.firmas:
        return _buildFirmasTab(palette, isCompact);
      case MielProfileTab.ajustesLibreMiel:
        return _buildAjustesLibreMielTab(palette, isCompact);
    }
  }

  // ===========================================================================
  // PESTAÑA: DATOS PERSONALES (RÉPLICA DE CAPTURA MIEL)
  // ===========================================================================

  Widget _buildDatosPersonalesTab(MielPalette palette, bool isCompact) {
    final session = ref.watch(appSessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título de la pantalla
        Text(
          'Datos personales',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: palette.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 18),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorState(palette)
        else
          Form(
            key: _formKey,
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildAvatarBox(palette)),
                      const SizedBox(height: 20),
                      _buildPersonalDataInputs(palette, session, isCompact),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna izquierda: Avatar y botones de foto
                      SizedBox(width: 200, child: _buildAvatarBox(palette)),
                      const SizedBox(width: 24),

                      // Columna derecha: Formulario completo
                      Expanded(
                        child: _buildPersonalDataInputs(
                          palette,
                          session,
                          isCompact,
                        ),
                      ),
                    ],
                  ),
          ),

        // Pie de página institucional
        _buildInstitutionalFooter(palette),
      ],
    );
  }

  Widget _buildAvatarBox(MielPalette palette) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contenedor con borde cuadrado de foto (aspect ratio 1:1)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            border: Border.all(color: palette.divider),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _buildAvatarImage(palette),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Botón: Cambiar foto...
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.buttonSecondaryBackground,
            foregroundColor: palette.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: _pickAvatar,
          child: const Text('Cambiar foto...'),
        ),
        const SizedBox(height: 8),

        // Botón: Eliminar foto
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.buttonSecondaryBackground,
            foregroundColor: palette.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed:
              ((_newAvatarBytes != null ||
                          (_profile?.hasCustomAvatar ?? false)) &&
                      !_removeAvatarRequested)
                  ? _removeAvatar
                  : null,
          child: const Text('Eliminar foto'),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(MielPalette palette) {
    if (_newAvatarBytes != null) {
      return Image.memory(
        _newAvatarBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_removeAvatarRequested) {
      return Container(
        color: palette.divider,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 64, color: palette.textMuted),
      );
    }

    final avatarUrl = _profile?.avatarUrl ?? '';
    if (avatarUrl.isNotEmpty) {
      return MielAvatar(
        avatarUrl: avatarUrl,
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(2),
        fallbackIconSize: 64,
      );
    }

    return Container(
      color: palette.divider,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 64, color: palette.textMuted),
    );
  }

  Widget _buildPersonalDataInputs(
    MielPalette palette,
    AppSessionState session,
    bool isCompact,
  ) {
    final profile = _profile!;
    final displayName = profile.nombreCompleto.isNotEmpty
        ? profile.nombreCompleto
        : (session.studentName.isNotEmpty
              ? session.studentName.toUpperCase()
              : 'ESTUDIANTE');
    final displayUsuario = profile.usuario.isNotEmpty
        ? profile.usuario
        : profile.dni;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre de usuario en cabecera
        Text(
          displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Usuario: $displayUsuario',
          style: TextStyle(fontSize: 13, color: palette.textMuted),
        ),
        const SizedBox(height: 16),

        // Carrera: *
        _FieldLabel(label: 'Carrera', isRequired: true, palette: palette),
        DropdownButtonFormField<String>(
          initialValue: profile.carrerasDisponibles.any(
            (c) => c.id == _selectedCarreraId,
          )
              ? _selectedCarreraId
              : (profile.carrerasDisponibles.isNotEmpty
                    ? profile.carrerasDisponibles.first.id
                    : '0'),
          decoration: _mielInputDecoration(palette),
          isExpanded: true,
          dropdownColor: palette.dropdownBackground,
          items: profile.carrerasDisponibles.map((c) {
            return DropdownMenuItem<String>(
              value: c.id,
              child: Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: palette.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCarreraId = val);
          },
        ),

        const SizedBox(height: 12),

        // Fila 1: DNI: * / Género: / Fecha de nacimiento:
        if (isCompact) ...[
          _FieldLabel(label: 'DNI', isRequired: true, palette: palette),
          TextFormField(
            controller: _dniController,
            decoration: _mielInputDecoration(palette),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Género', palette: palette),
          _buildSexoDropdown(palette),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Fecha de nacimiento', palette: palette),
          TextFormField(
            controller: _fechaNacimientoController,
            decoration: _mielInputDecoration(palette, hintText: 'DD/MM/AAAA'),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(
                      label: 'DNI',
                      isRequired: true,
                      palette: palette,
                    ),
                    TextFormField(
                      controller: _dniController,
                      decoration: _mielInputDecoration(palette),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Género', palette: palette),
                    _buildSexoDropdown(palette),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Fecha de nacimiento', palette: palette),
                    TextFormField(
                      controller: _fechaNacimientoController,
                      decoration: _mielInputDecoration(
                        palette,
                        hintText: 'DD/MM/AAAA',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),

        // Email personal: *
        _FieldLabel(label: 'Email personal', isRequired: true, palette: palette),
        TextFormField(
          controller: _emailController,
          decoration: _mielInputDecoration(palette),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'El email personal es obligatorio';
            }
            if (!v.contains('@') || !v.contains('.')) {
              return 'Ingresá un correo válido';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        // Email institucional UNLaM:
        _FieldLabel(label: 'Email institucional UNLaM', palette: palette),
        TextFormField(
          controller: _correoInstitucionalController,
          decoration: _mielInputDecoration(
            palette,
            hintText: 'Email @unlam, @alumno.unlam o @sac.unlam',
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        // Teléfono:
        _FieldLabel(label: 'Teléfono', palette: palette),
        TextFormField(
          controller: _telefonoController,
          decoration: _mielInputDecoration(palette),
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 12),

        // Dirección:
        _FieldLabel(label: 'Dirección', palette: palette),
        TextFormField(
          controller: _direccionController,
          decoration: _mielInputDecoration(palette),
        ),

        const SizedBox(height: 12),

        // Fila 2: Localidad: / Provincia: / Código postal:
        if (isCompact) ...[
          _FieldLabel(label: 'Localidad', palette: palette),
          TextFormField(
            controller: _localidadController,
            decoration: _mielInputDecoration(palette),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Provincia', palette: palette),
          TextFormField(
            controller: _provinciaController,
            decoration: _mielInputDecoration(palette),
          ),
          const SizedBox(height: 12),
          _FieldLabel(label: 'Código postal', palette: palette),
          TextFormField(
            controller: _codigoPostalController,
            decoration: _mielInputDecoration(palette),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Localidad', palette: palette),
                    TextFormField(
                      controller: _localidadController,
                      decoration: _mielInputDecoration(palette),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Provincia', palette: palette),
                    TextFormField(
                      controller: _provinciaController,
                      decoration: _mielInputDecoration(palette),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Código postal', palette: palette),
                    TextFormField(
                      controller: _codigoPostalController,
                      decoration: _mielInputDecoration(palette),
                    ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),

        // País:
        _FieldLabel(label: 'País', palette: palette),
        TextFormField(
          controller: _paisController,
          decoration: _mielInputDecoration(palette),
        ),

        const SizedBox(height: 20),

        // Botones de acción: Guardar cambios y Volver
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                  : const Text(
                      'Guardar cambios',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.buttonSecondaryBackground,
                foregroundColor: palette.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: widget.onGoHome ?? () => Navigator.maybePop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSexoDropdown(MielPalette palette) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSexo,
      decoration: _mielInputDecoration(palette),
      dropdownColor: palette.dropdownBackground,
      items: const [
        DropdownMenuItem(value: '', child: Text('-- Seleccionar --')),
        DropdownMenuItem(value: 'M', child: Text('Masculino')),
        DropdownMenuItem(value: 'F', child: Text('Femenino')),
        DropdownMenuItem(value: 'O', child: Text('Otro')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedSexo = val);
      },
    );
  }

  // ===========================================================================
  // PESTAÑA: SEGURIDAD
  // ===========================================================================

  Widget _buildSeguridadTab(MielPalette palette, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Seguridad',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: palette.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 18),

        // Aviso de Intraconsulta (exacto a MIeL web)
        _MielPanel(
          palette: palette,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para cambiar su contraseña oficial de la Universidad debe hacerlo desde el sistema de Intraconsulta.',
                  style: TextStyle(fontSize: 13.5, color: palette.textMuted),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ir a Intraconsulta'),
                  onPressed: () => launchUrl(
                    Uri.parse('https://alumnos.unlam.edu.ar/'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Formulario directo de cambio de clave en MIeL
        _MielPanel(
          palette: palette,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actualizar contraseña en MIeL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(
                    label: 'Contraseña actual',
                    isRequired: true,
                    palette: palette,
                  ),
                  TextFormField(
                    controller: _claveAnteriorController,
                    obscureText: true,
                    decoration: _mielInputDecoration(palette),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingresá tu clave actual' : null,
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(
                    label: 'Nueva contraseña (mínimo 8 caracteres)',
                    isRequired: true,
                    palette: palette,
                  ),
                  TextFormField(
                    controller: _claveNuevaController,
                    obscureText: true,
                    decoration: _mielInputDecoration(palette),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Debe tener al menos 8 caracteres';
                      }
                      if (v == _claveAnteriorController.text) {
                        return 'Debe ser diferente a la clave actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel(
                    label: 'Repetir nueva contraseña',
                    isRequired: true,
                    palette: palette,
                  ),
                  TextFormField(
                    controller: _claveNueva2Controller,
                    obscureText: true,
                    decoration: _mielInputDecoration(palette),
                    validator: (v) =>
                        (v != _claveNuevaController.text)
                            ? 'Las contraseñas no coinciden'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    onPressed: _isChangingPassword
                        ? null
                        : _submitPasswordChange,
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Actualizar contraseña'),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sesiones y Cierre general
        _MielPanel(
          palette: palette,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesiones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cerrar sesión en todos los dispositivos conectados a tu cuenta de MIeL.',
                  style: TextStyle(fontSize: 13, color: palette.textMuted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(Icons.devices, size: 16, color: palette.badgeRed),
                  label: Text(
                    'Cerrar sesión en todos los dispositivos',
                    style: TextStyle(color: palette.badgeRed),
                  ),
                  onPressed: () {
                    showMielStatusToast(
                      context,
                      message:
                          'Se solicitó el cierre de sesiones. Recuerde que esta acción puede tardar hasta 1 hora en efectuarse.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        _buildInstitutionalFooter(palette),
      ],
    );
  }

  // ===========================================================================
  // PESTAÑA: FIRMAS PERSONALIZADAS
  // ===========================================================================

  Widget _buildFirmasTab(MielPalette palette, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Firmas personalizadas',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: palette.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Las siguientes firmas se agregarán automáticamente al final de los mensajes enviados en foros y mensajería.',
          style: TextStyle(fontSize: 13.5, color: palette.textMuted),
        ),
        const SizedBox(height: 18),

        _MielPanel(
          palette: palette,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label: 'Firma #1', palette: palette),
                TextFormField(
                  controller: _firma1Controller,
                  maxLines: 3,
                  decoration: _mielInputDecoration(
                    palette,
                    hintText: 'Texto de la firma 1…',
                  ),
                ),
                const SizedBox(height: 14),

                _FieldLabel(label: 'Firma #2', palette: palette),
                TextFormField(
                  controller: _firma2Controller,
                  maxLines: 3,
                  decoration: _mielInputDecoration(
                    palette,
                    hintText: 'Texto de la firma 2…',
                  ),
                ),
                const SizedBox(height: 14),

                _FieldLabel(label: 'Firma #3', palette: palette),
                TextFormField(
                  controller: _firma3Controller,
                  maxLines: 3,
                  decoration: _mielInputDecoration(
                    palette,
                    hintText: 'Texto de la firma 3…',
                  ),
                ),
                const SizedBox(height: 18),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  onPressed: _isSavingFirmas
                      ? null
                      : () {
                          setState(() => _isSavingFirmas = true);
                          Future.delayed(const Duration(milliseconds: 600), () {
                            if (mounted) {
                              setState(() => _isSavingFirmas = false);
                              showMielStatusToast(
                                context,
                                message: 'Firmas guardadas exitosamente.',
                              );
                            }
                          });
                        },
                  child: _isSavingFirmas
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar firmas'),
                ),
              ],
            ),
          ),
        ),

        _buildInstitutionalFooter(palette),
      ],
    );
  }

  // ===========================================================================
  // PESTAÑA: AJUSTES DE LIBREMIEL (OPCIONES DE LA APP)
  // ===========================================================================

  Widget _buildAjustesLibreMielTab(MielPalette palette, bool isCompact) {
    final session = ref.watch(appSessionProvider);
    final controller = ref.read(appSessionProvider.notifier);
    final updater = ref.watch(updaterProvider);
    final updaterNotifier = ref.read(updaterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ajustes de LibreMIeL',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: palette.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 18),

        // Inicio con el sistema
        _SectionHeader(title: 'Inicio del sistema', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: session.autostartSupported
              ? SwitchListTile(
                  secondary: Icon(
                    Icons.power_settings_new,
                    color: palette.linkAccent,
                  ),
                  title: const Text('Ejecutar LibreMIeL al iniciar el sistema'),
                  subtitle: Text(
                    'Inicia la aplicación automáticamente al encender tu equipo para recibir notificaciones en segundo plano.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  value: session.launchAtStartup,
                  onChanged: controller.updateLaunchAtStartup,
                )
              : ListTile(
                  leading: Icon(
                    Icons.power_settings_new,
                    color: palette.linkAccent,
                  ),
                  title: const Text('Inicio automático en segundo plano'),
                  subtitle: Text(
                    'En Android, la sincronización periódica se reanuda automáticamente tras reiniciar el dispositivo.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
        ),
        if (!kIsWeb && Platform.isAndroid) ...[
          const SizedBox(height: 8),
          _AndroidBackgroundHealthSection(palette: palette),
        ],

        const SizedBox(height: 20),

        // Sincronización
        _SectionHeader(title: 'Sincronización', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.schedule, color: palette.linkAccent),
                title: const Text('Frecuencia de comprobación (Ciclo 1)'),
                subtitle: Text(
                  'En Android el mínimo del sistema es 15 min para cuidar la batería.',
                  style: TextStyle(color: palette.textMuted),
                ),
                trailing: DropdownButton<int>(
                  value: const [15, 30, 60].contains(session.syncIntervalMinutes)
                      ? session.syncIntervalMinutes
                      : 15,
                  dropdownColor: palette.dropdownBackground,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('Cada 15 min')),
                    DropdownMenuItem(value: 30, child: Text('Cada 30 min')),
                    DropdownMenuItem(value: 60, child: Text('Cada 60 min')),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.updateSyncInterval(v);
                  },
                ),
              ),
              Divider(height: 1, color: palette.divider),
              SwitchListTile(
                secondary: Icon(
                  Icons.assignment_turned_in,
                  color: palette.linkAccent,
                ),
                title: const Text('Monitorear Evaluaciones abiertas'),
                subtitle: Text(
                  'Revisa periódicamente la sección Evaluación en materias que la habilitan.',
                  style: TextStyle(color: palette.textMuted),
                ),
                value: session.monitorEvaluaciones,
                onChanged: controller.updateMonitorEvaluaciones,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Comportamiento en Foros
        _SectionHeader(title: 'Comportamiento en Foros', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: RadioGroup<ForumSyncMode>(
            groupValue: session.forumSyncMode,
            onChanged: (mode) {
              if (mode != null) controller.updateForumSyncMode(mode);
            },
            child: Column(
              children: [
                RadioListTile<ForumSyncMode>(
                  value: ForumSyncMode.mentionsAndReplies,
                  activeColor: palette.primary,
                  title: const Text('Solo si te etiquetan o responden (por defecto)'),
                  subtitle: Text(
                    'Te avisa únicamente cuando te etiquetan (@mención) o responden a tus mensajes o temas. Foro general desactivado.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                RadioListTile<ForumSyncMode>(
                  value: ForumSyncMode.teacherReplies,
                  activeColor: palette.primary,
                  title: const Text('Solo respuestas de docentes'),
                  subtitle: Text(
                    'Te avisa exclusivamente cuando un docente (Tutor/a) te responde o etiqueta.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                RadioListTile<ForumSyncMode>(
                  value: ForumSyncMode.nonInvasive,
                  activeColor: palette.primary,
                  title: const Text('Actividad general en foros'),
                  subtitle: Text(
                    'Te avisa ante cualquier actividad o tema nuevo en el foro (foro general activado). Conserva intactos los contadores de no leídos en MIeL web.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Actualizaciones
        _SectionHeader(title: 'Actualizaciones', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.system_update_alt,
                  color: palette.linkAccent,
                ),
                title: Text(
                  updater.currentVersion.isNotEmpty
                      ? 'Versión instalada: v${updater.currentVersion}'
                      : 'Versión instalada: comprobando…',
                ),
                subtitle: Text(
                  updater.hasUpdate && updater.availableRelease != null
                      ? 'Disponible v${updater.availableRelease!.version} — Tocá para actualizar.'
                      : (updater.lastCheckedAt != null
                            ? 'Última comprobación: ${_formatDateTime(updater.lastCheckedAt!)}'
                            : 'Aún no se comprobó la versión.'),
                  style: TextStyle(color: palette.textMuted),
                ),
                onTap: updater.hasUpdate
                    ? () => UpdateDialog.show(context)
                    : null,
                trailing: updater.isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : updater.hasUpdate
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          updater.isReadyToInstall
                              ? 'Lista para instalar'
                              : '¡Nueva versión!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              Divider(height: 1, color: palette.divider),
              SwitchListTile(
                secondary: Icon(Icons.autorenew, color: palette.linkAccent),
                title: const Text('Buscar actualizaciones automáticamente'),
                subtitle: Text(
                  'Consulta en segundo plano (máximo una vez cada 24 h) si hay nuevas versiones en GitHub Releases.',
                  style: TextStyle(color: palette.textMuted),
                ),
                value: updater.isAutoCheckEnabled,
                onChanged: (v) => updaterNotifier.setAutoCheckEnabled(v),
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(Icons.search, color: palette.linkAccent),
                title: const Text('Buscar actualizaciones ahora'),
                subtitle: Text(
                  updater.status == UpdateStatus.upToDate
                      ? 'Estás usando la versión más reciente.'
                      : updater.status == UpdateStatus.error &&
                            updater.errorMessage != null
                      ? updater.errorMessage!
                      : 'Comprueba manualmente contra GitHub Releases.',
                  style: TextStyle(
                    color: updater.status == UpdateStatus.error
                        ? palette.badgeRed
                        : (updater.status == UpdateStatus.upToDate
                              ? palette.primary
                              : palette.textMuted),
                  ),
                ),
                onTap: updater.isChecking
                    ? null
                    : () async {
                        if (updater.isReadyToInstall) {
                          UpdateDialog.show(context);
                          return;
                        }
                        await updaterNotifier.checkForUpdates(manual: true);
                        if (mounted) {
                          final latestState = ref.read(updaterProvider);
                          if (latestState.hasUpdate ||
                              latestState.status == UpdateStatus.upToDate) {
                            UpdateDialog.show(context);
                          }
                        }
                      },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Modo sin conexión
        _SectionHeader(
          title: 'Modo sin conexión y contingencia',
          palette: palette,
        ),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  Icons.cloud_off_rounded,
                  color: palette.linkAccent,
                ),
                title: const Text('Modo sin conexión'),
                subtitle: Text(
                  'Guarda copias locales de las secciones que consultás para seguir usándolas si MIeL se cae o no tenés internet.',
                  style: TextStyle(color: palette.textMuted),
                ),
                value: session.offlineModeEnabled,
                onChanged: controller.updateOfflineModeEnabled,
              ),
              Divider(height: 1, color: palette.divider),
              SwitchListTile(
                secondary: Icon(
                  Icons.cloud_done_outlined,
                  color: palette.linkAccent,
                ),
                title: const Text('Avisar cuando MIeL vuelva a estar en línea'),
                subtitle: Text(
                  'Envía una notificación nativa al restablecerse los servidores de MIeL tras una caída.',
                  style: TextStyle(color: palette.textMuted),
                ),
                value: session.notifyOnMielRecovery,
                onChanged: controller.updateNotifyOnMielRecovery,
              ),
              if (session.offlineModeEnabled) ...[
                Divider(height: 1, color: palette.divider),
                SwitchListTile(
                  secondary: Icon(
                    Icons.download_for_offline_outlined,
                    color: palette.linkAccent,
                  ),
                  title: const Text('Precarga segura de solo lectura'),
                  subtitle: Text(
                    'Precarga comisiones y listados seguros en cada sincronización sin alterar badges ni efectos colaterales de MIeL.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  value: session.offlinePrefetchSafeModules,
                  onChanged: controller.updateOfflinePrefetchSafeModules,
                ),
                Divider(height: 1, color: palette.divider),
                ListTile(
                  leading: Icon(
                    Icons.storage_outlined,
                    color: palette.linkAccent,
                  ),
                  title: const Text('Límite de almacenamiento del caché'),
                  subtitle: Text(
                    'Purga automáticamente las páginas e imágenes menos consultadas al superar la cuota.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  trailing: DropdownButton<int>(
                    value: const [50, 100, 250, 500].contains(
                      session.offlineCacheMaxMb,
                    )
                        ? session.offlineCacheMaxMb
                        : 100,
                    dropdownColor: palette.dropdownBackground,
                    items: const [
                      DropdownMenuItem(value: 50, child: Text('50 MB')),
                      DropdownMenuItem(value: 100, child: Text('100 MB')),
                      DropdownMenuItem(value: 250, child: Text('250 MB')),
                      DropdownMenuItem(value: 500, child: Text('500 MB')),
                    ],
                    onChanged: (v) {
                      if (v != null) controller.updateOfflineCacheMaxMb(v);
                    },
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                _OfflineCacheStatsTile(
                  palette: palette,
                  controller: controller,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Navegación y lectura
        _SectionHeader(title: 'Navegación y lectura', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: Column(
            children: [
              SwitchListTile(
                value: session.showBrowserNavControls,
                activeThumbColor: palette.linkAccent,
                title: const Text(
                  'Mostrar botones de navegador en la barra superior',
                ),
                subtitle: Text(
                  'Añade controles Atrás (←), Adelante (→) y Recargar (↻) junto al menú principal.',
                  style: TextStyle(color: palette.textMuted),
                ),
                onChanged: (val) => controller.updateShowBrowserNavControls(val),
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(
                  Icons.zoom_in_outlined,
                  color: palette.linkAccent,
                ),
                title: const Text('Zoom de lectura e interfaz'),
                subtitle: Text(
                  'Ajusta la escala entre 80% y 150% (Ctrl + Rueda o Ctrl + +/-/0).',
                  style: TextStyle(color: palette.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      splashRadius: 18,
                      tooltip: 'Reducir zoom',
                      onPressed: session.uiZoomScale > 0.81
                          ? () => controller.stepUiZoomScale(-0.1)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.buttonSecondaryBackground,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Text(
                        '${(session.uiZoomScale * 100).round()}%',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      splashRadius: 18,
                      tooltip: 'Aumentar zoom',
                      onPressed: session.uiZoomScale < 1.49
                          ? () => controller.stepUiZoomScale(0.1)
                          : null,
                    ),
                    if ((session.uiZoomScale - 1.0).abs() > 0.01)
                      TextButton(
                        onPressed: () => controller.resetUiZoomScale(),
                        child: Text(
                          'Restablecer',
                          style: TextStyle(
                            color: palette.linkAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(
                  Icons.keyboard_outlined,
                  color: palette.linkAccent,
                ),
                title: const Text('Atajos de teclado y ratón'),
                subtitle: Text(
                  'Mouse 4/5 (Atrás/Adelante) • F5 / Ctrl+R (Recargar) • Ctrl+Shift+R (Forzar red) • Ctrl+F (Buscar) • Ctrl+Wheel (Zoom)',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Cuenta y Datos Locales
        _SectionHeader(title: 'Cuenta y Datos Locales', palette: palette),
        const SizedBox(height: 8),
        _MielPanel(
          palette: palette,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.key_outlined, color: palette.linkAccent),
                title: const Text('Sesión permanente y credenciales'),
                subtitle: Text(
                  '${ref.read(credentialsStoreProvider).storageBackendLabel}\n'
                  'Se reconecta automáticamente al abrir LibreMIeL; solo cierra sesión cuando vos lo pedís.',
                  style: TextStyle(color: palette.textMuted),
                ),
                isThreeLine: true,
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(Icons.sync, color: palette.linkAccent),
                title: const Text('Forzar sincronización completa ahora'),
                subtitle: Text(
                  'Ejecuta Ciclo 1 (panel) y Ciclo 2 (Portafolio/Evaluación).',
                  style: TextStyle(color: palette.textMuted),
                ),
                onTap: session.isSyncing
                    ? null
                    : () => controller.syncNow(
                        includeCycle2: true,
                        ignoreAuthPause: true,
                      ),
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(Icons.logout, color: palette.badgeRed),
                title: Text(
                  'Cerrar sesión',
                  style: TextStyle(color: palette.badgeRed),
                ),
                subtitle: Text(
                  'Elimina credenciales del llavero y detiene alertas.',
                  style: TextStyle(color: palette.textMuted),
                ),
                onTap: () => controller.logout(wipeLocalData: false),
              ),
              Divider(height: 1, color: palette.divider),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: palette.badgeRed,
                ),
                title: Text(
                  'Cerrar sesión y borrar historial local',
                  style: TextStyle(color: palette.badgeRed),
                ),
                subtitle: Text(
                  'Limpia también snapshots, materias y novedades guardadas.',
                  style: TextStyle(color: palette.textMuted),
                ),
                onTap: () => controller.logout(wipeLocalData: true),
              ),
            ],
          ),
        ),

        _buildInstitutionalFooter(palette),
      ],
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildErrorState(MielPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: palette.badgeRed),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionalFooter(MielPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '© 2025 UNLaM. Todos los derechos reservados. MIeL Materias Interactivas en Línea ®',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://miel.unlam.edu.ar/principal/legal/'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                'Aviso legal',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.linkAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMPONENTES DE ESTILO W3.CSS / MIEL
// =============================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    this.isRequired = false,
    required this.palette,
  });

  final String label;
  final bool isRequired;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          text: '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: palette.textPrimary,
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

InputDecoration _mielInputDecoration(
  MielPalette palette, {
  String? hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontSize: 13,
      color: palette.textMuted.withValues(alpha: 0.65),
    ),
    filled: true,
    fillColor: palette.inputBackground,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: palette.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: palette.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: palette.linkAccent, width: 1.5),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.palette});

  final String title;
  final MielPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: palette.linkAccent,
      ),
    );
  }
}

class _MielPanel extends StatelessWidget {
  const _MielPanel({required this.palette, required this.child});

  final MielPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: child,
    );
  }
}

String _formatDateTime(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}

class _OfflineCacheStatsTile extends ConsumerStatefulWidget {
  const _OfflineCacheStatsTile({
    required this.palette,
    required this.controller,
  });

  final MielPalette palette;
  final AppSessionController controller;

  @override
  ConsumerState<_OfflineCacheStatsTile> createState() =>
      _OfflineCacheStatsTileState();
}

class _OfflineCacheStatsTileState
    extends ConsumerState<_OfflineCacheStatsTile> {
  double _cacheMb = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final db = ref.read(databaseProvider);
    final mediaService = ref.read(offlineMediaServiceProvider);
    final pageBytes = await db.getOfflineCacheTotalBytes();
    final mediaBytes = await mediaService.getTotalCachedMediaBytes();
    final totalMb = (pageBytes + mediaBytes) / (1024 * 1024);
    if (mounted) {
      setState(() {
        _cacheMb = totalMb;
        _loading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await widget.controller.clearOfflineCache();
    await _loadCacheSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se vació el caché local de navegación sin conexión.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final sizeText = _loading
        ? 'Calculando peso…'
        : '${_cacheMb.toStringAsFixed(1)} MB de ${session.offlineCacheMaxMb} MB';

    return ListTile(
      leading: Icon(
        Icons.cleaning_services_outlined,
        color: widget.palette.linkAccent,
      ),
      title: Text('Espacio en disco ocupado: $sizeText'),
      subtitle: Text(
        'Páginas HTML, datos estructurados e imágenes cacheadas localmente.',
        style: TextStyle(color: widget.palette.textMuted),
      ),
      trailing: OutlinedButton(
        onPressed: _loading ? null : _clearCache,
        child: const Text('Vaciar caché'),
      ),
    );
  }
}

class _AndroidBackgroundHealthSection extends ConsumerStatefulWidget {
  const _AndroidBackgroundHealthSection({required this.palette});

  final MielPalette palette;

  @override
  ConsumerState<_AndroidBackgroundHealthSection> createState() =>
      _AndroidBackgroundHealthSectionState();
}

class _AndroidBackgroundHealthSectionState
    extends ConsumerState<_AndroidBackgroundHealthSection>
    with WidgetsBindingObserver {
  bool? _ignoringBattery;
  bool? _notificationsEnabled;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final androidSystem = ref.read(androidSystemServiceProvider);
    final notifService = ref.read(notificationServiceProvider);
    final results = await Future.wait<bool?>([
      androidSystem.isIgnoringBatteryOptimizations(),
      notifService.areNotificationsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _ignoringBattery = results[0];
      _notificationsEnabled = results[1];
      _loading = false;
    });
  }

  Future<void> _requestBatteryExemption() async {
    final androidSystem = ref.read(androidSystemServiceProvider);
    await androidSystem.requestIgnoreBatteryOptimizations();
  }

  Future<void> _openNotificationSettings() async {
    final androidSystem = ref.read(androidSystemServiceProvider);
    await androidSystem.openAppNotificationSettings();
  }

  Future<void> _openWidgetPickerDialog() async {
    final widgetService = ref.read(androidWidgetServiceProvider);
    await ref.read(appSessionProvider.notifier).syncAndroidWidgetFromDb();
    final pinSupported = await widgetService.isPinWidgetSupported();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Widgets en pantalla de inicio'),
        content: Text(
          pinSupported
              ? 'Elegí el formato que querés agregar a tu pantalla de inicio:'
              : 'Mantené presionado un espacio libre de tu pantalla de inicio, '
                    'tocá "Widgets" y elegí LibreMIeL (Resumen 2×2 o Novedades y Materias 4×2).',
        ),
        actions: [
          if (pinSupported) ...[
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widgetService.requestPinWidget(AndroidWidgetKind.compact);
              },
              child: const Text('Resumen (2×2)'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await widgetService.requestPinWidget(AndroidWidgetKind.feed);
              },
              child: const Text('Novedades (4×2)'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final batteryOk = _ignoringBattery == true;
    final notifEnabled = _notificationsEnabled;

    final batterySubtitle = _loading
        ? 'Consultando configuración de energía del dispositivo…'
        : batteryOk
        ? 'Sin restricciones (activo). LibreMIeL puede sincronizar en segundo plano con la app cerrada.'
        : 'Optimización activa. Tocá para configurar en "Sin restricciones" y evitar retrasos en Samsung / Xiaomi / Motorola.';

    final notifSubtitle = _loading
        ? 'Consultando permiso de notificaciones del sistema…'
        : notifEnabled == false
        ? 'Las notificaciones de Android están desactivadas. Tocá para habilitarlas y configurar los canales.'
        : 'Gestioná sonidos, vibración y canales ("Novedades de MIeL" y "Sistema y actualizaciones") en Android.';

    return _MielPanel(
      palette: palette,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              batteryOk
                  ? Icons.battery_charging_full
                  : Icons.battery_alert_outlined,
              color: batteryOk ? palette.linkAccent : Colors.orange.shade700,
            ),
            title: const Text('Optimización de batería en Android'),
            subtitle: Text(
              batterySubtitle,
              style: TextStyle(color: palette.textMuted),
            ),
            trailing: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : batteryOk
                ? Icon(Icons.check_circle, color: palette.linkAccent)
                : const Icon(Icons.chevron_right),
            onTap: _requestBatteryExemption,
          ),
          Divider(height: 1, color: palette.divider),
          ListTile(
            leading: Icon(
              notifEnabled == false
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined,
              color: notifEnabled == false
                  ? Colors.orange.shade700
                  : palette.linkAccent,
            ),
            title: const Text('Notificaciones y canales en Android'),
            subtitle: Text(
              notifSubtitle,
              style: TextStyle(color: palette.textMuted),
            ),
            trailing: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _openNotificationSettings,
          ),
          Divider(height: 1, color: palette.divider),
          ListTile(
            leading: Icon(Icons.widgets_outlined, color: palette.linkAccent),
            title: const Text('Widgets en pantalla de inicio'),
            subtitle: Text(
              'Fijá los widgets de Resumen (2×2) o Novedades y Materias (4×2) en el launcher de Android.',
              style: TextStyle(color: palette.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openWidgetPickerDialog,
          ),
        ],
      ),
    );
  }
}
