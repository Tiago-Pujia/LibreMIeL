# Roadmap — Próximas Fases de LibreMIeL

Este documento describe en detalle las próximas fases planificadas para **LibreMIeL** a partir de la base ya completada (**Fase 0 — Core**, **Fase 1 — MVP de Notificaciones** y **Fase 2 — Lectura Nativa**).

> Ver el tablero de avance actual en [`STATUS.md`](STATUS.md) y las reglas técnicas invariantes en [`AGENTS.md`](AGENTS.md).

---

## Resumen de Fases

| Fase | Nombre | Estado | Enfoque principal |
| :--- | :--- | :---: | :--- |
| **Fase 0** | Core y Parsers | ✅ Completado | Cliente HTTP, cookies, parsers puros, SQLite (`Drift`) y `SyncEngine` en 2 ciclos |
| **Fase 1** | MVP y Notificaciones | ✅ Completado | UI fiel a MIeL, alertas nativas, tray, autostart, Android Worker y CI/releases |
| **Fase 2** | Lectura Nativa | ✅ Completado | Contenidos, Portafolio, Mensajería unificada, Foros, módulos secundarios y descargas autenticadas |
| **Fase 3** | Escritura y Envío de Contenido | ✅ Completado | Enviar mensajes, subir entregas de Portafolio, participar en Foros y acciones interactivas |
| **Fase 4** | Descarga Masiva (Foros y Contenidos) | ✅ Completado | Respaldo organizado por materia de archivos y foros completos antes de la depuración cuatrimestral |
| **Fase 5** | Sesión Permanente | ✅ Completado | Persistencia local de credenciales, renovación silenciosa y auto-login continuo hasta logout manual |
| **Fase 6** | Buscador Global Offline | ⏳ Planificado | Búsqueda instantánea *full-text* (SQLite FTS5) sobre todas las materias sin conexión |
| **Fase 7** | Integración con IA | ⏳ Planificado | Asistente de estudio *local-first* (Ollama/local o BYOK) sobre el material descargado de la cátedra |
| **Fase 8** | Actualizador Automático en la App | ✅ Completado | Alertas de nuevos releases en GitHub y actualización automática/asistida por SO sin salir al navegador |
| **Fase 9** | Modo Offline y Contingencia ante Caídas de MIeL | ✅ Completado | Navegación opcional sin conexión (Contenidos, Mensajería, Foros, Portafolio) con sesión activa y aviso de servidor caído |
| **Fase 10** | App Widget en Pantalla de Inicio (Android) | ✅ Completado | Widgets nativos en pantalla de inicio para resumen de novedades y materias |
| **Fase 11** | Soporte para iOS e iPadOS | ⏳ Planificado | Target `app/ios/`, adaptación de notificaciones/background, compilación `.ipa` en CI/CD y distribución (AltStore / TestFlight / App Store) |
| **Fase 12** | Navegación y Experiencia tipo Navegador Web | ✅ Completado | Historial Back/Forward (`Mouse 4/5`, `Alt+←/→`, Android `PopScope`), recarga contextual (`F5`/`Ctrl+R`), `Ctrl+F`, zoom, atajos web y *bfcache* sin efectos colaterales |

---

## Fase 3 — Escritura y Envío de Contenido en MIeL

**Objetivo:** Pasar de un cliente de solo lectura a un cliente completo donde el estudiante pueda redactar, responder y subir entregas directamente desde LibreMIeL sin tener que abrir el navegador.

### Alcance por módulo
- **Mensajería:**
  - Redactar nuevos mensajes (`/mensajeria/redactar/comision/{id}`) con selector de destinatarios por rol (`Tutor/a`, `Tutores`, `Alumno/a`, `Grupo`).
  - Responder mensajes recibidos, adjuntar archivos y guardar borradores.
  - Acciones rápidas sobre bandejas: marcar leído/no leído (`POST /mensajeria/event/marcarLeido/comision/{id}`), favorito (`POST /mensajeria/event/marcarFavorito/comision/{id}`) y marcar todos como leídos (`POST /mensajeria/event/marcarTodosComoLeidos/comision/{id}`).
- **Portafolio:**
  - Subir entregas de prácticas (`#formNuevaEntrega` en `/portafolio/entregas/comision/{id}/id/{idPractica}`) seleccionando archivo local y redactando el mensaje de entrega.
  - Soporte para entregas individuales y grupales con diálogo de confirmación previa antes de enviar.
