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

const String fixtureContenidosFase2Jerarquico = '''
<main>
  <div class="desplegarModulo w3-btn-block w3-light-grey">
    <i class="material-icons">folder</i>
    <span>Presentaciones de Clase</span>
    <span class="w3-badge w3-red w3-small">1</span>
  </div>
  <div class="w3-accordion-content">
    <table class="w3-table w3-bordered w3-hoverable">
      <thead>
        <tr>
          <th colspan="2">Slides Teoría</th>
          <th>Tipo lectura</th>
          <th>F. subida</th>
          <th>Tamaño</th>
          <th>Descargar</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><i class="material-icons icon-file-power"></i></td>
          <td>Presentación Unidad 1</td>
          <td>Obligatoria</td>
          <td>15/08/2026</td>
          <td>1.200 KB</td>
          <td>
            <a href="/contenido/event/descargarElemento/comision/117967/a/u1.pptx/id/6001" class="btnDescargar">
              <i class="material-icons w3-text-theme">file_download</i>
            </a>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <table class="w3-table w3-bordered w3-hoverable">
    <thead>
      <tr>
        <th colspan="2">Módulo 00 | Presentación de la materia</th>
        <th>Tipo lectura</th>
        <th>F. subida</th>
        <th>Tamaño</th>
        <th>Descargar</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><i class="material-icons icon-file-explore"></i></td>
        <td>Encuesta Alumnos</td>
        <td>Obligatoria</td>
        <td>14/08/2026</td>
        <td></td>
        <td>
          <a href="https://forms.example.edu/encuesta" class="btnDescargar btnMarcarDescargado link-icon" data-id-archivo="6002">
            <i class="material-icons w3-text-theme">link</i>
          </a>
        </td>
      </tr>
    </tbody>
    <thead>
      <tr>
        <th colspan="2">Módulo 01 | Modelos de Ciclo de Vida</th>
        <th>Tipo lectura</th>
        <th>F. subida</th>
        <th>Tamaño</th>
        <th>Descargar</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><i class="material-icons icon-file-text"></i></td>
        <td>
          Presentación Modelo de Ciclo de Vida
          <i class="material-icons verDescripcion">more_horiz</i>
          <div class="w3-padding-4 w3-text-grey w3-hide">https://prezi.example.com/ciclo-de-vida</div>
        </td>
        <td>Obligatoria</td>
        <td>11/04/2026</td>
        <td>0 KB</td>
        <td>
          <a href="/contenido/event/descargarElemento/comision/117967/a/ciclo.txt/id/6003" class="btnDescargar">
            <i class="material-icons w3-text-dark-gray">file_download</i>
          </a>
        </td>
      </tr>
    </tbody>
  </table>
</main>
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
<main>
  <div>Trabajos Prácticos - TP N°1 · <a href="/contenido/event/descargarElemento/comision/117967/a/tp1.pdf/id/282463" class="link">[Descargar]</a></div>
  <div class="w3-section">Entrega <strong>obligatoria grupal</strong></div>
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
  <div class="w3-padding entrega">
    <div class="w3-row w3-padding-4"><div class="w3-col"><strong>1º ENTREGA</strong></div></div>
    <div class="w3-row w3-padding-4"><div class="w3-col m3">Fecha y hora:</div><div class="w3-col m9">24/09/2026 01:07:59</div></div>
    <div class="w3-row w3-padding-4"><div class="w3-col m3">Práctica enviada:</div><div class="w3-col m9"><div><i class="material-icons">attach_file</i><a href="/portafolio/event/descargarEntrega/comision/117967/id/3712651" class="link">Entrega-Grupo-Demo.pdf</a></div></div></div>
    <div class="w3-row w3-padding-4"><div class="w3-col m3">Entrega grupal:</div><div class="w3-col m9">SÍ - <strong>Grupo Demo</strong><br>- ESTUDIANTE, DEMO 1 (00000001)<br>- ESTUDIANTE, DEMO 2 (00000002)</div></div>
    <div class="w3-row w3-padding-4"><div class="w3-col m3">Mensaje:</div><div class="w3-col m9">Adjuntamos entrega final</div></div>
  </div>
</main>
''';

const String fixturePortafolioNotasAsistencia = '''
<main>
  <h3>Asistencia</h3>
  <div class="asistencia-alumno w3-center">
    <div>18/08/2026</div>
    <div class="w3-green w3-round-small w3-padding-4">Presente</div>
    <div class="w3-text-gray">Virtual</div>
  </div>
  <div class="asistencia-alumno w3-center">
    <div>20/10/2026</div>
    <div class="w3-red w3-round-small w3-padding-4">Ausente</div>
    <div class="w3-text-gray"></div>
  </div>
  <h3>Notas de evaluación y autoevaluación</h3>
  <p>No hay evaluaciones o autoevaluaciones realizadas en MIeL.</p>
  <h3>Certificados</h3>
  <p>No se encontraron certificados para este curso.</p>
</main>
''';

const String fixtureMensajeriaVacia = '''
<table><tbody></tbody></table>
''';

