# Changelog — LibreMIeL

Todos los cambios notables de **LibreMIeL** se documentan en este archivo.  
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto adhiere a [Versionado Semántico (SemVer)](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- Documentación técnica completa de la plataforma MIeL (`2025.2.0`) en `docs/`.
- Licencia **MIT** (`LICENSE`) y documentación de gobernanza en `docs/` (`CONTRIBUTING.md`, `AGENTS.md`, `STATUS.md`, `GIT_WORKFLOW.md`, `CHANGELOG.md`).
- Script anonimizador de capturas HTML de MIeL (`scripts/anonymize_html.py`) con tests automatizados (`scripts/test_anonymize_html.py`).
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
- Migración de esquema SQLite local (`v1 → v3`) para almacenar código de materia, rol, herramientas habilitadas, orden personalizado (`sortOrder`) y visibilidad local por comisión sin perder datos previos.
- Nuevo ícono oficial de **LibreMIeL** aplicado en la app y en todos los targets (Linux, Android, Windows y macOS), manteniendo el hexágono esmeralda con campana en la bandeja del sistema (*system tray*).
- Integraciones de plataforma: almacenamiento seguro de credenciales (con fallback cifrado/restringido `chmod 600` en Linux sin `libsecret`), notificaciones nativas, bandeja del sistema en escritorio y worker periódico en Android (`WorkManager`).
- Workflows de GitHub Actions (`ci.yml` y `release.yml`) y configuraciones de empaquetado multi-arquitectura: Windows x64/ARM64 (`.exe` + `.zip`), macOS Universal x86_64+ARM64 (`.dmg` + `.zip`), Linux x64/ARM64 (`AppImage`, `.deb`, `.rpm`, Arch `.pkg.tar.zst`, portable `.tar.gz`) y Android (`.apk` universal + `arm64-v8a`, `armeabi-v7a`, `x86_64`).

### Changed
- Eliminadas secciones secundarias poco usadas (`Glosario`, `Preguntas frecuentes` en Contenidos y `Competencias` en Portafolio) y botones redundantes (`Actualizar` / `Abrir en MIeL`) en el encabezado de Contenidos.
- Alineado a la izquierda el nombre de la materia junto al botón de inicio en la barra superior, ajustado el badge rojo al ícono de herramienta y simplificado el placeholder del login a `DNI`.

### Fixed
- **Aislamiento al cambiar de cuenta:** al cerrar sesión e iniciar con otro usuario se limpian automáticamente las materias, docentes, snapshots, notificaciones, perfil y caché de imágenes de la cuenta anterior (`clearAccountData` + `sessionGenerationProvider`), se resetea el `CookieJar` antes de cada login, se cancelan sincronizaciones en vuelo (`isCancelled`) y Ciclo 1 poda comisiones que ya no existan en `/principal/interno/` (`pruneSubjectsNotIn`).
- **Carga de fotos de perfil:** soporte de descarga autenticada (`MielAvatar`) para avatares de usuario, remitentes en Mensajería y participantes en Foros.
- **Usabilidad en Fase 2:** aviso de descarga de archivos con cierre manual y auto-cierre sin quedar pegado en blanco, punteros de mano y subrayado en enlaces/filas interactivas, y retorno a la lista principal al re-clickear la sección activa en Mensajería y Portafolio.
