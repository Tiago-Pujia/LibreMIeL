# 05 — Estrategia de Notificaciones y Arquitectura Multiplataforma (LibreMIeL)

Este documento sintetiza las decisiones técnicas recomendadas para construir **LibreMIeL** como un cliente alternativo **gratuito, open source y multiplataforma** (Windows, macOS, Linux y Android).

> **Visión evolutiva para colaboradores e IAs:**  
> Las **notificaciones** (Contenidos, Portafolio, Mensajería y Foros) constituyen el **primer hito funcional**, pero la arquitectura debe ser modular y extensible para incorporar progresivamente otras capacidades (navegación cómoda de materias, descarga organizada de apuntes, lectura/respuesta en foros y mensajería, recordatorios de vencimientos, etc.).

---

## 1. Motor de Sincronización en Dos Ciclos (Mínima Carga y Máxima Precisión)

Dado que MIeL no ofrece WebSockets ni SSE, el motor debe basarse en **polling inteligente + comparación contra estado local (*snapshots*)**, estructurado en dos frecuencias para no sobrecargar los servidores de la UNLaM ni consumir batería innecesariamente:

### Ciclo 1 — Sondeo Principal (cada ~15 min en Android / 5–15 min en Escritorio)
1. **Validar sesión:** `GET /principal/event/isLogged/`. Si no devuelve `"1"`, re-autenticar transparentemente con `POST /principal/event/login/` (conservando `PHPSESSID` y `SESSID`).
2. **Lectura única del panel:** `GET /principal/interno/` (solo lectura, sin efectos colaterales).
   - Filtrar materias activas (ignorando `.materia-bloque-oculta` y materias silenciadas por el usuario).
3. **Actuar únicamente donde hubo badge `> 0`:**
   - **Contenidos (`badge > 0`):** Hacer 1 `GET /contenido/archivos/comision/{id}`. Extraer las filas con `w3-pale-yellow` y comparar `{idElemento}` contra el snapshot local. Emitir notificación con título del archivo, carpeta y materia, y guardar en el historial de notificaciones local *(ya que MIeL limpiará el badge al entregar la página)*.
   - **Mensajería (`badge > 0`):** Hacer `GET /mensajeria/entrada/comision/{id}` (**nunca** `verEntrada`). Detectar `tr.mensaje-no-leido` cuyo `data-id` no haya sido notificado aún. Identificar si el remitente es docente cruzándolo contra la lista cacheada de `/principal/cursoDetalles/id/{id}`. Si el asunto es `"Corrección"`, disparar además una actualización inmediata de **Portafolio** para traer los detalles de la devolución.
   - **Foros (`badge > 0`):** Hacer `GET /forov2/temas/comision/{id}` (no borra badges). Detectar temas cuyo `badge > 0` o cuya fecha de `Último mensaje` / `cantidadMensajes` haya cambiado.
     - *Modo no invasivo:* notificar actividad nueva en el tema sin abrir `/forov2/mensajes/...`.
     - *Modo detallado (configurable):* inspeccionar los mensajes nuevos (vía `actualizarMensajes` o `/forov2/mensajes/...`) para alertar específicamente cuando un `Tutor/a` responde a un mensaje/hilo del `usuarioId` o publica un aviso.
   - **Novedades globales (`badge > 0` en menú lateral):** Notificar novedad institucional en `/principal/novedades/`.

### Ciclo 2 — Sondeo Secundario (cada 30–60 min o al abrir la app)
Para módulos que **no emiten badge** en `/principal/interno/`:
- **Portafolio:** `GET /portafolio/practicas/comision/{id}` por cada materia activa. Comparar por `{idPractica}` cambios en:
  - Nueva práctica publicada.
  - Cambio en `F. vencim.` (y recordatorios locales configurables, ej. 24 h / 48 h antes del vencimiento si aún no figura entregada).
  - Cambio en `F. correc.`, `Estado` o `Nota` → opcionalmente abrir `/portafolio/entregas/comision/{id}/id/{idPractica}` para leer `div.correccion` (`Observaciones`, `Calificación`, `Corregido por`).
- **Evaluación (opcional):** `GET /evaluacion/evaluaciones/comision/{id}` para detectar nuevas evaluaciones/cuestionarios en estado `Abierto` / `Habilitado`.

---

## 2. Reglas de Seguridad, Privacidad y Modelo *Local-First*

Para que **LibreMIeL** sea confiable y sostenible como software libre sin costos de infraestructura:

- **Sin servidor central propio:** Cada dispositivo se conecta directamente a `https://miel.unlam.edu.ar/`. Ningún tercero recibe ni almacena el DNI, la contraseña ni las sesiones de los estudiantes.
- **Almacenamiento seguro de credenciales por sistema operativo:**
  - **Android:** Android Keystore / EncryptedSharedPreferences.
  - **Windows:** Windows Credential Manager (DPAPI).
  - **macOS:** Apple Keychain.
  - **Linux:** Secret Service API (`libsecret` / GNOME Keyring / KWallet).
