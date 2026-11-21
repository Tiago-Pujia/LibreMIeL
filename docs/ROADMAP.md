# Roadmap — Próximas Fases de LibreMIEL

Este documento describe en detalle las próximas fases planificadas para **LibreMIEL** a partir de la base ya completada (**Fase 0 — Core**, **Fase 1 — MVP de Notificaciones** y **Fase 2 — Lectura Nativa**).

> Ver el tablero de avance actual en [`STATUS.md`](STATUS.md) y las reglas técnicas invariantes en [`AGENTS.md`](AGENTS.md).

---

## Resumen de Fases

| Fase | Nombre | Estado | Enfoque principal |
| :--- | :--- | :---: | :--- |
| **Fase 0** | Core y Parsers | ✅ Completado | Cliente HTTP, cookies, parsers puros, SQLite (`Drift`) y `SyncEngine` en 2 ciclos |
| **Fase 1** | MVP y Notificaciones | ✅ Completado | UI fiel a MIeL, alertas nativas, tray, autostart, Android Worker y CI/releases |
| **Fase 2** | Lectura Nativa | ✅ Completado | Contenidos, Portafolio, Mensajería unificada, Foros, módulos secundarios y descargas autenticadas |
| **Fase 3** | Escritura y Envío de Contenido | ⏳ Planificado | Enviar mensajes, subir entregas de Portafolio, participar en Foros y acciones interactivas |
| **Fase 4** | Descarga Masiva (Foros y Contenidos) | ⏳ Planificado | Respaldo organizado por materia de archivos y foros completos antes de la depuración cuatrimestral |
| **Fase 5** | Sesión Permanente | ⏳ Planificado | Persistencia local de credenciales, renovación silenciosa y auto-login continuo hasta logout manual |
| **Fase 6** | Buscador Global Offline | ⏳ Planificado | Búsqueda instantánea *full-text* (SQLite FTS5) sobre todas las materias sin conexión |
| **Fase 7** | Integración con IA | ⏳ Planificado | Asistente de estudio *local-first* (Ollama/local o BYOK) sobre el material descargado de la cátedra |

---

## Fase 3 — Escritura y Envío de Contenido en MIeL

**Objetivo:** Pasar de un cliente de solo lectura a un cliente completo donde el estudiante pueda redactar, responder y subir entregas directamente desde LibreMIEL sin tener que abrir el navegador.

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

**Objetivo:** Que el estudiante inicie sesión una sola vez y LibreMIEL mantenga la sesión permanentemente activa en cada apertura y durante todo el uso, cerrando sesión **únicamente** cuando el usuario presione explícitamente **Cerrar sesión**.

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
- **Invariante anti-bloqueo (`estado: 1, 2, 3`):** si el usuario cambia su contraseña en MIeL web y el re-login automático recibe `estado != 0`, LibreMIEL debe **detener inmediatamente los reintentos** para evitar bloquear la cuenta (`estado: 3`) y mostrar un aviso puntual para actualizar la clave, sin borrar las materias ni el archivo offline local.

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
