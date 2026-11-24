import 'package:html/parser.dart' as html_parser;

import '../models/miel_models.dart';
import 'text_normalizer.dart';

/// Parser puro para la pantalla de datos personales de MIeL (`GET /perfil/datos/`).
MielUserProfile parsePerfilHtml(String rawHtml) {
  final doc = html_parser.parse(rawHtml);
  final form = doc.querySelector('#formUsuario') ?? doc.body;

  // 1. Nombre completo del estudiante desde el encabezado <h5>
  var nombreCompleto = '';
  final nameEl = form?.querySelector('h5');
  if (nameEl != null) {
    nombreCompleto = cleanWhitespace(nameEl.text);
  }

  // 2. Nombre de usuario / DNI desde el bloque w3-text-dark-grey
  var usuario = '';
  final userEl = form?.querySelector('.w3-text-dark-grey');
  if (userEl != null) {
    final text = userEl.text;
    final match = RegExp(
      r'Usuario:\s*(\S+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      usuario = match.group(1)?.trim() ?? '';
    } else {
      usuario = cleanWhitespace(text);
    }
  }

  // 3. Avatar actual desde el estilo background-image
  var avatarUrl = '';
  final avatarEl = doc.querySelector('#perfil-fotoAvatar');
  if (avatarEl != null) {
    avatarUrl = extractBackgroundImageUrl(avatarEl.attributes['style']);
  }
  if (avatarUrl.isEmpty) {
    final headerAvatar = doc.querySelector('.fotoPerfil');
    if (headerAvatar != null) {
      avatarUrl = extractBackgroundImageUrl(headerAvatar.attributes['style']);
    }
  }

  // 4. Carrera seleccionada y lista de carreras disponibles
  var carreraId = '0';
  final carreras = <CareerOption>[];
  final carreraSelect = form?.querySelector(
    'select#carrera, select[name="carrera"]',
  );
  if (carreraSelect != null) {
    for (final opt in carreraSelect.querySelectorAll('option')) {
      final val = opt.attributes['value']?.trim() ?? '';
      final label = cleanWhitespace(opt.text);
      if (val.isNotEmpty) {
        carreras.add(CareerOption(id: val, name: label));
      }
      if (opt.attributes.containsKey('selected')) {
        carreraId = val;
      }
    }
  }

  // 5. Sexo
  var sexo = '';
  final sexoSelect = form?.querySelector('select#sexo, select[name="sexo"]');
  if (sexoSelect != null) {
    for (final opt in sexoSelect.querySelectorAll('option')) {
      if (opt.attributes.containsKey('selected')) {
        sexo = opt.attributes['value']?.trim() ?? '';
        break;
      }
    }
  }

  // 6. Campos de texto
  String getInputValue(String selector) {
    final el = form?.querySelector(selector);
    return el?.attributes['value']?.trim() ?? '';
  }

  final dni = getInputValue('input#dni, input[name="dni"]');
  if (usuario.isEmpty && dni.isNotEmpty) {
    usuario = dni;
  }
  final fechaNacimiento = getInputValue(
    'input#fechaNacimiento, input[name="fechaNacimiento"]',
  );
  final email = getInputValue('input#email, input[name="email"]');
  final correoInstitucional = getInputValue(
    'input#correoInstitucional, input[name="correoInstitucional"]',
  );
  final telefono = getInputValue('input#telefono, input[name="telefono"]');
  final direccion = getInputValue('input#direccion, input[name="direccion"]');
  final localidad = getInputValue('input#localidad, input[name="localidad"]');
  final provincia = getInputValue('input#provincia, input[name="provincia"]');
  final codigoPostal = getInputValue(
    'input#codigoPostal, input[name="codigoPostal"]',
  );
  final pais = getInputValue('input#pais, input[name="pais"]');

  return MielUserProfile(
    nombreCompleto: nombreCompleto,
    usuario: usuario,
    avatarUrl: avatarUrl,
    carreraId: carreraId,
    carrerasDisponibles: carreras,
    dni: dni,
    sexo: sexo,
    fechaNacimiento: fechaNacimiento,
    email: email,
    correoInstitucional: correoInstitucional,
    telefono: telefono,
    direccion: direccion,
    localidad: localidad,
    provincia: provincia,
    codigoPostal: codigoPostal,
    pais: pais,
  );
}