const String fixtureMensajeriaConCorreccion = '''
<div>Página 1 de 2</div>
<table>
  <tbody>
    <tr class="mensaje-no-leido">
      <td>16/11/2026</td>
      <td>DOCENTE, UNO</td>
      <td class="w3-right-align"><span title="Contiene archivo adjunto"><i class="material-icons">attachment</i></span></td>
      <td><a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verEntrada/comision/117967/pag/1/from/entrada/id/11135488">Corrección</a></td>
      <td class="w3-right-align">
        <a class="botonFavorito" data-id="11135488" data-estado="1"><i class="material-icons">star</i></a>
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
        <i class="material-icons w3-text-purple">reply</i>
        <a class="botonFavorito" data-id="11130001" data-estado="0"><i class="material-icons">star_border</i></a>
        <a class="botonLeido" data-id="11130001" data-practica="0" data-estado="1">
          <i class="material-icons">drafts</i>
        </a>
      </td>
      <td><span>11/11/2026</span></td>
    </tr>
  </tbody>
</table>
''';

const String fixtureMensajeriaVerEntradaDetalle = '''
<main>
  <div class="w3-clear">
    <h1 class="w3-left">Ejercicio de bondad de ajuste</h1>
    <div class="w3-right"><a href="/mensajeria/entrada/comision/117967/pag/1" class="w3-btn w3-theme">Volver</a></div>
  </div>
  <div class="w3-row w3-section">
    <div class="w3-col w3-hide-small" style="width:65px;"><div class="w3-circle fotoRemitente"></div></div>
    <div class="w3-rest">
      <div><span class="w3-medium">De: DOCENTE, UNO</span><span class="w3-text-grey"> · Tutor/a</span></div>
      <div class="w3-text-grey">Para: 49 personas <a href="javascript:void(0)" data-mfp-src="/mensajeria/verDestinatariosEntrada/comision/117967/usuario/66174/idMensaje/11023589" class="popup-destinatarios"><i class="material-icons">more_horiz</i></a></div>
      <div class="w3-text-grey">20/10/2026 16:39:47 hs.</div>
      <div class="w3-section contrastify">
        <p>Buenas!</p>
        <p>Les pasamos un ejercicio extra para resolver en clase <strong>presencial</strong>.</p>
      </div>
      <div class="w3-section">
        <i class="material-icons icon-file-pdf icono-td"></i> Descargar archivo:
        <a href="/mensajeria/event/descargar/comision/117967/a/3656%5C_enunciado_bondad.pdf/t/M" class="link">enunciado_bondad.pdf</a>
      </div>
    </div>
  </div>
</main>
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
  <div class="w3-padding-4"><span class="w3-text-indigo"><i class="material-icons">group</i> Tema público - </span>Espacio de consultas</div>
  <div>8 mensajes · Último mensaje 20/11/2026 12:30:00</div>
</div>
''';

const String fixtureForoMensajesHilo = '''
<html>
<body>
  <script>var usuarioId = '900001';</script>
  <h1>Tema: Consultas Parcial 2</h1>
  <div id="textoUltimoMensaje">Último mensaje 20/11/2026, 12:40:00</div>
  <div id="textoCantidadMensajes">5 Mensajes</div>
  <div id="6193115">
    <ul>
      <li class="w3-padding-16 foro-mensaje" data-idmensajepadre="6193115" id="idMensaje-6193115">
        <div><strong>ALUMNO, EJEMPLO</strong></div>
        <div class="w3-text-gray"><i class="material-icons">account_circle</i> Alumno/a (com 01-2900)</div>
        <div>Enviado el 19/11/2026 18:00:00</div>
        <div class="foro-contenido-mensaje"><p>¿Entra el tema de interrupciones en el parcial?</p></div>
        <div class="w3-row"><div class="w3-col l4 m6"><img class="foroImgAdjuntos w3-responsive" src="/forov2/event/descargar/comision/117967/a/3656%5C_captura_formula.png"></div></div>
        <a class="btnMostrarDivRespuesta" data-idmensajepadre="6193115" data-idusuario="900001" data-idmensaje="6193115">Responder</a>
        <a class="btnMarcarUtil" data-idmensaje="6193115" data-util="0"><strong class="mensaje" id="msj_6193115">Me gusta (2)</strong></a>
      </li>
      <li class="w3-padding-16 foro-respuesta" data-idmensajepadre="6193115" id="idMensaje-6193120">
        <div><strong>DOCENTE, UNO</strong></div>
        <div class="w3-text-gray"><i class="material-icons">school</i> Tutor/a (com 01-2900)</div>
        <div>Enviado el 20/11/2026 12:30:00</div>
        <div class="foro-contenido-mensaje">
          <strong class="tagUsuario" data-idusuario="900001" data-idmensaje="6193115">@ALUMNO, EJEMPLO</strong>
          Sí, entra completo junto con los ejercicios de la guía 4.
        </div>
        <div class="w3-padding-4"><i class="material-icons icon-file-pdf icono-td"></i> Archivo adjunto: <a href="/forov2/event/descargar/comision/117967/a/3656%5C_Guia4-Resuelta.pdf" class="link">Guia4-Resuelta.pdf</a></div>
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

const String fixtureEvaluaciones6Columnas = '''
<table class="w3-table w3-bordered w3-hoverable tabla-mensajes">
  <tbody>
    <tr>
      <td>Auto-Evaluacion</td>
      <td>Autoevaluación: Revisión de Ensayo de Hipótesis</td>
      <td class="w3-center"><div class="w3-circle w3-green tippy" data-tippy-content="Habilitado para rendir"></div></td>
      <td><i class="material-icons icono-td" title="Abierto">lock_open</i></td>
      <td>0/2 intentos</td>
      <td><a class="botonIngresar link" data-id="8890" data-tc="0" data-tipo="auto">[Ingresar]</a></td>
    </tr>
  </tbody>
</table>
''';
