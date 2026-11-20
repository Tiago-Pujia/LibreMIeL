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
- Interfaz MVP Material 3: Login seguro, Bandeja unificada de novedades, Materias con filtros por módulo y Ajustes (incluyendo modo de foros no invasivo vs. respuestas de docentes).
- Integraciones de plataforma: almacenamiento seguro de credenciales, notificaciones nativas, bandeja del sistema en escritorio y worker periódico en Android (`WorkManager`).
- Workflows de GitHub Actions (`ci.yml` y `release.yml`) y configuraciones de empaquetado multi-arquitectura: Windows x64/ARM64 (`.exe` + `.zip`), macOS Universal x86_64+ARM64 (`.dmg` + `.zip`), Linux x64/ARM64 (`AppImage`, `.deb`, `.rpm`, Arch `.pkg.tar.zst`, portable `.tar.gz`) y Android (`.apk` universal + `arm64-v8a`, `armeabi-v7a`, `x86_64`).
