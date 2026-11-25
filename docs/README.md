# Guía de Documentación — LibreMIeL

Bienvenido a la carpeta de documentación (`/docs`) de **LibreMIeL**. Este documento sirve como mapa y guía rápida para entender cómo está organizada la documentación, qué propósito tiene cada archivo y dónde encontrar o actualizar la información funcional, operativa y del relevamiento técnico sobre **MIeL (UNLaM)** (versión relevada: `2025.2.0`).

> **Orientación para Modelos de IA y Agentes de Código:**  
> Lee primero **[`AGENTS.md`](AGENTS.md)** para conocer el contexto del proyecto, las invariantes técnicas inquebrantables y los comandos de verificación antes de editar código o diseñar módulos.

---

## 🗺️ Mapa Rápido de la Documentación

```text
docs/
├── 📄 README.md                                        <- Esta guía de navegación
├── 📄 AGENTS.md                                        <- Reglas canónicas e invariantes obligatorias (humanos e IA)
├── 📄 GIT_WORKFLOW.md                                  <- Estrategia de ramas (main prod / DEV), CI y releases
├── 📄 CONTRIBUTING.md                                  <- Guía de contribución, entorno y anonimización de HTML
├── 📄 STATUS.md                                        <- Estado actual del proyecto por fase y componente
├── 📄 ROADMAP.md                                       <- Hoja de ruta evolutiva y especificación de fases (Fases 0 a 12)
├── 📄 IMPLEMENTATION_PLAN.md                           <- Plan técnico detallado de implementación por fases
├── 📄 CHANGELOG.md                                     <- Historial cronológico de cambios y versiones (SemVer)
├── 📄 01-proyecto-relacionado.md                       <- Antecedentes y lecciones validadas en ExtraerForosMiel
├── 📄 02-arquitectura-y-sesion-miel.md                 <- Stack de MIeL, flujo de login, cookies, CORS y sesión
├── 📄 03-panel-principal-y-modulos.md                  <- Estructura de /principal/interno/, docentes y sistema de badges
├── 📄 04-modulos-clave-endpoints-y-dom.md              <- Endpoints, selectores DOM y efectos colaterales (4 módulos clave)
└── 📄 05-estrategia-notificaciones-y-arquitectura.md   <- Motor de sincronización en 2 ciclos, seguridad local-first y stack
```

---

## 📄 Gobernanza, Gestión y Flujo de Trabajo

| Archivo | ¿De qué trata? | ¿Cuándo consultarlo o actualizarlo? |
| :--- | :--- | :--- |
| [`AGENTS.md`](AGENTS.md) | **Fuente canónica de reglas e invariantes** para desarrolladores y agentes de IA. Define el stack Flutter, efectos colaterales prohibidos en MIeL, separación `MielApiClient` / `MielInteractiveReader` / `MielWriter`, aislamiento multi-cuenta y checklist de tests. | Al iniciar cualquier tarea o cuando cambie una regla arquitectónica o convención del repositorio. |
| [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md) | **Estrategia oficial de Git y Releases.** Establece que `main` es exclusiva de producción, `DEV` es la rama troncal de desarrollo diario, detalla Conventional Commits y cómo validar compilaciones en los 4 SO antes de publicar un tag. | Al crear ramas, preparar commits, ejecutar pruebas en GitHub Actions o publicar un nuevo Release. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | **Guía de colaboración y privacidad.** Explica cómo preparar el entorno (Flutter + Python 3), cómo reportar cambios en pantallas de MIeL y cómo usar `scripts/anonymize_html.py` para limpiar datos personales de capturas HTML. | Al sumar nuevos colaboradores, agregar o actualizar fixtures en `app/test/fixtures/` o modificar reglas de privacidad. |
| [`STATUS.md`](STATUS.md) | **Tablero de estado actual.** Resume el grado de avance por fase (Investigación, Gobernanza, Fases 0 a 12, CI/CD y verificación local) y concentra en su tabla general las tareas y mejoras pendientes. | Al comenzar una sesión de trabajo o al completar/avanzar un componente o fase del proyecto. |
| [`ROADMAP.md`](ROADMAP.md) | **Hoja de ruta funcional y técnica.** Describe la visión evolutiva de LibreMIeL (Fases 0 a 12) y detalla las especificaciones de tareas y mejoras pendientes (widgets Android, perfil de MIeL, autostart silencioso, panel de configuración, descargas móviles, comparativa UI y auditoría final). | Al planificar nuevas fases, diseñar capacidades futuras o revisar el alcance funcional de cada etapa. |
| [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) | **Plan técnico de ejecución.** Consolida el diseño de ingeniería, decisiones de arquitectura, contratos de clases (`SyncEngine`, `MielInteractiveReader`, `MielWriter`, `BulkDownloadManager`) y hallazgos DOM aplicados en cada fase. | Al implementar o refactorizar funcionalidades complejas de una fase activa o auditar decisiones de diseño previas. |
| [`CHANGELOG.md`](CHANGELOG.md) | **Registro cronológico de cambios.** Historial estructurado bajo *Keep a Changelog* y *Versionado Semántico (SemVer)* con todas las adiciones, mejoras y correcciones del proyecto. | En cada Pull Request, merge o cierre de tarea que agregue o altere funcionalidades del sistema. |

