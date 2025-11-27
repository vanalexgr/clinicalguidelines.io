import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vad/vad.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/background_streaming_handler.dart';
import '../../../core/services/settings_service.dart';

part 'voice_input_service.g.dart';

/// Lightweight locale representation used across the UI.
class LocaleName {
  final String localeId;
  final String name;
  const LocaleName(this.localeId, this.name);
}

class VoiceInputService {
  static const int _vadSampleRate = 16000;
  static const int _vadFrameSamples = 512;
  static const int _vadPreSpeechPadFrames = 16;
  static const int _vadMinSpeechFrames = 8;
  static const int _vadEndSpeechPadFrames = 6;
  static const double _vadPositiveSpeechThreshold = 0.6;
  static const double _vadNegativeSpeechThreshold = 0.35;
  static const Duration _localeFetchTimeout = Duration(seconds: 2);
  static const String _backgroundSttStreamId = 'voice-input-stt';

  final VadHandler _vadHandler = VadHandler.create();
  final SpeechToText _speech = SpeechToText();
  final AudioRecorder _microphonePermissionProbe = AudioRecorder();
  final ApiService? _api;
  final Ref? _ref;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _localSttAvailable = false;
  bool _localSttActive = false;
  SttPreference _preference = SttPreference.deviceOnly;
  bool _usingServerStt = false;
  String? _selectedLocaleId;
  List<LocaleName> _locales = const [];
  bool _usingFallbackLocales = false;
  Future<void>? _startingLocalStt;
  StreamController<String>? _textStreamController;
  String _currentText = '';
  StreamController<int>? _intensityController;
  Stream<int> get intensityStream =>
      _intensityController?.stream ?? const Stream<int>.empty();
  int _lastIntensity = 0;
  Timer? _intensityDecayTimer;
  List<double>? _vadPendingSamples;
  bool _backgroundMicPinned = false;

  Stream<String> get textStream =>
      _textStreamController?.stream ?? const Stream<String>.empty();
  Timer? _autoStopTimer;
  StreamSubscription<List<double>>? _vadSpeechEndSub;
  StreamSubscription<({double isSpeech, double notSpeech, List<double> frame})>?
  _vadFrameSub;
  StreamSubscription<String>? _vadErrorSub;

  bool get isSupportedPlatform => Platform.isAndroid || Platform.isIOS;
  bool get hasServerStt => _api != null;
  SttPreference get preference => _preference;
  bool get prefersServerOnly => _preference == SttPreference.serverOnly;
  bool get prefersDeviceOnly => _preference == SttPreference.deviceOnly;
  bool get _isIosSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  VoiceInputService({ApiService? api, Ref? ref}) : _api = api, _ref = ref;

  void updatePreference(SttPreference preference) {
    _preference = preference;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (!isSupportedPlatform) return false;
    final deviceTag = WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag();

    if (_isIosSimulator) {
      _localSttAvailable = false;
      _ensureFallbackLocale(deviceTag);
      _isInitialized = true;
      return true;
    }
    // Prepare local speech recognizer
    try {
      // Initialize speech_to_text and check availability
      _localSttAvailable = await _speech.initialize(
        onStatus: _handleSttStatus,
        onError: _handleSttError,
      );
      if (_localSttAvailable) {
        await _loadLocales(deviceTag);
      }
    } catch (_) {
      _localSttAvailable = false;
    }
    _isInitialized = true;
    return true;
  }

  void _handleSttStatus(String status) {
    debugPrint('Local STT Status: $status');
    if (status == 'listening') {
      _localSttActive = true;
    } else if (status == 'notListening' || status == 'done') {
      final wasActive = _localSttActive;
      _localSttActive = false;
      // If we were actively listening and the platform stopped us,
      // properly close the stream so voice call service can restart
      if (wasActive && _isListening && !_usingServerStt) {
        debugPrint('Platform stopped listening, closing stream');
        unawaited(_stopListening());
      }
    }
  }

