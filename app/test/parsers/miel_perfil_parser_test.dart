import 'package:flutter_test/flutter_test.dart';
import 'package:libremiel/core/parsers/miel_perfil_parser.dart';

void main() {
  group('parsePerfilHtml', () {
    test('extrae datos personales y carreras de HTML de perfil', () {
      const html = '''
<!DOCTYPE html>
<html>
<body>
  <div id="perfil-fotoAvatar" style="background-image:url('https://miel.unlam.edu.ar/archivos/avatares/avatar_test123.jpg');">
    <div id="perfil-fotoAvatarLayer" class="w3-hide"></div>
  </div>

  <form id="formUsuario" action="https://miel.unlam.edu.ar/perfil/event/modificarUsuario/" method="post">
    <h5>TEST APELLIDO Y NOMBRE</h5>
    <div class="w3-text-dark-grey">Usuario: 99887766</div>

    <select id="carrera" name="carrera">
      <option value="0">Otros</option>
      <option value="201" selected>Ingeniería en Informática</option>
      <option value="202">Tecnicatura Universitaria en Web</option>
    </select>

    <input type="text" id="dni" name="dni" value="99887766" readonly>

    <select id="sexo" name="sexo">
      <option value="">Seleccionar</option>
      <option value="M" selected>Masculino</option>
      <option value="F">Femenino</option>
      <option value="O">Otro</option>
    </select>

    <input type="text" id="fechaNacimiento" name="fechaNacimiento" value="15/05/2000">
    <input type="text" id="email" name="email" value="alumno_prueba@ejemplo.com">
    <input type="text" id="correoInstitucional" name="correoInstitucional" value="alumno@alumno.unlam.edu.ar">
    <input type="text" id="telefono" name="telefono" value="11-4455-6677">
    <input type="text" id="direccion" name="direccion" value="Florencio Varela 1903">
    <input type="text" id="localidad" name="localidad" value="San Justo">
    <input type="text" id="provincia" name="provincia" value="Buenos Aires">
    <input type="text" id="codigoPostal" name="codigoPostal" value="1754">
    <input type="text" id="pais" name="pais" value="Argentina">
  </form>
</body>
</html>
''';

      final perfil = parsePerfilHtml(html);

      expect(perfil.nombreCompleto, equals('TEST APELLIDO Y NOMBRE'));
      expect(perfil.usuario, equals('99887766'));
      expect(
        perfil.avatarUrl,
        equals(
          'https://miel.unlam.edu.ar/archivos/avatares/avatar_test123.jpg',
        ),
      );
      expect(perfil.hasCustomAvatar, isTrue);
      expect(perfil.carreraId, equals('201'));
      expect(perfil.carrerasDisponibles.length, equals(3));
      expect(
        perfil.carrerasDisponibles[1].name,
        equals('Ingeniería en Informática'),
      );
      expect(perfil.dni, equals('99887766'));
      expect(perfil.sexo, equals('M'));
      expect(perfil.fechaNacimiento, equals('15/05/2000'));
      expect(perfil.email, equals('alumno_prueba@ejemplo.com'));
      expect(perfil.correoInstitucional, equals('alumno@alumno.unlam.edu.ar'));
      expect(perfil.telefono, equals('11-4455-6677'));
      expect(perfil.direccion, equals('Florencio Varela 1903'));
      expect(perfil.localidad, equals('San Justo'));
      expect(perfil.provincia, equals('Buenos Aires'));
      expect(perfil.codigoPostal, equals('1754'));
      expect(perfil.pais, equals('Argentina'));
    });

    test('maneja perfil sin avatar personalizado ni datos secundarios', () {
      const html = '''
<div id="perfil-fotoAvatar" style="background-image:url('https://miel.unlam.edu.ar/vista/imagenes/foto_perfil.jpg');"></div>
<form id="formUsuario">
  <h5>ESTUDIANTE MINIMO</h5>
  <div class="w3-text-dark-grey">Usuario: 11223344</div>
  <select id="carrera" name="carrera">
    <option value="0" selected>Otros</option>
  </select>
  <input type="text" id="dni" value="11223344">
  <input type="text" id="email" value="minimo@ejemplo.com">
</form>
''';

      final perfil = parsePerfilHtml(html);

      expect(perfil.nombreCompleto, equals('ESTUDIANTE MINIMO'));
      expect(perfil.usuario, equals('11223344'));
      expect(perfil.hasCustomAvatar, isFalse);
      expect(perfil.carreraId, equals('0'));
      expect(perfil.carrerasDisponibles.length, equals(1));
      expect(perfil.dni, equals('11223344'));
      expect(perfil.sexo, equals(''));
      expect(perfil.email, equals('minimo@ejemplo.com'));
      expect(perfil.telefono, equals(''));
    });
  });
}
