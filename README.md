# Clinical Guidelines

**Your AI Copilot for Clinical Practice.**

Clinical Guidelines is a specialized mobile client designed to provide evidence-based clinical decision support. Built on the **ClinicalGuidelines.io** platform, it connects securely to our Open-WebUI infrastructure to deliver accurate, citation-backed answers using GraphRAG (Graph Retrieval-Augmented Generation) technology.

<div align="center">

<a href="https://play.google.com/apps/internaltest/4701679299948056587">
<img src="docs/store-badges/google.webp" alt="Get it on Google Play" style="height:56px;"/>
</a>
<a href="https://testflight.apple.com/join/JjxCNGbn">
<img src="docs/store-badges/apple.webp" alt="Download on the App Store" style="height:56px;"/>
</a>

</div>

## Key Features

* **Evidence-Based AI:** Answers are strictly "locked" to approved guidelines (starting with ESVS Vascular Surgery guidelines).
* **Zero Hallucinations:** The system utilizes GraphRAG to ensure answers are derived solely from provided source texts.
* **Traceable Citations:** Every response links directly to the specific guideline paragraph and Evidence Level (e.g., Class I, Level B).
* **Secure Authentication:** Supports seamless SSO login via Apple, Google, Microsoft, Yahoo, and LinkedIn.
* **Voice Interface:** Integrated Speech-to-Text (STT) and Text-to-Speech (TTS) for hands-free clinical use.
* **Multi-Modal:** Support for analyzing medical images and documents uploaded directly from your device.

## Technical Architecture

This application is a customized fork of [Conduit](https://github.com/cogwheel0/conduit), tailored for the Clinical Guidelines ecosystem.

### Core Customizations
* **Server Lock:** The app is hardcoded to connect exclusively to `https://chat.clinicalguidelines.io`.
* **SSO-Only Flow:** Traditional username/password login is disabled in favor of a secure, token-based SSO flow using native browser deep linking (`clinicalguidelines://auth`).
* **Privacy-First:** No third-party analytics or telemetry SDKs are included. All data transmission occurs directly between the device and the Clinical Guidelines server.

### Tech Stack
* **Framework:** Flutter (Dart)
* **State Management:** Riverpod 3.0
* **Local Storage:** Hive CE (NoSQL) & Flutter Secure Storage (Keychain/Keystore)
* **Networking:** Dio & Socket.IO (for real-time streaming)

## Build Instructions

To build the application locally:

```bash
# Get dependencies
flutter pub get

# Generate code (Riverpod/Freezed/JSON)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```