  void _handleSttError(dynamic error) {
    debugPrint('Local STT Error: $error');
    final errorStr = error.toString().toLowerCase();

    // These errors are non-fatal - they just mean no speech was detected
    // or the session timed out. The status handler will close the stream
    // and voice call service will restart listening.
    final nonFatalErrors = [
      'error_no_match',
      'error_speech_timeout',
      'error_busy', // Temporary, can retry
    ];

    final isNonFatal = nonFatalErrors.any((e) => errorStr.contains(e));
    if (isNonFatal) {
      debugPrint('Non-fatal STT error, allowing normal stream close');
      // Let the status handler / auto-stop timer close the stream.
      // We do not treat this as a fatal failure for the current session.
      return;
    }

    // Fatal errors - mark STT as unavailable
    _handleLocalRecognizerError(error);
  }

  Future<bool> checkPermissions() async {
    final micGranted = await _ensureMicrophonePermission();
    if (!micGranted) {
      return false;
    }
    // Note: Don't disable _localSttAvailable based on hasPermission check
    // The permission might be granted lazily when listen() is called on iOS,
    // and the check can be unreliable. Let speech_to_text handle permissions
    // during the actual listen() call.
    return true;
  }

  bool get isListening => _isListening;
  bool get isAvailable =>
      _isInitialized && (_localSttAvailable || hasServerStt);
  bool get hasLocalStt => _localSttAvailable;
  bool get localeMetadataIncomplete => _usingFallbackLocales;

  /// Checks if on-device STT is properly supported.
  Future<bool> checkOnDeviceSupport() async {
    if (!isSupportedPlatform || !_isInitialized) return false;
    try {
      // speech_to_text isAvailable is set after initialize()
      return _speech.isAvailable;
    } catch (e) {
      // ignore errors checking on-device support
      return false;
    }
  }

  /// Test method to verify on-device STT functionality.
  Future<String> testOnDeviceStt() async {
    try {
      // First ensure we're initialized
      await initialize();

      if (!_localSttAvailable) {
        return 'Local STT not available. Available: $_localSttAvailable';
      }

      // Check microphone permission
      final hasMic = await checkPermissions();
      if (!hasMic) {
        return 'Microphone permission not granted';
      }

      // Test if speech recognition is available
      if (!_speech.isAvailable) {
        return 'Speech recognition service is not available on this device';
      }

      // Start and stop quickly to test
      await _speech.listen(onResult: (_) {}, localeId: _selectedLocaleId);
      await Future.delayed(const Duration(milliseconds: 100));
      await _speech.stop();

      return 'On-device STT test completed successfully. '
          'Local STT available: $_localSttAvailable, '
          'Selected locale: $_selectedLocaleId';
    } catch (e) {
      return 'On-device STT test failed: $e';
    }
  }

  String? get selectedLocaleId => _selectedLocaleId;
  List<LocaleName> get locales => _locales;

  void setLocale(String? localeId) {
    _selectedLocaleId = localeId;
  }

  Future<void> _loadLocales(String deviceTag) async {
    _ensureFallbackLocale(deviceTag);
    try {
      final sttLocales = await Future.value(
        _speech.locales(),
      ).timeout(_localeFetchTimeout, onTimeout: () => const []);
      if (sttLocales.isEmpty) {
        return;
      }
      // Map speech_to_text LocaleName to our own LocaleName class
      _locales = sttLocales
          .map((loc) => LocaleName(loc.localeId, loc.name))
          .toList();
      _usingFallbackLocales = false;
      final match = _matchLocale(deviceTag);
      _selectedLocaleId = match.localeId;
    } catch (_) {
      // Some engines may not support locale listing
    }
  }

  void _ensureFallbackLocale(String deviceTag) {
    if (_locales.isNotEmpty && _selectedLocaleId != null) {
      return;
    }
    _usingFallbackLocales = true;
    if (deviceTag.isEmpty) {
      _locales = const [LocaleName('en_US', 'en_US')];
      _selectedLocaleId = 'en_US';
      return;
    }
    _locales = [LocaleName(deviceTag, deviceTag)];
    _selectedLocaleId = deviceTag;
  }

