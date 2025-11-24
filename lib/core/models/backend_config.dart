import 'package:flutter/foundation.dart';

/// Subset of the backend `/api/config` response the app cares about.
@immutable
class BackendConfig {
  const BackendConfig({
    this.enableWebsocket,
    this.enableAudioInput,
    this.enableAudioOutput,
    this.sttProvider,
    this.ttsProvider,
    this.ttsVoice,
    this.defaultSttLocale,
    this.audioSampleRate,
    this.audioFrameSize,
    this.vadEnabled,
  });

  /// Mirrors `features.enable_websocket` from OpenWebUI.
  final bool? enableWebsocket;
  final bool? enableAudioInput;
  final bool? enableAudioOutput;
  final String? sttProvider;
  final String? ttsProvider;
  final String? ttsVoice;
  final String? defaultSttLocale;
  final int? audioSampleRate;
  final int? audioFrameSize;
  final bool? vadEnabled;

  /// Returns a copy with updated fields.
  BackendConfig copyWith({
    bool? enableWebsocket,
    bool? enableAudioInput,
    bool? enableAudioOutput,
    String? sttProvider,
    String? ttsProvider,
    String? ttsVoice,
    String? defaultSttLocale,
    int? audioSampleRate,
    int? audioFrameSize,
    bool? vadEnabled,
  }) {
    return BackendConfig(
      enableWebsocket: enableWebsocket ?? this.enableWebsocket,
      enableAudioInput: enableAudioInput ?? this.enableAudioInput,
      enableAudioOutput: enableAudioOutput ?? this.enableAudioOutput,
      sttProvider: sttProvider ?? this.sttProvider,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      defaultSttLocale: defaultSttLocale ?? this.defaultSttLocale,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioFrameSize: audioFrameSize ?? this.audioFrameSize,
      vadEnabled: vadEnabled ?? this.vadEnabled,
    );
  }

  /// Whether the backend only allows WebSocket transport.
  bool get websocketOnly => enableWebsocket == true;

  /// Whether the backend only allows HTTP polling transport.
  bool get pollingOnly => enableWebsocket == false;

  /// Whether the backend permits choosing WebSocket-only mode.
  bool get supportsWebsocketOnly => !pollingOnly;

  /// Whether the backend permits choosing polling fallback.
  bool get supportsPolling => !websocketOnly;

  /// Returns the enforced transport mode derived from backend policy.
  String? get enforcedTransportMode {
    if (websocketOnly) return 'ws';
    if (pollingOnly) return 'polling';
    return null;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enable_websocket': enableWebsocket,
      'enable_audio_input': enableAudioInput,
      'enable_audio_output': enableAudioOutput,
      'stt_provider': sttProvider,
      'tts_provider': ttsProvider,
      'tts_voice': ttsVoice,
      'default_stt_locale': defaultSttLocale,
      'audio_sample_rate': audioSampleRate,
      'audio_frame_size': audioFrameSize,
      'vad_enabled': vadEnabled,
    };
  }

  static BackendConfig fromJson(Map<String, dynamic> json) {
    bool? enableWebsocket;
    bool? enableAudioInput;
    bool? enableAudioOutput;
    String? sttProvider;
    String? ttsProvider;
    String? ttsVoice;
    String? defaultSttLocale;
    int? audioSampleRate;
    int? audioFrameSize;
    bool? vadEnabled;
    // Try canonical format first
    final value = json['enable_websocket'];
    if (value is bool) {
      enableWebsocket = value;
    }

    final audioIn = json['enable_audio_input'];
    if (audioIn is bool) enableAudioInput = audioIn;
    final audioOut = json['enable_audio_output'];
    if (audioOut is bool) enableAudioOutput = audioOut;

    final stt = json['stt_provider'];
    if (stt is String) sttProvider = stt;
    final tts = json['tts_provider'];
    if (tts is String) ttsProvider = tts;
    final ttsVoiceValue = json['tts_voice'];
    if (ttsVoiceValue is String) ttsVoice = ttsVoiceValue;

    final defaultLocale = json['default_stt_locale'];
    if (defaultLocale is String) defaultSttLocale = defaultLocale;

    final sampleRate = json['audio_sample_rate'];
    if (sampleRate is int) audioSampleRate = sampleRate;
    final frameSize = json['audio_frame_size'];
    if (frameSize is int) audioFrameSize = frameSize;

    final vad = json['vad_enabled'];
    if (vad is bool) vadEnabled = vad;

    // Fallback to nested format for backwards compatibility
    final features = json['features'];
    if (features is Map<String, dynamic>) {
      final nestedValue = features['enable_websocket'];
      if (nestedValue is bool && enableWebsocket == null) {
        enableWebsocket = nestedValue;
      }
      final nestedAudioIn = features['enable_audio_input'];
      if (nestedAudioIn is bool && enableAudioInput == null) {
        enableAudioInput = nestedAudioIn;
      }
      final nestedAudioOut = features['enable_audio_output'];
      if (nestedAudioOut is bool && enableAudioOutput == null) {
        enableAudioOutput = nestedAudioOut;
      }
      final nestedStt = features['stt_provider'];
      if (nestedStt is String && sttProvider == null) {
        sttProvider = nestedStt;
      }
      final nestedTts = features['tts_provider'];
      if (nestedTts is String && ttsProvider == null) {
        ttsProvider = nestedTts;
      }
      final nestedVoice = features['tts_voice'];
      if (nestedVoice is String && ttsVoice == null) {
        ttsVoice = nestedVoice;
      }
      final nestedLocale = features['default_stt_locale'];
      if (nestedLocale is String && defaultSttLocale == null) {
        defaultSttLocale = nestedLocale;
      }
      final nestedSample = features['audio_sample_rate'];
      if (nestedSample is int && audioSampleRate == null) {
        audioSampleRate = nestedSample;
      }
      final nestedFrame = features['audio_frame_size'];
      if (nestedFrame is int && audioFrameSize == null) {
        audioFrameSize = nestedFrame;
      }
      final nestedVad = features['vad_enabled'];
      if (nestedVad is bool && vadEnabled == null) {
        vadEnabled = nestedVad;
      }
    }

    return BackendConfig(
      enableWebsocket: enableWebsocket,
      enableAudioInput: enableAudioInput,
      enableAudioOutput: enableAudioOutput,
      sttProvider: sttProvider,
      ttsProvider: ttsProvider,
      ttsVoice: ttsVoice,
      defaultSttLocale: defaultSttLocale,
      audioSampleRate: audioSampleRate,
      audioFrameSize: audioFrameSize,
      vadEnabled: vadEnabled,
    );
  }
}
