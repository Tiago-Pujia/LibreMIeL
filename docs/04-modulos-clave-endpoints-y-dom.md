# 04 — Referencia de Endpoints, DOM y Efectos Colaterales (4 Módulos Clave)

Este documento detalla la estructura HTTP y HTML/JSON de las cuatro áreas prioritarias de MIeL que motivan el proyecto: **Contenidos**, **Portafolio**, **Mensajería** y **Foros (`forov2`)**.

---

## 1. Contenidos

### Endpoints
- **Listado completo:** `GET https://miel.unlam.edu.ar/contenido/archivos/comision/{idComision}`
  - Subsecciones opcionales: `/contenido/glosario/comision/{idComision}`, `/contenido/faq/comision/{idComision}`.
  - Búsqueda/filtro: `POST` al mismo URL con `buscarTipo` y `buscarPalabra`.
- **Descarga de archivo alojado en MIeL:**  
  `GET https://miel.unlam.edu.ar/contenido/event/descargarElemento/comision/{idComision}/a/{nombreCodificado}/id/{idElemento}`
- **Marcar enlace/video externo como visto/descargado:**  
  `GET https://miel.unlam.edu.ar/contenido/event/marcarElementoDescargadoAjax/comision/{idComision}?id={idElemento}`

### Estructura HTML y Metadatos
- **100% HTML server-side.** Todo el árbol de módulos/carpetas viene incluido en la respuesta inicial dentro de `div.w3-accordion` con pares `div.desplegarModulo` + `div.w3-accordion-content > table.w3-table` (o tablas planas con **múltiples pares alternados `<thead>` + `<tbody>`** dentro de un mismo `<table>`, uno por submódulo). Abrir una carpeta en la web solo alterna `.w3-show` sin peticiones de red.
- Si no hay archivos cargados, muestra `<p>No se encontraron archivos en este curso.</p>`.
- **Por cada fila `<tr>` (ítem):**
  - **Tipo de recurso:** clase CSS del ícono (`icon-file-pdf`, `icon-file-image`, `icon-file-text`, `icon-file-explore` para links externos, `.link-icon`, `.popup-video` para YouTube, `.popup-mp4` para videos locales).
  - **ID único estable (`{idElemento}`):** extraíble de `/id/{idElemento}` en el `href` de descarga o del atributo `data-id-archivo="{idElemento}"` en recursos externos con clase `.btnMarcarDescargado`.
  - **Título y descripción:** nombre del archivo + descripción oculta opcional (`.verDescripcion` + `<div class="w3-hide">`).
  - **Metadatos tabulares:** `Tipo lectura` (ej. `Obligatoria`), `F. subida` (`DD/MM/YYYY`), `Tamaño` (ej. `150 KB`, vacío en links externos).
  - **Estado descargado / no descargado (persistente):**
    - Dentro de `a.btnDescargar > i`: `w3-text-dark-gray` indica **aún no descargado/abierto**; `w3-text-theme` indica **ya descargado/abierto**.

### ⚠️ Efecto Colateral Crítico al Consultar (`GET`)
- Antes de entrar a Contenidos, si el docente subió material nuevo:
  - `/principal/interno/` muestra `<span class="w3-badge w3-red w3-small">{N}</span>` en `Contenidos`.
  - En el **primer `GET`** a `/contenido/archivos/comision/{idComision}`, la carpeta `.desplegarModulo` afectada muestra `<span class="w3-badge w3-red w3-small">{N}</span>` y las filas nuevas tienen la clase `<tr class="w3-pale-yellow">`.
- **Al responder ese primer `GET`**, el backend de MIeL **limpia automáticamente** el badge de `/principal/interno/`, el badge de la carpeta y la clase `w3-pale-yellow` (aunque no se descargue ningún archivo).
- **Regla obligatoria:** No hacer polling ciego a `/contenido/archivos/comision/{idComision}`. Consultar primero `/principal/interno/` y solo pedir `/contenido/archivos/...` cuando el badge sea `> 0` (capturando en ese único `GET` las filas `w3-pale-yellow` y haciendo *diff* contra el snapshot local de `{idElemento}`).

---

## 2. Portafolio

