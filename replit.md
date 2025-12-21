# Conduit - Open-WebUI Mobile Client

## Overview

Conduit is an open-source, cross-platform mobile application that serves as a native client for Open-WebUI. It enables users to connect to their self-hosted AI infrastructure, chat with AI models, manage conversations, and interact with their AI on the go. The app is built with Flutter and supports iOS, Android, and web platforms.

Key capabilities include:
- Real-time streaming chat with AI models
- Voice input/output (speech-to-text and text-to-speech)
- File and image uploads for RAG (Retrieval-Augmented Generation)
- Markdown rendering with syntax highlighting
- Multi-language support (EN, DE, ES, FR, IT, KO, NL, RU, ZH)
- iOS widgets for quick access

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **Framework**: Flutter with Dart
- **State Management**: Riverpod (flutter_riverpod with riverpod_annotation for code generation)
- **Navigation**: go_router for declarative routing
- **UI Patterns**: 
  - Composition over inheritance for widget building
  - Immutable widgets preferred (StatelessWidget where possible)
  - Separation of ephemeral state and app state

### Data Layer
- **Local Storage**: Hive CE (hive_ce, hive_ce_flutter) for local data persistence
- **Secure Storage**: flutter_secure_storage for credentials (uses Keychain on iOS, Keystore on Android)
- **Caching**: cached_network_image for image caching

### Network Layer
- **HTTP Client**: Dio for API requests
- **Real-time Communication**: socket_io_client for streaming chat
- **Connectivity**: connectivity_plus for network state monitoring

### Code Generation
- **Serialization**: Freezed + json_annotation for immutable data models
- **State**: riverpod_annotation with build_runner for provider generation

### Platform-Specific Features
- **iOS**: Native widgets (ConduitWidget) using SwiftUI
- **Voice**: stts for speech-to-text, flutter_tts for text-to-speech
- **File Handling**: file_picker, image_picker for attachments
- **Sharing**: share_plus, share_handler for content sharing

### Rich Content Rendering
- **Markdown**: flutter_markdown_plus with syntax highlighting
- **Math**: flutter_math_fork for LaTeX rendering
- **Charts**: Chart.js (bundled in assets) for data visualization
- **Diagrams**: Mermaid.js (bundled in assets) for diagram rendering
- **WebView**: webview_flutter for embedded web content

### Build & Deployment
- **Android**: Fastlane for Google Play deployment
- **iOS**: Fastlane for App Store deployment
- **Localization**: Flutter's intl package with ARB files in lib/l10n/

## External Dependencies

### Server Requirement
- Requires an existing **Open-WebUI server** - Conduit does not host AI models
- All data stays with the user's configured server by default

### Third-Party Packages (Key Dependencies)
| Purpose | Package |
|---------|---------|
| HTTP | dio |
| WebSocket | socket_io_client |
| State Management | flutter_riverpod, riverpod_annotation |
| Routing | go_router |
| Local DB | hive_ce, hive_ce_flutter |
| Secure Storage | flutter_secure_storage |
| Speech | stts, flutter_tts |
| Files | file_picker, image_picker |
| Markdown | flutter_markdown_plus |
| Networking | connectivity_plus |

### Bundled JavaScript Libraries
- Chart.js v4.5.0 (assets/chartjs.min.js) - for chart rendering
- Mermaid.js (assets/mermaid.min.js) - for diagram rendering

### No External Analytics
- The app does not include third-party analytics or advertising SDKs
- All communication is between the app and the user's configured Open-WebUI server