- **Foros (`forov2`):**
  - Crear nuevos hilos (`POST /forov2/event/nuevoMensajeAjax/comision/{id}`, cuerpo en Base64 `#mensajeNuevoBase64`) y responder dentro de hilos existentes (`POST /forov2/event/nuevaRespuestaAjax/comision/{id}`) con soporte para `@menciones` y adjuntos.
  - Marcar/desmarcar *Me gusta* (`POST /forov2/event/marcarUtil/comision/{id}`) y marcar todos los temas como leídos (`POST /forov2/event/marcarTemasComoLeidos/comision/{id}`).
- **Módulos secundarios (progresivo):**
  - Envío de respuestas en **Encuestas** e ingreso a **Evaluaciones** con soporte para clave de acceso (`POST /evaluacion/event/ingresar/comision/{id}` cuando `data-tc="1"`).

### Arquitectura e invariantes
- Introducir una interfaz aislada **`MielWriter`** (separada de `MielApiClient` y `MielInteractiveReader`) para encapsular toda operación de escritura (`POST` / `multipart/form-data`) sin contaminar el polling de fondo.
- Validar sesión (`isLogged` + re-login silencioso) antes de disparar cualquier envío para evitar perder textos redactados si expiró `PHPSESSID`.
- Guardar borrador local temporal en caso de fallo de red y refrescar el estado/badges locales inmediatamente tras una respuesta exitosa del servidor.

---

## Fase 4 — Descarga Masiva de Foros y Contenidos

**Objetivo:** Permitir respaldar localmente, en un clic, todos los contenidos y foros de una o varias materias en carpetas ordenadas antes de que MIeL los depure al terminar el cuatrimestre o el año lectivo.

### Alcance funcional
- **Descarga de foros por materia** *(basada en [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel))* :
  - Exportar todos los temas de una comisión (o una selección) incluyendo jerarquía mensaje padre/respuestas, roles (`Tutor/a` / `Alumno/a`), fechas, `@menciones`, imágenes embebidas y archivos adjuntos binarios.
  - Formatos de salida: **Markdown (`.md`)**, **JSON estructurado (`.json`)** y **HTML offline autocontenido (`.html`)** con rutas relativas a los adjuntos locales.
- **Descarga masiva de contenidos por materia:**
  - Bajar el árbol completo respetando carpetas/módulos y submódulos (`<Materia>/<Módulo>/<archivo>`).
  - **Modo incremental:** detectar qué `{idElemento}` ya fue descargado para bajar solo material nuevo o modificado.
  - Generar un índice local (`.md`/`.html`) para enlaces externos (videos de YouTube, Google Drive, bibliografía web) que no son archivos binarios directos.
- **Gestor de cola respetuoso con MIeL:**
  - Ejecución estrictamente **secuencial** (con pausa, cancelación, barra de progreso detallada y reintento ante errores `5xx`/timeouts) para no sobrecargar los servidores de la UNLaM.
  - Sanitización multiplataforma de nombres y rutas (Windows, macOS, Linux, Android) y registro del catálogo descargado en SQLite (base directa para las Fases 6 y 7).

---

## Fase 5 — Sesión Permanente

**Objetivo:** Que el estudiante inicie sesión una sola vez y LibreMIeL mantenga la sesión permanentemente activa en cada apertura y durante todo el uso, cerrando sesión **únicamente** cuando el usuario presione explícitamente **Cerrar sesión**.

### Comportamiento esperado
- **Inicio automático siempre activo:** una vez autenticado con éxito, la app persiste las credenciales localmente y entra directo al panel de materias al abrirse (sin pedir login de nuevo tras reinicios, cierres o actualizaciones de la app).
- **Reconexión silenciosa ante vencimiento de `PHPSESSID`:**
  - Mantener viva la sesión periódicamente con `GET /principal/event/recargarSesion/`.
  - Si el servidor expiró la cookie por inactividad o cambio de red, re-autenticar automáticamente en segundo plano (`POST /principal/event/login/`) y reintentar la operación en curso de forma transparente para el usuario (tanto en `SyncEngine` como en `MielInteractiveReader` y `MielWriter`).
- **Cierre de sesión exclusivamente manual:** las credenciales persistidas solo se eliminan cuando el usuario elige explícitamente **Cerrar sesión** (manteniendo el aislamiento multi-cuenta ya implementado al cambiar de usuario).

