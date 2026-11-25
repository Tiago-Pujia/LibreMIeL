# LibreMIeL — Brand Identity & Design Assets

Repositorio central de identidad visual, sistema cromático y recursos gráficos normalizados de **LibreMIeL (Cliente libre para MIeL UNLaM)**.
Diseñado para consulta rápida tanto por desarrolladores como por agentes de IA.

---

## Directory Structure

```text
branding/
├── README.md                                <- Índice general de identidad de marca
├── foto_ds.png                              <- Copia del archivo original maestro del emblema
├── color-palette/
│   └── COLOR-PALETTE.md                     <- Especificación cromática AI-Ready, tokens Flutter, XML y CSS
├── icons/
│   ├── README.md                            <- Guía de implementación y catálogo de isotipos por tamaño
│   └── png/                                 <- Mapas de bits renderizados por resolución (cuadrada y circular)
│       ├── master-512x512.png
│       ├── 512x512/
│       ├── 256x256/
│       ├── 128x128/
│       ├── 64x64/
│       ├── 48x48/
│       └── 32x32/
└── scripts/
    └── generate-brand-icons.py              <- Generador reproducible de iconos y drawables Android
```

---

## 1. Master Color Palette

Los colores oficiales de **LibreMIeL** responden a la identidad de la UNLaM y a las alertas funcionales de la plataforma MIeL:

| Prioridad | Nombre | Rol en el sistema | HEX | RGB | HSL | Token Flutter | Token Android | Uso principal |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **01 · Principal** | **Verde Esmeralda UNLaM** | Identidad institucional | `#009674` | `0, 150, 116` | `166° / 100% / 29%` | `palette.primary` | `@color/widget_primary` | Barra superior, botones primarios, enlaces y bordes de acento. |
| **02 · Mascota** | **Verde Emblema Pato-Gato** | Identidad de la app | `#11883D` | `17, 136, 61` | `142° / 78% / 30%` | *Brand Asset* | `@drawable/ic_widget_logo` | Fondo del logo oficial, widgets de inicio y avatares. |
| **03 · Alerta** | **Rojo Notificación** | Atención prioritaria | `#F44336` | `244, 67, 54` | `4° / 90% / 58%` | `palette.badgeRed` | `@color/widget_badge_red` | Contador de mensajes sin leer, exámenes y alertas de conexión. |
| **04 · Novedad** | **Amarillo Pale MIeL** | Novedad en contenidos | `#FFFFCC` | `255, 255, 204` | `60° / 100% / 90%` | `palette.paleYellowBackground` | — | Marcador de archivos y contenidos sin abrir (clase `w3-pale-yellow` de MIeL). |

- **Accesibilidad y contraste:**
  - Sobre Verde UNLaM (`#009674`) y Verde Mascota (`#11883D`), usar siempre **texto blanco `#FFFFFF`** (Ratios `4.52:1` y `4.71:1`, cumpliendo WCAG AA).
  - En modo oscuro, la superficie principal es `#121212` / `#262626` con texto `#EEEEEE` (`14.5:1` AAA) y verde atenuado `#128268` / `#7BCEB9`.
- **Especificación completa (escalas `50–950`, neutros y variables):** ver [`color-palette/COLOR-PALETTE.md`](./color-palette/COLOR-PALETTE.md).

---

## 2. Official Brand Icons

Catálogo completo y resoluciones disponibles en [`icons/README.md`](./icons/README.md).

| Vista previa | Variante | Geometría | Fondo | Uso recomendado |
| :---: | :--- | :--- | :--- | :--- |
| <img src="./icons/png/64x64/libremiel-icon-circle-64.png" width="48" height="48" alt="Circle Icon" /> | **`libremiel-icon-circle`** | Circular con transparencia | `#11883D` | **Widgets de Android (`ic_widget_logo`), icono de app móvil, avatares.** |
| <img src="./icons/png/64x64/libremiel-icon-square-64.png" width="48" height="48" alt="Square Icon" /> | **`libremiel-icon-square`** | Cuadrada sólida | `#11883D` | **Splash screens, banners y tiendas de aplicaciones.** |

---

## 3. Regenerating Icons

Para regenerar todas las resoluciones y actualizar automáticamente los drawables de Android en `app/android/app/src/main/res/`:

```bash
python3 branding/scripts/generate-brand-icons.py
```
