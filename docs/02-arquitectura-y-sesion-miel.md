# 02 — Arquitectura Interna, Autenticación y Sesión de MIeL

> Relevamiento realizado sobre `https://miel.unlam.edu.ar/` — versión observada en assets/footer: **`2025.2.0`**.

---

## 1. Stack Tecnológico Observado

- **Servidor Web:** `Apache/2.4.68 (Debian)` detrás de balanceo de nodos (evidenciado por cookie de afinidad `SESSID=nodo3`).
- **Backend:** PHP tradicional con **renderizado HTML server-side** en la mayoría de las vistas y endpoints AJAX puntuales (algunos devuelven JSON incluso con cabecera `Content-Type: text/html; charset=utf-8`).
- **Frontend:** `W3.CSS`, `jQuery 1.12.4`, `jquery-validation`, `magnific-popup`, `tippy.js`, `TinyMCE` (en foros/formularios), `contrastify.js`, `datepicker.js`, `Sortable.min.js` y `gtag.js`.
- **Comunicación en tiempo real:**
  - **WebSockets (`ws://` / `wss://`):** **Ausentes** en toda la plataforma (incluso el módulo de Chat usa polling HTTP).
  - **Server-Sent Events (`EventSource`):** **Ausentes.**
  - Toda actualización dinámica en la web se realiza mediante `setInterval` + peticiones AJAX (`jQuery $.ajax`).

---

## 2. Flujo de Autenticación (Login)

### Pantalla inicial
- **URL:** `GET https://miel.unlam.edu.ar/principal/home/`
- **CAPTCHA / Anti-bot:** **Ausente.** No hay reCAPTCHA, hCaptcha, Cloudflare Turnstile ni desafíos JS.
- **Tokens CSRF:** **Ausentes.** El formulario `#formLogin` no incluye tokens ocultos ni cabeceras personalizadas anti-CSRF.
- **Cookies emitidas en la carga inicial (`GET /principal/home/`):**
  - `PHPSESSID=<id>; path=/`
  - `SESSID=<nodo>; path=/` (ej. `nodo3`, afinidad de nodo del balanceador)
  - *Flags observados:* En el flujo estándar sin `recordar`, las cookies no presentan `HttpOnly`, `Secure`, `SameSite` ni `Expires`/`Max-Age` (son cookies de sesión).

### Petición de Login
- **Endpoint:** `POST https://miel.unlam.edu.ar/principal/event/login/`
- **Content-Type:** `application/x-www-form-urlencoded; charset=UTF-8`
- **Campos del payload:**
  - `usuario`: DNI / identificador de usuario.
  - `clave`: Contraseña del usuario.
  - `recordar`: Checkbox opcional (*"Mantener mi sesión activa"*).
- **Comportamiento de cookies:** Al hacer `POST /principal/event/login/` **no** se rota ni reemite `Set-Cookie`; el servidor asocia el estado autenticado al mismo `PHPSESSID` obtenido previamente (o el que se establezca en la primera respuesta). Es buena práctica hacer primero un `GET /principal/home/` o persistir todas las cookies recibidas (`PHPSESSID` + `SESSID`).
- **Respuesta JSON** *(puede llegar con header `Content-Type: text/html; charset=utf-8`, por lo que conviene parsear siempre el cuerpo como JSON)*:
  - `{ "estado": 0 }` → Login exitoso (la web redirige a `/principal/interno/`).
  - `{ "estado": 1 }` o `{ "estado": 2 }` → Credenciales inválidas.
  - `{ "estado": 3 }` → Usuario bloqueado.

---

## 3. Verificación y Mantenimiento de Sesión

Todas las páginas internas incluyen en su `<head>` dos utilidades globales que el cliente alternativo puede aprovechar:

| Endpoint | Método | Respuesta / Propósito |
| :--- | :--- | :--- |
| `https://miel.unlam.edu.ar/principal/event/isLogged/` | `GET` | Devuelve `"1"` si la sesión PHP sigue activa; de lo contrario, el cliente debe re-autenticarse. |
| `https://miel.unlam.edu.ar/principal/event/recargarSesion/` | `GET` | Renueva el timestamp de última actividad en el servidor para mantener viva la sesión. |

