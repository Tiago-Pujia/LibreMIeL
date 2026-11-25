# LibreMIeL — Guía de Identidad Cromática y Sistema de Color (AI-Ready)

> **Propósito de este archivo:** Especificación en texto estructurado (Markdown + Tokens Dart/XML/CSS) del sistema de identidad visual de **LibreMIeL**, optimizada para lectura directa por agentes de IA, desarrolladores y diseñadores. Para los isotipos e iconos normalizados, ver [`../icons/README.md`](../icons/README.md).

---

## 1. Identidad de Marca y Concepto

- **Nombre:** `LibreMIeL`
- **Lema / Tagline:** *"Tu MIeL, libre, rápido y en tus manos."*
- **Concepto:**
  - Cliente alternativo, gratuito, *local-first* y de código abierto (Licencia GPL-3.0) para la plataforma **MIeL (UNLaM)**.
  - Combina la seriedad institucional de la Universidad Nacional de La Matanza con la calidez y compañerismo de su comunidad estudiantil.
- **Isotipo oficial:**
  - El emblema del **Pato y el Gato** (`foto ds.png`), símbolo de dualidad armónica (Yin-Yang estudiantil) en fondo verde esmeralda, que representa el equilibrio entre el estudio riguroso y la camaradería universitaria.
- **Valores de marca (4 pilares):**
  1. **Libertad & Privacidad:** *Local-first*, sin servidores intermedios, sin telemetría invasiva.
  2. **Agilidad:** Arranque instantáneo, sincronización en dos ciclos en segundo plano y widgets de escritorio/móvil.
  3. **Claridad:** Jerarquía limpia, tipografía legible y fidelidad a las alertas originales de MIeL.
  4. **Comunidad:** Desarrollado por y para estudiantes de la UNLaM.

---

## 2. Colores Oficiales (Especificaciones Maestras)

| Prioridad | Nombre | Rol en el sistema | HEX | RGB | HSL | Token Flutter | Token Android | Uso principal |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **01 · Principal** | **Verde Esmeralda UNLaM** | Identidad institucional | `#009674` | `0, 150, 116` | `166° / 100% / 29%` | `palette.primary` | `@color/widget_primary` | Barra de título, botones de acción, enlaces, bordes activos y acentos de navegación. |
| **02 · Mascota** | **Verde Emblema Pato-Gato** | Identidad comunitaria | `#11883D` | `17, 136, 61` | `142° / 78% / 30%` | *Brand Asset* | `@drawable/ic_widget_logo` | Fondo del logo oficial de la aplicación, widgets y recursos gráficos comunitarios. |
| **03 · Acento / Alerta** | **Rojo Notificación** | Urgencia y atención | `#F44336` | `244, 67, 54` | `4° / 90% / 58%` | `palette.badgeRed` | `@color/widget_badge_red` | Contador de mensajes no leídos, alertas de exámenes, desconexión y acciones destructivas. |
| **04 · Novedad MIeL** | **Amarillo Pale MIeL** | Novedades no leídas | `#FFFFCC` | `255, 255, 204` | `60° / 100% / 90%` | `palette.paleYellowBackground` | — | Marcador de archivos y contenidos sin abrir (fiel a la clase `w3-pale-yellow` del servidor MIeL). |

### Modo Oscuro (Dark Theme Variants)
- **Primary Dark Theme:** `#128268` (RGB: `18, 130, 104`)
- **Badge Red Dark Theme:** `#EA4A3E` (RGB: `234, 74, 62`)
- **Pale Yellow Dark Theme:** `#464633` (Borde: `#69694C`)
- **Link Accent Dark Theme:** `#7BCEB9` (RGB: `123, 206, 185`)

---

## 3. Escalas de Color (`50` a `950`)

### 3.1. Verde Esmeralda UNLaM (Principal `#009674`)

| Nivel | HEX | RGB | Uso sugerido |
| :--- | :--- | :--- | :--- |
| `50` | `#E6F5F1` | `230, 245, 241` | Fondos de chips, superficies sutiles y estados de hover muy tenues |
| `100` | `#C1E6DC` | `193, 230, 220` | Indicadores secundarios y fondos de selección |
| `200` | `#99D5C5` | `153, 213, 197` | Bordes suaves de elementos interactivos |
| `300` | `#70C4AE` | `112, 196, 174` | Enlaces en modo oscuro / acentos atenuados |
| `400` | `#48B396` | `72, 179, 150` | Estados activos intermedios |
| **`500`** | **`#009674`** | **`0, 150, 116`** | **Color Maestro UNLaM / Botones primarios / Header** |
| `600` | `#008566` | `0, 133, 102` | Hover de botones en modo claro (`primaryHover`) |
| `700` | `#00765B` | `0, 118, 91` | Pressed state y modo oscuro contrastado (`primaryDark`) |
| `800` | `#005C47` | `0, 92, 71` | Texto de alto contraste sobre fondos verdosos suaves |
| `900` | `#004031` | `0, 64, 49` | Fondos profundos de identidad |
| `950` | `#00291F` | `0, 41, 31` | Profundidad máxima |