### Almacenamiento local de credenciales y consideraciones de seguridad
- **Opción recomendada por defecto (segura):** almacenar la credencial en el llavero nativo del sistema operativo (`Android Keystore`, `Windows Credential Manager`, `macOS Keychain`, `Linux libsecret`) con *fallback* automático a archivo local cifrado/protegido (`chmod 600`) en el directorio privado de soporte de la app.
- **Soporte de archivo local tipo `.env` (consideraciones):**
  - Si se incorpora persistencia en un archivo `.env` local dedicado para garantizar portabilidad o configuración directa, debe guardarse **exclusivamente** en el directorio privado de datos de la aplicación del usuario (nunca dentro del repositorio ni en carpetas sincronizadas como Google Drive/OneDrive), con permisos `0600` (solo propietario) y, preferentemente, cifrado en reposo o advirtiendo claramente si se almacena en texto plano.
- **Invariante anti-bloqueo (`estado: 1, 2, 3`):** si el usuario cambia su contraseña en MIeL web y el re-login automático recibe `estado != 0`, LibreMIeL debe **detener inmediatamente los reintentos** para evitar bloquear la cuenta (`estado: 3`) y mostrar un aviso puntual para actualizar la clave, sin borrar las materias ni el archivo offline local.

---

## Fase 6 — Buscador Global Offline

**Objetivo:** Encontrar instantáneamente cualquier archivo, mensaje, hilo de foro, práctica o devolución docente a través de **todas las materias**, incluso sin conexión a internet o fuera de cuatrimestre.

### Alcance funcional
- **Índice *full-text* local (`SQLite FTS5` sobre `Drift`):**
  - Indexación automática de todo lo sincronizado y descargado (Fase 4):
    - **Contenidos:** nombres de archivo, carpetas, descripciones y extracción opcional de texto de documentos locales (`.pdf`, `.txt`, `.md`).
    - **Mensajería:** asuntos, remitentes y cuerpos de mensajes leídos/cacheables.
    - **Foros:** títulos de temas, autores, rol (`Tutor/a` / `Alumno/a`) y cuerpo de mensajes.
    - **Portafolio:** consignas, fechas de vencimiento, estados y observaciones docentes.
- **Experiencia de búsqueda:**
  - Acceso global desde la barra superior (atajo `Ctrl + K` en escritorio / lupa en móvil).
  - Búsqueda insensible a tildes y mayúsculas, con vista previa (*snippet*) resaltando las coincidencias.
  - Filtros combinables por **materia**, **módulo**, **solo docentes (`Tutor/a`)**, **rango de fechas** y **disponible offline**.
  - Salto directo desde el resultado al archivo descargado local o al lector nativo correspondiente.

---

## Fase 7 — Integración con IA (Asistente de Estudio)

**Objetivo:** Incorporar herramientas de Inteligencia Artificial sobre el material real de cada materia para estudiar mejor, sin comprometer el modelo *local-first* ni la privacidad del estudiante.

