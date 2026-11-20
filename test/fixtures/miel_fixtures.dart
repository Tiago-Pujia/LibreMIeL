/// Fixtures HTML 100% anonimizados replicando la estructura real de MIEL (2025.2.0).
library;

const String fixtureInternoSinBadges = '''
<html>
<head><title>MIeL - Materias Interactivas en Línea</title></head>
<body>
  <nav>
    <a href="https://miel.unlam.edu.ar/principal/novedades/">Novedades</a>
  </nav>
  <div class="nombreUsuario">ALUMNO, EJEMPLO<br></div>
  <div class="materia-bloque" data-id="117967">
    <div class="w3-slarge materia-titulo">FUNDAMENTOS DE SISTEMAS EMBEBIDOS</div>
    <div class="w3-small">Com: 01-2900</div>
    <div class="materia-herramientas">
      <a href="/contenido/archivos/comision/117967">Contenidos</a>
      <a href="/portafolio/practicas/comision/117967">Portafolio</a>
      <a href="/mensajeria/entrada/comision/117967">Mensajes</a>
      <a href="/forov2/temas/comision/117967">Foro</a>
      <a href="/evaluacion/evaluaciones/comision/117967">Evaluación</a>
    </div>
  </div>
  <div class="materia-bloque materia-bloque-oculta w3-hide" data-id="999001">
    <div class="w3-slarge materia-titulo">MATERIA VIEJA OCULTA</div>
    <div class="w3-small">Com: 01-1900</div>
    <div class="materia-herramientas">
      <a href="/contenido/archivos/comision/999001">Contenidos <span class="w3-badge w3-red w3-small">5</span></a>
    </div>
  </div>
</body>
</html>
''';

const String fixtureInternoConBadges = '''
<html>
<head>
  <title>(1) MIeL - Materias Interactivas en Línea</title>
</head>
<body>
  <nav>
    <a href="https://miel.unlam.edu.ar/principal/novedades/">
      Novedades <span class="w3-badge w3-red w3-small">1</span>
    </a>
  </nav>
  <div class="nombreUsuario">ALUMNO, EJEMPLO<br></div>
  <div class="materia-bloque" data-id="117967">
    <div class="w3-slarge materia-titulo">FUNDAMENTOS DE SISTEMAS EMBEBIDOS</div>
    <div class="w3-small">Com: 01-2900</div>
    <div class="materia-herramientas">
      <a href="/contenido/archivos/comision/117967">
        Contenidos <span class="w3-badge w3-red w3-small">2</span>
      </a>
      <a href="/portafolio/practicas/comision/117967">Portafolio</a>
      <a href="/mensajeria/entrada/comision/117967">
        Mensajes <span class="w3-badge w3-red w3-small">1</span>
      </a>
      <a href="/forov2/temas/comision/117967">
        Foro <span class="w3-badge w3-red w3-small">3</span>
      </a>
      <a href="/evaluacion/evaluaciones/comision/117967">Evaluación</a>
    </div>
  </div>
</body>
</html>
''';

const String fixtureCursoDetalles = '''
<div class="w3-container">
  <p>Cuatrimestre: 2C 2026</p>
  <p>Modalidad: Presencial</p>
  <ul>
    <li><strong>DOCENTE, UNO</strong> (Tutor/a)</li>
    <li>DOCENTE, DOS - Tutor/a</li>
  </ul>
</div>
''';

const String fixtureContenidosConNovedad = '''
<div class="w3-accordion">
  <div class="desplegarModulo">
    Generalidades <span class="w3-badge w3-red w3-small">2</span>
  </div>
  <div class="w3-accordion-content">
    <table class="w3-table">
      <tbody>
        <tr class=" w3-pale-yellow">
          <td><i class="icon-file-pdf"></i></td>
          <td>Acta de Cursada 2026<div class="w3-hide">Descripción oculta</div></td>
          <td>Obligatoria</td>
          <td>19/11/2026</td>
          <td>150 KB</td>
          <td>
            <a class="btnDescargar" href="/contenido/event/descargarElemento/comision/117967/a/acta.pdf/id/5001">
              <i class="material-icons w3-text-dark-gray">file_download</i>
            </a>
          </td>
        </tr>
        <tr class=" w3-pale-yellow">
          <td><i class="icon-file-explore"></i></td>
          <td>Video Clase 12</td>
          <td>Opcional</td>
          <td>20/11/2026</td>
          <td></td>
          <td>
            <a class="btnDescargar btnMarcarDescargado popup-video" data-id-archivo="5002" href="https://example.org/clase12">
              <i class="material-icons w3-text-dark-gray">open_in_new</i>
            </a>
          </td>
        </tr>
        <tr>
          <td><i class="icon-file-pdf"></i></td>
          <td>Cronograma Inicial</td>
          <td>Obligatoria</td>
          <td>10/08/2026</td>
          <td>80 KB</td>
          <td>
            <a class="btnDescargar" href="/contenido/event/descargarElemento/comision/117967/a/crono.pdf/id/4001">
              <i class="material-icons w3-text-theme">file_download</i>
            </a>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
''';

