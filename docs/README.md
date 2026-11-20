# Documentación y Guías — LibreMIEL

Esta carpeta centraliza toda la documentación de **LibreMIEL**: seguimiento del proyecto, colaboración, flujo Git, instrucciones para asistentes de IA y relevamiento técnico completo de **MIEL (UNLaM)** (versión relevada: `2025.2.0`).

> **Orientación para Modelos de IA y Agentes de Código:**  
> Lee primero **[`AGENTS.md`](AGENTS.md)** para conocer las reglas invariantes del proyecto antes de editar código o diseñar módulos.

---

## 📂 Documentos de Gestión y Comunidad

| Documento | Descripción |
| :--- | :--- |
| **[STATUS.md](STATUS.md)** | Tabla de estado general del proyecto por fase y componente. |
| **[CHANGELOG.md](CHANGELOG.md)** | Historial de cambios y versiones (Keep a Changelog / SemVer). |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Cómo preparar el entorno, colaborar y anonimizar capturas HTML de MIEL. |
| **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** | Explicación práctica sobre cómo usar las ramas de Git, commits y releases. |
| **[AGENTS.md](AGENTS.md)** | Reglas estrictas, invariantes técnicas y checklist para modelos de IA. |

---

## 🧭 Relevamiento Técnico de MIEL y Arquitectura

| Si necesitás... | Lee este documento |
| :--- | :--- |
| Ver el punto de partida y código ya probado contra MIEL | **[01-proyecto-relacionado.md](01-proyecto-relacionado.md)** (sobre [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)) |
| Implementar login, cookies, renovación de sesión o entender restricciones CORS/Push/Legal | **[02-arquitectura-y-sesion-miel.md](02-arquitectura-y-sesion-miel.md)** |
| Parsear materias activas/ocultas, docentes (`Tutor/a`), badges del home o módulos extra | **[03-panel-principal-y-modulos.md](03-panel-principal-y-modulos.md)** |
| Ver endpoints exactos, selectores DOM y **efectos colaterales** de Contenidos, Portafolio, Mensajería y Foros | **[04-modulos-clave-endpoints-y-dom.md](04-modulos-clave-endpoints-y-dom.md)** |
| Diseñar el motor de sincronización, almacenamiento local, segundo plano en Android/Desktop o elegir stack | **[05-estrategia-notificaciones-y-arquitectura.md](05-estrategia-notificaciones-y-arquitectura.md)** |
