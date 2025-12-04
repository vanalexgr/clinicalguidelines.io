import AVFoundation
import BackgroundTasks
import Flutter
import AppIntents
import UIKit
import UniformTypeIdentifiers

final class VoiceBackgroundAudioManager {
    static let shared = VoiceBackgroundAudioManager()

    private var isActive = false

    private init() {}

    func activate() {
        guard !isActive else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .mixWithOthers,
                    .defaultToSpeaker,
                ]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            isActive = true
        } catch {
            print("VoiceBackgroundAudioManager: Failed to activate audio session: \(error)")
        }
    }

    func deactivate() {
        guard isActive else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("VoiceBackgroundAudioManager: Failed to deactivate audio session: \(error)")
        }

        isActive = false
    }
}

// Background streaming handler class
class BackgroundStreamingHandler: NSObject {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var bgProcessingTask: BGTask?
    private var activeStreams: Set<String> = []
    private var microphoneStreams: Set<String> = []
    private var channel: FlutterMethodChannel?

    static let processingTaskIdentifier = "app.cogwheel.conduit.refresh"

    override init() {
        super.init()
        setupNotifications()
    }
    
    func setup(with channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        if !activeStreams.isEmpty {
            startBackgroundTask()
        }
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startBackgroundExecution":
            if let args = call.arguments as? [String: Any],
               let streamIds = args["streamIds"] as? [String] {
                let requiresMic = args["requiresMicrophone"] as? Bool ?? false
                startBackgroundExecution(streamIds: streamIds, requiresMic: requiresMic)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        case "stopBackgroundExecution":
            if let args = call.arguments as? [String: Any],
               let streamIds = args["streamIds"] as? [String] {
                stopBackgroundExecution(streamIds: streamIds)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        case "keepAlive":
            keepAlive()
            result(nil)
            
        case "saveStreamStates":
            if let args = call.arguments as? [String: Any],
               let states = args["states"] as? [[String: Any]] {
                saveStreamStates(states)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        case "recoverStreamStates":
            result(recoverStreamStates())
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startBackgroundExecution(streamIds: [String], requiresMic: Bool) {
        activeStreams.formUnion(streamIds)
        microphoneStreams.formIntersection(activeStreams)
        if requiresMic {
            microphoneStreams.formUnion(streamIds)
        }

        if !microphoneStreams.isEmpty {
            VoiceBackgroundAudioManager.shared.activate()
        }

        if UIApplication.shared.applicationState == .background {
            startBackgroundTask()
            scheduleBGProcessingTask()
        }
    }

    private func stopBackgroundExecution(streamIds: [String]) {
        streamIds.forEach { activeStreams.remove($0) }
        streamIds.forEach { microphoneStreams.remove($0) }

        if activeStreams.isEmpty {
            endBackgroundTask()
            cancelBGProcessingTask()
        }

        if microphoneStreams.isEmpty {
            VoiceBackgroundAudioManager.shared.deactivate()
        }
    }
    
    private func startBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ConduitStreaming") { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    private func keepAlive() {
        if backgroundTask != .invalid {
            endBackgroundTask()
            startBackgroundTask()
        }

        if !microphoneStreams.isEmpty {
            VoiceBackgroundAudioManager.shared.activate()
        }
    }
    
    private func saveStreamStates(_ states: [[String: Any]]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: states, options: [])
            UserDefaults.standard.set(jsonData, forKey: "ConduitActiveStreams")
        } catch {
            print("BackgroundStreamingHandler: Failed to serialize stream states: \(error)")
        }
    }

    private func recoverStreamStates() -> [[String: Any]] {
        guard let jsonData = UserDefaults.standard.data(forKey: "ConduitActiveStreams") else {
            return []
        }
        do {
            if let states = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                return states
            }
        } catch {
            print("BackgroundStreamingHandler: Failed to deserialize stream states: \(error)")
        }
        return []
    }