const String fixturePortafolioInicial = '''
<table class="w3-table w3-bordered w3-hoverable">
  <tbody>
    <tr>
      <td>Módulo 1<br><a href="/contenido/event/descargarElemento/comision/117967/a/tp1.pdf/id/282463">TP N°1</a></td>
      <td>Obligatoria Individual</td>
      <td>25/11/2026</td>
      <td><a href="/portafolio/entregas/comision/117967/id/282463">[ENTREGAR / VER]</a></td>
      <td>10/11/2026</td>
      <td>---</td>
      <td>ENTREGADO</td>
      <td>---</td>
    </tr>
  </tbody>
</table>
''';

const String fixturePortafolioCorregido = '''
<table class="w3-table w3-bordered w3-hoverable">
  <tbody>
    <tr>
      <td>Módulo 1<br><a href="/contenido/event/descargarElemento/comision/117967/a/tp1.pdf/id/282463">TP N°1</a></td>
      <td>Obligatoria Individual</td>
      <td>25/11/2026</td>
      <td><a href="/portafolio/entregas/comision/117967/id/282463">[ENTREGAR / VER]</a></td>
      <td>10/11/2026</td>
      <td>16/11/2026</td>
      <td>VISTO</td>
      <td>9</td>
    </tr>
  </tbody>
</table>
''';

const String fixturePortafolioEntregasCorregido = '''
<div class="w3-padding correccion">
  <div class="w3-row w3-padding-4">
    <div class="w3-col m3">Fecha y hora:</div>
    <div class="w3-col m9">16/11/2026 16:48:42</div>
  </div>
  <div class="w3-row w3-padding-4">
    <div class="w3-col m3">Estado:</div>
    <div class="w3-col m9">VISTO</div>
  </div>
  <div class="w3-row w3-padding-4">
    <div class="w3-col m3">Calificación:</div>
    <div class="w3-col m9">9</div>
  </div>
  <div class="w3-row w3-padding-4">
    <div class="w3-col m3">Observaciones:</div>
    <div class="w3-col m9">Excelente resolución.<br></div>
  </div>
  <div class="w3-row w3-padding-4">
    <div class="w3-col m3">Corregido por:</div>
    <div class="w3-col m9">DOCENTE, UNO</div>
  </div>
</div>
''';

const String fixtureMensajeriaVacia = '''
<table><tbody></tbody></table>
''';

const String fixtureMensajeriaConCorreccion = '''
<table>
  <tbody>
    <tr class="mensaje-no-leido">
      <td>16/11/2026</td>
      <td>DOCENTE, UNO</td>
      <td class="w3-right-align"><span title="Contiene archivo adjunto"><i class="material-icons">attachment</i></span></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verEntrada/comision/117967/pag/1/from/entrada/id/11135488">Corrección</a></td>
      <td class="w3-right-align">
        <a class="botonLeido" data-id="11135488" data-practica="0" data-estado="0">
          <i class="material-icons">markunread</i>
        </a>
      </td>
      <td class="w3-hide-small"><span class="w3-hide"></span></td>
    </tr>
    <tr class="mensaje-leido">
      <td>10/11/2026</td>
      <td>ALUMNO, DOS</td>
      <td></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verEntrada/comision/117967/pag/1/from/entrada/id/11130001">Consulta vieja</a></td>
      <td>
        <a class="botonLeido" data-id="11130001" data-practica="0" data-estado="1">
          <i class="material-icons">drafts</i>
        </a>
      </td>
      <td><span>11/11/2026</span></td>
    </tr>
  </tbody>
</table>
''';