  LocaleName _matchLocale(String deviceTag) {
    if (_locales.isEmpty) {
      return const LocaleName('en_US', 'en_US');
    }
    final normalizedDevice = deviceTag.toLowerCase();
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase() == normalizedDevice) {
        return locale;
      }
    }
    final parts = normalizedDevice.split(RegExp('[-_]'));
    final primary = parts.isNotEmpty ? parts.first : normalizedDevice;
    for (final locale in _locales) {
      if (locale.localeId.toLowerCase().startsWith('$primary-')) {
        return locale;
      }
    }
    return _locales.first;
  }

  void _handleLocalRecognizerError(Object? error) {
    if (!_isListening) {
      return;
    }
    // Don't permanently disable _localSttAvailable on transient errors
    // The next session should still try local STT
    final message = error?.toString().trim();
    final exception = Exception(
      (message == null || message.isEmpty)
          ? 'Speech recognition failed'
          : message,
    );
    _textStreamController?.addError(exception);
    unawaited(_stopListening());
  }

  Future<bool> _ensureMicrophonePermission() async {
    try {
      return await _microphonePermissionProbe.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> _startLocalRecognition({
    required bool allowOnlineFallback,
  }) async {
    if (_startingLocalStt != null) {
      await _startingLocalStt;
    }
    final completer = Completer<void>();
    _startingLocalStt = completer.future;
    _localSttActive = false;

    // Only reset if there's an active session to avoid startup delay
    if (_speech.isListening) {
      await _ensureLocalSttReset();
      // Give the platform a moment to fully release the audio session
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Use user's configured silence duration for pause detection
    final settings = _ref?.read(appSettingsProvider);
    final pauseDuration = Duration(
      milliseconds: settings?.voiceSilenceDuration ?? 2000,
    );

    try {
      await _speech.listen(
        onResult: _handleSttResult,
        localeId: _selectedLocaleId,
        // Extended duration for voice calls - listen up to 60 seconds
        listenFor: const Duration(seconds: 60),
        // Use user's silence duration setting for pause detection
        pauseFor: pauseDuration,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: false,
        ),
      );
      _localSttActive = true;
    } catch (error) {
      _localSttActive = false;
      await _ensureLocalSttReset();
      rethrow;
    } finally {
      completer.complete();
      _startingLocalStt = null;
    }
  }

  void _handleSttResult(SpeechRecognitionResult result) {
    if (!_isListening) return;
    final prevLen = _currentText.length;
    _currentText = result.recognizedWords;
    _textStreamController?.add(_currentText);
    final delta = (_currentText.length - prevLen).clamp(0, 50);
    final mapped = (delta / 5.0).ceil();
    _lastIntensity = mapped.clamp(0, 10);
    try {
      _intensityController?.add(_lastIntensity);
    } catch (_) {}
    if (result.finalResult) {
      unawaited(_stopListening());
    }
  }

  Future<Stream<String>> startListening() async {
    if (!_isInitialized) {
      throw Exception('Voice input not initialized');
    }

    if (_startingLocalStt != null) {
      try {
        await _startingLocalStt;
      } catch (_) {}
    }

    if (_isListening) {
      await stopListening();
    }

    _textStreamController = StreamController<String>.broadcast();
    _currentText = '';
    _isListening = true;
    _intensityController = StreamController<int>.broadcast();
    _lastIntensity = 0;
    _usingServerStt = false;

    _startIntensityDecayTimer();

    final bool canUseLocal = _localSttAvailable;
    final bool serverAvailable = hasServerStt;
    final bool shouldUseLocal =
        canUseLocal && _preference != SttPreference.serverOnly;
    final bool shouldUseServer =
        serverAvailable &&
        (_preference == SttPreference.serverOnly ||
            (!shouldUseLocal && _preference != SttPreference.deviceOnly));

    if (shouldUseLocal) {
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 60), () {
        if (_isListening) {
          unawaited(_stopListening());
        }
      });
      try {
        if (!_speech.isAvailable && _isListening) {
          _textStreamController?.addError(
            Exception('On-device speech recognition unavailable'),
          );
          await _stopListening();
          return _textStreamController!.stream;
        }
      } catch (_) {
        // ignore availability check errors
      }

      try {
        debugPrint('Starting local recognition...');
        await _startLocalRecognition(allowOnlineFallback: !prefersDeviceOnly);
        debugPrint('Local recognition started');
      } catch (error) {
        debugPrint('Failed to start local recognition: $error');
        if (!_isListening) {
          return _textStreamController!.stream;
        }
        _textStreamController?.addError(error);
        await _stopListening();
      }
    } else if (shouldUseServer) {
      _usingServerStt = true;
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 90), () {
        if (_isListening) {
          unawaited(_stopListening());
        }
      });
      Future(() async {
        try {
          await _startServerRecording();
        } catch (error) {
          if (!_isListening) return;
          _textStreamController?.addError(error);
          await _stopListening();
        }
      });
    } else {
      final Exception error;
      if (prefersDeviceOnly) {
        error = Exception(
          'On-device speech recognition required but unavailable',
        );
      } else if (prefersServerOnly) {
        error = Exception('Server speech-to-text is not configured');
      } else {
        error = Exception('Speech recognition not available on this device');
      }
      Future.microtask(() {
        _textStreamController?.addError(error);
        unawaited(_stopListening());
      });
    }

    return _textStreamController?.stream ?? const Stream<String>.empty();
  }

  /// Centralized entry point to begin voice recognition.
  /// Ensures initialization and microphone permission before starting.
  Future<Stream<String>> beginListening() async {
    await initialize();
    final hasMic = await checkPermissions();
    if (!hasMic) {
      throw Exception('Microphone permission not granted');
    }
    return await startListening();
  }

  Future<void> stopListening() async {
    await _stopListening();
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    _isListening = false;

    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    if (_usingServerStt) {
      await _stopVadRecording();
      final samples = _vadPendingSamples;
      _vadPendingSamples = null;
      if (samples != null && samples.isNotEmpty) {
        await _processVadSamples(samples);
      }
    } else {
      await _stopLocalStt();
      if (_currentText.isNotEmpty) {
        _textStreamController?.add(_currentText);
      }
    }

    _intensityDecayTimer?.cancel();
    _intensityDecayTimer = null;
    _lastIntensity = 0;

    await _closeControllers();

    _usingServerStt = false;
    await _releaseBackgroundMicrophone();
  }

  Future<void> _stopLocalStt() async {
    final pendingStart = _startingLocalStt;
    if (pendingStart != null) {
      try {
        await pendingStart;
      } catch (_) {}
    }

    final shouldStopStt = _localSttActive && _localSttAvailable;
    _localSttActive = false;
    if (shouldStopStt) {
      try {
        await _speech.stop();
      } catch (_) {}
    }
  }

  Future<void> _releaseBackgroundMicrophone() async {
    if (!Platform.isIOS || !_backgroundMicPinned) return;
    _backgroundMicPinned = false;
    try {
      await BackgroundStreamingHandler.instance.stopBackgroundExecution(const [
        _backgroundSttStreamId,
      ]);
    } catch (_) {}
  }

  Future<void> _ensureLocalSttReset() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> _startServerRecording() async {
    await _setupVadStreams();
    final settings = _ref?.read(appSettingsProvider);
    final silenceMs = settings?.voiceSilenceDuration ?? 2000;
    final redemptionFrames = _silenceDurationToFrames(
      silenceMs,
      frameSamples: _vadFrameSamples,
    );

    try {
      await _vadHandler.startListening(
        frameSamples: _vadFrameSamples,
        model: 'v5',
        minSpeechFrames: _vadMinSpeechFrames,
        preSpeechPadFrames: _vadPreSpeechPadFrames,
        redemptionFrames: redemptionFrames,
        endSpeechPadFrames: _vadEndSpeechPadFrames,
        positiveSpeechThreshold: _vadPositiveSpeechThreshold,
        negativeSpeechThreshold: _vadNegativeSpeechThreshold,
        submitUserSpeechOnPause: true,
        recordConfig: const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _vadSampleRate,
          numChannels: 1,
          bitRate: 16,
          echoCancel: true,
          autoGain: false,
          noiseSuppress: true,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition,
            audioManagerMode: AudioManagerMode.modeInCommunication,
            speakerphone: true,
            manageBluetooth: true,
            useLegacy: false,
          ),
        ),
      );
    } catch (error) {
      _textStreamController?.addError(error);
      rethrow;
    }
  }

  Future<void> _setupVadStreams() async {
    await _vadSpeechEndSub?.cancel();
    _vadSpeechEndSub = _vadHandler.onSpeechEnd.listen((samples) {
      if (!_isListening || !_usingServerStt) return;
      if (samples.isEmpty) return;
      _vadPendingSamples = samples;
      if (_isListening) {
        unawaited(_stopListening());
      }
    });

    await _vadFrameSub?.cancel();
    _vadFrameSub = _vadHandler.onFrameProcessed.listen((frameData) {
      if (!_isListening) return;
      final intensity = _intensityFromVadFrame(frameData.frame);
      _lastIntensity = intensity;
      try {
        _intensityController?.add(_lastIntensity);
      } catch (_) {}
    });

    await _vadErrorSub?.cancel();
    _vadErrorSub = _vadHandler.onError.listen((message) {
      _textStreamController?.addError(Exception(message));
      if (_isListening) {
        unawaited(_stopListening());
      }
    });
  }

  Future<void> _stopVadRecording() async {
    try {
      await _vadHandler.stopListening();
    } catch (_) {}
    await _vadSpeechEndSub?.cancel();
    _vadSpeechEndSub = null;
    await _vadFrameSub?.cancel();
    _vadFrameSub = null;
    await _vadErrorSub?.cancel();
    _vadErrorSub = null;
  }

  Future<void> _processVadSamples(List<double> samples) async {
    final api = _api;
    if (api == null) return;

    try {
      final wavBytes = _samplesToWav(samples);
      final fileName =
          'conduit_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      final response = await api.transcribeSpeech(
        audioBytes: wavBytes,
        fileName: fileName,
        mimeType: 'audio/wav',
        language: _languageForServer(),
      );

      final transcript = _extractTranscriptionText(response);
      if (transcript != null && transcript.trim().isNotEmpty) {
        _currentText = transcript.trim();
        _textStreamController?.add(_currentText);
      } else {
        throw StateError('Empty transcription result');
      }
    } catch (error) {
      _textStreamController?.addError(error);
    }
  }

  int _silenceDurationToFrames(int milliseconds, {int? frameSamples}) {
    final samples = frameSamples ?? _vadFrameSamples;
    final frameDurationMs = (samples / _vadSampleRate) * 1000;
    final frames = (milliseconds / frameDurationMs).round();
    return frames.clamp(4, 50);
  }

  int _intensityFromVadFrame(List<double> frame) {
    if (frame.isEmpty) return 0;
    double peak = 0;
    for (final sample in frame) {
      final value = sample.abs();
      if (value > peak) {
        peak = value;
      }
    }
    final scaled = (peak * 12).round();
    return scaled.clamp(0, 10);
  }

  Uint8List _samplesToWav(List<double> samples) {
    if (samples.isEmpty) {
      return Uint8List(0);
    }
    final dataLength = samples.length * 2; // 2 bytes per sample (16-bit)
    final bytesPerSample = 2;
    final numChannels = 1;
    final byteRate = _vadSampleRate * numChannels * bytesPerSample;
    final blockAlign = numChannels * bytesPerSample;
    const headerSize = 44;

    final totalSize = headerSize + dataLength;
    final buffer = Uint8List(totalSize);
    final view = ByteData.view(buffer.buffer);

    // RIFF chunk
    buffer.setRange(0, 4, ascii.encode('RIFF'));
    view.setUint32(4, 36 + dataLength, Endian.little);
    buffer.setRange(8, 12, ascii.encode('WAVE'));

    // fmt chunk
    buffer.setRange(12, 16, ascii.encode('fmt '));
    view.setUint32(16, 16, Endian.little); // PCM chunk size
    view.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    view.setUint16(22, numChannels, Endian.little);
    view.setUint32(24, _vadSampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, 16, Endian.little); // BitsPerSample

    // data chunk
    buffer.setRange(36, 40, ascii.encode('data'));
    view.setUint32(40, dataLength, Endian.little);

    // Write samples
    var offset = 44;
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      // Convert float to 16-bit PCM
      final pcm = (clamped * 32767).round().clamp(-32768, 32767);
      view.setInt16(offset, pcm, Endian.little);
      offset += 2;
    }

    return buffer;
  }

  String? _languageForServer() {
    final locale = _selectedLocaleId;
    if (locale != null && locale.isNotEmpty) {
      final primary = locale.split(RegExp('[-_]')).first.toLowerCase();
      if (primary.length >= 2) {
        return primary;
      }
    }
    try {
      final fallback = WidgetsBinding.instance.platformDispatcher.locale;
      final primary = fallback.languageCode.toLowerCase();
      if (primary.isNotEmpty) {
        return primary;
      }
    } catch (_) {}
    return null;
  }

  String? _extractTranscriptionText(Map<String, dynamic> data) {
    final direct = data['text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final display = data['display_text'] ?? data['DisplayText'];
    if (display is String && display.trim().isNotEmpty) {
      return display;
    }

    final result = data['result'];
    if (result is Map<String, dynamic>) {
      final resultText = result['text'];
      if (resultText is String && resultText.trim().isNotEmpty) {
        return resultText;
      }
    }

    final combined = data['combinedRecognizedPhrases'];
    if (combined is List && combined.isNotEmpty) {
      final first = combined.first;
      if (first is Map<String, dynamic>) {
        final candidate =
            first['display'] ??
            first['Display'] ??
            first['transcript'] ??
            first['text'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate;
        }
      } else if (first is String && first.trim().isNotEmpty) {
        return first;
      }
    }

    final results = data['results'];
    if (results is Map<String, dynamic>) {
      final channels = results['channels'];
      if (channels is List && channels.isNotEmpty) {
        final channel = channels.first;
        if (channel is Map<String, dynamic>) {
          final alternatives = channel['alternatives'];
          if (alternatives is List && alternatives.isNotEmpty) {
            final alternative = alternatives.first;
            if (alternative is Map<String, dynamic>) {
              final transcript =
                  alternative['transcript'] ?? alternative['text'];
              if (transcript is String && transcript.trim().isNotEmpty) {
                return transcript;
              }
            }
          }
        }
      }
    }

    final segments = data['segments'];
    if (segments is List && segments.isNotEmpty) {
      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is Map<String, dynamic>) {
          final text = segment['text'];
          if (text is String && text.trim().isNotEmpty) {
            buffer.write(text.trim());
            buffer.write(' ');
          }
        } else if (segment is String && segment.trim().isNotEmpty) {
          buffer.write(segment.trim());
          buffer.write(' ');
        }
      }
      final combinedText = buffer.toString().trim();
      if (combinedText.isNotEmpty) {
        return combinedText;
      }
    }

    return null;
  }

  Future<void> _closeControllers() async {
    if (_textStreamController != null) {
      try {
        await _textStreamController?.close();
      } catch (_) {}
      _textStreamController = null;
    }
    if (_intensityController != null) {
      try {
        await _intensityController?.close();
      } catch (_) {}
      _intensityController = null;
    }
  }

  void _startIntensityDecayTimer() {
    _intensityDecayTimer?.cancel();
    _intensityDecayTimer = Timer.periodic(const Duration(milliseconds: 120), (
      _,
    ) {
      if (!_isListening) return;
      if (_lastIntensity <= 0) return;
      _lastIntensity = (_lastIntensity - 1).clamp(0, 10);
      try {
        _intensityController?.add(_lastIntensity);
      } catch (_) {}
    });
  }

  void dispose() {
    stopListening();
    unawaited(_vadHandler.dispose());
    unawaited(_microphonePermissionProbe.dispose());
    try {
      _speech.stop();
    } catch (_) {}
  }
}