---

## 🧭 Relevamiento Técnico de MIeL y Arquitectura (`01` a `05`)

Documentos de referencia profunda sobre el funcionamiento interno de `https://miel.unlam.edu.ar/` (`2025.2.0`) y la arquitectura *local-first* de **LibreMIeL**:

| Archivo | ¿De qué trata? | ¿Cuándo consultarlo o actualizarlo? |
| :--- | :--- | :--- |
| [`01-proyecto-relacionado.md`](01-proyecto-relacionado.md) | **Antecedentes ([ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)).** Resume la herramienta CLI previa en Node.js y las lecciones reutilizables: cliente HTTP con *cookie jar* sin navegador headless, descargas binarias autenticadas, sanitización multiplataforma y peticiones secuenciales. | Al trabajar sobre el exportador masivo de foros (`.md`, `.json`, `.html`) o revisar los fundamentos del cliente HTTP. |
| [`02-arquitectura-y-sesion-miel.md`](02-arquitectura-y-sesion-miel.md) | **Autenticación, cookies y restricciones de red.** Documenta el stack de MIeL (`Apache` + PHP server-side + `W3.CSS`), el login `POST /principal/event/login/` (`estado: 0/1/2/3`), las cookies `PHPSESSID` y `SESSID`, endpoints `isLogged` y `recargarSesion`, ausencia de WebSockets/Push y políticas CORS. | Al modificar el login, persistencia de sesión, reconexión automática (`ensureActiveSession`), manejo de errores de cuenta o cliente HTTP (`DioMielClient`). |
| [`03-panel-principal-y-modulos.md`](03-panel-principal-y-modulos.md) | **Panel `/principal/interno/`, docentes y badges.** Explica cómo parsear tarjetas `.materia-bloque` (activas vs. `.materia-bloque-oculta`), el modal `/principal/cursoDetalles/id/{id}` para cachear docentes (`Tutor/a`), qué módulos emiten `.w3-badge` rojo y qué módulos adicionales existen (`Evaluación`, `Encuestas`, `Autoguía`, etc.). | Al editar el parser o la UI de Materias activas, la detección de rol docente, el cálculo de badges o la navegación hacia módulos secundarios. |
| [`04-modulos-clave-endpoints-y-dom.md`](04-modulos-clave-endpoints-y-dom.md) | **Contratos HTTP, selectores DOM y efectos colaterales.** Especificación exhaustiva de los 4 módulos principales (**Contenidos**, **Portafolio**, **Mensajería** y **Foros `forov2`**), detallando URLs de lectura, descarga y escritura (`POST`), tablas, clases CSS y qué peticiones `GET` borran badges o marcan ítems como leídos en el servidor. | Antes de tocar cualquier parser HTML (`app/lib/core/parsers/`), vista nativa de lectura/escritura o lógica que consulte endpoints de Contenidos, Portafolio, Mensajería o Foros. |
| [`05-estrategia-notificaciones-y-arquitectura.md`](05-estrategia-notificaciones-y-arquitectura.md) | **Arquitectura multiplataforma y `SyncEngine`.** Define el motor de sincronización en 2 ciclos (Ciclo 1 rápido sobre `/principal/interno/` guiado por badges y Ciclo 2 sobre Portafolio/Evaluación), el modelo de base de datos SQLite (`Drift`), el almacenamiento seguro de credenciales por SO y la ejecución en segundo plano (Android `WorkManager` / Desktop Tray). | Al modificar el motor de sincronización (`SyncEngine`), las reglas de disparo de notificaciones, el esquema SQLite o la integración con el sistema operativo en escritorio y Android. |

---

## 📌 Reglas de Mantenimiento de la Documentación

1. **Raíz limpia y sin duplicaciones:** Mantener toda la documentación centralizada en `/docs` y el código Flutter en `/app`, dejando únicamente [`README.md`](../README.md) y [`LICENSE`](../LICENSE) en la raíz del repositorio.
2. **Actualización continua:** Cuando un cambio modifique el avance de una fase, la arquitectura o el comportamiento de un parser/módulo, se debe actualizar el documento correspondiente en `/docs` ([`STATUS.md`](STATUS.md), [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), etc.) y registrar una entrada en [`CHANGELOG.md`](CHANGELOG.md).
3. **Privacidad y anonimización estricta:** Nunca incluir DNIs, contraseñas, cookies (`PHPSESSID`, `SESSID`) ni nombres reales en ejemplos documentales o fixtures; toda captura HTML de MIeL debe procesarse con `python3 scripts/anonymize_html.py` siguiendo [`CONTRIBUTING.md`](CONTRIBUTING.md).
4. **Flujo de desarrollo:** Toda contribución debe respetar las invariantes técnicas de [`AGENTS.md`](AGENTS.md) y la estrategia de ramas (`DEV` / `main`) definida en [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md).

