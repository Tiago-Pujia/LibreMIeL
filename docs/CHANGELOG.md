# Changelog — LibreMIeL

Todos los cambios notables de **LibreMIeL** se documentan en este archivo.  
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto adhiere a [Versionado Semántico (SemVer)](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- Documentación técnica completa de la plataforma MIeL (`2025.2.0`) en `docs/`.
- Licencia **GPL-3.0** (`LICENSE`) y documentación de gobernanza en `docs/` (`CONTRIBUTING.md`, `AGENTS.md`, `STATUS.md`, `GIT_WORKFLOW.md`, `CHANGELOG.md`).
- Script anonimizador de capturas HTML de MIeL (`scripts/anonymize_html.py`) con tests automatizados (`scripts/test_anonymize_html.py`).
- Entorno de emulación Android AVD oficial (`LibreMIeL_Pixel7`, Pixel 7, Android 14 x86_64 con KVM) para depuración y pruebas locales/asistidas, documentado en `docs/CONTRIBUTING.md` y con captura en `docs/screenshots/android-login.png`.
- Estructura inicial de la aplicación **Flutter** multiplataforma (`android`, `linux`, `windows`, `macos`) bajo el identificador `io.github.tiago_pujia.libremiel`.
- Core de MIeL:
  - Cliente HTTP (`MielClient`) con manejo de cookies (`PHPSESSID`, `SESSID`), verificación de sesión y protección contra bloqueo de cuenta.
  - Parsers HTML puros para panel interno, detalles de comisión/docentes, Contenidos, Portafolio, Mensajería, Foros (`forov2`) y Evaluaciones, con tests unitarios y fixtures anonimizados.
  - Persistencia local SQLite (`Drift`) para snapshots, historial de notificaciones, caché de docentes y configuración por materia.
  - Motor de sincronización en dos ciclos (`SyncEngine`) con *baseline* silencioso inicial y respeto por efectos colaterales de lectura en MIeL.
- Interfaz fiel a **MIeL UNLaM** en modo claro y modo oscuro (`#009674` / `#128268`) con cambio rápido de tema persistido:
  - Pantalla de Login con degradado esmeralda, hexágonos flotantes animados, saludo dinámico, inputs translúcidos y botón primario blanco.
  - Pantalla de inicio idéntica a `/principal/interno/` (**Materias activas**) con barra doble superior (acceso **Mi perfil** y hovers completos), menú lateral minimalista (`230px` en escritorio, drawer en móvil), tarjetas de materias con herramientas semánticas (hover verde/azul/rojo, sin botón Chat), badges rojos, modo **Organizar materias** (arrastrar para reordenar, ocultar/mostrar y silenciar alertas), botón **Ver materias ocultas** junto a **Organizar materias** y diálogo `⋮` de docentes y alertas por módulo.
  - Feed de **Novedades** adaptado al estilo `.mensaje-no-leido` (borde esmeralda de `4px`) y pantalla de **Alertas y ajustes** con opción de **ejecutar LibreMIeL al iniciar el sistema** (Linux XDG Autostart, Windows Registry `HKCU\...\Run`, macOS LaunchAgents).
  - **Fase 2 — Lectura nativa completa** fiel a MIeL (`2025.2.0`), con separación estricta entre el cliente de sincronización (`MielApiClient`) y el lector interactivo (`MielInteractiveReader`), más servicio multiplataforma de descargas autenticadas (`FileDownloadService`):
    - **Contenidos:** árbol jerárquico con carpetas plegables (`.desplegarModulo`) y tablas con múltiples pares alternados `<thead>`/`<tbody>`, filtro por tipo (`Teoría`, `Prácticas`, `Enlaces`) y palabra clave con barra de búsqueda alineada, expansión de descripciones ocultas (`•••`), íconos semánticos `.icon-file-*` claro/oscuro, descarga autenticada nativa con notificación auto-descartable y marcado de enlaces externos vistos.
    - **Portafolio:** tabla completa de **Prácticas**, vista detallada **Entrega de prácticas** (bloques `div.correccion` y `div.entrega` con integrantes grupales y descarga autenticada), **Archivos enviados** y **Mis grupos** con cabeceras tabulares y **Asistencia, notas y certificados** (tarjetas `Presente` en verde, `Ausente` en rojo y `Justificado` en azul `.w3-blue`, más modalidad `Virtual`/`Presencial`).
    - **Mensajería:** bandejas de **Entrada**, **Salida**, **Borradores** y **Favoritos** (con retorno a la lista al re-clickear la bandeja activa en el lateral), modo **Bandeja unificada (`Todas las materias`)** en solo lectura, paginación, panel de filtros, lector completo `verEntrada`/`verSalida` con `MielRichText`, modal de destinatarios (`verDestinatariosEntrada`), fotos de perfil autenticadas y descarga de adjuntos.
    - **Foros (`forov2`):** listado de **Temas abiertos** con tarjetas completamente clicables (y navegación directa desde el menú lateral), lector de hilos con barra lateral esmeralda (`4px` raíz / `1.5px` respuestas), colapsado inteligente `Ver comentarios anteriores (N)`, buscador interno con resaltado amarillo, `Invertir orden`, insignia docente `Tutor/a`, `@menciones` interactivas con scroll y destello, avatares e imágenes embebidas autenticadas (`img.foroImgAdjuntos`) con visor modal de zoom (`InteractiveViewer`) y descarga de adjuntos.
    - **Módulos secundarios:** lectores nativos para **Evaluación** (tabla de 6 columnas con estado de habilitación, candado e intentos), **Encuestas** y **Autoguía**.
- **Fase 5 — Sesión permanente y auto-login continuo:**
  - Persistencia segura de credenciales en el llavero del sistema operativo (`flutter_secure_storage`) o archivo local protegido `chmod 600` en el directorio de soporte del usuario.
  - Auto-login inmediato en cada apertura de la app, iniciando sesión automáticamente sin requerir interacción del estudiante hasta que elija **Cerrar sesión** manualmente.
  - Reconexión silenciosa en segundo plano (`ensureActiveSession`) con exclusión mutua para re-autenticar y reintentar peticiones caídas ante vencimiento de `PHPSESSID`.
  - Keep-alive periódico en escritorio (`GET /principal/event/recargarSesion/`) cada 20 minutos para mantener la sesión viva.
  - Invariante anti-bloqueo: interrupción inmediata de reintentos ante respuestas `estado != 0` (clave cambiada o cuenta bloqueada).
- **Fase 3 — Escritura y envío nativo de contenido en MIeL:**
  - Interfaz aislada `MielWriter` implementada en `DioMielClient`, blindando a `SyncEngine` contra efectos colaterales de escritura.
  - Formato multipart/form-data y codificación UTF-8 Base64 fiel a `helpers.js` de MIeL.
  - **Mensajería:** redactor nativo (`MensajeriaComposePanel`) con selector de destinatarios agrupados por rol (`Tutores`, `Alumnos`), respuesta (`MensajeriaReplyPanel`), validación de adjuntos (límite de 40 MB), guardado de borradores, toggle interactivo de favoritos, marcar leído/no leído individual y masivo, y eliminación de borradores.
  - **Portafolio:** panel nativo de nueva entrega (`PortafolioSubmissionCard`) con selección de tutor destinatario, observaciones, enlace web y adjuntos validados.
  - **Foros (`forov2`):** creación nativa de hilos, respuestas inline con `@mención` del autor y adjuntos (límite de 5 MB), contador en vivo interactivo de *Me gusta* (`POST /forov2/event/marcarUtil/`) y marcar todos los temas como leídos.
  - **Evaluaciones:** modal nativo para ingreso con clave de acceso (`POST /evaluacion/event/ingresar/`).
- **Fase 4 — Descarga masiva y exportación offline de Contenidos y Foros:**
  - Exporters puros basados en la arquitectura de `ExtraerForosMIeL`:
    - **Markdown (`.md`):** hilos anidados con roles (`Tutor/a` / `Alumno/a`), fechas, citas Markdown `> `, `@menciones` y rutas relativas a adjuntos locales.
    - **JSON estructurado (`.json`):** catálogo completo del hilo con árbol de respuestas y metadatos.
    - **HTML offline (`.html`):** documento autocontenido, responsivo y estilizado con la estética esmeralda de LibreMIeL para visualización en navegador sin conexión.
    - **Contenidos:** generación automática de `indice_contenidos.md` y recopilador de enlaces externos/videos en `enlaces_externos.md`.
  - Gestor de descargas masivas `BulkDownloadManager`:
    - Ejecución estrictamente secuencial con pausas educadas de 250 ms (`_politeDelay`) para evitar sobrecargar los servidores de la UNLaM.
    - Modo incremental inteligente: verificación previa de archivo en disco y catálogo en base de datos para omitir descargas redundantes.
    - Controles interactivos con barra de progreso detallada, porcentaje, métricas en vivo (completados, omitidos, MB descargados), pausa, reanudación y cancelación.
    - Cálculo de hash SHA-256 para archivos binarios descargados.
    - Migración de base de datos a `schemaVersion: 4` con tabla `DownloadedResources`.
  - Interfaz de respaldo offline `BulkDownloadSheet` (diálogo en escritorio y bottom sheet en móvil), integrable con selección de materias, módulos y formatos, accesible desde el encabezado de Contenidos ("Respaldo offline"), el encabezado de Foros ("Exportar foros") y el menú lateral ("Respaldo offline").
  - Extracción de fotos de perfil autenticadas de docentes (`avatarUrl`), código de curso, comisión con cuatrimestre, modalidad con enlace de infografía y aula con leyenda cursiva en `parseCursoDetallesHtml`, junto con soporte de avatares rectangulares/cuadrados en `MielAvatar` y migración a `schemaVersion: 5` en SQLite (`CachedTeachers.avatarUrl`).

### Changed
- **Modal de Detalle de comisión:** rediseñado para replicar fielmente el diseño oficial de MIeL (`2025.2.0`), con cabecera neutra, alineación en dos columnas (`.w3-col.m3` vs `.w3-col.m9`), fotos cuadradas de docentes y sin franja verde ni botón redundante inferior.
- **Aviso de actividades en inicio:** cambiado el texto del aviso a "Tenés X actividades nuevas" (con soporte singular y plural) e incorporado botón directo "Limpiar" para marcar todas las notificaciones como leídas y ocultar el aviso de inmediato.
- **Notificaciones por defecto:** establecido por defecto el modo de sincronización de Foros en `mentionsAndReplies` ("Solo si te etiquetan o responden"), desactivando por defecto las alertas por actividad general en foros (evitando avisos masivos) y manteniendo activas Contenidos, Portafolio y Mensajería.
- **Detección en Foros:** implementada la función pura `isMentionOrReplyToCurrentUser` para detectar `@menciones` con el ID de usuario del estudiante, respuestas directas a sus mensajes y respuestas en hilos propios tanto de docentes como de compañeros.
- Eliminadas secciones secundarias poco usadas (`Glosario`, `Preguntas frecuentes` en Contenidos y `Competencias` en Portafolio) y botones redundantes (`Actualizar` / `Abrir en MIeL`) en el encabezado de Contenidos.
- Alineado a la izquierda el nombre de la materia junto al botón de inicio en la barra superior, ajustado el badge rojo al ícono de herramienta y simplificado el placeholder del login a `DNI`.
- **Barra superior:** retirada la campana de notificaciones de la barra verde para mantener una barra limpia; las notificaciones permanecen accesibles desde el menú lateral en *Funcionalidades* -> *Novedades*.
- **Tarjetas de materias:** unificado el color de la campana de notificaciones a blanco (en modo oscuro) o gris secundario (en modo claro) para concordar con los demás íconos de la tarjeta.
- **Footer del menú principal:** retirado el enlace "Abrir MIeL oficial en el navegador" debajo de la leyenda de licencia.
- **Encabezados de Contenidos y Foros:** retirados los botones redundantes "Respaldo offline" y "Exportar foros"; el respaldo masivo permanece centralizado en el menú lateral.
- **Respaldo offline:** eliminada la opción redundante de adjuntos (ahora siempre se descargan) e incorporado selector con lista de verificación interactiva y atajos (*Todas* / *Ninguna*) al seleccionar materias específicas.
- **Foros y Portafolio:** retirados los botones "Abrir en MIeL" de las barras superiores de los módulos, conservando solo las acciones esenciales (`Actualizar` y `Marcar todos leídos`).
- **Bandeja del sistema (*system tray*):** agregado indicador visual de notificación no leída (`tray_icon_unread.png` / `.ico` con insignia roja) que se actualiza reactivamente cuando llegan novedades y vuelve al ícono normal al marcarlas como leídas, junto con conteo en el menú contextual.
- **Feed de Novedades:** eliminado el botón externo "Abrir en MIeL" de cada tarjeta de notificación; al hacer click sobre cualquier notificación se marca como leída y abre directamente el módulo correspondiente dentro de LibreMIeL.
- **Licencia del proyecto:** relicenciado todo el proyecto a **GNU General Public License v3.0 (GPL-3.0)**.

### Fixed
- **Detalle de comisión:** corregido el bug de parsing en `parseCursoDetallesHtml` que provocaba nombres duplicados y capturaba etiquetas del contenedor como si fueran docentes (ej. `"Docentes asignados: ... Tutor/a"`).
- **Portafolio:** corregida la aserción de Flutter (`DropdownButton: There should be exactly one item with value: 0`) deduplicando las opciones de tutores en `parsePortafolioEntregasDetalleHtml` y sanitizando las opciones en `PortafolioSubmissionCard`.
- **Notificaciones:** corregido el registro de mensajes y foros no leídos en `SyncEngine` (`_syncMensajeria` y `_syncForos`), garantizando que los avisos no leídos existentes se registren correctamente en el feed de Novedades sin depender exclusivamente de cambios de estado posteriores al baseline inicial.

### Fixed
- **Aislamiento al cambiar de cuenta:** al cerrar sesión e iniciar con otro usuario se limpian automáticamente las materias, docentes, snapshots, notificaciones, perfil y caché de imágenes de la cuenta anterior (`clearAccountData` + `sessionGenerationProvider`), se resetea el `CookieJar` antes de cada login, se cancelan sincronizaciones en vuelo (`isCancelled`) y Ciclo 1 poda comisiones que ya no existan en `/principal/interno/` (`pruneSubjectsNotIn`).
- **Carga de fotos de perfil:** soporte de descarga autenticada (`MielAvatar`) para avatares de usuario, remitentes en Mensajería y participantes en Foros.
- **Usabilidad en Fase 2:** aviso de descarga de archivos con cierre manual y auto-cierre sin quedar pegado en blanco, punteros de mano y subrayado en enlaces/filas interactivas, y retorno a la lista principal al re-clickear la sección activa en Mensajería y Portafolio.
