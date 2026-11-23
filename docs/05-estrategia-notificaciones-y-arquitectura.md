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

## 4. Segundo Plano, Optimización de Batería y Notificaciones (Android vs. Escritorio)

### Escritorio (Windows, macOS, Linux)
- La aplicación puede quedar minimizada en la bandeja del sistema (*system tray*) ejecutando el Ciclo 1 cada 5–15 minutos con notificaciones nativas inmediatas del sistema operativo.
- Soporta inicio automático al encender el sistema (*Autostart*) mediante XDG en Linux, el Registro en Windows (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`) y LaunchAgents en macOS.

### Android (`WorkManager`, Doze Mode y Políticas de Ahorro Agresivo)
- Debido a **Doze Mode** y las políticas de ahorro de batería de Android, el mecanismo estándar y eficiente es **`WorkManager`**, que impone un intervalo mínimo periódico de **15 minutos** (suficiente para avisos académicos sin drenar la batería).
- **Problema de suspensión profunda (*Deep Sleep*) en capas OEM (Samsung One UI, Xiaomi HyperOS/MIUI, Motorola, etc.):**
  Los fabricantes implementan administradores de energía sumamente agresivos que suspenden por completo los procesos de fondo y retrasan o descartan los workers periódicos de las apps si están en modo "Optimizado" o "Restringido".
- **Configuración obligatoria para el usuario en Android:**
  Para garantizar que las notificaciones lleguen de forma puntual con la pantalla apagada o la app cerrada, el usuario debe deshabilitar la optimización restrictiva de batería:
  * **Samsung (One UI):**
    > **Ajustes > Aplicaciones > LibreMIeL > Batería > Seleccionar "Sin restricciones"** (*Unrestricted*).
  * **Xiaomi / Redmi / POCO (MIUI / HyperOS):**
    > **Ajustes > Aplicaciones > Administrar aplicaciones > LibreMIeL > Ahorro de batería > Seleccionar "Sin restricciones"**, y habilitar **"Inicio automático"**.
  * **Android Stock / Google Pixel / Motorola:**
    > **Ajustes > Aplicaciones > LibreMIeL > Batería de la aplicación > Seleccionar "Sin restricciones"**.
- **Permisos y mitigaciones en la aplicación:**
  - `WAKE_LOCK`: Garantiza que durante el sondeo HTTP de fondo la CPU no se suspenda a mitad de la respuesta de MIeL.
  - `POST_NOTIFICATIONS`: Solicitado explícitamente en Android 13+ (API 33+) únicamente desde primer plano (`requestPermissions: true`); el worker headless de `WorkManager` inicializa con `requestPermissions: false` para no requerir `Activity`.
  - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Integrado con el `MethodChannel` nativo (`MainActivity.kt`) y la pantalla de **Ajustes**, que muestra el estado real (`Sin restricciones` vs `Optimización activa`) y abre el diálogo/ajustes del sistema con fallbacks por OEM.
  - `RECEIVE_BOOT_COMPLETED`: Reprograma las tareas periódicas tras reiniciar el teléfono.
  - **Programación sin reinicio del temporizador:** `WorkManager` se inicializa una única vez (`AndroidBackgroundWorker.ensureInitialized()`) y usa `ExistingPeriodicWorkPolicy.keep` en cada arranque (reservando `ExistingPeriodicWorkPolicy.update` únicamente cuando el usuario cambia el intervalo en Ajustes).
  - **SQLite concurrente y recuperación en segundo plano:** `AppDatabase` opera con `PRAGMA journal_mode = WAL`, `PRAGMA busy_timeout = 5000` y `shareAcrossIsolates: true`, refrescando streams en `HomeShell` al volver a primer plano (`AppLifecycleState.resumed`). Además, el worker persiste caídas de MIeL (`miel_outage_detected_at`) para emitir el aviso de recuperación incluso con la app cerrada.

### Estética, Canales y Navegación Profunda de Notificaciones
- **Estética enriquecida:**
  - **Ícono de barra de estado:** VectorDrawable monocromático blanco (`drawable/ic_stat_libremiel.xml`, protegido con `raw/keep.xml`), evitando círculos sólidos al renderizar en Android.
  - **Título:** Remitente en negrita (`ROGER, MATIAS ALEJANDRO (Docente)` o `Corrección • ...`) siguiendo la convención de apps de chat modernas.
  - **Cuerpo (`BigTextStyleInformation`):** Asunto del mensaje o detalle de la novedad con soporte expandible y emoji de adjunto (`📎`).
  - **SubText / Encabezado:** Nombre de la comisión o materia académica (*Fundamentos de Sistemas Embebidos*), evitando saturar el título.
  - **Acento institucional:** Color verde esmeralda `#009674` (`_mielEmerald`) para iconos, badges y LEDs de notificación (`ledOnMs: 1000`, `ledOffMs: 500`).
  - **Canales separados:** `libremiel_updates` (*Novedades de MIeL*, importancia alta) para actividad académica y `libremiel_system` (*Sistema y actualizaciones*, importancia normal) para nuevas versiones y recuperación de MIeL.
  - **Categorización, IDs deterministas y agrupación:** `AndroidNotificationCategory.message`, `social` y `event`, IDs deterministas FNV-1a de 31 bits entre isolates, y `groupKey` por comisión con notificación resumen silenciosa (`setAsGroupSummary: true`, `InboxStyleInformation`) cuando llegan 2 o más novedades de una misma materia.
- **Navegación nativa al pulsar la notificación:**
  - Al pulsar la notificación, **LibreMIeL no redirige al navegador web externo**.
  - A través de `NotificationTapPayload` y el stream `NotificationService.onNotificationTapped` (o `getLaunchDetails()` si la app estaba cerrada, con fallback directo a SQLite si `subjectsStreamProvider` aún está cargando), LibreMIeL abre internamente la comisión, la herramienta específica (`mensajeria`, `contenidos`, `portafolio`, `foro` —incluyendo el `idTema` si viene en la URL— o `evaluacion`), o el panel de Novedades si la comisión no se encuentra.

### App Widgets nativos en Android *(Fase 10 — ✅ Completado)*
- Sobre la infraestructura de `WorkManager` (`runAndroidBackgroundSyncTask`), `SyncEngine.runCycle1` y navegación profunda de `HomeShell`, se implementaron **App Widgets** nativos (`AppWidgetProvider` + `RemoteViews` XML adaptativos):
  - Formato compacto `2×2` / `4×1` (`MielCompactWidgetProvider`) y feed/materias `4×2` (`MielFeedWidgetProvider`).
  - Puente nativo local `libremiel_android_widget` (`FlutterPlugin` + `MethodChannel`) para ambos engines (`MainActivity` y `WorkManager`).
  - Botón de refresco manual con `OneTimeWorkRequest` (`libremiel_widget_refresh`), deep-linking directo con `NotificationTapPayload` y marcado automático de lectura.
  - Vaciado síncrono obligatorio de `SharedPreferences` al cerrar sesión o cambiar de cuenta (**Invariante #11**). Ver [`ROADMAP.md`](ROADMAP.md#fase-10--app-widget-en-pantalla-de-inicio-android-estado--completado).


---

## 5. Estrategia de Mantenibilidad y Guía de Implementación para IAs

Dado que la plataforma renderiza HTML server-side sin una API REST pública oficial, la implementación de **LibreMIeL** sigue esta separación de capas:

1. **Capa de red desacoplada (`MielApiClient` y `MielInteractiveReader`):** Manejo centralizado de `PHPSESSID` + `SESSID`, reseteo limpio de `CookieJar` en cada login, redirecciones, re-login transparente ante sesión vencida y control de tasa/backoff. El polling de fondo (`SyncEngine`) solo consume `MielApiClient`, mientras que la lectura interactiva y descargas autenticadas de archivos/avatares pasan por `MielInteractiveReader`.
2. **Capa de *Adapters / Parsers* (`MielParsers`):** Un módulo independiente por sección (`interno`, `contenidos`, `portafolio`, `mensajeria`, `forov2`, `evaluacion`, `encuestas`, `autoguia`), desacoplado de la interfaz y validado con pruebas unitarias sobre *fixtures* HTML anonimizados.
3. **Capa de estado local, diff y aislamiento multi-cuenta (`SyncEngine` / `AppDatabase`):** Persistencia local SQLite (`Drift`) de snapshots por comisión, historial de notificaciones, configuración por materia, poda de comisiones inactivas (`pruneSubjectsNotIn`) y limpieza automática por cuenta (`clearAccountData` + `sessionGenerationProvider`) cuando cambia el usuario autenticado.
4. **Detección defensiva de cambios en MIeL:** Si un parser espera estructuras conocidas (ej. `.materia-bloque` o `table.w3-table`) y recibe un HTML distinto tras una actualización de MIeL (`2025.2.0` → futuras versiones), emitir una alerta controlada de *"formato de MIeL modificado"* en lugar de corromper snapshots o disparar falsas notificaciones masivas.
