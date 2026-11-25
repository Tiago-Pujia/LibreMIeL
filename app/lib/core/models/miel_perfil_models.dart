/// Opciones de carrera para el perfil de MIeL.
class CareerOption {
  const CareerOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareerOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name ($id)';
}

/// Modelo inmutable de datos personales del perfil de MIeL (`/perfil/datos/`).
class MielUserProfile {
  const MielUserProfile({
    required this.nombreCompleto,
    required this.usuario,
    this.avatarUrl = '',
    this.carreraId = '0',
    this.carrerasDisponibles = const [],
    this.dni = '',
    this.sexo = '',
    this.fechaNacimiento = '',
    this.email = '',
    this.correoInstitucional = '',
    this.telefono = '',
    this.direccion = '',
    this.localidad = '',
    this.provincia = '',
    this.codigoPostal = '',
    this.pais = '',
  });

  /// Nombre completo estático extraído del encabezado del perfil (ej. "PEREZ JUAN").
  final String nombreCompleto;

  /// Nombre de usuario del estudiante (DNI).
  final String usuario;

  /// URL de la imagen de avatar o ruta relativa de MIeL.
  final String avatarUrl;

  /// Código identificador de la carrera seleccionada (ej. "0", "201").
  final String carreraId;

  /// Lista de opciones de carreras extraídas del `<select id="carrera">`.
  final List<CareerOption> carrerasDisponibles;

  /// Documento Nacional de Identidad del formulario.
  final String dni;

  /// Género: `""` (no especificado), `"M"` (masculino), `"F"` (femenino), `"O"` (otro).
  final String sexo;

  /// Fecha de nacimiento en formato `DD/MM/YYYY`.
  final String fechaNacimiento;

  /// Correo electrónico personal (obligatorio).
  final String email;

  /// Correo electrónico institucional `@unlam` o `@alumno.unlam` (opcional).
  final String correoInstitucional;

  /// Teléfono de contacto.
  final String telefono;

  /// Domicilio (calle y número).
  final String direccion;

  /// Localidad o ciudad.
  final String localidad;

  /// Provincia o estado.
  final String provincia;

  /// Código postal.
  final String codigoPostal;

  /// País de residencia.
  final String pais;

  bool get hasCustomAvatar =>
      avatarUrl.isNotEmpty && !avatarUrl.contains('foto_perfil.jpg');

  MielUserProfile copyWith({
    String? nombreCompleto,
    String? usuario,
    String? avatarUrl,
    String? carreraId,
    List<CareerOption>? carrerasDisponibles,
    String? dni,
    String? sexo,
    String? fechaNacimiento,
    String? email,
    String? correoInstitucional,
    String? telefono,
    String? direccion,
    String? localidad,
    String? provincia,
    String? codigoPostal,
    String? pais,
  }) {
    return MielUserProfile(
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      usuario: usuario ?? this.usuario,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      carreraId: carreraId ?? this.carreraId,
      carrerasDisponibles: carrerasDisponibles ?? this.carrerasDisponibles,
      dni: dni ?? this.dni,
      sexo: sexo ?? this.sexo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      email: email ?? this.email,
      correoInstitucional: correoInstitucional ?? this.correoInstitucional,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      pais: pais ?? this.pais,
    );
  }
}