### Endpoints
- **Listado de prácticas:** `GET https://miel.unlam.edu.ar/portafolio/practicas/comision/{idComision}`
- **Detalle de entregas y devoluciones:** `GET https://miel.unlam.edu.ar/portafolio/entregas/comision/{idComision}/id/{idPractica}` *(nota: `id/0` corresponde a "Otras prácticas")*.
- **Descarga de entrega enviada:** `GET https://miel.unlam.edu.ar/portafolio/event/descargarEntrega/comision/{idComision}/id/{idEntrega}`
- **Subsecciones complementarias:** `/portafolio/archivosEnviados/comision/{id}`, `/portafolio/grupos/comision/{id}`, `/portafolio/notas/comision/{id}`, `/portafolio/competencias/comision/{id}`.

### Estructura HTML y Metadatos
- **100% HTML server-side** (solo lectura, no altera badges ni vistos).
- **Tabla principal (`.w3-table.w3-bordered.w3-hoverable`) en `/portafolio/practicas/...`:**
  - `Práctica`: nombre del módulo + `<br>` + enlace de descarga a la consigna (`/contenido/event/descargarElemento/.../id/{idPractica}`).
  - `Entrega`: modalidad (`Obligatoria` / `Opcional`, `Individual` / `Grupal`).
  - `F. vencim.`: fecha límite (`DD/MM/YYYY` o `---`).
  - `Detalle entregas`: enlace `[ENTREGAR / VER]` → `/portafolio/entregas/comision/{idComision}/id/{idPractica}`.
  - `F. entrega`: fecha de última entrega (`DD/MM/YYYY` o `---`).
  - `F. correc.`: fecha de corrección docente (`DD/MM/YYYY` o `---`).
  - `Estado`: ej. `ENTREGADO`, `VISTO`, `---`, etc.
  - `Nota`: calificación publicada (o vacío / `---`).
- **Bloques de detalle en `/portafolio/entregas/...`:**
  - Tras `#formNuevaEntrega`, aparecen los bloques de devolución docente `<div class="w3-padding correccion">` y los de entregas `<div class="w3-padding entrega">` (`1º ENTREGA`, etc.).
  - Campos dentro de `div.correccion` (filas `.w3-row.w3-padding-4` con `.w3-col.m3` etiqueta y `.w3-col.m9` valor):
    - `Fecha y hora:` (`DD/MM/YYYY HH:MM:SS`)
    - `Estado:` (ej. `VISTO`, `APROBADO`, etc.)
    - `Calificación:`
    - `Observaciones:`
    - `Corregido por:` (`APELLIDO, NOMBRE` del docente)
  - Campos dentro de `div.entrega`: `Fecha y hora:`, `Práctica enviada:` (enlace de descarga o aviso de descarga deshabilitada), `Entrega grupal:` (`NO` o `SÍ - GRUPO NºX` con integrantes) y `Mensaje:`.
- **Asistencia en `/portafolio/notas/comision/{idComision}`:**
  - Tarjetas `div.asistencia-alumno` con clases de estado oficial W3.CSS: `.w3-green` (`Presente`), `.w3-red` (`Ausente`) y `.w3-blue` (`Justificado`, `#2196F3` en modo claro / `#4F90C4` en modo oscuro), acompañadas por la modalidad (`Virtual` / `Presencial`).

### Relación con Mensajería y Detección de Cambios
- Portafolio **no muestra badge** en `/principal/interno/`.
- Sin embargo, **cuando un docente corrige una entrega**, MIeL genera un **mensaje automático en Mensajería** (asunto `"Corrección"`, con `Módulo`, `Práctica` y `Estado`), lo que sí enciende el badge de `Mensajes`.
- Para detectar **prácticas nuevas publicadas** o **cambios en `F. vencim.`**, el cliente debe comparar periódicamente un snapshot de `/portafolio/practicas/comision/{idComision}` indexado por `{idPractica}`.

---

## 3. Mensajería

### Alcance y Endpoints
- **Alcance estrictamente por comisión:** **No existe bandeja global.** `GET https://miel.unlam.edu.ar/mensajeria/entrada/` sin `/comision/{idComision}` redirige a `/errores/403/`.
- **Bandeja de entrada:** `GET https://miel.unlam.edu.ar/mensajeria/entrada/comision/{idComision}` (paginación `/pag/{n}`).
- **Otras bandejas:** `/mensajeria/salida/comision/{id}`, `/mensajeria/borradores/comision/{id}`, `/mensajeria/favoritos/comision/{id}`.
- **Ver detalle de mensaje:** `GET https://miel.unlam.edu.ar/mensajeria/verEntrada/comision/{idComision}/pag/{p}/from/entrada/id/{idMensaje}`
- **Descarga de adjunto:** `GET https://miel.unlam.edu.ar/mensajeria/event/descargar/comision/{idComision}/a/{archivoCodificado}/t/M`
- **Destinatarios / Redacción:**
  - `GET /mensajeria/verDestinatariosEntrada/comision/{id}/usuario/{idUsuario}/idMensaje/{idMensaje}`
  - `GET /mensajeria/redactar/comision/{id}` (lista destinatarios con `data-type="tutor"` / `"alumno"` / `"tutores"` / `"grupo"`).
