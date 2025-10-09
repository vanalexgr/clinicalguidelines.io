import AVFoundation
import Flutter
import UIKit

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
    private var activeStreams: Set<String> = []
    private var microphoneStreams: Set<String> = []
    private var channel: FlutterMethodChannel?
    
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
        activeStreams = Set(streamIds)
        if requiresMic {
            microphoneStreams = microphoneStreams.union(streamIds)
            VoiceBackgroundAudioManager.shared.activate()
        }

        if UIApplication.shared.applicationState == .background {
            startBackgroundTask()
        }
    }

    private func stopBackgroundExecution(streamIds: [String]) {
        streamIds.forEach { activeStreams.remove($0) }
        streamIds.forEach { microphoneStreams.remove($0) }

        if activeStreams.isEmpty {
            endBackgroundTask()
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
        VoiceBackgroundAudioManager.shared.deactivate()
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
    
    // Setup background streaming handler using the plugin registry messenger
    if let registrar = self.registrar(forPlugin: "BackgroundStreamingHandler") {
      let channel = FlutterMethodChannel(
        name: "conduit/background_streaming",
        binaryMessenger: registrar.messenger()
      )

      backgroundStreamingHandler = BackgroundStreamingHandler()
      backgroundStreamingHandler?.setup(with: channel)

      // Register method call handler
      channel.setMethodCallHandler { [weak self] (call, result) in
        self?.backgroundStreamingHandler?.handle(call, result: result)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