final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final service = VoiceInputService(api: api, ref: ref);
  final currentSettings = ref.read(appSettingsProvider);
  service.updatePreference(currentSettings.sttPreference);
  ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
    if (previous?.sttPreference != next.sttPreference) {
      service.updatePreference(next.sttPreference);
    }
  });
  ref.onDispose(service.dispose);
  return service;
});

@Riverpod(keepAlive: true)
Future<bool> voiceInputAvailable(Ref ref) async {
  final service = ref.watch(voiceInputServiceProvider);
  if (!service.isSupportedPlatform) return false;
  final initialized = await service.initialize();
  if (!initialized) return false;
  switch (service.preference) {
    case SttPreference.deviceOnly:
      if (service.hasLocalStt) return true;
      if (!service.hasServerStt) return false;
      break;
    case SttPreference.serverOnly:
      return service.hasServerStt;
  }
  final hasPermission = await service.checkPermissions();
  if (!hasPermission) return false;
  return service.isAvailable;
}

final voiceInputStreamProvider = StreamProvider<String>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return service.textStream;
});

/// Stream of crude voice intensity for waveform visuals
final voiceIntensityStreamProvider = StreamProvider<int>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return service.intensityStream;
});

final localVoiceRecognitionAvailableProvider = FutureProvider<bool>((
  ref,
) async {
  final service = ref.watch(voiceInputServiceProvider);
  final initialized = await service.initialize();
  if (!initialized) return false;
  if (service.hasLocalStt) return true;
  return service.checkOnDeviceSupport();
});

final serverVoiceRecognitionAvailableProvider = Provider<bool>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return service.hasServerStt;
});
