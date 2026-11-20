# Documentación Técnica y Guía para IAs — LibreMIEL

Esta carpeta documenta el funcionamiento interno de la plataforma **MIEL (UNLaM)** (versión relevada: `2025.2.0`), las lecciones de proyectos open source previos y las decisiones de diseño de **LibreMIEL**.

> **Orientación para Modelos de IA y Agentes de Código:**  
> Antes de proponer arquitectura, escribir parsers o implementar nuevas funcionalidades en **LibreMIEL**, lee esta guía y el documento específico del módulo con el que vayas a trabajar.  
> **Alcance del proyecto:** LibreMIEL es un cliente alternativo multiplataforma (Windows, macOS, Linux y Android), gratuito, *local-first* y open source. Las **notificaciones** (Contenidos, Portafolio, Mensajería y Foros) son el **primer hito**, pero la base debe quedar diseñada de forma extensible para sumar gradualmente más funciones (lectura cómoda, descargas, interacción con foros/mensajería, recordatorios, etc.).

---

## 🧭 Mapa de Lectura Rápida (para Humanos e IAs)

| Si necesitás... | Lee este documento |
| :--- | :--- |
| Ver el punto de partida y código ya probado contra MIEL | **[01-proyecto-relacionado.md](01-proyecto-relacionado.md)** (sobre [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)) |
| Implementar login, cookies, renovación de sesión o entender restricciones CORS/Push/Legal | **[02-arquitectura-y-sesion-miel.md](02-arquitectura-y-sesion-miel.md)** |
| Parsear materias activas/ocultas, docentes (`Tutor/a`), badges del home o módulos extra | **[03-panel-principal-y-modulos.md](03-panel-principal-y-modulos.md)** |
| Ver endpoints exactos, selectores DOM y **efectos colaterales** de Contenidos, Portafolio, Mensajería y Foros | **[04-modulos-clave-endpoints-y-dom.md](04-modulos-clave-endpoints-y-dom.md)** |
| Diseñar el motor de sincronización, almacenamiento local, segundo plano en Android/Desktop o elegir stack | **[05-estrategia-notificaciones-y-arquitectura.md](05-estrategia-notificaciones-y-arquitectura.md)** |

---

## ⚠️ Reglas Críticas que Todo Agente IA Debe Respetar en LibreMIEL

1. **No hacer polling ciego a `Contenidos`:** El solo `GET /contenido/archivos/comision/{id}` limpia en el servidor el badge rojo y la marca amarilla `w3-pale-yellow` de los archivos nuevos. Consultar siempre `/principal/interno/` primero y entrar a `Contenidos` únicamente cuando su badge sea `> 0`.
2. **No abrir mensajes al monitorear `Mensajería`:** Leer únicamente `/mensajeria/entrada/comision/{id}` (no altera el estado de lectura). Abrir `/mensajeria/verEntrada/...` marca el mensaje como leído en MIEL.
3. **Cuidar el estado leído en `Foros`:** Consultar `/forov2/temas/comision/{id}` no borra badges; entrar a `/forov2/mensajes/...` sí marca el tema como leído del lado del servidor.
4. **Sin CORS ni WebSockets:** MIEL no expone `Access-Control-Allow-Origin`, bloquea iframes (`SAMEORIGIN`) y no usa WebSockets/SSE. No diseñar el core como una SPA/PWA que llame a MIEL desde un navegador externo; usar siempre un cliente HTTP nativo.
5. **Modelo estrictamente *local-first*:** Nunca proponer ni implementar servidores centrales que reciban o almacenen credenciales o cookies de usuarios. Guardar credenciales únicamente en el almacén seguro del sistema operativo.
6. **Parsers desacoplados y defensivos:** MIEL renderiza HTML server-side en PHP. Aislar todo scraping en una capa de *adapters/parsers* testeada con *fixtures* HTML anonimizados, sin mezclar selectores con la UI.
7. **Seguridad, privacidad y propiedad intelectual:**
   - Nunca incluir credenciales (`.env`), DNIs, nombres reales de alumnos/docentes ni cookies en código, tests o documentación.
   - No copiar CSS, JS, íconos ni logotipos propietarios de MIEL/UNLaM.
   - Evitar ráfagas paralelas agresivas contra los servidores institucionales; usar peticiones secuenciales o concurrencia mínima y frenar reintentos si el login falla (`estado: 1, 2 o 3`).
