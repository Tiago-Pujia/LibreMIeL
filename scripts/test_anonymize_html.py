import unittest

from anonymize_html import Anonymizer


class AnonymizerTests(unittest.TestCase):
    def test_removes_pii_and_preserves_miel_dom_structure(self) -> None:
        sample_html = """
        <html>
        <head>
          <script>
            var usuarioId = '176673';
            const pushKey = 'BGl6KbODjul-SECRET-KEY-123';
          </script>
        </head>
        <body>
          <div class="nombreUsuario">PEREZ, JUAN CARLOS<br>DNI: 40123456</div>
          <p>Contacto: juan.perez@unlam.edu.ar | Tel: +54 9 11 4567-8901</p>
          <table>
            <tr class="mensaje-no-leido">
              <td>13/11/2026</td>
              <td>GOMEZ, MARIA LAURA</td>
              <td></td>
              <td><a class="verMensaje" href="/mensajeria/verEntrada/comision/117967/pag/1/from/entrada/id/111">Asunto</a></td>
              <td><a class="botonLeido" data-id="111" data-practica="0" data-estado="0"></a></td>
            </tr>
          </table>
          <li class="foro-respuesta" data-idmensajepadre="500" id="idMensaje-501">
            <div><strong>GOMEZ, MARIA LAURA</strong></div>
            <div class="w3-text-gray">Tutor/a (com 01-2900)</div>
            <div class="foro-contenido-mensaje">
              <strong class="tagUsuario" data-idusuario="176673" data-idmensaje="500">@PEREZ, JUAN CARLOS</strong>
              Hola Juan, tu nota privada es 10.
            </div>
            <a class="btnMostrarDivRespuesta" data-idusuario="99887" data-nombreusuario="GOMEZ, MARIA LAURA" data-idmensaje="501">Responder</a>
          </li>
          <div class="w3-padding correccion">
            <div class="w3-row"><div class="w3-col m3">Observaciones:</div><div class="w3-col m9">Muy buen trabajo Juan</div></div>
            <div class="w3-row"><div class="w3-col m3">Corregido por:</div><div class="w3-col m9">GOMEZ, MARIA LAURA</div></div>
          </div>
          <!-- Cookie: PHPSESSID=abc123def456ghi789 -->
        </body>
        </html>
        """

        result = Anonymizer(extra_terms=["secreto_extra"]).anonymize(sample_html)

        # Ningún dato sensible debe sobrevivir
        for forbidden in [
            "PEREZ, JUAN CARLOS",
            "GOMEZ, MARIA LAURA",
            "40123456",
            "juan.perez@unlam.edu.ar",
            "4567-8901",
            "176673",
            "99887",
            "BGl6KbODjul-SECRET-KEY-123",
            "abc123def456ghi789",
            "tu nota privada es 10",
            "Muy buen trabajo Juan",
        ]:
            self.assertNotIn(forbidden, result)

        # La estructura DOM y atributos críticos para los parsers deben permanecer
        for required in [
            'class="nombreUsuario"',
            'class="mensaje-no-leido"',
            'data-id="111"',
            'data-practica="0"',
            'data-estado="0"',
            'class="foro-respuesta"',
            'data-idmensajepadre="500"',
            'id="idMensaje-501"',
            'class="tagUsuario"',
            'data-idmensaje="500"',
            'class="w3-padding correccion"',
            "Tutor/a (com 01-2900)",
        ]:
            self.assertIn(required, result)

        # El usuarioId anonimizado debe ser consistente entre JS y data-idusuario
        import re

        js_uid = re.search(r"var usuarioId = '(\d+)'", result).group(1)
        tag_uid = re.search(r'class="tagUsuario" data-idusuario="(\d+)"', result).group(1)
        self.assertEqual(js_uid, tag_uid)


if __name__ == "__main__":
    unittest.main()
