# Prompt for Claude Code on the Mac mini: build and upload the iOS app

Paste everything below the line into Claude Code, run from the project folder.

---

You are on my Mac mini. Build the Clinical Guidelines iOS app in Xcode and get it uploaded to App Store Connect (TestFlight first). Work step by step, and stop and ask me before anything that touches my Apple account, signing, or App Store Connect settings.

## Project context

- Flutter app, a customized fork of the open-source Conduit (Open WebUI client). Branch to use: `clinicalguidelines-on-upstream` of `https://github.com/vanalexgr/clinicalguidelines.io`.
- It is locked to `https://chat.clinicalguidelines.io`, SSO-only, Open WebUI only. Voice, speech, microphone, CarPlay, Hermes and direct connections are removed or hidden on purpose. I do NOT want to apply to Apple for any special permission or entitlement. Do not add any of these back: microphone, speech recognition, Personal Voice, CarPlay, Private Cloud Compute, VoIP background mode.
- iOS project: `ios/Runner.xcodeproj`, workspace `ios/Runner.xcworkspace`. Targets: `Runner`, `ConduitWidget` (home-screen widget extension), `ShareExtension`, `RunnerTests`.
- Bundle ids in the project: `app.clinicalguidelines` (app), `app.clinicalguidelines.clinicalguidelinesWidget`, `app.clinicalguidelines.ShareExtension`. App group: `group.app.clinicalguidelines` (debug: `group.app.clinicalguidelines.debug`), set through the `APP_GROUP_ID` build setting. `DEVELOPMENT_TEAM` is deliberately empty in the project; you must set my team in Xcode.
- Deployment target is iOS 16.0.

## Steps

1. Get the code and tools
   - Check out the branch (`git fetch origin && git checkout clinicalguidelines-on-upstream`).
   - This version needs Flutter 3.47+ (Dart 3.13+). Run `flutter --version`; run `flutter upgrade` if older. Check `flutter doctor` for the iOS toolchain, Xcode and CocoaPods.
   - `git submodule update --init third_party/mermaid third_party/katex` (the other submodules are not needed).
   - `flutter pub get`.
   - Generate code twice: `dart run build_runner build --delete-conflicting-outputs` in the project root, and again inside `packages/conduit_core`. Then `flutter gen-l10n`.

2. Version
   - In `pubspec.yaml`, set the version as `name+build`. The build number must be higher than any build already uploaded to App Store Connect for this app (ask me, or check App Store Connect > TestFlight). The name should be a normal marketing version.

3. Pods
   - `cd ios && pod install --repo-update` (delete `ios/Podfile.lock` and `ios/Pods` first only if pod install fails on stale pods; the voice plugins `record`, `vad`, `flutter_webrtc`, `flutter_callkit_incoming`, `permission_handler` were removed from pubspec, so old Pods must go).

4. Fix compile errors. IMPORTANT
   - Several Swift changes were made on a Linux machine that cannot compile Swift, so expect errors. I deleted these files and their references: `NativeSttBridge.swift`, `NativeIosTtsBridge.swift`, `RealtimeAudioBridge.swift`, `VoiceAudioRouteBridge.swift`; removed `NativeSttCallKitAppDelegate` from `AppDelegate.swift`; removed 28 voice tests from `ios/RunnerTests/RunnerTests.swift`. Fix any leftover references (dangling symbols, missing files in the project, tests referencing deleted types) by removing the dead code. Do not restore the deleted voice code.
   - Build the app: `flutter build ios --release --no-codesign`, and also make sure `RunnerTests` and both extensions compile.

5. Entitlements and Info.plist: check they stay clean
   - `ios/Runner/Runner.entitlements` must contain only the app-groups entry (`$(APP_GROUP_ID)`). No CarPlay, Private Cloud Compute, VoIP or similar entitlements.
   - `ios/Runner/Info.plist` must have NO `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` or `NSPersonalVoiceUsageDescription`, no CarPlay scene (`CPTemplateApplicationSceneSessionRoleApplication`), and `UIBackgroundModes` of only `processing`. Camera, photo library and location descriptions stay.
   - `ios/Podfile` must not define `PERMISSION_MICROPHONE` or `PERMISSION_SPEECH_RECOGNIZER`.
   - Search the compiled app for leftover references that App Store validation would flag: `grep -rn "SFSpeech\|requestRecordPermission\|requestPersonalVoice\|NSMicrophone" ios/Runner` and inspect the built `.app` Info.plist.

6. Signing (stop and ask me here)
   - Open `ios/Runner.xcworkspace` in Xcode. For each of the three app targets, set my Team and keep "Automatically manage signing" on, unless I say otherwise.
   - The App IDs and the app group `group.app.clinicalguidelines` must exist in my Apple Developer account (Certificates, Identifiers & Profiles). Ask me before creating or changing any identifier, app group or certificate. Tell me exactly what is missing instead of guessing.
   - Tell me if the existing App Store Connect app record uses a different bundle id than `app.clinicalguidelines`. If so, STOP and ask; do not change bundle ids on your own.

7. Archive and upload
   - Run `flutter build ipa --release` (or archive in Xcode: Product > Archive with the Runner scheme and a generic iOS device).
   - Validate the archive, then upload with Xcode Organizer (Distribute App > App Store Connect > Upload) or `xcrun altool` / Transporter. Ask me before the final upload, and tell me the version and build number you are about to send.
   - Do not submit for App Review and do not press any release button in App Store Connect. I will do that myself after checking TestFlight.

## Rules

- Never print, paste or commit passwords, certificates, API keys or provisioning secrets. If a password prompt appears, tell me and let me type it.
- Commit any fixes to this branch with clear messages (end commit messages with the usual attribution line), and show me the diff summary before pushing.
- When done, tell me: what you changed, what compiled and what did not, the final version/build number, and whether the upload succeeded.
