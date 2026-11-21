# 01 — Proyecto Relacionado: ExtraerForosMiel

Antes de iniciar **LibreMIeL**, se analizó el proyecto open source previo **[ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)**, que ya demostró en producción la viabilidad de autenticarse y extraer información estructurada de MIeL (UNLaM) mediante peticiones HTTP estándar, sin navegadores *headless*.

---

## 1. Resumen de [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)

### Propósito y enfoque
Herramienta CLI en Node.js (CommonJS, sin dependencias externas) diseñada para iniciar sesión en MIeL, obtener el listado de comisiones inscriptas del estudiante, descargar hilos completos de los foros (`forov2`) junto con sus adjuntos binarios (PDFs, imágenes y documentos) y exportarlos a Markdown (`.md`), JSON estructurado (`.json`) y HTML offline (`.html`).

### Arquitectura y módulos clave
- **`mielClient.js` (Cliente HTTP y gestión de sesión):**
  - Mantiene un almacén de cookies en memoria (`Map`) que captura cabeceras `set-cookie` en cada respuesta y las reenvía en el header `Cookie`.
  - Envía un `User-Agent` estándar de navegador de escritorio.
  - Sigue redirecciones HTTP (`301`, `302`, `303`, `307`, `308`) convirtiendo a `GET` cuando corresponde.
  - Soporta tanto texto UTF-8 como descargas binarias (`Buffer`) para adjuntos.
  - Implementa el login vía `POST https://miel.unlam.edu.ar/principal/event/login/` (`application/x-www-form-urlencoded` con `usuario` y `clave`) validando `{ "estado": 0 }` en el JSON de respuesta.
- **`forumParser.js` (Motor de parsing HTML):**
  - Extrae el nombre del estudiante autenticado desde `.nombreUsuario`.
  - Extrae materias y comisiones desde los bloques `<div ... materia-bloque ...>` de `/principal/interno/` (`data-id`, `.materia-titulo`, código `Com: XX-XXXX`).
  - Extrae temas de `/forov2/temas/comision/{idComision}` desde `.foro-tema` (con *fallback* al menú lateral), obteniendo `idTema`, título, descripción, cantidad de mensajes y fecha de último mensaje.
  - Extrae hilos de `/forov2/mensajes/comision/{idComision}/tema/{idTema}` desde `<li class="... foro-mensaje | foro-respuesta ..." data-idMensajePadre="..." id="idMensaje-...">`, reconstruyendo relación padre-hijo (`parentId`, `esRespuesta`), autor, rol (`Docente`, `Tutor`, `Alumno`), fecha, cuerpo convertido a Markdown limpio y adjuntos (`.foroImgAdjuntos` y enlaces `/forov2/event/descargar/...`).
  - Decodifica entidades HTML nominales y numéricas (`&#...;`, `&#x...;`) y sanitiza nombres de archivos/carpetas para compatibilidad entre Windows, macOS y Linux (`sanitizarNombre()`).
- **`exporters.js` e `index.js`:**
  - Serializan la conversación manteniendo agrupadas las respuestas con su mensaje padre.
  - Ejecutan las descargas de forma **secuencial** para evitar disparar límites de tasa (*rate-limiting*) en los servidores de la universidad.

---

## 2. Lecciones Reutilizables para LibreMIeL (y Guía para Agentes IA)

Cuando un desarrollador o agente IA diseñe el core de **LibreMIeL**, puede apoyarse en estas conclusiones ya validadas en [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel):

1. **Cliente HTTP nativo > Navegador headless:** No hace falta automatizar Chromium/Puppeteer para interactuar con MIeL; un cliente HTTP con *cookie jar* y seguimiento de redirecciones es órdenes de magnitud más liviano y portable a escritorio y Android.
2. **Parser DOM real recomendado:** En `ExtraerForosMiel` el parsing se hizo con expresiones regulares por su restricción de cero dependencias. En **LibreMIeL** conviene usar un **parser DOM real** (ej. `html` en Dart, `cheerio`/`linkedom` en TS, `jsoup`/`ksoup` en Kotlin) para mayor resistencia ante cambios menores de atributos o espacios en las plantillas PHP de MIeL.
3. **Descarga autenticada de binarios:** Todos los adjuntos de foros y contenidos requieren reutilizar exactamente la misma sesión (`PHPSESSID` + `SESSID`).
4. **Sanitización multiplataforma:** Mantener sanitización estricta de nombres al guardar archivos descargados en Windows, macOS, Linux y Android.
5. **Peticiones conservadoras:** Respetar ejecución secuencial (o concurrencia muy baja) para no sobrecargar los nodos de MIeL.

---

## 3. Qué se amplió respecto a `ExtraerForosMiel`

`ExtraerForosMiel` cubría únicamente login básico, listado de materias y descarga estática de foros. Los documentos `02` a `05` amplían esa base con el relevamiento completo de:
- **Contenidos**, **Portafolio**, **Mensajería** y módulos adicionales (`Evaluación`, `Autoguía`, `Encuestas`, `Chat`, `Calendario`, `Novedades`).
- **Badges en `/principal/interno/`** y los **efectos colaterales de lectura** de cada endpoint.
- **Endpoints AJAX/JSON del foro**, verificación/renovación de sesión, restricciones CORS y estrategia para notificaciones y futuras funcionalidades de **LibreMIeL**.