- **Acciones AJAX (para futuras funciones interactivas):**
  - `POST /mensajeria/event/marcarLeido/comision/{id}`
  - `POST /mensajeria/event/marcarFavorito/comision/{id}`
  - `POST /mensajeria/event/marcarTodosComoLeidos/comision/{id}`
  - `POST /mensajeria/event/filtrarMensajes/comision/{id}`

### Estructura HTML Real de Fila No Leída vs. Leída
En `/mensajeria/entrada/comision/{idComision}`:

```html
<tr class="mensaje-no-leido">
  <td>DD/MM/YYYY</td>
  <td>APELLIDO, NOMBRE</td>
  <td class="w3-right-align">
    <!-- Opcional: <span title="Contiene archivo adjunto"><i class="material-icons ...">attachment</i></span> -->
  </td>
  <td>
    <a class="verMensaje" href="https://miel.unlam.edu.ar/mensajeria/verEntrada/comision/{idComision}/pag/1/from/entrada/id/{idMensaje}">
      Asunto del mensaje
    </a>
  </td>
  <td class="w3-right-align">
    <a href="javascript:void(0);" class="botonFavorito" data-id="{idMensaje}" data-estado="0">...</a>
    <a href="javascript:void(0);" class="botonLeido" data-id="{idMensaje}" data-practica="0" data-estado="0">
      <span title="Marcar como leído"><i class="material-icons w3-text-black icono-td">markunread</i></span>
    </a>
  </td>
  <td class="w3-hide-small"><span class="w3-hide"></span></td>
</tr>
```

- **Fila leída (`<tr class="mensaje-leido">`):** `data-estado="1"`, ícono `drafts` (`w3-text-gray`) y fecha de lectura visible en la última celda `<td><span>DD/MM/YYYY</span></td>`.
- **Variables JS inline en el HTML:** `cantidadMensajesPracticasNoLeidos` y `cantidadMensajesGeneralesNoLeidos`. *(Nota: en las comisiones relevadas no existe una pestaña separada de mensajes de prácticas — `/mensajeria/practicas/comision/{id}` devuelve `404` — y hasta las notificaciones de `"Corrección"` de Portafolio llegan a la bandeja general con `data-practica="0"`).*
- **Identificación de docente sin abrir el mensaje:** El listado solo muestra el nombre del remitente (el rol explícito `· Tutor/a` aparece dentro de `verEntrada`). Cruzando el nombre normalizado contra la lista cacheada de `Tutor/a` de `/principal/cursoDetalles/id/{idComision}` (o `/mensajeria/redactar/...`), la app sabe de inmediato si escribió un docente.

### ⚠️ Regla de Solo Lectura
- `GET /mensajeria/entrada/comision/{idComision}` **NO modifica** el estado de lectura.
- `GET /mensajeria/verEntrada/...` **SÍ marca** el mensaje como leído en el servidor. El monitor de notificaciones debe leer únicamente `entrada` y solo abrir `verEntrada` cuando el usuario abra el mensaje en la app.

---

## 4. Foros (`forov2`)

### Endpoints
- **Listado de temas:** `GET https://miel.unlam.edu.ar/forov2/temas/comision/{idComision}`
- **Hilo completo de un tema:** `GET https://miel.unlam.edu.ar/forov2/mensajes/comision/{idComision}/tema/{idTema}`
- **Descarga de adjunto:** `GET https://miel.unlam.edu.ar/forov2/event/descargar/comision/{idComision}/a/{archivoCodificado}`
- **Marcar todos los temas como leídos:** `POST https://miel.unlam.edu.ar/forov2/event/marcarTemasComoLeidos/comision/{idComision}`
- **Endpoints JSON de polling nativo** (que la web llama cada `15.000 ms` dentro de un tema):
  1. `GET /forov2/event/actualizarMensajes/comision/{idComision}/ultimoMensajeId/{maxId}?tema={idTema}`  
     → Devuelve `{"mensajes": [...], "cantMensajesActivos": N}`. (Para renderizar HTML de nuevos mensajes, la web llama a `POST /forov2/event/renderizarMensaje/comision/{idComision}`).
  2. `GET /forov2/event/actualizarCabecera/comision/{idComision}?codTema={idTema}`  
     → Devuelve `{"fechaUltimoMensajeActivo": "YYYY-MM-DD HH:MM:SS", "cantidadMensajesActivos": N}`.
  3. `GET /forov2/event/actualizarVotos/comision/{idComision}?tema={idTema}`
  4. `GET /forov2/event/actualizarMensajesBaneados/comision/{idComision}?tema={idTema}`
