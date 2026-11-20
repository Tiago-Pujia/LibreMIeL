# Guía de Contribución — LibreMIEL

¡Gracias por tu interés en mejorar **LibreMIEL**!  
Este proyecto es gratuito, independiente y de código abierto bajo licencia [MIT](../LICENSE). Toda ayuda es bienvenida: desde reportar si MIEL cambió alguna pantalla hasta sumar nuevas funciones o corregir errores.

---

## 1. Antes de empezar (Humanos y Agentes de IA)

Si vas a modificar parsers, lógica de red o sincronización, **lee primero la documentación técnica en [`docs/README.md`](README.md)** y la guía de reglas en [`AGENTS.md`](AGENTS.md).

### Reglas inviolables del proyecto
1. **Privacidad primero (*local-first*):** Nunca envíes credenciales, DNIs, cookies (`PHPSESSID`, `SESSID`) ni datos de estudiantes a servidores de terceros.
2. **No romper el estado de lectura en MIEL web:**
   - No hagas polling ciego a `/contenido/archivos/comision/{id}` (el `GET` borra el badge de novedades y la marca amarilla en el servidor).
   - No abras `/mensajeria/verEntrada/...` durante la sincronización en segundo plano (marca el mensaje como leído).
   - En foros, consultá primero `/forov2/temas/comision/{id}` y respetá el modo configurado por el usuario.
3. **Respeto a los servidores de la UNLaM:** Usá peticiones secuenciales o concurrencia mínima, respetá los intervalos prudentes y frená reintentos automáticos si el login devuelve `estado` distinto de `0`.
4. **Propiedad intelectual:** No copies ni redistribuyas hojas de estilo, scripts, imágenes ni logotipos propietarios de MIEL/UNLaM.
5. **Cero datos personales en el repositorio:** Nunca subas archivos `.env`, capturas HTML sin anonimizar, capturas de pantalla con DNIs/nombres reales ni archivos de firma (`.jks`, `.keystore`, `key.properties`).

---

## 2. Cómo reportar si MIEL cambió una pantalla (Anonimizar HTML)

Como MIEL renderiza HTML del lado del servidor, una actualización de la plataforma puede cambiar clases CSS o tablas y romper un parser.  
Si encontrás un error de lectura en alguna materia, **podés ayudarnos enviando el HTML anonimizado** de esa pantalla para que actualicemos el parser y agreguemos un test.

### Paso a paso seguro

1. Abrí la página con el problema en tu navegador (por ejemplo, `Contenidos`, `Portafolio`, `Mensajería` o `Foro`).
2. Guardá la página como **Página web, solo HTML** (`Ctrl + S` → *"Página web, solo HTML"*).
3. Ejecutá el script anonimizador incluido en este repositorio (requiere solo **Python 3**, sin dependencias externas):

   ```bash
   python3 scripts/anonymize_html.py ruta/a/pagina_guardada.html -o fixture_anonimizado.html
   ```

   También podés verificar un archivo ya anonimizado o pasarle tus propios nombres/DNIs adicionales a ocultar:

   ```bash
   python3 scripts/anonymize_html.py entrada.html -o salida.html --extra "MI APELLIDO" "MI NOMBRE"
   ```

4. **Revisá manualmente `fixture_anonimizado.html`** con un editor de texto antes de compartirlo en un Issue o Pull Request:
   - Confirmá que no aparezca tu DNI, tu nombre, nombres de compañeros/docentes, correos electrónicos, teléfonos ni el contenido privado de mensajes o entregas.
   - El script conserva todas las etiquetas HTML, clases CSS y atributos `data-*` que necesitan los parsers.

---

## 3. Preparar el entorno de desarrollo (Flutter)

### Requisitos generales
- **Flutter SDK** (canal `stable`).  
  > En Linux se recomienda instalar Flutter desde el **tarball oficial** (y no desde Snap) para evitar problemas de enlace con `libsecret`.
- **Git** y **Python 3** (para scripts auxiliares).

### Dependencias nativas por plataforma

- **Linux (Debian / Ubuntu):**
  ```bash
  sudo apt-get update
  sudo apt-get install -y clang cmake ninja-build pkg-config \
    libgtk-3-dev libsecret-1-dev libjsoncpp-dev libayatana-appindicator3-dev libsqlite3-dev
  ```
- **Linux (Fedora / Red Hat):**
  ```bash
  sudo dnf install -y clang cmake ninja-build pkgconf-pkg-config \
    gtk3-devel libsecret-devel jsoncpp-devel libayatana-appindicator-gtk3-devel sqlite-devel
  ```
- **Linux (Arch Linux):**
  ```bash
  sudo pacman -S --needed clang cmake ninja pkgconf gtk3 libsecret jsoncpp libayatana-appindicator sqlite
  ```
- **Windows:** Visual Studio (carga *"Desarrollo para el escritorio con C++"*).
- **macOS:** Xcode + CocoaPods.
- **Android:** Android SDK (`cmdline-tools` / Android Studio) + OpenJDK 17.

### Comandos básicos del proyecto

```bash
# 1. Instalar dependencias Dart/Flutter
flutter pub get

# 2. Generar código de base de datos local (Drift) si modificaste tablas
dart run build_runner build --delete-conflicting-outputs

# 3. Verificar formato y análisis estático
dart format --output=none --set-exit-if-changed lib test
flutter analyze

# 4. Ejecutar pruebas unitarias
flutter test

# 5. Probar el script anonimizador
python3 -m unittest scripts/test_anonymize_html.py

# 6. Ejecutar en escritorio Linux limitando trabajos paralelos de C++ (recomendado en equipos <= 16 GB RAM)
CMAKE_BUILD_PARALLEL_LEVEL=4 flutter run -d linux
```

---

## 4. Arquitectura del Código

El proyecto está organizado en capas independientes para facilitar contribuciones:

- `lib/core/network/`: Cliente HTTP (`MielClient`), manejo de cookies (`PHPSESSID` + `SESSID`), sesión y reintentos.
- `lib/core/parsers/`: Funciones **puras** (`String html -> Modelo`) separadas por módulo de MIEL. Siempre deben incluir tests en `test/parsers/` con fixtures anonimizados en `test/fixtures/`.
- `lib/core/storage/`: Base de datos SQLite local (`Drift`) para snapshots, historial de notificaciones y preferencias.
- `lib/core/sync/`: Motor de sincronización en dos ciclos (`SyncEngine`).
- `lib/platform/`: Integraciones nativas (almacén seguro de credenciales, notificaciones locales, bandeja de escritorio, worker de Android).
- `lib/features/`: Pantallas de la interfaz (Login, Feed de novedades, Materias, Ajustes y futuras vistas).
- `packaging/` y `.github/workflows/`: Empaquetado para Windows, macOS, Linux (AppImage, `.deb`, `.rpm`, Arch `.pkg.tar.zst` + `PKGBUILD`, portable `.tar.gz`) y Android (`.apk`).

---

## 5. Flujo de Pull Requests y Commits

1. Creá una rama desde `main`:
   ```bash
   git checkout -b feat/mi-mejora
   ```
2. Usá mensajes de commit claros siguiendo **Conventional Commits**:
   - `feat:` nueva funcionalidad
   - `fix:` corrección de error
   - `docs:` cambios en documentación
   - `test:` nuevos tests o fixtures anonimizados
   - `refactor:` reestructuración sin cambio de comportamiento
   - `chore:` tareas de mantenimiento, CI o empaquetado
3. Verificá que `dart format`, `flutter analyze` y `flutter test` pasen sin errores antes de abrir el Pull Request.
