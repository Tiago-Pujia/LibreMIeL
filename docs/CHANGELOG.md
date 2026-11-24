# Changelog — LibreMIeL

Todos los cambios notables de **LibreMIeL** se documentan en este archivo.  
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto adhiere a [Versionado Semántico (SemVer)](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- **Inicio con el sistema en segundo plano:**
  - Registro de argumento `--minimized` en `AutostartService` para Linux (archivo `.desktop`), Windows (Registro `HKCU Run`) y macOS (`LaunchAgents plist`).
  - Modificación del runner nativo de Linux (`my_application.cc`) y Windows (`main.cpp` / `flutter_window.cpp`) para evitar la presentación visible de la ventana en el primer fotograma (`first-frame`) cuando se recibe la bandera `--minimized` o `--hidden`.
  - Propagación de argumentos de entrada en `main(List<String> args)` y supresión de ventana en `DesktopTrayService.initialize(startMinimized: true)` para mantener la aplicación silenciosa en la bandeja del sistema hasta la interacción del usuario.
- **Perfil de MIeL (Lectura y Modificación de Datos Personales):**
  - Modelo inmutable `MielUserProfile` con lista de carreras universitarias disponibles (`CareerOption`), datos personales, contacto y detección de avatar personalizado.
  - Parser puro `parsePerfilHtml` (`miel_perfil_parser.dart`) con extracción de carrera, DNI, género, fecha de nacimiento, emails, teléfono, domicilio y URL de avatar desde `style="background-image:..."`.
  - Extensión de `MielInteractiveReader` con `fetchPerfilHtml()` y `MielWriter` con mutaciones multipart (`updatePerfil` hacia `/perfil/event/modificarUsuario/`, `deleteAvatar` hacia `/perfil/event/eliminarAvatar/` y `changePassword` hacia `/perfil/event/cambiarClave/`).
  - Nueva interfaz modal interactiva `MielProfileDialog` accesible desde el diálogo de usuario en `HomeShell`, permitiendo previsualizar y cambiar la foto de perfil (vía `file_selector`), editar campos personales/contacto y cambiar contraseña de forma segura.
  - Cobertura de pruebas unitarias en `test/parsers/miel_perfil_parser_test.dart` y actualización de `test/platform/autostart_service_test.dart`.
- **Widgets Android:**
  - Prototipo web interactivo autocontenido en [`docs/prototypes/android_widgets.html`](prototypes/android_widgets.html) con simulación en tiempo real de los diseños compacto (`2×2`/`3×2`), barra resumen (`4×1`) y tablero feed/materias (`4×2`/`4×3`), selector de modo claro/oscuro y pruebas de conectividad.
- **Integración de tareas y mejoras pendientes en la Tabla General de Estado:**
  - Registro directo en la **Tabla General de Estado** de [`docs/STATUS.md`](STATUS.md) y especificación en [`docs/ROADMAP.md`](ROADMAP.md) e [`docs/IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md):
    - **1. Ejecución de fases restantes:** Fase 11 (iOS e iPadOS con plan completo en `PLAN_IMPLEMENTACION_FASE_11.md`), Fase 6 (Buscador Global Offline FTS5) y Fase 7 (Integración con IA / Asistente de estudio local-first y BYOK).
    - **2. Actualización de widgets Android:** Optimización de layouts `RemoteViews`, refresco confiable tras background sync (`WorkManager`) y deep-linking a materias.
    - **3. Habilitar modificación de perfil de MIeL:** Extensión de `MielInteractiveReader` y `MielWriter` para consulta y edición de perfil (`/principal/perfil/`), subida de avatar e invalidación reactiva de caché.
    - **4. Inicio de sistema en segundo plano:** Flag de arranque silencioso (`--minimized` / `--tray-only`) para que LibreMIeL inicie en la bandeja del sistema (System Tray) sin abrir la ventana completa al encender la PC.
    - **5. Revisión del panel de configuración:** Reorganización modular y verificación de persistencia en SQLite de todas las opciones en `SettingsScreen`.
    - **6. Corrección de descargas en celulares:** Compatibilidad con Scoped Storage en Android 10–14+, permisos limpios, guardado accesible y apertura con `FileProvider`.
    - **7. Revisión y comparativa integral de UI contra MIeL:** Auditoría visual módulo por módulo para garantizar máxima fidelidad y paridad con la web oficial de MIeL (`2025.2.0`).
    - **8. Auditoría integral del proyecto con Gemini (Paso final):** Revisión exhaustiva final de código, arquitectura, invariantes técnicas de `AGENTS.md`, pruebas y seguridad.

## [0.2.1] - 2026-11-23

### Added
- **Fase 12 — Navegación y Experiencia tipo Navegador Web:**
  - Historial lineal de navegación en memoria (`NavigationHistoryController`, máx 80 entradas, FIFO) que unifica el estado profundo de todas las vistas (`HomeShell`, `ContenidosView`, `MensajeriaView`, `PortafolioView`, `ForoView`, `SecondaryModulesView`).
  - Navegación bidireccional mediante botones laterales del ratón (`Mouse 4` / `kBackMouseButton` y `Mouse 5` / `kForwardMouseButton`) con bitmask y debounce que previene dobles saltos en Linux, Windows y macOS.
  - Atajos de teclado completos (`Alt + ←`, `Alt + →`, `Alt + Home`, `Ctrl + F`, `Esc`, `F5`, `Ctrl + R`, `Ctrl + Shift + R`, `Ctrl + +`, `Ctrl + -`, `Ctrl + 0`).
  - Protección estricta de foco: cuando un `EditableText` (e.g. `TextField` de búsqueda, redactor de mensajes o respuesta en foro) tiene foco, los atajos de teclado sin modificador (`Home`, `End`, `PageUp`, `PageDown`) no interfieren con la edición de texto.
  - *bfcache* de sesión en RAM (`_sessionBfHtmlCache`, LRU 40 entradas) con `markBfCacheRestoreKeys`, permitiendo retroceder y avanzar de forma instantánea sin generar peticiones HTTP innecesarias contra los servidores de MIeL ni decrementar involuntariamente contadores de no leídos.
  - Protección de borradores no guardados (`DraftDirtyRegistry`): intercepta intentos de navegación o recarga cuando hay texto sin enviar en Mensajería, Portafolio o Foros, mostrando un diálogo de confirmación con opciones para seguir editando o descartar.
  - Zoom de interfaz y lectura (0.8x a 1.5x) mediante `BrowserZoomViewport`, adaptando dinámicamente `MediaQuery` y el árbol visual para mantener hit-testing exacto y breakpoints responsivos sin desbordes.
  - Prioridad de retroceso con `PopScope`: cierra drawer si está abierto, luego la barra de búsqueda `BrowserFindBar`, verifica borradores sucios, retrocede en el historial lineal y delega al sistema operativo únicamente en la raíz.
  - Controles visuales opcionales en barra superior (`←`, `→`, `↻`) e indicador lineal de progreso, desactivados por defecto para preservar la fidelidad estética con MIeL pero configurables en Ajustes.
  - Menús contextuales nativos (`MielContextMenu` / `MielWebActionTarget`) sobre materias, temas de foro, mensajes y notificaciones con opciones para copiar enlace canónico oficial de MIeL y abrir en navegador externo (con soporte para clic central / Shift + clic).
- Documentación técnica completa de la plataforma MIeL (`2025.2.0`) en `docs/`.
- Especificación técnica y hoja de ruta de **Fase 12 — Navegación y Experiencia tipo Navegador Web** (historial unificado Back/Forward con `Mouse 4`/`Mouse 5`, `Alt+←/→`, `Cmd+[/]` y Android `PopScope`, recarga contextual con `F5`/`Ctrl+R`, búsqueda en página `Ctrl+F`, zoom, navegación por teclado y preservación de *bfcache*/borradores) en `docs/ROADMAP.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/STATUS.md`, `docs/AGENTS.md` y `docs/README.md`.
- Especificación técnica y hoja de ruta de **Fase 8 — Actualizador Automático Multiplataforma** (alertas de releases vía GitHub API, verificación SHA-256 contra `SHA256SUMS.txt` e instalación in-app en Windows, Android, Linux y macOS) en `docs/ROADMAP.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/STATUS.md`, `docs/AGENTS.md` y `docs/GIT_WORKFLOW.md`.
- Especificación técnica y hoja de ruta de **Fase 9 — Modo Offline y Contingencia ante Caídas de MIeL** (caché local opcional bajo sesión autenticada para Contenidos, Mensajería, Foros, Portafolio y módulos secundarios, diferenciación de caídas del servidor vs. falta de internet, banner global de aviso y respeto estricto a efectos colaterales) en `docs/ROADMAP.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/STATUS.md` y `docs/AGENTS.md`.
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
- **Fase 8 — Actualizador Automático Multiplataforma en la App:**
  - Detección automática y manual de nuevas versiones de LibreMIeL contra la API de GitHub Releases con soporte de ETag HTTP (`If-None-Match` / `304 Not Modified`) y rate limiting (24 hs en segundo plano).
  - Parser SemVer estricto (`SemVer.parse`) para comparación confiable de versiones (`vX.Y.Z`).
  - Verificación criptográfica obligatoria **SHA-256** en streaming contra `SHA256SUMS.txt`, eliminando de inmediato archivos descargados si el checksum no coincide (`Sha256Verifier.verifyOrDelete`).
  - Resolutor determinista de artefactos (`AssetResolver`) según sistema operativo y arquitectura:
    - **Windows:** instalador ejecutable (`setup.exe`) o portable (`.zip`).
    - **Android:** APK nativo según arquitectura del dispositivo (`arm64-v8a`, `armeabi-v7a`, `x86_64`) o fallback universal.
    - **Linux:** AppImage (reemplazo atómico `rename` y reinicio desacoplado), `.deb`, `.rpm`, `.pkg.tar.zst` o `.tar.gz`.
    - **macOS:** `.dmg` montable o `.zip`.
  - Instalación in-app asistida o automática:
    - **Windows:** ejecución desasociada con `/SILENT` y parámetros Inno Setup (`AppMutex`, `CloseApplications=yes`, `RestartApplications=yes`).
    - **Android:** integración nativa mediante `MethodChannel` (`REQUEST_INSTALL_PACKAGES` y `FileProvider`).
    - **Linux:** reemplazo atómico in-place de AppImage con permisos ejecutables (`chmod +x`) y reinicio silencioso con `xdg-open` / detached process para paquetes del sistema.
    - **macOS:** apertura nativa del archivo `.dmg` / `.zip` con `open`.
  - Notificaciones nativas del sistema (`showUpdateNotification`) y diálogo in-app modal (`UpdateDialog`) con estética oficial MIeL (`MielPalette`), notas de la versión con scroll, barra de progreso interactiva, opción de omitir versión y botones responsivos con `Wrap`.
  - Sección *"Actualizaciones"* en la pantalla de Ajustes con versión actual instalada, estado del conmutador de comprobación automática, fecha de última comprobación y botón *"Buscar actualizaciones ahora"*.
- **Fase 9 — Modo Offline y Contingencia ante Caídas de MIeL:**
  - Clasificador determinista de estado de red (`classifyMielNetworkError` y `isLikelyMielMaintenanceHtml`) distinguiendo entre dispositivo sin conexión local (`MielServerStatus.deviceOffline`) y caída/mantenimiento de MIeL (`MielServerStatus.mielDown` ante 5xx, timeouts, connection refused, errores TLS o páginas de mantenimiento Apache/Nginx).
  - Tabla de caché local en Drift SQLite (`OfflinePageCache`, esquema `schemaVersion: 6`) para páginas HTML visitadas con política de desalojo LRU según cuota configurable en MB (`pruneOfflineCacheToQuota`), recuento de bytes y limpieza atómica.
  - Servicio de almacenamiento persistente de recursos multimedia autenticados en disco (`OfflineMediaService`) para fotos de perfil e imágenes embebidas de foros.
  - Estrategia de consulta *Network-first con fallback automático a caché local* (`fetchInteractiveHtmlWithAuth`) en todos los proveedores de módulos (Comisiones, Contenidos, Portafolio, Mensajería, Foros, Evaluación, Encuestas, Autoguía).
  - Precargador seguro de páginas (`OfflinePrefetcher`) con respeto absoluto a las invariantes de `AGENTS.md` (nunca consulta `Contenidos`, `verEntrada` ni `forov2/mensajes`, y respeta tokens de cancelación), complementado con cacheo automático en `SyncEngine` sobre las páginas ya obtenidas legítimamente.
  - Banner global persistente `MielStatusBanner` en la cabecera de la aplicación informando si MIeL no responde (ámbar) o si no hay conexión a internet (azul/gris), mostrando la fecha de la última sincronización exitosa, reintento manual seguro, reintento automático con *backoff* exponencial y notificación nativa opcional cuando MIeL vuelve a estar en línea.
  - Bloqueo preventivo de envíos (`runMielWriteWithAuth`), estados de contingencia claros en módulos sin caché (`MielModuleErrorView`) e integración de Contenidos offline con `DownloadedResources` (Fase 4) para abrir archivos ya descargados en disco.
  - Sección *"Modo sin conexión y contingencia"* en Ajustes con interruptor maestro, aviso de recuperación de MIeL, selector de cuota conjunta de almacenamiento LRU (HTML + imágenes: 50, 100, 250, 500 MB), interruptor de precarga segura en segundo plano, visor en vivo del espacio ocupado y botón para vaciar el caché.
  - Aislamiento completo: borrado automático de `OfflinePageCache` y `OfflineMediaService` al cerrar sesión o cambiar de cuenta, y poda al cambiar materias activas en `pruneSubjectsNotIn()`.
  - Endurecimiento de seguridad en Fase 8: verificación SHA-256 estrictamente obligatoria (rechazo ante ausencia o fallo de `SHA256SUMS.txt`), validación de URLs HTTPS oficiales de GitHub, consulta real de ABIs en Android (`getSupportedAbis`), reemplazo atómico cross-filesystem de AppImage en Linux, persistencia de release cacheado ante `304 Not Modified`, deduplicación persistente de notificaciones por versión y manejo de estados/permisos en `UpdateDialog`.
- **Fase 10 — App Widgets en Pantalla de Inicio (Android):**
  - Implementación nativa de widgets para Android (`AppWidgetProvider` + `RemoteViews` XML adaptativos) en formato compacto `2×2` / tira `4×1` (`MielCompactWidgetProvider`) y formato extendido de novedades y materias `4×2` (`MielFeedWidgetProvider`).
  - Puente nativo desacoplado `libremiel_android_widget` como `FlutterPlugin` local Android-only (`app/packages/libremiel_android_widget/`), garantizando registro automático y compatibilidad tanto en el `FlutterEngine` principal (`MainActivity`) como en el isolate headless de `WorkManager` (`runAndroidBackgroundSyncTask`).
  - Renderizado dinámico atómico mediante 5 slots XML predefinidos (evitando desincronizaciones de `RemoteViewsService`/`ListView` en lanzadores como One UI o MIUI) adaptativo a altura (`OPTION_APPWIDGET_MIN_HEIGHT`) y tema del sistema (claro/oscuro con paleta oficial de MIeL).
  - Contador en vivo de novedades no leídas, materias con badges pendientes, chip interactivo de última novedad y pill semántico de estado del servidor (`online`, `mielDown`, `deviceOffline`, `authPaused`) con hora de última sincronización.
  - Refresco manual directo desde el widget con la app cerrada: botón de actualización que despacha `ACTION_WIDGET_REFRESH`, muestra estado *"Actualizando…"* con TTL de seguridad de 45 segundos y encola un `OneTimeWorkRequest` sobre `BackgroundWorker` (`libremiel_widget_refresh`), ejecutando `SyncEngine.runCycle1` sin efectos colaterales.
  - *Deep-linking* nativo y navegación profunda: toque en materias o tarjetas de novedad enruta inmediatamente a través de `AndroidWidgetService` y `HomeShell` hacia la comisión y herramienta correspondiente (`contenidos`, `portafolio`, `mensajeria`, `foros`, `evaluacion`), marcando automáticamente la notificación como leída en SQLite.
  - **Invariante #11 de privacidad:** vaciado síncrono obligatorio de `SharedPreferences` (`libremiel_widget_prefs`) y redibujado inmediato de todas las instancias en estado *"Sesión cerrada"* (sin nombres de materias, sin novedades y sin botón de refresh) al ejecutar `logout()` o cambiar de cuenta en `_bootstrap()`/`login()`.
  - Soporte de fijado directo en pantalla de inicio (`requestPinWidget` / `isPinWidgetSupported` para Android 8.0+) accesible desde la sección de segundo plano en la pantalla de Ajustes con guía manual ilustrada.

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
- **Feed de Novedades y Notificaciones Nativas:** eliminado el botón externo "Abrir en MIeL"; al hacer click sobre cualquier notificación nativa o tarjeta del feed se abre directamente el módulo y comisión correspondiente dentro de LibreMIeL sin salir al navegador externo.
- **Estética de Notificaciones Nativas en Android:** rediseño visual para mostrar el remitente como título destacado en negrita (`ROGER, MATIAS ALEJANDRO (Docente)` o `Corrección • ...`), el asunto en el cuerpo expandible (`BigTextStyleInformation`), la materia en el `subText` superior y el acento institucional verde esmeralda `#009674` (`_mielEmerald`) con luces LED y categorización nativa (`message`, `social`, `event`).
- **Navegación Profunda Nativa al Tocar Notificaciones:** implementación de `NotificationTapPayload` en `NotificationService` y `HomeShell` con enrutamiento reactivo en caliente y en frío (*cold start* vía `getLaunchDetails()`), suprimiendo completamente el uso de `launchUrl(externalApplication)`.
- **Licencia del proyecto:** relicenciado todo el proyecto a **GNU General Public License v3.0 (GPL-3.0)**.

### Fixed
- **Segundo Plano y Suspensión en Android (Samsung One UI / MIUI):** resolución de bloqueos por Doze Mode e hibernación agresiva mediante la incorporación de `WAKE_LOCK` y `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` en `AndroidManifest.xml`, inicialización temprana de `Workmanager` en el bootstrap de `main.dart`, y guía de configuración en Ajustes para seleccionar **"Sin restricciones"** en la batería de la aplicación.
- **Validación de Mensajería en Producción:** prueba real de extremo a extremo de envío y recepción bidireccional entre cuentas de estudiantes autorizadas en comisión común (`117982`), confirmando HTTP 302 y 0 interacciones con terceros (docentes o compañeros).

### Fixed
- **Detalle de comisión:** corregido el bug de parsing en `parseCursoDetallesHtml` que provocaba nombres duplicados y capturaba etiquetas del contenedor como si fueran docentes (ej. `"Docentes asignados: ... Tutor/a"`).
- **Portafolio:** corregida la aserción de Flutter (`DropdownButton: There should be exactly one item with value: 0`) deduplicando las opciones de tutores en `parsePortafolioEntregasDetalleHtml` y sanitizando las opciones en `PortafolioSubmissionCard`.
- **Notificaciones:** corregido el registro de mensajes y foros no leídos en `SyncEngine` (`_syncMensajeria` y `_syncForos`), garantizando que los avisos no leídos existentes se registren correctamente en el feed de Novedades sin depender exclusivamente de cambios de estado posteriores al baseline inicial.

### Fixed
- **Aislamiento al cambiar de cuenta:** al cerrar sesión e iniciar con otro usuario se limpian automáticamente las materias, docentes, snapshots, notificaciones, perfil y caché de imágenes de la cuenta anterior (`clearAccountData` + `sessionGenerationProvider`), se resetea el `CookieJar` antes de cada login, se cancelan sincronizaciones en vuelo (`isCancelled`) y Ciclo 1 poda comisiones que ya no existan en `/principal/interno/` (`pruneSubjectsNotIn`).
- **Carga de fotos de perfil:** soporte de descarga autenticada (`MielAvatar`) para avatares de usuario, remitentes en Mensajería y participantes en Foros.
- **Usabilidad en Fase 2:** aviso de descarga de archivos con cierre manual y auto-cierre sin quedar pegado en blanco, punteros de mano y subrayado en enlaces/filas interactivas, y retorno a la lista principal al re-clickear la sección activa en Mensajería y Portafolio.
