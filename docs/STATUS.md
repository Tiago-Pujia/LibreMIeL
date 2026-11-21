# Estado del Proyecto — LibreMIEL

*Última actualización: 21 de noviembre de 2026*

Este tablero resume el avance de **LibreMIEL** por fase y componente.

---

## Tabla General de Estado

| Fase / Módulo | Componente | Estado | Detalle |
| :--- | :--- | :---: | :--- |
| **Investigación** | Relevamiento técnico de MIEL (`2025.2.0`) | ✅ Completado | Login, cookies, CORS, badges, efectos colaterales, avatares autenticados y endpoints documentados en `docs/` |
| **Gobernanza** | Licencia MIT, `CONTRIBUTING.md`, `AGENTS.md`, `GIT_WORKFLOW.md`, `CHANGELOG.md` | ✅ Completado | Documentación centralizada en `docs/` y raíz limpia con `README.md` |
| **Gobernanza** | Script anonimizador de HTML (`scripts/anonymize_html.py`) + tests | ✅ Completado | Python 3 sin dependencias externas, testeado con `unittest` |
| **Fase 0 — Core** | Scaffolding Flutter (`android`, `linux`, `windows`, `macos`) | ✅ Completado | Configurado en `app/` con `io.github.tiago_pujia.libremiel`, entitlements macOS y permisos Android |
| **Fase 0 — Core** | Cliente HTTP y sesión (`MielClient` + `MielInteractiveReader` + `PersistCookieJar`) | ✅ Completado | Login limpio (reseteo de cookies previo), `isLogged`, `recargarSesion`, cola secuencial, backoff, corte ante `estado != 0` y descargas autenticadas |
| **Fase 0 — Core** | Parsers HTML puros (`interno`, `cursoDetalles`, `contenidos`, `portafolio`, `mensajeria`, `forov2`, `evaluacion`, `encuestas`, `autoguia`) | ✅ Completado | Basados en `package:html` con tests unitarios y fixtures anonimizados |
| **Fase 0 — Core** | Base de datos local SQLite (`Drift`, esquema `v3`) | ✅ Completado | Snapshots por materia/módulo, caché de docentes, ajustes, historial de alertas, poda automática (`pruneSubjectsNotIn`) y aislamiento al cambiar de cuenta (`clearAccountData`) |
| **Fase 0 — Core** | Motor de sincronización en 2 ciclos (`SyncEngine`) | ✅ Completado | Baseline silencioso + Ciclo 1 (`/principal/interno/` + poda de comisiones inactivas) + Ciclo 2 (`Portafolio`/`Evaluación`) + cancelación segura ante cambio de cuenta + tests de invariantes |
| **Fase 1 — MVP** | Almacenamiento seguro de credenciales (`flutter_secure_storage`) | ✅ Completado | Keystore / Credential Manager / Keychain / `libsecret` (con fallback local `chmod 600` en Linux) |
| **Fase 1 — MVP** | Notificaciones nativas + Tray de escritorio + Worker Android | ✅ Completado | `flutter_local_notifications`, `tray_manager` (hexágono con campana), `window_manager`, `workmanager` y autostart en escritorio |
| **Fase 1 — MVP** | Interfaz fiel a MIeL (Login, Materias activas, Novedades, Ajustes) | ✅ Completado | Estética oficial de MIeL en modo claro y oscuro (`#009674` / `#128268`), tarjetas con herramientas y badges rojos ajustados, barra doble + sidebar responsive y aislamiento multi-cuenta |
| **CI/CD y Releases** | Workflows de GitHub Actions (`ci.yml` y `release.yml`) + `packaging/` | ✅ Completado | Windows x64/ARM64 (`.exe` + `.zip`), macOS Universal x86_64+ARM64 (`.dmg` + `.zip`), Linux x64/ARM64 (`AppImage`, `.deb`, `.rpm`, `.pkg.tar.zst`, `.tar.gz`), Android (`universal`, `arm64-v8a`, `armeabi-v7a`, `x86_64`) |
| **Verificación local** | Compilación Linux, Android APK, paquetes Linux y prueba real en MIEL | ✅ Completado | Compilado `linux-x64`, `AppImage`/`.deb`/`.rpm`/`.pkg.tar.zst`, Android APKs y validado `SyncEngine` + lectores nativos en vivo (`27/27` tests en verde) |
| **Fase 2 — Lectura** | Visor nativo de Contenidos, Mensajería unificada, Portafolio, Foros y módulos secundarios | ✅ Completado | Lectores nativos fieles a MIeL (`2025.2.0`) en claro y oscuro (`MielInteractiveReader` separado de `SyncEngine`), descargas autenticadas (`Downloads/LibreMIEL`) con notificación no bloqueante, avatares autenticados (`MielAvatar`), Contenidos (acordeones `.desplegarModulo`, pares `thead`/`tbody` y buscador alineado), Portafolio (prácticas, entregas/correcciones, archivos enviados y grupos con cabeceras, asistencia `Presente`/`Ausente`/`Justificado` en azul `.w3-blue`, notas y certificados), Mensajería (bandejas, bandeja unificada multi-materia, filtros, `verEntrada` y destinatarios), Foros (`Temas abiertos` con tarjetas clicables, hilos anidados, colapsado `li-ver-mas`, `@menciones`, imágenes autenticadas con zoom y adjuntos) y Evaluación/Encuestas/Autoguía |
| **Fase 3 — Escritura** | Envío de contenido nativo (Mensajería, Portafolio, Foros y módulos secundarios) | ⏳ Pendiente | Redactar/responder mensajes, subir entregas en Portafolio, publicar/responder en Foros y acciones rápidas (`MielWriter`). Ver [`ROADMAP.md`](ROADMAP.md#fase-3--escritura-y-envío-de-contenido-en-miel) |
| **Fase 4 — Descarga masiva** | Descargar foros completos y contenidos por materia | ⏳ Pendiente | Exportar foros a `.md`/`.json`/`.html` (basado en `ExtraerForosMiel`) y descarga incremental organizada de Contenidos con cola secuencial. Ver [`ROADMAP.md`](ROADMAP.md#fase-4--descarga-masiva-de-foros-y-contenidos) |
| **Fase 5 — Sesión permanente** | Persistencia local de credenciales y auto-login continuo | ⏳ Pendiente | Inicio de sesión automático en cada arranque y reconexión silenciosa ante vencimiento de `PHPSESSID`, cerrando sesión solo por acción explícita del usuario. Ver [`ROADMAP.md`](ROADMAP.md#fase-5--sesión-permanente) |
| **Fase 6 — Buscador offline** | Buscador global *full-text* sin conexión | ⏳ Pendiente | Índice local SQLite FTS5 sobre Contenidos, Mensajería, Foros y Portafolio con filtros por materia, módulo y rol docente. Ver [`ROADMAP.md`](ROADMAP.md#fase-6--buscador-global-offline) |
| **Fase 7 — Integración con IA** | Asistente de estudio *local-first* (Ollama/local o BYOK) | ⏳ Pendiente | Resúmenes, preguntas con citas sobre apuntes/foros descargados y guías de estudio sin servidor central. Ver [`ROADMAP.md`](ROADMAP.md#fase-7--integración-con-ia-asistente-de-estudio) |

---

## Leyenda

- ✅ **Completado:** Implementado y verificado.
- 🔄 **En progreso:** En construcción en la iteración actual.
- ⏳ **Pendiente:** Planificado para fases posteriores.
- ⚠️ **Requiere acción:** Depende de un paso manual local (ej. instalación con `sudo` o prueba con credenciales reales).
