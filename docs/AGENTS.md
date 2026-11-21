# AGENTS.md — Guía para Modelos de IA y Agentes de Código (LibreMIeL)

Este archivo concentra el contexto operativo, las invariantes técnicas y las reglas obligatorias para cualquier asistente o agente de IA que trabaje sobre el repositorio **LibreMIeL**.

---

## 1. Contexto del Proyecto

- **Nombre:** LibreMIeL
- **Propósito:** Cliente alternativo, gratuito, *local-first* y de código abierto (Licencia GPL-3.0) para la plataforma **MIeL (UNLaM)** (`https://miel.unlam.edu.ar/`).
- **Plataformas objetivo:** Windows, macOS, Linux (`AppImage`, `.deb`, `.rpm`, Arch `.pkg.tar.zst`, portable `.tar.gz`) y Android (`.apk`).
- **Identificador de aplicación:** `io.github.tiago_pujia.libremiel`
- **Stack:** Flutter (Dart), `dio` + `cookie_jar`, `html` (DOM parser), `drift` (SQLite), `flutter_riverpod`, `flutter_secure_storage`, `flutter_local_notifications`, `workmanager`, `tray_manager`, `window_manager`.
- **Evolución:** Las notificaciones (Contenidos, Portafolio, Mensajería y Foros) son el **primer hito**, pero toda la arquitectura debe mantenerse modular para incorporar progresivamente más funcionalidades.

---

## 2. Mapa de Lectura Obligatoria

Antes de editar código, revisá únicamente el documento que corresponde a tu tarea:

1. **Estado actual del proyecto:** [`STATUS.md`](STATUS.md)
2. **Próximas fases y roadmap técnico (Fases 3 a 7):** [`ROADMAP.md`](ROADMAP.md)
3. **Protocolo de login, sesión, cookies y CORS:** [`02-arquitectura-y-sesion-miel.md`](02-arquitectura-y-sesion-miel.md)
4. **Panel `/principal/interno/`, badges y módulos extra:** [`03-panel-principal-y-modulos.md`](03-panel-principal-y-modulos.md)
5. **Endpoints exactos, DOM y efectos colaterales (4 módulos clave):** [`04-modulos-clave-endpoints-y-dom.md`](04-modulos-clave-endpoints-y-dom.md)
6. **Estrategia de sincronización en 2 ciclos y arquitectura:** [`05-estrategia-notificaciones-y-arquitectura.md`](05-estrategia-notificaciones-y-arquitectura.md)
7. **Flujo de ramas Git y commits:** [`GIT_WORKFLOW.md`](GIT_WORKFLOW.md)
8. **Guía de contribución y anonimización de fixtures:** [`CONTRIBUTING.md`](CONTRIBUTING.md)

---

## 3. Invariantes Técnicas Críticas (No Romper Jamás)

1. **Efecto colateral de `Contenidos`:**
   - Un `GET /contenido/archivos/comision/{id}` **borra automáticamente** el badge en `/principal/interno/` y la clase `w3-pale-yellow` en el servidor.
   - **Regla:** Nunca consultar `Contenidos` si su badge en `/principal/interno/` es `0` (salvo apertura explícita del usuario).
2. **Efecto colateral de `Mensajería`:**
   - `GET /mensajeria/entrada/comision/{id}` es seguro (solo lectura).
   - `GET /mensajeria/verEntrada/...` **marca el mensaje como leído**.
   - **Regla:** El `SyncEngine` jamás debe llamar a `verEntrada`. Para detectar docentes, cruzar remitente contra la lista cacheada de `/principal/cursoDetalles/id/{id}`.
3. **Efecto colateral de `Foros` (`forov2`):**
   - `GET /forov2/temas/comision/{id}` es seguro (no borra badges).
   - `GET /forov2/mensajes/...` **marca el tema como leído** en el servidor.
   - **Regla:** Respetar siempre el modo elegido por el usuario (*No invasivo* vs *Respuestas de docentes*).
4. **Protección contra bloqueo de cuenta (`estado: 3`):**
   - Ante respuesta de login `estado: 1`, `2` o `3`, **detener inmediatamente** el polling automático y notificar al usuario; jamás reintentar en bucle.
5. **Sin CORS / Sin WebSockets / Sin servidor central:**
   - Todas las peticiones deben salir del cliente HTTP nativo del dispositivo (`MielClient`), nunca desde un navegador externo ni a través de un backend intermedio.
6. **Parsers 100% puros y desacoplados:**
   - Todo código en `app/lib/core/parsers/` debe ser puro (`String html -> Modelo`), sin dependencia de `Dio`, Flutter UI ni SQLite, y acompañado de tests en `app/test/parsers/` usando HTML anonimizado en `app/test/fixtures/`.
7. **Seguridad y privacidad:**
   - Nunca commitear `.env`, DNIs, contraseñas, `PHPSESSID`, datos personales reales ni archivos de firma (`.jks`, `.keystore`, `key.properties`).
   - No copiar CSS, JS, imágenes ni logotipos de MIeL/UNLaM.
   - Mantener la raíz del repositorio limpia: el proyecto Flutter completo vive en `app/` y toda la documentación/gestión en `docs/`, dejando únicamente `README.md` y `LICENSE` en la raíz.
8. **Separación entre polling (`MielApiClient`) y lectura interactiva (`MielInteractiveReader`):**
   - `SyncEngine` únicamente depende de `MielApiClient` (solo lectura segura). Toda lectura iniciada explícitamente por el usuario (abrir mensajes `verEntrada`, descargar archivos/imágenes autenticadas o explorar subsecciones de Fase 2) debe pasar por `MielInteractiveReader`.
9. **Aislamiento multi-cuenta:**
   - Al iniciar sesión con un usuario distinto al registrado en `account_username`, ejecutar siempre `clearAccountData()` antes de sincronizar, limpiar cookies (`CookieJar`) antes del login, incrementar `sessionGenerationProvider` (invalidando caché en memoria de avatares/imágenes) y cancelar cualquier sincronización en curso (`isCancelled`).
   - En Ciclo 1, podar con `pruneSubjectsNotIn()` toda comisión local que ya no aparezca en `/principal/interno/`.

---

## 4. Comandos de Verificación antes de Cerrar una Tarea

```bash
# Desde app/: formato, análisis estático y pruebas unitarias Flutter/Dart
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# Desde la raíz del repo: pruebas del anonimizador de HTML
python3 -m unittest discover -s scripts -v
```

> **Importante sobre publicación:** Nunca ejecutar `git push` ni agregar remotos sin autorización explícita del mantenedor.