- **Endpoints interactivos (para futuras funciones de escritura):**
  - Nuevo mensaje: `POST /forov2/event/nuevoMensajeAjax/comision/{idComision}` (cuerpo codificado en Base64 en `#mensajeNuevoBase64`).
  - Nueva respuesta: `POST /forov2/event/nuevaRespuestaAjax/comision/{idComision}` (`#respuestaNuevaBase64`).
  - Me gusta: `POST /forov2/event/marcarUtil/comision/{idComision}`.

### Estructura HTML y Metadatos
- **En `/forov2/temas/comision/{idComision}`:**
  - Cada bloque `.foro-tema` contiene enlace al tema (`/forov2/mensajes/comision/{id}/tema/{idTema}`), título, descripción, cantidad de mensajes (`N mensajes`), fecha exacta del último mensaje (`Último mensaje DD/MM/YYYY HH:MM:SS`), estado (`Tema abierto` / `Tema vencido` con ícono `speaker_notes_off`) y badge de no leídos `<span class="w3-badge w3-red w3-small badge-icono">{N}</span>` dentro de `.foro-icono` (y duplicado para mobile).
  - La suma de badges de los temas coincide exactamente con el badge de `Foro` en `/principal/interno/`.
  - *Nota menor:* algunas comisiones con temas vencidos pueden mostrar `#botonMarcarTemasLeidos` aunque tengan `0` badges visibles en temas activos.
- **En `/forov2/mensajes/comision/{idComision}/tema/{idTema}`:**
  - Incluso las respuestas colapsadas (`.respuestaOculta`) vienen en el HTML inicial.
  - El JS inline expone el ID numérico del usuario logueado: `var usuarioId = '{id}';`.
  - Cada hilo raíz está envuelto en `<div id="{idMensajeRaiz}">`:
    - Mensaje raíz: `<li id="idMensaje-{id}" class="... foro-mensaje ..." data-idmensajepadre="{idMensajeRaiz}">`
    - Respuesta: `<li id="idMensaje-{id}" class="... foro-respuesta ..." data-idmensajepadre="{idMensajeRaiz}">`
  - **Rol del autor:** primer `.w3-text-gray` muestra `Tutor/a (com ...)` (ícono `school`) o `Alumno/a (com ...)`.
  - **ID del autor:** atributo `data-idusuario="{idAutor}"` en `.btnMostrarDivRespuesta` (junto con `data-idmensaje` y `data-idmensajepadre`).
  - **Mención / respuesta directa:** cuando alguien responde a un mensaje, MIeL inserta en `.foro-contenido-mensaje`:
    ```html
    <strong class="tagUsuario" data-idusuario="{idUsuarioDestinatario}" data-idmensaje="{idMensajeRespondido}">@NOMBRE</strong>
    ```

### Cómo Detectar "Un Docente te Respondió"
Un mensaje nuevo (`id > maxIdVisto`) corresponde a una respuesta docente al usuario si su rol es `Tutor/a` (o `Docente`) **y** cumple al menos una condición:
1. Contiene `.tagUsuario[data-idusuario="{usuarioId}"]`, **o**
2. Contiene `.tagUsuario[data-idmensaje]` apuntando a un mensaje cuyo autor es `{usuarioId}`, **o**
3. Pertenece a un `data-idmensajepadre` cuyo mensaje raíz (o alguna intervención previa del hilo) fue escrito por `{usuarioId}` *(cubre el caso donde el docente borra el `@mención` antes de enviar)*.

### ⚠️ Efecto Colateral al Entrar a un Hilo
- `GET /forov2/temas/comision/{idComision}` **NO** altera los badges de no leídos.
- `GET /forov2/mensajes/comision/{idComision}/tema/{idTema}` **SÍ** marca ese tema como leído en el servidor al entregar la vista (no depende de una llamada AJAX posterior).
- *Punto a validar en fase de prototipo:* Comprobar si consultar directamente `GET /forov2/event/actualizarMensajes/comision/{id}/ultimoMensajeId/{maxId}?tema={idTema}` (cuando ya se conoce `maxId`) devuelve mensajes nuevos **sin** marcar el tema como leído en la vista web.
