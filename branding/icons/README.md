# LibreMIeL — Normalized Brand Icons

Pack de isotipos y recursos gráficos oficiales de **LibreMIeL**, derivados del emblema oficial del **Pato y el Gato** (`foto ds.png`), normalizados en dimensiones estándar y optimizados para Android (Widgets y Launcher), Linux (AppImage, `.deb`, `.rpm`, `.desktop`), Windows (Bandeja de sistema / `.ico`), macOS y Web.

---

## 1. Catálogo Visual de Variantes

| Vista previa (64px) | Variante | Geometría | Fondo | Uso recomendado |
| :---: | :--- | :--- | :--- | :--- |
| <img src="./png/64x64/libremiel-icon-circle-64.png" width="48" height="48" alt="Circle Icon" /> | **`libremiel-icon-circle`** | Circular con transparencia alfa | Verde esmeralda `#11883D` | **Icono oficial de la app, avatares, widgets Android (`ic_widget_logo`) y PWA.** |
| <img src="./png/64x64/libremiel-icon-square-64.png" width="48" height="48" alt="Square Icon" /> | **`libremiel-icon-square`** | Cuadrada sólida | Verde esmeralda `#11883D` | **Splash screens, tiendas de aplicaciones (Google Play / F-Droid), banners y material gráfico.** |
| <img src="./png/64x64/libremiel-icon.png" width="48" height="48" alt="App Icon" /> | **`libremiel-icon`** | Canónica circular | Verde esmeralda `#11883D` | **Recurso estándar (`app/assets/icons/libremiel.png`) referenciado en el cliente Flutter.** |

---

## 2. Resoluciones Normalizadas (`./png/`)

Renderizados con canal alfa (RGBA) a 32 bits y compresión PNG optimizada:

| Resolución | Directorio | Archivos incluidos | Caso de uso principal |
| :--- | :--- | :--- | :--- |
| **`512x512`** | [`png/512x512/`](./png/512x512/) | `libremiel-icon-{square,circle}-512.png`, `libremiel-icon.png` | Master store asset, banners, splash screen en alta resolución, Linux hicolor 512x512. |
| **`256x256`** | [`png/256x256/`](./png/256x256/) | `libremiel-icon-{square,circle}-256.png`, `libremiel-icon.png` | Ventana 'Acerca de', modales de perfil, Linux hicolor 256x256, macOS `.icns`. |
| **`128x128`** | [`png/128x128/`](./png/128x128/) | `libremiel-icon-{square,circle}-128.png`, `libremiel-icon.png` | Notificaciones expandidas del sistema operativo, Linux hicolor 128x128. |
| **`64x64`** | [`png/64x64/`](./png/64x64/) | `libremiel-icon-{square,circle}-64.png`, `libremiel-icon.png` | Widgets móviles, encabezados de módulo, Linux hicolor 64x64. |
| **`48x48`** | [`png/48x48/`](./png/48x48/) | `libremiel-icon-{square,circle}-48.png`, `libremiel-icon.png` | Launcher icon estándar Android (mdpi), Linux hicolor 48x48, barra de tareas. |
| **`32x32`** | [`png/32x32/`](./png/32x32/) | `libremiel-icon-{square,circle}-32.png`, `libremiel-icon.png` | Favicon web, iconos de bandeja de sistema (tray), Linux hicolor 32x32. |

---

## 3. Integración en el Proyecto

### 3.1. Widgets nativos de Android (`res/layout/`)
Los drawables se generan automáticamente en las carpetas de densidad de Android:
- `app/android/app/src/main/res/drawable/ic_widget_logo.png`
- `app/android/app/src/main/res/drawable-mdpi/ic_widget_logo.png` (48px)
- `app/android/app/src/main/res/drawable-hdpi/ic_widget_logo.png` (72px)
- `app/android/app/src/main/res/drawable-xhdpi/ic_widget_logo.png` (96px)
- `app/android/app/src/main/res/drawable-xxhdpi/ic_widget_logo.png` (144px)
- `app/android/app/src/main/res/drawable-xxxhdpi/ic_widget_logo.png` (192px)

Referencia en XML:
```xml
<ImageView
    android:layout_width="22dp"
    android:layout_height="22dp"
    android:contentDescription="@string/widget_compact_name"
    android:scaleType="fitCenter"
    android:src="@drawable/ic_widget_logo" />
```

### 3.2. Flutter (`assets/icons/`)
```dart
Image.asset(
  'assets/icons/libremiel.png',
  width: 48,
  height: 48,
)
```

### 3.3. HTML / Web
```html
<img src="branding/icons/png/64x64/libremiel-icon-circle.png" width="32" height="32" alt="LibreMIeL" />
```

---

## 4. Regeneración Automática

Para volver a generar todos los tamaños y actualizar los drawables de Android:

```bash
python3 branding/scripts/generate-brand-icons.py
```
