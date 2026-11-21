# 03 — Panel Principal (`/principal/interno/`), Badges y Módulos Adicionales

El panel principal (`GET https://miel.unlam.edu.ar/principal/interno/`) es el punto de entrada tras el login y una pieza central para diseñar un sistema de notificaciones eficiente.

---

## 1. Estructura de Tarjetas de Materias (`.materia-bloque`)

El HTML renderizado del servidor incluye todas las comisiones asociadas al estudiante dentro de bloques `.materia-bloque`:

- **Atributo clave:** `data-id="{idComision}"` (identificador numérico único de la comisión en MIEL).
- **Nombre de la materia:** `.materia-titulo` (ej. `<div class="w3-slarge materia-titulo">...</div>`).
- **Código de comisión:** dentro del primer bloque `.w3-small` bajo el título (`Com: XX-XXXX`).
- **Materias ocultas:** Permanecen en el DOM con clase `.materia-bloque-oculta` (y `w3-hide`, alternables en la web con `.btnMostrarOcultas` / `.btnOcultarOcultas`). El cliente debe distinguirlas para no consultar innecesariamente materias archivadas u ocultas por el estudiante.
- **Foto de perfil del estudiante:** se expone en `.fotoPerfil` (frecuentemente vía estilo `background-image: url(...)` o `<img>`) y apunta a recursos autenticados que requieren las cookies de sesión (`PHPSESSID` + `SESSID`), al igual que `.fotoRemitente` en Mensajería y `.foro-fotoPerfil` en Foros.
- **Anuncios / paneles globales descartables:** `/principal/interno/` admite paneles `.w3-panel` que pueden marcarse como leídos vía `POST /principal/event/marcarLeidaAjax/` (`idNotificacion`).

---

## 2. Detalles de Comisión y Lista de Docentes

Cada tarjeta expone un modal cargado por AJAX:

- **Endpoint:** `GET https://miel.unlam.edu.ar/principal/cursoDetalles/id/{idComision}`
- **Formato:** Fragmento HTML.
- **Datos disponibles:**
  - Código de materia, comisión, cuatrimestre, modalidad, aula y departamento.
  - **Lista completa de docentes asignados con rol `Tutor/a`**.

> **Valor clave:** Cachear la lista de docentes de cada comisión una vez por sesión/día permite identificar con certeza si un remitente en **Mensajería** es docente o alumno **sin necesidad de abrir el mensaje** (evitando marcarlo como leído).

---

## 3. Sistema de Badges (`.w3-badge`) en `/principal/interno/`

Uno de los hallazgos más importantes del relevamiento (validado con cuentas con actividad real sin leer) es cómo funcionan los indicadores rojos `<span class="w3-badge w3-red w3-small">{N}</span>` dentro de `.materia-herramientas` y el menú lateral `nav`:

| Módulo / Sección | ¿Muestra badge en `/principal/interno/`? | Observaciones verificadas |
| :--- | :---: | :--- |
| **Contenidos** | **Sí** | Muestra la cantidad de archivos/elementos nuevos sin ver. **Atención:** el badge desaparece apenas se realiza un `GET` a `/contenido/archivos/comision/{id}` (ver doc `04`). |
| **Mensajes (Mensajería)** | **Sí** | Coincide exactamente con la cantidad de filas `tr.mensaje-no-leido` en la bandeja de entrada de esa comisión. Además, la suma total de mensajes no leídos se inyecta en `<title>` (`"(N) MIeL - ..."`). |
| **Foro (`forov2`)** | **Sí** | Coincide exactamente con la suma de badges `.w3-badge` de todos los temas activos en `/forov2/temas/comision/{id}`. |
| **Novedades globales (`nav`)** | **Sí** | Enlace `/principal/novedades/` en el menú lateral muestra badge rojo cuando hay anuncios institucionales nuevos. |
| **Portafolio** | **No** | No muestra badge por prácticas nuevas pendientes ni por correcciones/notas. *(Sin embargo, una corrección docente suele disparar un mensaje automático en **Mensajería**, encendiendo indirectamente el badge de `Mensajes`).* |
| **Evaluación** | **No** | No muestra badge cuando hay evaluaciones/TPs abiertos o habilitados. |
| **Autoguía** | **No** | Sin badge en el panel interno. |
| **Encuestas** | **No** | Sin badge en el panel interno. |
| **Chat** | **No** | Sus contadores `#cantidadMensajesNuevosCom{id}` solo se calculan en memoria JS mientras la pestaña del chat está abierta. |
| **Calendario** | **No** | Sin badge en el panel interno. |

### Conclusión operativa del panel principal
**Una sola petición `GET /principal/interno/`** (que además es completamente de solo lectura y no altera estados de visto) alcanza para detectar actividad pendiente en **Contenidos, Mensajería, Foros y Novedades globales** de todas las materias a la vez.  
Para **Portafolio** (nuevas prácticas o fechas límite) y **Evaluación**, se necesita un sondeo periódico aparte de menor frecuencia.

---

## 4. Módulos Adicionales Relevados

Además de los 4 módulos objetivo (*Contenidos*, *Portafolio*, *Mensajería* y *Foro*), las comisiones pueden habilitar otras herramientas en `.materia-herramientas` y en el menú lateral:

- **Evaluación:**
  - `GET https://miel.unlam.edu.ar/evaluacion/evaluaciones/comision/{idComision}`
  - Tabla HTML con columnas `Tipo` (ej. `PDC`), `Título`, `Habilitado` (indicador visual), `Estado` (ej. `Abierto` + ícono `lock_open`) y botón `[Ingresar]` (`a.botonIngresar[data-id][data-tc][data-tipo]`; si `data-tc="1"` solicita clave vía `#popupClave` hacia `POST /evaluacion/event/ingresar/comision/{idComision}`).
  - *Relevancia para notificaciones:* Alta (opcional), ya que no tiene badge en `/principal/interno/` y un docente puede habilitar cuestionarios o evaluaciones con ventana temporal acotada.
- **Autoguía:**
  - `GET https://miel.unlam.edu.ar/autoguia/modulos/comision/{idComision}`
  - Tarjetas `.autoguia-card` con módulos de estudio y porcentaje de avance.
- **Encuestas:**
  - `GET https://miel.unlam.edu.ar/encuesta/encuestas/comision/{idComision}`
  - Listado de encuestas/formularios de la comisión.
- **Chat:**
  - `GET https://miel.unlam.edu.ar/chat/chat/comision/{idComision}`
  - Usa polling AJAX cada **2.500 ms** vía `POST /chat/event/cargar-mensajes/`. No utiliza WebSockets.
- **Calendario:**
  - `GET https://miel.unlam.edu.ar/calendario/calendario/`
  - Carga mensual bajo demanda `POST /calendario/event/obtenerCalendarioAjax/` y detalle `GET /calendario/eventosPopup//fecha/{YYYY-MM-DD}`.
- **Novedades y enlaces laterales:**
  - `/principal/novedades/`, `Curso Ley Micaela`, `Biblioteca BiDi`.
