# Android Widget Setup

The Android home screen widget is automatically included in the app build. This document describes the implementation details.

## Overview

The widget uses **Material 3 / Material You** design with dynamic colors on Android 12+ (API 31+).

## Widget Design (Native Android)

```
┌─────────────────────────────────────┐
│  ✨  Ask Conduit                    │  ← Primary color (dynamic)
│                                     │
├───────────┬───────────┬─────────────┤
│  📷       │  🖼️       │  📋        │
│ Camera    │ Photos    │ Clipboard   │  ← Secondary container
└───────────┴───────────┴─────────────┘
```

### Material You (Android 12+)

- **Primary button**: System accent color (`system_accent1_600`)
- **Secondary buttons**: Secondary container color (`system_accent2_100`)
- **Background**: Neutral surface color (`system_neutral1_10`)
- **Icons**: Tinted with `system_accent1_700`

### Fallback (Android 11 and below)

- **Primary button**: Material 3 default purple (`#6750A4`)
- **Secondary buttons**: Light purple container (`#E8DEF8`)
- **Background**: Near-white surface (`#FFFBFE`)

## Files Structure

```
android/app/src/main/
├── kotlin/.../ConduitWidgetProvider.kt   # Widget logic
├── res/
│   ├── layout/
│   │   └── conduit_widget.xml            # Widget layout
│   ├── drawable/
│   │   ├── widget_background.xml         # Surface background
│   │   ├── widget_button_primary.xml     # Primary button
│   │   ├── widget_button_secondary.xml   # Secondary buttons
│   │   ├── ic_widget_camera.xml          # Camera icon
│   │   ├── ic_widget_photos.xml          # Photos icon
│   │   ├── ic_widget_clipboard.xml       # Clipboard icon
│   │   └── widget_preview.xml            # Widget picker preview
│   ├── drawable-v31/                     # Material You overrides
│   │   └── (same files with dynamic colors)
│   ├── values/
│   │   ├── colors.xml                    # Light mode colors
│   │   ├── dimens.xml                    # Widget dimensions
│   │   └── strings.xml                   # Widget strings
│   ├── values-night/
│   │   └── colors.xml                    # Dark mode colors
│   └── xml/
│       └── conduit_widget_info.xml       # Widget metadata
└── AndroidManifest.xml                   # Widget receiver registration
```

## Deep Link Handling

The widget uses `homewidget://` URL scheme:

| Action | URL |
|--------|-----|
| New Chat | `homewidget://new_chat` |
| Camera | `homewidget://camera` |
| Photos | `homewidget://photos` |
| Clipboard | `homewidget://clipboard` |

## Widget Configuration

The widget is configured in `res/xml/conduit_widget_info.xml`:

- **Min size**: 250x110dp (3x2 cells)
- **Resizable**: Horizontal and vertical
- **Category**: Home screen
- **Update period**: Never (static widget)

## Testing

1. Build and install the debug APK:
   ```bash
   flutter build apk --debug
   flutter install
   ```

2. Long press on home screen
3. Tap "Widgets"
4. Search for "Conduit"
5. Drag widget to home screen

## Customization

### Changing the accent color

The widget automatically picks up the system's Material You palette on Android 12+. On older versions, modify the fallback colors in `values/colors.xml`:

```xml
<color name="widget_primary_fallback">#YOUR_COLOR</color>
```

### Changing widget size

Modify `res/xml/conduit_widget_info.xml`:

```xml
<appwidget-provider
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    ...
/>
```

## Troubleshooting

### Widget not appearing

- Ensure the app was installed (not just built)
- Try restarting the home launcher
- Check that `ConduitWidgetProvider` is registered in AndroidManifest.xml

### Colors not updating on theme change

- Widget colors are set at creation time
- User needs to re-add widget after theme change
- Or trigger update via `HomeWidget.updateWidget()` from Flutter

