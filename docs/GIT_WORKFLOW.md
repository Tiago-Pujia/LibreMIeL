# Flujo de Trabajo, Ramas (`DEV` / `main`) y Verificación Pre-Producción — LibreMIeL

Esta guía explica cómo organizar el trabajo diario entre la rama de desarrollo (**`DEV`**) y la rama de producción (**`main`**), y cómo comprobar con certeza absoluta que una versión compila sin errores en los 4 sistemas operativos (**Linux, Windows, Android y macOS**) **antes** de publicar un Release oficial.

---

## 1. Estructura de Ramas

| Rama / Prefijo | Propósito | ¿Se puede borrar? |
| :--- | :--- | :---: |
| **`main`** | **Producción (siempre estable).** Solo recibe código ya probado y verificado desde `DEV`. Desde `main` se crean los tags oficiales de Release (`v0.1.0`, `v0.2.0`, etc.). | No |
| **`DEV`** | **Desarrollo activo.** Rama principal de trabajo diario donde se desarrollan, integran y prueban nuevas funciones, mejoras de interfaz y correcciones sin afectar producción. | No |
| `feat/<nombre>` | *(Opcional)* Rama temporal para desarrollar una función grande aislada antes de integrarla a `DEV`. | Sí |
| `fix/<nombre>` | *(Opcional)* Rama temporal para corregir un bug puntual o cambio de HTML en MIeL. | Sí |

---

## 2. Trabajo Diario en la Rama `DEV`

Todo cambio nuevo se realiza sobre **`DEV`** (nunca directamente sobre `main`):

```bash
# 1. Asegurate de estar parado en la rama DEV
git checkout DEV
git pull origin DEV

# 2. Hacé tus cambios y confirmalos con Conventional Commits
git status
git add <archivos>
git commit -m "feat(foros): agregar filtro por docente"

# 3. Subí tus avances a DEV en GitHub (dispara automáticamente el CI de tests y formato)
git push origin DEV
```

Prefijos recomendados para los mensajes de commit:
- `feat:` nueva funcionalidad
- `fix:` corrección de error
- `style:` / `refactor:` ajustes visuales o de estructura interna
- `docs:` cambios en documentación
- `test:` pruebas automatizadas
- `ci:` / `chore:` pipelines de GitHub Actions, dependencias o empaquetado

---

## 3. Cómo Saber que Todo Está Correcto Antes de Compilar en Producción

Antes de pasar cambios de `DEV` a `main` y lanzar un tag de producción, ejecutá este protocolo de **2 pasos** para garantizar **cero errores**:

### Paso 1: Verificación local rápida en tu Kubuntu (~15 segundos)

Ejecutá exactamente los mismos comandos que exige el servidor de integración continua (CI):

```bash
cd /home/tiago/Proyectos/LibreMIEL/app
export PATH="$HOME/development/flutter/bin:$PATH"

# 1. Formatear el código Dart y verificar que cumpla el estándar del CI
dart format lib test
dart format --output=none --set-exit-if-changed lib test

# 2. Análisis estático (0 warnings, 0 imports sin usar, 0 errores de tipos)
flutter analyze

# 3. Ejecutar la suite completa de tests automatizados de Flutter
flutter test

# 4. Ejecutar los tests de los scripts de Python (anonimizador HTML)
cd /home/tiago/Proyectos/LibreMIEL
python3 -m unittest discover -s scripts -v

# 5. (Opcional) Probar compilación nativa de release en Linux
cd /home/tiago/Proyectos/LibreMIEL/app
flutter build linux --release
```

Si los puntos 1 al 4 terminan sin errores, el código Dart/Flutter y los tests están 100% válidos.

---

### Paso 2: Simulacro real en los 4 Sistemas Operativos SIN publicar Release (`workflow_dispatch`)

Como desde Linux no se compilan localmente instaladores `.exe` de Windows ni `.dmg` de macOS, el workflow [`.github/workflows/release.yml`](../.github/workflows/release.yml) cuenta con una salvaguarda:
- El último job (**`Publicar GitHub Release`**) solo se ejecuta cuando el evento es un tag `v*` (`if: startsWith(github.ref, 'refs/tags/v')`).
- Si lo disparás manualmente sobre la rama **`DEV`**, GitHub Actions **compila los 18 paquetes reales en Linux (`x64`/`arm64`), Windows (`x64`), Android (`arm64-v8a`/`armeabi-v7a`/`x86_64`/`universal`) y macOS (`Universal`)**, pero **NO crea ni publica ningún Release público**.

Corré el simulacro desde tu terminal con un solo comando:

```bash
# 1. Disparar el simulacro multiplataforma sobre la rama DEV
gh workflow run release.yml --ref DEV -f version=0.2.0-test

# 2. Monitorear en vivo en la terminal hasta que todos los sistemas den tilde verde (✓)
gh run watch
```

- Si hubiera cualquier problema en Gradle (Android), Inno Setup (Windows), Xcode (macOS) o nFPM/AppImage (Linux), lo vas a ver ahí mismo en `DEV` sin haber tocado `main` ni publicado una versión rota.
- Además, podés descargar los artefactos compilados de prueba desde la página del workflow en GitHub Actions para probarlos antes de liberar la versión.

---

## 4. Pase a Producción y Publicación de Release Oficial (`DEV` $\rightarrow$ `main`)

Una vez que el **Paso 1** y el **Paso 2** terminaron en verde (`✓`):

1. En `DEV`, actualizá el número de versión en [`app/pubspec.yaml`](../app/pubspec.yaml) (ej. `version: 0.2.0+2`) y documentá las novedades en [`docs/CHANGELOG.md`](CHANGELOG.md):
   ```bash
   git checkout DEV
   git add app/pubspec.yaml docs/CHANGELOG.md
   git commit -m "chore(release): preparar v0.2.0"
   git push origin DEV
   ```
2. Pasá los cambios validados de `DEV` a `main`:
   ```bash
   git checkout main
   git pull origin main
   git merge --no-ff DEV -m "Merge branch 'DEV' into main (Release v0.2.0)"
   git push origin main
   ```
3. Creá y subí el tag de la versión para que GitHub Actions publique el Release oficial con todos los instaladores y `SHA256SUMS.txt`:
   ```bash
   git tag -a v0.2.0 -m "Release v0.2.0"
   git push origin v0.2.0
   ```
4. Volvé a pararte en `DEV` para seguir trabajando tranquilo:
   ```bash
   git checkout DEV
   ```

> **Compatibilidad con la web de descargas y el futuro actualizador in-app (Fase 8):** mantené siempre alineado el tag `vX.Y.Z` con `version: X.Y.Z+N` en `app/pubspec.yaml`, sin cambiar los sufijos de artefactos ni omitir `SHA256SUMS.txt` ni la firma Android (`release.keystore`), ya que tanto [`packaging/web/`](../packaging/web) como el actualizador multiplataforma dependen de esa convención.

---

## 5. Reglas de Seguridad en Git

- **Nunca hagas `git add .` a ciegas:** revisá siempre `git status` y `git diff` para asegurarte de no subir archivos `.env`, credenciales, capturas HTML sin anonimizar ni llaves de firma (`.jks`, `.keystore`, `key.properties`).
- **Trabajá siempre en `DEV`:** verificá con `git branch` que estés en `DEV` antes de empezar a programar.