- **Respeto por los servidores de UNLaM:**
  - Peticiones secuenciales (o concurrencia máxima de 2) por ciclo de sincronización.
  - Backoff exponencial ante errores `5xx`, timeouts o caídas temporales de MIeL.
  - Detener reintentos automáticos inmediatamente si el login devuelve `estado: 1`, `2` (clave cambiada/incorrecta) o `3` (usuario bloqueado), avisando al usuario para evitar bloqueos de cuenta.

---

## 3. Elección Tecnológica para Escritorio + Android (Superando CORS)

Como MIeL **no envía cabeceras CORS** (`Access-Control-Allow-Origin` ausente) y bloquea iframes (`x-frame-options: SAMEORIGIN`), queda descartada una Web App / PWA pura en navegador. El cliente **debe ejecutar sus peticiones HTTP de forma nativa** fuera de las restricciones CORS de un browser.

> **Decisión adoptada:** **LibreMIeL está implementado en Flutter (Dart)** (en `app/`), manteniendo la tabla comparativa debajo como registro de la decisión arquitectónica.

| Opción | Plataformas | Ventajas | Consideraciones |
| :--- | :--- | :--- | :--- |
| **Flutter (Dart)** *(elegida)* | Windows, macOS, Linux, Android | Un solo codebase UI + lógica; cliente HTTP nativo (`dio` + `cookie_jar`); parser DOM (`html`); `workmanager` en Android y notificaciones/tray en Desktop. | Requiere escribir la lógica en Dart (adaptando las ideas de [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)). |
| **Tauri / Electron (Desktop) + React Native / Capacitor (Android)** | Windows, macOS, Linux, Android | Permite compartir un core en TypeScript/JavaScript (muy alineado con [ExtraerForosMiel](https://github.com/Tiago-Pujia/ExtraerForosMiel)). | En Android requiere capa nativa (`WorkManager` en Kotlin) para notificaciones fiables con la app cerrada y mantener 2 shells UI/build. |
| **Kotlin Multiplatform (KMP) + Compose Multiplatform** | Windows, macOS, Linux, Android | Excelente integración nativa en Android (`WorkManager`, Keystore), Ktor HTTP nativo y UI compartida con Compose. | Comunidad open source algo más chica en escritorio comparado con Flutter o JS/TS. |

---

## 4. Limitaciones Realistas en Segundo Plano (Android vs. Escritorio)

- **Escritorio (Windows, macOS, Linux):** La aplicación puede quedar minimizada en la bandeja del sistema (*system tray*) ejecutando el Ciclo 1 cada 5–15 minutos con notificaciones nativas inmediatas del sistema operativo.
- **Android:** Debido a *Doze Mode* y las políticas de ahorro de batería de Android, el mecanismo estándar y eficiente (`WorkManager`) garantiza un intervalo mínimo de **15 minutos** (suficiente para avisos académicos sin drenar la batería). Si en el futuro alguien deseara alertas al segundo, podría existir un modo opcional de *Foreground Service* o un demonio *self-hosted* (corriendo en la PC/servidor del propio usuario) que envíe notificaciones push vía `ntfy` o similar.

---

## 5. Estrategia de Mantenibilidad y Guía de Implementación para IAs

Dado que la plataforma renderiza HTML server-side sin una API REST pública oficial, la implementación de **LibreMIeL** sigue esta separación de capas:

1. **Capa de red desacoplada (`MielApiClient` y `MielInteractiveReader`):** Manejo centralizado de `PHPSESSID` + `SESSID`, reseteo limpio de `CookieJar` en cada login, redirecciones, re-login transparente ante sesión vencida y control de tasa/backoff. El polling de fondo (`SyncEngine`) solo consume `MielApiClient`, mientras que la lectura interactiva y descargas autenticadas de archivos/avatares pasan por `MielInteractiveReader`.
2. **Capa de *Adapters / Parsers* (`MielParsers`):** Un módulo independiente por sección (`interno`, `contenidos`, `portafolio`, `mensajeria`, `forov2`, `evaluacion`, `encuestas`, `autoguia`), desacoplado de la interfaz y validado con pruebas unitarias sobre *fixtures* HTML anonimizados.
3. **Capa de estado local, diff y aislamiento multi-cuenta (`SyncEngine` / `AppDatabase`):** Persistencia local SQLite (`Drift`) de snapshots por comisión, historial de notificaciones, configuración por materia, poda de comisiones inactivas (`pruneSubjectsNotIn`) y limpieza automática por cuenta (`clearAccountData` + `sessionGenerationProvider`) cuando cambia el usuario autenticado.
4. **Detección defensiva de cambios en MIeL:** Si un parser espera estructuras conocidas (ej. `.materia-bloque` o `table.w3-table`) y recibe un HTML distinto tras una actualización de MIeL (`2025.2.0` → futuras versiones), emitir una alerta controlada de *"formato de MIeL modificado"* en lugar de corromper snapshots o disparar falsas notificaciones masivas.
