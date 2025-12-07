# iOS Widget Extension Setup

This document describes how the ConduitWidget extension was added and how to configure it.

## Overview

The widget extension was created via Xcode and provides quick access buttons:

- **Ask Conduit** - Opens app with new chat, focuses composer
- **Camera** - Opens app, creates new chat, launches camera
- **Photos** - Opens app, creates new chat, opens photo picker  
- **Clipboard** - Opens app with clipboard contents as prompt

## Files Structure

```
ios/ConduitWidget/
├── Assets.xcassets/           # Asset catalog
│   ├── AccentColor.colorset/  # Theme accent color
│   ├── AppIcon.appiconset/    # Widget icon (uses app icon)
│   └── WidgetBackground.colorset/  # Light/dark backgrounds
├── ConduitWidget.entitlements # App group for data sharing
├── ConduitWidget.swift        # Main widget implementation
├── ConduitWidgetBundle.swift  # Widget bundle entry point
└── Info.plist                 # Extension configuration
```

## App Group Configuration

Both the main app and widget share data via the app group `group.app.cogwheel.conduit`.

**Important:** Ensure both targets have this app group in their capabilities:

1. Select the **Runner** target → Signing & Capabilities → App Groups
2. Verify `group.app.cogwheel.conduit` is listed

3. Select the **ConduitWidget** target → Signing & Capabilities → App Groups  
4. Verify `group.app.cogwheel.conduit` is listed

## Deep Link Handling

The widget uses `homewidget://` URL scheme to communicate with the Flutter app:

| Action | URL |
|--------|-----|
| New Chat | `homewidget://new_chat` |
| Camera | `homewidget://camera` |
| Photos | `homewidget://photos` |
| Clipboard | `homewidget://clipboard` |

These are handled by `HomeWidgetCoordinator` in the Flutter code.

## Widget Design (Native iOS)

```
┌─────────────────────────────────────┐
│  ✨  Ask Conduit                    │  ← System tint color
│                                     │
├───────────┬───────────┬─────────────┤
│  📷       │  🖼️       │  📋        │
│ Camera    │ Photos    │ Clipboard   │  ← Secondary system bg
└───────────┴───────────┴─────────────┘
```

- **Size**: Medium widget (systemMedium)
- **Primary button**: System tint color (follows app accent)
- **Secondary buttons**: `secondarySystemGroupedBackground`
- **Icons**: SF Symbols with hierarchical rendering
- **Typography**: SF Rounded font
- **Supports**: Light/dark mode, Dynamic Type

## Building

The widget extension is built automatically when you build the main app:

```bash
flutter build ios
```

Or build from Xcode:

1. Open `ios/Runner.xcworkspace`
2. Select the **Runner** scheme
3. Build (⌘B)

## Testing

1. Build and run the main app on a device/simulator
2. Go to home screen
3. Long press → tap **+** to add widgets
4. Search for "Conduit"
5. Add the medium widget

## Troubleshooting

### Widget not appearing in picker

- Ensure the widget extension builds without errors
- Check deployment target is iOS 17.0+
- Clean build folder (⇧⌘K) and rebuild

### Widget actions don't work

- Verify the `homewidget://` URL scheme is handled
- Check `HomeWidgetCoordinator` is initialized in app startup
- Ensure app group is configured on both targets

### Widget doesn't update

- The widget uses `.never` refresh policy (static content)
- Call `HomeWidget.updateWidget()` from Flutter to trigger refresh

## Adding to a Fresh Clone

If cloning the repo fresh, the widget extension should already be configured in the Xcode project. Just ensure:

1. Team/signing is set for both targets
2. App groups capability is enabled
3. Pod install has been run