const String fixtureForoTemasInicial = '''
<div class="foro-tema">
  <div class="foro-icono"></div>
  <a href="https://miel.unlam.edu.ar/forov2/mensajes/comision/117967/tema/229745">
    <div class="w3-medium"><strong>Consultas Parcial 2</strong></div>
  </a>
  <div class="w3-padding-4">Espacio de consultas</div>
  <div>5 mensajes · Último mensaje 14/11/2026 10:00:00</div>
</div>
''';

const String fixtureForoTemasConActividad = '''
<div class="foro-tema">
  <div class="foro-icono">
    <span class="w3-badge w3-red w3-small badge-icono">3</span>
  </div>
  <a href="https://miel.unlam.edu.ar/forov2/mensajes/comision/117967/tema/229745">
    <div class="w3-medium"><strong>Consultas Parcial 2</strong></div>
  </a>
  <div class="w3-padding-4">Espacio de consultas</div>
  <div>8 mensajes · Último mensaje 20/11/2026 12:30:00</div>
</div>
''';

const String fixtureForoMensajesHilo = '''
<html>
<body>
  <script>var usuarioId = '900001';</script>
  <h1>Tema: Consultas Parcial 2</h1>
  <div id="6193115">
    <ul>
      <li class="w3-padding-16 foro-mensaje" data-idmensajepadre="6193115" id="idMensaje-6193115">
        <div><strong>ALUMNO, EJEMPLO</strong></div>
        <div class="w3-text-gray"><i class="material-icons">account_circle</i> Alumno/a (com 01-2900)</div>
        <div>Enviado el 19/11/2026 18:00:00</div>
        <div class="foro-contenido-mensaje">¿Entra el tema de interrupciones en el parcial?</div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193115" data-idusuario="900001" data-idmensaje="6193115">Responder</a>
      </li>
      <li class="w3-padding-16 foro-respuesta" data-idmensajepadre="6193115" id="idMensaje-6193120">
        <div><strong>DOCENTE, UNO</strong></div>
        <div class="w3-text-gray"><i class="material-icons">school</i> Tutor/a (com 01-2900)</div>
        <div>Enviado el 20/11/2026 12:30:00</div>
        <div class="foro-contenido-mensaje">
          <strong class="tagUsuario" data-idusuario="900001" data-idmensaje="6193115">@ALUMNO, EJEMPLO</strong>
          Sí, entra completo junto con los ejercicios de la guía 4.
        </div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193115" data-idusuario="900099" data-idmensaje="6193120">Responder</a>
      </li>
      <li class="w3-padding-16 foro-respuesta" data-idmensajepadre="6193115" id="idMensaje-6193121">
        <div><strong>ALUMNO, DOS</strong></div>
        <div class="w3-text-gray"><i class="material-icons">account_circle</i> Alumno/a (com 01-2900)</div>
        <div>Enviado el 20/11/2026 12:35:00</div>
        <div class="foro-contenido-mensaje">¡Gracias profe!</div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193115" data-idusuario="900002" data-idmensaje="6193121">Responder</a>
      </li>
    </ul>
  </div>
  <div id="6193200">
    <ul>
      <li class="w3-padding-16 foro-mensaje" data-idmensajepadre="6193200" id="idMensaje-6193200">
        <div><strong>ALUMNO, DOS</strong></div>
        <div class="w3-text-gray">Alumno/a (com 01-2900)</div>
        <div>Enviado el 19/11/2026 19:00:00</div>
        <div class="foro-contenido-mensaje">Otra consulta ajena</div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193200" data-idusuario="900002" data-idmensaje="6193200">Responder</a>
      </li>
      <li class="w3-padding-16 foro-respuesta" data-idmensajepadre="6193200" id="idMensaje-6193201">
        <div><strong>DOCENTE, UNO</strong></div>
        <div class="w3-text-gray">Tutor/a (com 01-2900)</div>
        <div>Enviado el 20/11/2026 12:40:00</div>
        <div class="foro-contenido-mensaje">Respuesta a otro alumno sin mencionarte</div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193200" data-idusuario="900099" data-idmensaje="6193201">Responder</a>
      </li>
    </ul>
  </div>
</body>
</html>
''';

const String fixtureEvaluaciones = '''
<table class="w3-table">
  <tbody>
    <tr>
      <td>PDC</td>
      <td>TPo N°3</td>
      <td><span title="Habilitado">●</span></td>
      <td>Abierto</td>
      <td><a class="botonIngresar" data-id="7781" data-tc="1" data-tipo="pdc">Ingresar</a></td>
    </tr>
  </tbody>
</table>
''';