    // MARK: - BGTaskScheduler Methods

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBGProcessingTask(task: task as! BGProcessingTask)
        }
    }

    private func scheduleBGProcessingTask() {
        // Cancel any existing task
        cancelBGProcessingTask()

        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // Schedule for immediate execution when app backgrounds
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundStreamingHandler: Scheduled BGProcessingTask")
        } catch {
            print("BackgroundStreamingHandler: Failed to schedule BGProcessingTask: \(error)")
        }
    }

    private func cancelBGProcessingTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
        print("BackgroundStreamingHandler: Cancelled BGProcessingTask")
    }

    private func handleBGProcessingTask(task: BGProcessingTask) {
        print("BackgroundStreamingHandler: BGProcessingTask started")
        bgProcessingTask = task

        // Schedule a new task for continuation if streams are still active
        if !activeStreams.isEmpty {
            scheduleBGProcessingTask()
        }

        // Set expiration handler
        task.expirationHandler = { [weak self] in
            print("BackgroundStreamingHandler: BGProcessingTask expiring")
            self?.notifyTaskExpiring()
            self?.bgProcessingTask = nil
        }

        // Notify Flutter that we have extended background time
        channel?.invokeMethod("backgroundTaskExtended", arguments: [
            "streamIds": Array(activeStreams),
            "estimatedTime": 180 // ~3 minutes typical for BGProcessingTask
        ])

        // Keep task alive while streams are active
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Keep sending keepAlive signals
            let keepAliveInterval: TimeInterval = 30
            var elapsedTime: TimeInterval = 0
            let maxTime: TimeInterval = 180 // 3 minutes

            while !self.activeStreams.isEmpty && elapsedTime < maxTime {
                Thread.sleep(forTimeInterval: keepAliveInterval)
                elapsedTime += keepAliveInterval

                // Notify Flutter to keep streams alive
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("backgroundKeepAlive", arguments: nil)
                }
            }

            // Mark task as complete
            task.setTaskCompleted(success: true)
            self.bgProcessingTask = nil
        }

        DispatchQueue.global(qos: .background).async(execute: workItem)
    }

    private func notifyTaskExpiring() {
        channel?.invokeMethod("backgroundTaskExpiring", arguments: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
        VoiceBackgroundAudioManager.shared.deactivate()
  }
}

/// Manages the method channel for App Intent invocations to Flutter.
/// Native Swift intents call this to invoke Flutter-side business logic.
final class AppIntentMethodChannel {
    static var shared: AppIntentMethodChannel?

    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "conduit/app_intents",
            binaryMessenger: messenger
        )
    }

    /// Invokes a Flutter handler for the given intent identifier.
    func invokeIntent(
        identifier: String,
        parameters: [String: Any]
    ) async -> [String: Any] {
        // No [weak self] needed here - the closure executes immediately on the
        // main queue and there's no retain cycle risk. Using weak self would
        // risk the continuation never resuming if self became nil.
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.channel.invokeMethod(
                    identifier,
                    arguments: parameters
                ) { result in
                    if let dict = result as? [String: Any] {
                        continuation.resume(returning: dict)
                    } else {
                        continuation.resume(returning: [
                            "success": false,
                            "error": "Invalid response from Flutter"
                        ])
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
enum AppIntentError: Error {
    case executionFailed(String)
}

@available(iOS 16.0, *)
struct AskConduitIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Conduit"
    static var description = IntentDescription(
        "Start a Conduit chat with an optional prompt."
    )
    static var isDiscoverable = true
    static var openAppWhenRun = true

    @Parameter(
        title: "Prompt",
        requestValueDialog: IntentDialog("What should Conduit answer?")
    )
    var prompt: String?

    init() {}

    init(prompt: String?) {
        self.prompt = prompt
    }

    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & OpensIntent
    {
        guard let channel = AppIntentMethodChannel.shared else {
            throw AppIntentError.executionFailed("App not ready")
        }

        let parameters: [String: Any] = prompt?.isEmpty == false
            ? ["prompt": prompt ?? ""]
            : [:]
        let result = await channel.invokeIntent(
            identifier: "app.cogwheel.conduit.ask_chat",
            parameters: parameters
        )

        if let success = result["success"] as? Bool, success {
            let value = result["value"] as? String ?? "Opening chat"
            return .result(value: value)
        }

        let message = result["error"] as? String
            ?? "Unable to open Conduit chat"
        throw AppIntentError.executionFailed(message)
    }
}

@available(iOS 16.0, *)
struct StartVoiceCallIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Voice Call"
    static var description = IntentDescription(
        "Start a live voice call with Conduit."
    )
    static var isDiscoverable = true
    static var openAppWhenRun = true

    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & OpensIntent
    {
        guard let channel = AppIntentMethodChannel.shared else {
            throw AppIntentError.executionFailed("App not ready")
        }

        let result = await channel.invokeIntent(
            identifier: "app.cogwheel.conduit.start_voice_call",
            parameters: [:]
        )

        if let success = result["success"] as? Bool, success {
            let value = result["value"] as? String ?? "Starting voice call"
            return .result(value: value)
        }

        let message = result["error"] as? String
            ?? "Unable to start voice call"
        throw AppIntentError.executionFailed(message)
    }
}

@available(iOS 16.0, *)
struct ConduitSendTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Send to Conduit"
    static var description = IntentDescription(
        "Start a Conduit chat with provided text."
    )
    static var isDiscoverable = true
    static var openAppWhenRun = true

    @Parameter(
        title: "Text",
        requestValueDialog: IntentDialog("What should Conduit process?")
    )
    var text: String?

    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & OpensIntent
    {
        guard let channel = AppIntentMethodChannel.shared else {
            throw AppIntentError.executionFailed("App not ready")
        }

        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = await channel.invokeIntent(
            identifier: "app.cogwheel.conduit.send_text",
            parameters: ["text": trimmed ?? ""]
        )

        if let success = result["success"] as? Bool, success {
            let value = result["value"] as? String ?? "Sent to Conduit"
            return .result(value: value)
        }

        let message = result["error"] as? String ?? "Unable to send text"
        throw AppIntentError.executionFailed(message)
    }
}

