# Estado del Proyecto — LibreMIEL

*Última actualización: 20 de noviembre de 2026*

Este tablero resume el avance de **LibreMIEL** por fase y componente.

---

## Tabla General de Estado

| Fase / Módulo | Componente | Estado | Detalle |
| :--- | :--- | :---: | :--- |
| **Investigación** | Relevamiento técnico de MIEL (`2025.2.0`) | ✅ Completado | Login, cookies, CORS, badges, efectos colaterales y endpoints documentados en `docs/` |
| **Gobernanza** | Licencia MIT, `CONTRIBUTING.md`, `AGENTS.md`, `GIT_WORKFLOW.md`, `CHANGELOG.md` | ✅ Completado | Documentación centralizada en `docs/` y raíz limpia con `README.md` |
| **Gobernanza** | Script anonimizador de HTML (`scripts/anonymize_html.py`) + tests | ✅ Completado | Python 3 sin dependencias externas, testeado con `unittest` |
| **Fase 0 — Core** | Scaffolding Flutter (`android`, `linux`, `windows`, `macos`) | ✅ Completado | Configurado con `io.github.tiago_pujia.libremiel`, entitlements macOS y permisos Android |
| **Fase 0 — Core** | Cliente HTTP y sesión (`MielClient` + `PersistCookieJar`) | ✅ Completado | Login, `isLogged`, `recargarSesion`, cola secuencial, backoff y corte ante `estado != 0` |
| **Fase 0 — Core** | Parsers HTML puros (`interno`, `cursoDetalles`, `contenidos`, `portafolio`, `mensajeria`, `forov2`, `evaluacion`) | ✅ Completado | Basados en `package:html` con tests unitarios y fixtures anonimizados |
| **Fase 0 — Core** | Base de datos local SQLite (`Drift`) | ✅ Completado | Snapshots por materia/módulo, caché de docentes, ajustes e historial de alertas |
| **Fase 0 — Core** | Motor de sincronización en 2 ciclos (`SyncEngine`) | ✅ Completado | Baseline silencioso + Ciclo 1 (`/principal/interno/`) + Ciclo 2 (`Portafolio`/`Evaluación`) + tests de invariantes |
| **Fase 1 — MVP** | Almacenamiento seguro de credenciales (`flutter_secure_storage`) | ✅ Completado | Keystore / Credential Manager / Keychain / `libsecret` |
| **Fase 1 — MVP** | Notificaciones nativas + Tray de escritorio + Worker Android | ✅ Completado | `flutter_local_notifications`, `tray_manager`, `window_manager`, `workmanager` |
| **Fase 1 — MVP** | Pantallas MVP (Login, Feed unificado, Materias, Ajustes) | ✅ Completado | Material 3 responsive para escritorio (`NavigationRail`) y Android (`NavigationBar`) |
| **CI/CD y Releases** | Workflows de GitHub Actions (`ci.yml` y `release.yml`) + `packaging/` | ✅ Completado | Windows x64/ARM64 (`.exe` + `.zip`), macOS Universal x86_64+ARM64 (`.dmg` + `.zip`), Linux x64/ARM64 (`AppImage`, `.deb`, `.rpm`, `.pkg.tar.zst`, `.tar.gz`), Android (`universal`, `arm64-v8a`, `armeabi-v7a`, `x86_64`) |
| **Verificación local** | Compilación Linux, Android APK, paquetes Linux y prueba real en MIEL | ✅ Completado | Compilado `linux-x64` (`28 MB`), `AppImage`/`.deb`/`.rpm`/`.pkg.tar.zst` (`12 MB`), Android APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`, universal) y validado `SyncEngine` + parsers en vivo (solo lectura) |
| **Fase 2 — Lectura** | Visor nativo de Contenidos, Mensajería unificada, Portafolio y Foros | ⏳ Pendiente | Planificado para `v0.2` – `v0.3` |
| **Fase 3 — Interacción** | Responder foros/mensajes, exportar a Markdown, Evaluaciones y Calendario | ⏳ Pendiente | Planificado para `v1.0+` |

---

## Leyenda

- ✅ **Completado:** Implementado y verificado.
- 🔄 **En progreso:** En construcción en la iteración actual.
- ⏳ **Pendiente:** Planificado para fases posteriores.
- ⚠️ **Requiere acción:** Depende de un paso manual local (ej. instalación con `sudo` o prueba con credenciales reales).