### Casos de uso principales
- **Resúmenes y síntesis:** resumir apuntes/PDFs de Contenidos, destilar hilos extensos de Foros resaltando las aclaraciones de `Tutor/a` y sintetizar correcciones/observaciones de Portafolio.
- **Consultas con citas (RAG sobre material local):** responder preguntas sobre una materia usando los documentos y foros descargados (apoyándose en el índice de Fase 6), citando el archivo o mensaje exacto de respaldo.
- **Apoyo al estudio:** generación de guías de repaso, preguntas de autoevaluación/*flashcards* a partir del material de la cátedra y priorización de entregas próximas.

### Arquitectura de privacidad (sin servidor propio)
- **100% opcional (desactivada por defecto)** y configurable por el usuario en Ajustes:
  1. **Modo IA 100% local (privacidad máxima):** conexión a backends locales compatibles con API OpenAI/Ollama (**Ollama**, **LM Studio**, `llama.cpp`) ejecutándose en el propio equipo sin enviar datos a internet.
  2. **Modo BYOK (*Bring Your Own Key*):** el usuario aporta su propia clave de API (Gemini, OpenAI, Anthropic, OpenRouter u otro proveedor compatible), guardada en el almacén seguro del sistema operativo.
- **Protección de datos personales:** antes de enviar contexto a un modelo externo, filtrar/excluir automáticamente credenciales, cookies, DNI y datos personales sensibles, y mostrar con claridad qué archivos o fragmentos de la materia se incluyen en cada consulta.

---

## Fase 8 — Actualizador Automático en la App

**Objetivo:** Detectar automáticamente nuevas versiones publicadas en **GitHub Releases**, notificar al estudiante mediante alertas nativas e in-app y permitir la descarga e instalación automática o asistida sin necesidad de abrir el navegador ni visitar la página web del proyecto.

### Alcance funcional
- **Comprobación silenciosa y eficiente:**
  - Consultar periódicamente `GET https://api.github.com/repos/Tiago-Pujia/LibreMIeL/releases/latest` (máximo una vez cada 12–24 horas usando cabecera `If-None-Match` / `ETag` para no agotar la cuota gratuita de GitHub API) y ofrecer un botón manual *"Buscar actualizaciones ahora"* en **Ajustes**.
  - Comparar SemVer contra la versión local instalada (`package_info_plus`), ignorando *drafts* y *pre-releases* por defecto, y permitir omitir una versión específica (`skippedReleaseVersion`).
- **Alertas y experiencia in-app:**
  - **Notificación del sistema (`NotificationService`):** aviso único por versión (`dedupeKey: app_update_<version>`) que al tocarse abre directamente el diálogo de actualización dentro de LibreMIeL (sin derivar al navegador externo).
  - **Diálogo/banner de actualización:** muestra versión instalada vs. nueva versión, notas del release (`body`), tamaño de descarga, barra de progreso en vivo y botones `[Actualizar ahora]`, `[Omitir versión]` y `[Más tarde]`.
- **Seguridad e integridad obligatoria:**
  - Verificar siempre el checksum **SHA-256** del archivo descargado contra el `SHA256SUMS.txt` oficial adjunto en cada GitHub Release antes de ejecutar cualquier instalador.
  - Cliente HTTP completamente aislado de `MielApiClient` / `SyncEngine` (sin compartir `CookieJar` ni enviar datos de MIeL hacia GitHub).

### Estrategia de actualización por sistema operativo
- **Windows:** descarga del instalador `LibreMIeL-<ver>-windows-<arch>-setup.exe` en `%TEMP%` y ejecución desatendida con Inno Setup (`/SILENT /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS`), cerrando y relanzando la aplicación ya actualizada de forma transparente.
- **Android:** descarga in-app del APK correspondiente a la ABI del dispositivo (`arm64-v8a`, `armeabi-v7a`, `x86_64` o *fallback* `universal`) y disparo directo del instalador nativo vía `Intent(ACTION_VIEW)` con `FileProvider` y permiso `REQUEST_INSTALL_PACKAGES` (actualización en 1 toque conservando base de datos y sesión).
- **Linux:** detección automática en tiempo de ejecución del formato instalado:
  - **AppImage:** descarga del nuevo `.AppImage`, `chmod +x`, reemplazo atómico del ejecutable referenciado por `APPIMAGE` y relanzamiento automático.
  - **Paquetes del sistema (`.deb`, `.rpm`, `.pkg.tar.zst` en `/opt/libremiel/`):** descarga en `/tmp/` y apertura directa con el gestor gráfico del sistema (`xdg-open`) o instalación elevada vía `pkexec` previa confirmación del usuario.
  - **Portable (`.tar.gz`):** descarga, extracción y reemplazo del bundle en disco con reinicio automático.
- **macOS:** integración recomendada con el framework **Sparkle** (vía `auto_updater`) o descarga del `.zip` universal con reemplazo del bundle `.app` en `/Applications/` y relanzamiento.

---

## Fase 9 — Modo Offline y Contingencia ante Caídas de MIeL *(Estado: ✅ Completado)*

**Objetivo:** Permitir que un estudiante **ya autenticado** siga consultando sus materias, **Contenidos**, **Mensajería**, **Foros (`forov2`)**, **Portafolio** y módulos secundarios dentro de LibreMIeL incluso cuando los servidores de **MIeL (`miel.unlam.edu.ar`) estén caídos** o el dispositivo se encuentre sin internet, informando con total claridad el estado real del servidor.

### Requisitos funcionales clave
- **Opcional y configurable desde Ajustes:**
  - Interruptor principal *"Modo sin conexión (caché ante caídas de MIeL)"* en **Ajustes** para que el usuario decida si desea conservar caché local de navegación o mantener un perfil mínimo sin copias adicionales.
  - Opciones complementarias: límite de almacenamiento del caché, botón *"Limpiar caché offline"* y opción de precarga automática restringida exclusivamente a endpoints de solo lectura seguros (sin efectos colaterales).
- **Exclusivo para sesiones ya autenticadas:**
  - Solo funciona cuando existe una sesión activa/persistida localmente (`isAuthenticated == true` y `account_username` válido en SQLite, apoyándose en la Fase 5).
  - Si los servidores de MIeL están caídos al abrir la app y el usuario ya había iniciado sesión antes, LibreMIeL **no** lo expulsa al login ni invalida su cuenta: abre directamente el panel en modo contingencia offline y reintenta la conexión en segundo plano con *backoff*.
  - Al cerrar sesión manualmente o cambiar de cuenta, todo el caché offline se borra junto con `clearAccountData()`.
- **Aviso explícito de MIeL caído vs. sin internet:**
  - Detectar y distinguir en red entre falta de conectividad local y caída/mantenimiento del servidor de MIeL (`500`/`502`/`503`/`504`, `Connection refused`, *timeouts* o páginas de error Apache/PHP).
  - Mostrar un **banner global persistente** y visible en toda la app indicando que MIeL está caído / no responde, la fecha de la última sincronización exitosa y un botón `[Reintentar conexión]`.
  - Notificación opcional cuando MIeL vuelve a responder normalmente tras una caída, reactivando la sincronización automática sin intervención del usuario.

### Cobertura por módulo en modo sin conexión
- **Panel principal y Docentes:** materias activas/ocultas, badges conocidos y lista cacheada de `Tutor/a` desde SQLite.
- **Contenidos:** estructura completa de carpetas/módulos y enlace directo para abrir archivos ya descargados en disco (integración directa con `DownloadedResources` de Fase 4).
- **Mensajería:** consulta de bandejas cacheadas (`Entrada`, `Salida`, `Borradores`, `Favoritos`), lectura de mensajes ya visitados y posibilidad de guardar borradores locales si se intenta redactar sin conexión.
- **Foros (`forov2`):** listado de temas e hilos/mensajes cacheados durante la navegación previa o respaldados mediante la exportación masiva de Fase 4, incluyendo imágenes/avatares cacheados localmente.
- **Portafolio y módulos secundarios:** prácticas, fechas de vencimiento, entregas/correcciones previas, asistencia, notas, **Evaluación**, **Encuestas**, **Autoguía** y **Novedades**.
- **Acciones bloqueadas con aviso claro:** cualquier envío (`MielWriter`), apertura de mensajes/hilos nunca visitados ni descargados, o descarga de archivos nuevos no cacheados muestra un estado claro indicando que requiere que MIeL vuelva a estar en línea.
- **Respeto absoluto a los efectos colaterales:** el caché se puebla al navegar (*cache-on-read*) y sobre las respuestas seguras que `SyncEngine` ya obtiene; nunca se consulta `Contenidos` con badge `0`, `verEntrada` ni `forov2/mensajes` en segundo plano a escondidas del estudiante.

---

## Fase 10 — App Widget en Pantalla de Inicio (Android) *(Estado: ✅ Completado)*

**Objetivo:** Permitir que el estudiante consulte de un vistazo sus novedades sin leer, estado de materias y última sincronización directamente desde la pantalla de inicio de Android mediante **App Widgets** nativos (`RemoteViews`), sin necesidad de abrir la aplicación.

### Arquitectura técnica prevista
- **Capa nativa Android (Kotlin + XML):**
  - `AppWidgetProvider` en `app/android/app/src/main/kotlin/io/github/tiago_pujia/libremiel/` con layouts XML (`RemoteViews`) adaptativos a tema claro/oscuro de Android y metadatos `appwidget-provider` declarados en `AndroidManifest.xml`.
  - No requiere Compose/Glance pesado: `RemoteViews` XML mantiene el tamaño del APK mínimo y es compatible con `minSdk 24`.
- **Puente Flutter ↔ Android:**
  - Integración mediante `home_widget` o un `MethodChannel` dedicado + `SharedPreferences` compartidas con el `AppWidgetProvider`.
  - Actualización automática del snapshot del widget al finalizar cada sincronización en primer plano (`AppSessionController.syncNow`) y en segundo plano (`runAndroidBackgroundSyncTask` en `WorkManager`), además de botón manual de refresco rápido en el propio widget.
- **Formatos propuestos:**
  - **Widget compacto (`2×2` / `4×1`):** Contador de novedades sin leer, última novedad detectada, estado de conexión con MIeL (normal / caído) y hora de última sincronización.
  - **Widget de feed / materias (`4×2` o redimensionable):** Lista de las últimas 3–5 entradas de `NotificationLogs` o materias activas con badges pendientes.
- **Navegación profunda e invariantes de privacidad:**
  - **Deep-linking:** Al tocar una novedad o materia del widget, abrir la app directamente en esa comisión/herramienta reutilizando `NotificationTapPayload` y el enrutamiento de `HomeShell`.
  - **Privacidad en logout / cambio de cuenta (Invariante #11):** Al ejecutar `logout()` o detectar cambio de cuenta (`clearAccountData`), limpiar inmediatamente los datos persistidos del widget y forzar un redibujado en estado *"Sesión cerrada"* para no exponer mensajes ni materias en la pantalla de inicio.

---

## Fase 11 — Soporte para iOS e iPadOS (iPhone / iPad) *(Estado: ⏳ Pendiente)*

**Objetivo:** Llevar **LibreMIeL** a dispositivos **iPhone** y **iPad** manteniendo intacta la arquitectura *local-first* (sin servidores propios intermedios), la paridad funcional de lectura/escritura/respaldo offline y la automatización de compilación en CI/CD desde GitHub Actions.

### Scaffolding y configuración nativa (`app/ios/`)
- **Generación del target iOS:** ejecutar `flutter create --platforms=ios .` dentro de `app/`, manteniendo el identificador de paquete canónico (`io.github.tiago_pujia.libremiel`), íconos adaptados y versión mínima objetivo compatible con las dependencias actuales (ej. iOS 13.0+ / 14.0+).
- **Permisos y capacidades (`Info.plist`):**
  - **Notificaciones locales:** configurar `DarwinInitializationSettings` en `NotificationService` (`flutter_local_notifications`) y solicitar permisos explícitos al usuario en iOS.
  - **Almacenamiento y descargas visibles:** habilitar `UIFileSharingEnabled` y `LSSupportsOpeningDocumentsInPlace` para que los apuntes descargados y foros exportados (Fase 4) sean accesibles desde la app nativa **Archivos** (*Files*) del iPhone/iPad.
  - **Seguridad de credenciales:** utilizar **Apple Keychain** a través de `flutter_secure_storage` (ya contemplado en `SecureCredentialsStore`).

### Sincronización en segundo plano y notificaciones
- **Restricciones del SO:** A diferencia de Android (`WorkManager` periódico cada ~15 min) o escritorio (daemon en barra de sistema), iOS restringe severamente la ejecución en segundo plano y **no garantiza intervalos fijos exactos** para apps sin notificaciones push remotas (APNs).
- **Estrategia *local-first*:**
  - Registrar `BGTaskSchedulerPermittedIdentifiers` (`BGAppRefreshTask`) mediante `workmanager` / plugin nativo para ejecutar ciclos oportunistas de `SyncEngine` decididos por iOS según batería y patrones de uso del estudiante.
  - Sincronización inmediata garantizada al abrir o volver a primer plano la aplicación.
  - Dejar documentado al usuario en **Ajustes** que la puntualidad en segundo plano depende de la gestión energética de iOS (salvo que en un futuro lejano existiera infraestructura APNs externa, fuera del alcance *local-first*).

### UI/UX, iPadOS y Actualizador in-app
- **iPhone (Safe Areas y navegación):** verificar márgenes seguros (*notch*, *Dynamic Island*, barra inferior de gestos) y compatibilidad con gestos nativos de retroceso.
- **iPadOS:** aprovechar el ancho de pantalla en tablets mostrando el layout adaptativo de barra lateral persistente (similar a escritorio) para lectura cómoda de PDFs, apuntes y foros.
- **Actualizador in-app (Fase 8):** dado que iOS prohíbe la autoinstalación directa de binarios `.ipa` desde dentro de una app, `UpdateInstaller` en iOS detectará nuevas versiones vía GitHub Releases API y ofrecerá abrir el enlace oficial de descarga (GitHub Release / TestFlight / App Store según el canal de instalación).

### CI/CD, compilación sin Mac local y distribución
- **Compilación en la nube (GitHub Actions):**
  - Añadir job `build-ios` en `.github/workflows/release.yml` corriendo sobre `runs-on: macos-latest` (gratuito para repositorios públicos).
  - Generar automáticamente el paquete `.ipa` (sin firma comercial o firmado mediante certificados inyectados por *GitHub Secrets*) adjunto en cada *GitHub Release*.
- **Canales de distribución previstos:**
  1. **Sideloading comunitario gratuito (corto plazo):** publicación del `.ipa` en *GitHub Releases* para instalación mediante herramientas gratuitas como **AltStore**, **SideStore** o **Sideloadly** usando un Apple ID común (sujeto a la limitación de Apple de renovar la firma cada 7 días).
  2. **TestFlight / App Store oficial (largo plazo):** si el proyecto cuenta con suscripción al *Apple Developer Program* ($99 USD/año), habilitar la distribución en 1 clic mediante enlace público de **TestFlight** (hasta 10.000 alumnos) y publicación en **App Store**.
- **Flujo de desarrollo y pruebas desde Linux:**
  - Como Xcode y el *iOS Simulator* son exclusivos de macOS y no corren de forma nativa en Linux, el desarrollo cotidiano de lógica y diseño responsive continúa en Linux y el emulador Android (`LibreMIeL_Pixel7`), validando la compilación iOS mediante GitHub Actions (`macos-latest`), simuladores web en la nube (ej. Appetize.io) o pruebas en dispositivos físicos de colaboradores.

---

## Fase 12 — Navegación y Experiencia tipo Navegador Web *(Estado: ✅ Completado)*

**Objetivo:** Dotar a **LibreMIeL** de la ergonomía, atajos y flujo de navegación propios de un navegador web moderno (ratón con botones laterales `Mouse 4`/`Mouse 5`, recarga con `F5`/`Ctrl+R`, historial Back/Forward, búsqueda en página, zoom, navegación por teclado y retroceso nativo en móvil), manteniendo la arquitectura de **ventana única**, la estética oficial de MIeL y el respeto estricto por sus invariantes de privacidad y efectos colaterales.

### 1. Historial Unificado Back / Forward y *bfcache*
- **Modelo unificado de ubicación interna (`NavigationHistoryEntry`):**
  - Elevar el sub-estado profundo de navegación que hoy vive fragmentado entre [`HomeShell`](../app/lib/features/home/home_shell.dart) y los lectores internos ([`MensajeriaView`](../app/lib/features/modules/mensajeria_view.dart), [`PortafolioView`](../app/lib/features/modules/portafolio_view.dart), [`ForoView`](../app/lib/features/modules/foro_view.dart)) hacia un controlador único (`NavigationHistoryController`).
  - Cada entrada del historial representa exactamente el equivalente a una URL de navegación en MIeL: sección del shell (`home`, `novedades`, `ajustes`, `module`), `idComision`, `MielToolKind`, sub-sección lateral (`sectionIndex`), página de bandeja / modo unificado / mensaje abierto (`verEntrada`/`verSalida`), práctica abierta en Portafolio (`entregas`), tema de foro (`idTema`) y desplazamiento vertical (`scrollOffset`).
  - **Deduplicación y tope:** evitar apilar entradas consecutivas idénticas y acotar la pila (ej. últimas 50–100 entradas en memoria).
- **Restauración instantánea (*bfcache* de sesión):**
  - Al retroceder o avanzar dentro de la misma sesión, restaurar la vista y su posición de scroll utilizando los datos ya cargados en memoria/Riverpod o caché local sin disparar peticiones HTTP ocultas redundantes (protegiendo el servidor de MIeL y evitando marcas involuntarias de lectura).
- **Limpieza en cierre de sesión:**
  - Al ejecutar `logout()` o detectar cambio de cuenta (`clearAccountData`), vaciar inmediatamente toda la pila Back/Forward para no exponer rutas ni identificadores de la sesión anterior.

### 2. Entradas de Ratón, Teclado y Gestos Móviles
- **Botones laterales del ratón (`Mouse 4` y `Mouse 5`):**
  - Capturar globalmente en `HomeShell` mediante `Listener` los eventos de puntero de botones extra (`kBackMouseButton` / `Mouse 4` para retroceder y `kForwardMouseButton` / `Mouse 5` para avanzar) en Windows, Linux y macOS, filtrando correctamente la transición para no disparar doble navegación entre *pointer down* y *pointer up*.
- **Botón / gesto Atrás en Android (`PopScope`):**
  - En lugar de cerrar la aplicación directamente al pulsar Atrás dentro de un mensaje, hilo de foro, entrega o módulo, consumir la acción para retroceder paso a paso en la pila de historial interna (por ejemplo: mensaje abierto → bandeja → *Materias activas*), delegando al sistema operativo únicamente cuando no haya historial previo en la raíz.
- **Recarga de vista activa (`F5`, `Ctrl + R` / `Cmd + R`, `Ctrl + Shift + R` / `Ctrl + F5`):**
  - **`F5` / `Ctrl + R` (`Cmd + R` en macOS):** refresca exclusivamente la vista o sub-vista actualmente visible:
    - En **Materias activas** o **Novedades**: ejecuta `AppSessionController.syncNow(includeCycle2: true)`.
    - En un **módulo activo** (**Contenidos**, **Portafolio**, **Mensajería**, **Foros**, **Evaluación**, **Encuestas**, **Autoguía**): invalida con `ref.invalidate(...)` únicamente el provider correspondiente a la comisión/sección/detalle abierto en [`module_providers.dart`](../app/lib/features/modules/module_providers.dart).
  - **`Ctrl + Shift + R` / `Ctrl + F5` (recarga forzada):** fuerza consulta en vivo contra MIeL evitando lectura pasiva de caché cuando exista conectividad (manteniendo el fallback seguro de Fase 9 si MIeL está caído).
- **Atajos de navegación, búsqueda, zoom y lectura (*"etc..."*):**
  - **Navegación por teclado:** `Alt + ←` / `Alt + →` (Windows/Linux) y `Cmd + [` / `Cmd + ]` o `Cmd + ←` / `Cmd + →` (macOS) para atrás/adelante; `Alt + Home` para volver a *Materias activas*.
  - **Búsqueda en la página (`Ctrl + F` / `Cmd + F`):** enfoca automáticamente el buscador/filtro nativo de la vista activa (barra de palabras clave en `ContenidosView`, buscador de hilo en `ForoView`, panel `#divFiltros` en `MensajeriaView`) o abre una barra rápida de búsqueda/filtrado en página, complementando al buscador global `Ctrl + K` de la Fase 6.
  - **Zoom de lectura (`Ctrl + +`, `Ctrl + -`, `Ctrl + 0` y `Ctrl + Rueda del ratón`):** ajusta y persiste un factor de escala de lectura/interfaz en Ajustes (ej. `80%`–`150%`), con restablecimiento inmediato al `100%` mediante `Ctrl + 0`.
  - **Desplazamiento y cierre rápido (`Home`, `End`, `PageUp`, `PageDown`, `Esc`):** desplazamiento fluido en listados/foros extensos cuando no hay un input enfocado; `Esc` cierra en orden de prioridad diálogos modales, visor de imágenes (`InteractiveViewer`), barra de búsqueda inline o paneles de respuesta/composición.
  - **Menú contextual en enlaces y tarjetas (`Clic derecho` / `Middle Click`):** menú contextual nativo en tarjetas de materias, temas de foro, mensajes y enlaces de Contenidos con opciones *Abrir*, *Copiar enlace oficial de MIeL* al portapapeles y *Abrir en navegador web* (con `Middle Click` / `Shift + Click` como acceso rápido al navegador externo).

### 3. Ergonomía Visual Opcional y Guardas de Seguridad
- **Controles visuales opcionales en `#menu-principal`:**
  - Mantener por defecto la barra verde fiel a la estética oficial de MIeL web, ofreciendo en **Ajustes** un interruptor opcional para mostrar botones discretos de navegación (`←`, `→`, `↻`) y una barra lineal sutil de progreso bajo `#menu-principal` durante recargas interactivas.
- **Protección de foco en inputs (`EditableText` / `TextField`):**
  - Ningún atajo sin modificador (como `Backspace`, `Home`, `End`, `Space`) debe robar pulsaciones mientras el estudiante escribe en un buscador o formulario.
- **Respeto a rutas modales abiertas:**
  - Si hay un diálogo, selector de descarga o visor de imágenes abierto sobre el shell, `Esc`, `Mouse 4` o Android Back cierran primero la capa modal antes de modificar la pila de navegación de fondo.
- **Protección de borradores y envíos en curso:**
  - Si existe texto, destinatarios o adjuntos sin guardar en [`MensajeriaComposePanel`](../app/lib/features/modules/widgets/mensajeria_composer.dart), [`PortafolioSubmissionCard`](../app/lib/features/modules/widgets/portafolio_submission_card.dart) o el redactor/respuesta de [`ForoView`](../app/lib/features/modules/foro_view.dart), interceptar la navegación atrás/adelante o `F5` con una confirmación explícita (*"Tenés cambios sin enviar, ¿querés descartarlos?"*).
- **Alcance de ventana única:**
  - Se adopta explícitamente navegación en **ventana única con historial** en lugar de múltiples pestañas concurrentes para preservar el diseño original de MIeL y evitar duplicación de estado de `SyncEngine` o carreras sobre cookies/lecturas.
