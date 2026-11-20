# Changelog — LibreMIEL

Todos los cambios notables de **LibreMIEL** se documentan en este archivo.  
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto adhiere a [Versionado Semántico (SemVer)](https://semver.org/lang/es/).

---

## [Unreleased]

### Added
- Documentación técnica completa de la plataforma MIEL (`2025.2.0`) en `docs/`.
- Licencia **MIT** (`LICENSE`) y documentación de gobernanza en `docs/` (`CONTRIBUTING.md`, `AGENTS.md`, `STATUS.md`, `GIT_WORKFLOW.md`, `CHANGELOG.md`).
- Script anonimizador de capturas HTML de MIEL (`scripts/anonymize_html.py`) con tests automatizados (`scripts/test_anonymize_html.py`).
- Estructura inicial de la aplicación **Flutter** multiplataforma (`android`, `linux`, `windows`, `macos`) bajo el identificador `io.github.tiago_pujia.libremiel`.
- Core de MIEL:
  - Cliente HTTP (`MielClient`) con manejo de cookies (`PHPSESSID`, `SESSID`), verificación de sesión y protección contra bloqueo de cuenta.
  - Parsers HTML puros para panel interno, detalles de comisión/docentes, Contenidos, Portafolio, Mensajería, Foros (`forov2`) y Evaluaciones, con tests unitarios y fixtures anonimizados.
  - Persistencia local SQLite (`Drift`) para snapshots, historial de notificaciones, caché de docentes y configuración por materia.
  - Motor de sincronización en dos ciclos (`SyncEngine`) con *baseline* silencioso inicial y respeto por efectos colaterales de lectura en MIEL.
- Interfaz fiel a **MIeL UNLaM** en modo claro y modo oscuro (`#009674` / `#128268`) con cambio rápido de tema persistido:
  - Pantalla de Login con degradado esmeralda, hexágonos flotantes animados, saludo dinámico, inputs translúcidos y botón primario blanco.
  - Pantalla de inicio idéntica a `/principal/interno/` (**Materias activas**) con barra doble superior (acceso **Mi perfil** y hovers completos), menú lateral minimalista (`230px` en escritorio, drawer en móvil), tarjetas de materias con herramientas semánticas (hover verde/azul/rojo, sin botón Chat), badges rojos, modo **Organizar materias** (arrastrar para reordenar, ocultar/mostrar y silenciar alertas), botón **Ver materias ocultas** junto a **Organizar materias** y diálogo `⋮` de docentes y alertas por módulo.
  - Feed de **Novedades** adaptado al estilo `.mensaje-no-leido` (borde esmeralda de `4px`) y pantalla de **Alertas y ajustes** con opción de **ejecutar LibreMIEL al iniciar el sistema** (Linux XDG Autostart, Windows Registry `HKCU\...\Run`, macOS LaunchAgents).
  - Vistas en **modo borrador (Fase 2)** para cada módulo (`Contenidos`, `Autoguía`, `Portafolio`, `Mensajería`, `Foros`, `Encuestas`, `Evaluación`) con breadcrumbs desplegables, sub-menú lateral fiel a MIeL, previsualización de caché local SQLite sin peticiones invasivas y botón directo a MIeL web.
- Migración de esquema SQLite local (`v1 → v3`) para almacenar código de materia, rol, herramientas habilitadas, orden personalizado (`sortOrder`) y visibilidad local por comisión sin perder datos previos.
- Nuevo ícono oficial de **LibreMIEL** aplicado en la app y en todos los targets (Linux, Android, Windows y macOS).
- Integraciones de plataforma: almacenamiento seguro de credenciales (con fallback cifrado/restringido `chmod 600` en Linux sin `libsecret`), notificaciones nativas, bandeja del sistema en escritorio y worker periódico en Android (`WorkManager`).
- Workflows de GitHub Actions (`ci.yml` y `release.yml`) y configuraciones de empaquetado multi-arquitectura: Windows x64/ARM64 (`.exe` + `.zip`), macOS Universal x86_64+ARM64 (`.dmg` + `.zip`), Linux x64/ARM64 (`AppImage`, `.deb`, `.rpm`, Arch `.pkg.tar.zst`, portable `.tar.gz`) y Android (`.apk` universal + `arm64-v8a`, `armeabi-v7a`, `x86_64`).