**Recomendación para el cliente:** Antes de un ciclo de sincronización, comprobar `/principal/event/isLogged/` (o detectar redirecciones al login `/principal/home/`) y re-autenticar de forma transparente usando las credenciales almacenadas en el gestor seguro del sistema operativo.

---

## 4. Cabeceras HTTP, CORS y Restricciones de Embebido

- **CORS (`Access-Control-Allow-Origin`):** **Ausente.** MIeL opera bajo política *same-origin* estricta.
  - *Consecuencia arquitectónica:* Una SPA o PWA alojada en un dominio externo **no puede comunicarse directamente** con `miel.unlam.edu.ar` desde el navegador del usuario porque el navegador bloqueará las peticiones por CORS.
  - En cambio, un cliente con motor HTTP nativo fuera de un navegador web (aplicación de escritorio o app móvil nativa/multiplataforma) **no está sujeto a CORS** y gestiona las cookies directamente.
- **Embebido en iframes:** `x-frame-options: SAMEORIGIN` (no se puede incrustar MIeL en un `<iframe>` desde otro origen).
- **Caché:** `cache-control: no-store, no-cache, must-revalidate` en rutas PHP dinámicas.
- **CSP (`Content-Security-Policy`):** No se observó cabecera CSP activa.

---

## 5. Estado Real del Sistema Web Push Nativo de MIeL

Durante la inspección se descubrió que MIeL posee infraestructura parcial de Web Push registrada en el frontend, pero con limitaciones que explican por qué no resuelve el problema actual de los estudiantes:

- Registra `https://miel.unlam.edu.ar/sw.js?2025.2.0` (Service Worker con listeners `push` y `notificationclick`) y carga `https://miel.unlam.edu.ar/vista/script/push-notifications.js?2025.2.0` con una clave VAPID (`pushKey`) y endpoints:
  - `POST /principal/event/guardarSuscripcionPush/`
  - `POST /principal/event/eliminarSuscripcionPush/`
  - `POST /principal/event/actualizarSuscripcionPush/`
- **Limitaciones críticas verificadas:**
  1. Los botones de activación (`#btnHabilitarNotificaciones` / `#btnDeshabilitarNotificaciones`) y el enlace lateral hacia `/perfil/notificaciones/` **no están visibles/habilitados** en la interfaz estándar (`/perfil/datos/` solo muestra *Datos personales*, *Seguridad* y *Firmas personalizadas*; tampoco hay toggles de notificaciones por email).
  2. Incluso accediendo directamente a `https://miel.unlam.edu.ar/perfil/notificaciones/` (`POST /perfil/event/guardarSuscripciones/`), el formulario solo ofrece **2 tipos de notificación**:
     - `value="1"`: *Mensajes recibidos por Mensajería*
     - `value="2"`: *Respuestas recibidas a mensajes propios en Foros*
  3. **No existe ningún soporte nativo de push para `Contenidos` ni para `Portafolio`**, ni para nuevos temas/mensajes generales en Foros, ni para Evaluaciones.

---

## 6. Consideraciones del Aviso Legal (`/principal/legal/`)

Del aviso legal publicado en `https://miel.unlam.edu.ar/principal/legal/` (última actualización observada: 18/05/2024):

- El nombre, diseño visual y código de MIeL son propiedad / marca registrada de la **UNLaM**, prohibiéndose su reproducción, redistribución o explotación comercial.
- Las interacciones entre usuarios (foros, mensajería, etc.) se depuran al finalizar cada cuatrimestre (materias cuatrimestrales) o al finalizar el año (materias anuales).

**Buenas prácticas para este proyecto open source:**
1. Desarrollar una **interfaz, íconos, estilos y branding 100% propios**, sin copiar ni redistribuir CSS, JS, imágenes o logotipos de MIeL/UNLaM.
2. Dejar explícito en el proyecto que es una **herramienta independiente y no oficial**, gratuita y sin fines comerciales.
3. Implementar consultas conservadoras (respetuosas con la infraestructura de la universidad) y no almacenar datos de terceros en servidores centrales.