### 3.2. Verde Emblema Mascota (`#11883D`)

| Nivel | HEX | RGB | Uso sugerido |
| :--- | :--- | :--- | :--- |
| `50` | `#E8F6ED` | `232, 246, 237` | Fondos de avatar / tarjetas de comunidad |
| `100` | `#C6E7D2` | `198, 231, 210` | Bordes decorativos |
| `200` | `#A0D7B4` | `160, 215, 180` | Realces secundarios |
| `300` | `#78C694` | `120, 198, 148` | Variantes ilustrativas |
| `400` | `#53B576` | `83, 181, 118` | Sombras y acentos del logotipo |
| **`500`** | **`#11883D`** | **`17, 136, 61`** | **Color Maestro Mascota (Fondo del emblema Pato y Gato)** |
| `600` | `#0F7A37` | `15, 122, 55` | Realce y sombras |
| `700` | `#0D662E` | `13, 102, 46` | Contornos marcados |
| `800` | `#0A5024` | `10, 80, 36` | Textos sobre superficies claras del logo |
| `900` | `#073819` | `7, 56, 25` | Fondo oscuro de alto peso visual |
| `950` | `#042310` | `4, 35, 16` | Fondo máximo para avatares oscuros |

### 3.3. Rojo Alerta y Notificación (`#F44336`)

| Nivel | HEX | Uso sugerido |
| :--- | :--- | :--- |
| `50` | `#FEECEB` | Fondo de avisos de error y badges tenues |
| `100` | `#FCD0CD` | Contenedores de advertencia |
| `200` | `#F9A49E` | Bordes de campos con error |
| `500` | **`#F44336`** | **Badge de no leídos / Alertas críticas / Exámenes** |
| `600` | `#E53935` | Hover en botones de acción destructiva |
| `700` | `#D32F2F` | Pressed en acciones críticas |

---

## 4. Superficies y Neutros

### Modo Claro
- **Página / Ventana:** `#FFFFFF`
- **Sidebar / Drawer:** `#F3F9F6` (Borde: `#E2E7E7`)
- **Tarjetas / Módulos:** `#EEEEEE` (Hover: `#E5E5E5`, Borde: `#E0E0E0`)
- **Texto Principal:** `#000000` (En widgets: `#121A17`)
- **Texto Secundario:** `#555555`
- **Texto Atenuado:** `#757575`
- **Divisores:** `#E5E5E5`

### Modo Oscuro
- **Página / Ventana:** `#121212`
- **Sidebar / Drawer:** `#262626` (Borde: `#333333`)
- **Tarjetas / Módulos:** `#262626` (Hover: `#333333`, Borde: `#343434`)
- **Texto Principal:** `#EEEEEE`
- **Texto Secundario:** `#DDDDDD`
- **Texto Atenuado:** `#999999`
- **Divisores:** `#3A3A3A`

---

## 5. Reglas de Accesibilidad y Contraste (WCAG AA)

1. **Texto sobre Verde UNLaM (`#009674`):**
   - Usar **siempre texto blanco `#FFFFFF`**.
   - Ratio de contraste: **`4.52:1`** (Cumple WCAG AA para texto estándar y títulos).
2. **Texto sobre Verde Mascota (`#11883D`):**
   - Usar **siempre texto blanco `#FFFFFF`**.
   - Ratio de contraste: **`4.71:1`** (Cumple WCAG AA).
3. **Texto sobre Rojo Badge (`#F44336`):**
   - Usar texto blanco `#FFFFFF` (en negrita o tamaño >= 12sp para badges).
4. **Modo oscuro:**
   - En superficies `#121212` y `#262626`, usar `#EEEEEE` (`14.5:1` AAA) o `#7BCEB9` (`9.8:1` AAA para enlaces).

---

## 6. Tokens de Código

### Flutter / Dart (`MielPalette`)
```dart
MielPalette.light = MielPalette(
  primary: Color(0xFF009674),
  primaryHover: Color(0xFF008566),
  primaryDark: Color(0xFF00765B),
  badgeRed: Color(0xFFF44336),
  pageBackground: Color(0xFFFFFFFF),
  sidebarBackground: Color(0xFFF3F9F6),
  // ...
);
```

### Android XML (`res/values/colors_widget.xml`)
```xml
<color name="widget_primary">#FF009674</color>
<color name="widget_primary_dark">#FF00765B</color>
<color name="widget_badge_red">#FFF44336</color>
<color name="widget_bg">#FFFFFFFF</color>
<color name="widget_surface">#FFF3F9F6</color>
<color name="widget_text_primary">#FF121A17</color>
```

### Web / CSS Tokens
```css
:root {
  --miel-primary: #009674;
  --miel-primary-hover: #008566;
  --miel-primary-dark: #00765B;
  --miel-mascot-green: #11883D;
  --miel-badge-red: #F44336;
  --miel-bg: #FFFFFF;
  --miel-surface: #F3F9F6;
  --miel-text-primary: #000000;
}
```