@available(iOS 16.0, *)
struct ConduitSendUrlIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Link to Conduit"
    static var description = IntentDescription(
        "Send a URL into Conduit for summary or analysis."
    )
    static var isDiscoverable = true
    static var openAppWhenRun = true

    @Parameter(
        title: "URL",
        requestValueDialog: IntentDialog("Which link should Conduit analyze?")
    )
    var url: URL

    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & OpensIntent
    {
        guard let channel = AppIntentMethodChannel.shared else {
            throw AppIntentError.executionFailed("App not ready")
        }

        let result = await channel.invokeIntent(
            identifier: "app.cogwheel.conduit.send_url",
            parameters: ["url": url.absoluteString]
        )

        if let success = result["success"] as? Bool, success {
            let value = result["value"] as? String ?? "Sent link to Conduit"
            return .result(value: value)
        }

        let message = result["error"] as? String ?? "Unable to send link"
        throw AppIntentError.executionFailed(message)
    }
}

@available(iOS 16.0, *)
struct ConduitSendImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Image to Conduit"
    static var description = IntentDescription(
        "Send an image into Conduit for analysis."
    )
    static var isDiscoverable = true
    static var openAppWhenRun = true

    @Parameter(
        title: "Image",
        requestValueDialog: IntentDialog("Choose an image for Conduit.")
    )
    var image: IntentFile

    func perform() async throws
        -> some IntentResult & ReturnsValue<String> & OpensIntent
    {
        guard let channel = AppIntentMethodChannel.shared else {
            throw AppIntentError.executionFailed("App not ready")
        }

        if let type = image.type, !type.conforms(to: .image) {
            throw AppIntentError.executionFailed(
                "Only image files are supported."
            )
        }

        let data = try image.data
        let base64 = data.base64EncodedString()
        let name = image.filename ?? "shared_image.jpg"

        let result = await channel.invokeIntent(
            identifier: "app.cogwheel.conduit.send_image",
            parameters: [
                "filename": name,
                "bytes": base64,
            ]
        )

        if let success = result["success"] as? Bool, success {
            let value = result["value"] as? String ?? "Sent image to Conduit"
            return .result(value: value)
        }

        let message = result["error"] as? String ?? "Unable to send image"
        throw AppIntentError.executionFailed(message)
    }
}

@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: AskConduitIntent(),
                phrases: [
                    "Ask with \(.applicationName)",
                    "Start chat in \(.applicationName)",
                    "Open composer in \(.applicationName)",
                ]
            ),
            AppShortcut(
                intent: StartVoiceCallIntent(),
                phrases: [
                    "Start voice call in \(.applicationName)",
                    "Call with \(.applicationName)",
                    "Begin voice chat in \(.applicationName)",
                ]
            ),
            AppShortcut(
                intent: ConduitSendTextIntent(),
                phrases: [
                    "Send text to \(.applicationName)",
                    "Share text with \(.applicationName)",
                    "Summarize this in \(.applicationName)",
                ]
            ),
            AppShortcut(
                intent: ConduitSendUrlIntent(),
                phrases: [
                    "Summarize link in \(.applicationName)",
                    "Analyze link with \(.applicationName)",
                    "Send URL to \(.applicationName)",
                ]
            ),
            AppShortcut(
                intent: ConduitSendImageIntent(),
                phrases: [
                    "Send image to \(.applicationName)",
                    "Analyze image with \(.applicationName)",
                    "Share photo to \(.applicationName)",
                ]
            ),
        ]
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundStreamingHandler: BackgroundStreamingHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup App Intents method channel for native -> Flutter communication
    if let registrar = self.registrar(forPlugin: "AppIntentMethodChannel") {
      AppIntentMethodChannel.shared = AppIntentMethodChannel(
        messenger: registrar.messenger()
      )
    }

    // Setup background streaming handler using the plugin registry messenger
    if let registrar = self.registrar(forPlugin: "BackgroundStreamingHandler") {
      let channel = FlutterMethodChannel(
        name: "conduit/background_streaming",
        binaryMessenger: registrar.messenger()
      )

      backgroundStreamingHandler = BackgroundStreamingHandler()
      backgroundStreamingHandler?.setup(with: channel)

      // Register BGTaskScheduler tasks
      backgroundStreamingHandler?.registerBackgroundTasks()

      // Register method call handler
      channel.setMethodCallHandler { [weak self] (call, result) in
        self?.backgroundStreamingHandler?.handle(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
