# Flujo de Trabajo y Uso de Ramas Git — LibreMIEL

Esta guía explica de forma simple cómo organizar las ramas, los commits y los lanzamientos (*releases*) en **LibreMIEL** usando un modelo liviano basado en **GitHub Flow + tags semánticos**.

---

## 1. Ramas Principales y Temporales

| Rama / Prefijo | Propósito | ¿Se puede borrar después del merge? |
| :--- | :--- | :---: |
| `main` | Rama principal y **siempre estable**. Todo lo que entra acá debe compilar y pasar `flutter analyze` + `flutter test`. Desde `main` se crean los tags de Release (`v0.1.0`, `v0.2.0`, etc.). | No |
| `feat/<nombre>` | Desarrollo de una nueva funcionalidad (ej. `feat/lector-contenidos`, `feat/notificaciones-portafolio`). | Sí |
| `fix/<nombre>` | Corrección de un error o ajuste cuando MIEL cambia algún selector HTML (ej. `fix/parser-forov2-fechas`). | Sí |
| `docs/<nombre>` | Cambios únicamente en documentación (ej. `docs/actualizar-status`). | Sí |
| `refactor/<nombre>` | Mejoras internas de código sin cambiar el comportamiento externo. | Sí |
| `chore/<nombre>` | Mantenimiento, dependencias, CI/CD o empaquetado (ej. `chore/actualizar-nfpm`). | Sí |

> **¿Por qué no usamos una rama `develop` permanente?**  
> Para un proyecto open source ágil, mantener `main` siempre estable y trabajar cada cambio en una rama corta (`feat/...`, `fix/...`) evita conflictos largos de integración y facilita recibir Pull Requests de la comunidad.

---

## 2. Flujo Diario Paso a Paso

### 1) Actualizar `main` antes de empezar algo nuevo
```bash
git checkout main
# (Cuando tengas remoto en GitHub:)
# git pull origin main
```

### 2) Crear una rama nueva para tu tarea
```bash
git checkout -b feat/mi-nueva-funcion
```

### 3) Trabajar y hacer commits pequeños y claros (Conventional Commits)
```bash
git status
git add <archivos>
git commit -m "feat(parsers): soportar nuevos estados de entrega en portafolio"
```

Formato recomendado de commits: `<tipo>(<alcance opcional>): <descripción breve en imperativo>`
- `feat:` nueva característica
- `fix:` corrección de bug
- `docs:` documentación
- `test:` pruebas unitarias o fixtures anonimizados
- `refactor:` reorganización de código
- `chore:` dependencias, build, GitHub Actions, packaging

### 4) Verificar que todo pase antes de integrar a `main`
```bash
# Desde app/
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

### 5) Integrar la rama a `main`
- **En local (trabajando solo):**
  ```bash
  git checkout main
  git merge --no-ff feat/mi-nueva-funcion
  git branch -d feat/mi-nueva-funcion
  ```
- **En GitHub (con Pull Request):**
  1. Subí tu rama: `git push -u origin feat/mi-nueva-funcion`.
  2. Abrí un Pull Request hacia `main`.
  3. Esperá que el workflow `CI` (`.github/workflows/ci.yml`) pase en verde.
  4. Hacé **Squash and merge** (o **Merge pull request**) y borrá la rama temporal.

---

## 3. Cómo Publicar una Nueva Versión (Releases Automáticos)

El workflow `.github/workflows/release.yml` se dispara automáticamente cuando subís un **tag semántico** (`vMAJOR.MINOR.PATCH`) a GitHub:

1. Actualizá la versión en `app/pubspec.yaml` (ej. `version: 0.2.0+1`) y mové los cambios de `[Unreleased]` a `[0.2.0] - AAAA-MM-DD` en [`docs/CHANGELOG.md`](CHANGELOG.md).
2. Hacé commit en `main`:
   ```bash
   git add app/pubspec.yaml docs/CHANGELOG.md
   git commit -m "chore(release): preparar v0.2.0"
   ```
3. Creá el tag anotado:
   ```bash
   git tag -a v0.1.0 -m "Release v0.1.0 — MVP de notificaciones"
   ```
4. Cuando ya tengas el repositorio conectado a GitHub y quieras publicar:
   ```bash
   git push origin main
   git push origin v0.1.0
   ```
   GitHub Actions compilará y adjuntará automáticamente todos los instaladores y portables para **Windows, macOS, Linux y Android** en la sección **Releases**.

---

## 4. Reglas de Seguridad en Git

- **Nunca hagas `git add .` a ciegas:** revisá siempre `git status` y `git diff --staged` para asegurarte de no subir `.env`, capturas HTML sin anonimizar, archivos de firma (`.jks`, `.keystore`) ni `docs/IMPLEMENTATION_PLAN.md` (que está ignorado en `.gitignore`).
- Si te equivocaste en el último commit local (antes de hacer push), podés corregirlo con `git commit --amend`. Nunca reescribas historia que ya fue publicada en `main` en GitHub.
