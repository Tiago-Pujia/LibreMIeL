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

  // Extraer valores asignados por script inline de jQuery (usado por el backend de MIeL)
  final jsVals = _extractJQueryValAssignments(rawHtml);

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
  if (jsVals.containsKey('carrera') && jsVals['carrera']!.isNotEmpty) {
    carreraId = jsVals['carrera']!;
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
  if (jsVals.containsKey('sexo')) {
    sexo = jsVals['sexo']!;
  }

  // 6. Campos de texto (prioridad: script inline de jQuery -> atributo HTML value)
  String getInputValue(String id, String selector) {
    final fromJs = jsVals[id];
    if (fromJs != null && fromJs.isNotEmpty) {
      return fromJs;
    }
    final el = form?.querySelector(selector);
    return el?.attributes['value']?.trim() ?? fromJs ?? '';
  }

  final dni = getInputValue('dni', 'input#dni, input[name="dni"]');
  if (usuario.isEmpty && dni.isNotEmpty) {
    usuario = dni;
  }
  final fechaNacimiento = getInputValue(
    'fechaNacimiento',
    'input#fechaNacimiento, input[name="fechaNacimiento"]',
  );
  final email = getInputValue('email', 'input#email, input[name="email"]');
  final correoInstitucional = getInputValue(
    'correoInstitucional',
    'input#correoInstitucional, input[name="correoInstitucional"]',
  );
  final telefono = getInputValue(
    'telefono',
    'input#telefono, input[name="telefono"]',
  );
  final direccion = getInputValue(
    'direccion',
    'input#direccion, input[name="direccion"]',
  );
  final localidad = getInputValue(
    'localidad',
    'input#localidad, input[name="localidad"]',
  );
  final provincia = getInputValue(
    'provincia',
    'input#provincia, input[name="provincia"]',
  );
  final codigoPostal = getInputValue(
    'codigoPostal',
    'input#codigoPostal, input[name="codigoPostal"]',
  );
  final pais = getInputValue('pais', 'input#pais, input[name="pais"]');

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

/// Extrae asignaciones de valores realizadas dinámicamente con jQuery en la página
/// (ej: `$("#email").val("alumno@unlam.edu.ar")`, `$('#carrera').val(0)`).
Map<String, String> _extractJQueryValAssignments(String html) {
  final result = <String, String>{};
  // Coincide con $(["']#fieldId["']).val("value" o 'value' o número o vacío)
  final regExp = RegExp(
    r'''\$\s*\(\s*["']#([a-zA-Z0-9_\-]+)["']\s*\)\s*\.val\s*\(\s*(?:"([^"]*)"|'([^']*)'|([0-9]+)|([^)]*))\s*\)''',
  );
  for (final match in regExp.allMatches(html)) {
    final fieldId = match.group(1);
    if (fieldId == null) continue;
    final val =
        match.group(2) ??
        match.group(3) ??
        match.group(4) ??
        match.group(5)?.trim() ??
        '';
    result[fieldId] = val.trim();
  }
  return result;
}
