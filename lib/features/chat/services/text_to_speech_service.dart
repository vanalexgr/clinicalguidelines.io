import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/settings_service.dart';

/// Lightweight wrapper around FlutterTts to centralize configuration
class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final ApiService? _api;
  TtsEngine _engine = TtsEngine.device;
  String? _preferredVoice;
  bool _initialized = false;
  bool _available = false;
  bool _voiceConfigured = false;
  int _session = 0; // increments to cancel in-flight work
  final List<Uint8List> _buffered = <Uint8List>[]; // server chunks
  int _expectedChunks = 0;
  int _currentIndex = -1;
  bool _waitingNext = false;
  String? _serverDefaultVoice;
  Future<String?>? _serverDefaultVoiceFuture;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  VoidCallback? _onCancel;
  VoidCallback? _onPause;
  VoidCallback? _onContinue;
  void Function(String message)? _onError;
  void Function(int sentenceIndex)? _onSentenceIndex;
  void Function(int start, int end)? _onDeviceWordProgress;

  bool get isInitialized => _initialized;
  bool get isAvailable => _available;

  TextToSpeechService({ApiService? api}) : _api = api {
    // Wire minimal player events to callbacks
    _player.onPlayerComplete.listen((_) => _onAudioComplete());
    _player.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.playing) _handleStart();
    });
  }

  /// Register callbacks for TTS lifecycle events
  void bindHandlers({
    VoidCallback? onStart,
    VoidCallback? onComplete,
    VoidCallback? onCancel,
    VoidCallback? onPause,
    VoidCallback? onContinue,
    void Function(String message)? onError,
    void Function(int sentenceIndex)? onSentenceIndex,
    void Function(int start, int end)? onDeviceWordProgress,
  }) {
    _onStart = onStart;
    _onComplete = onComplete;
    _onCancel = onCancel;
    _onPause = onPause;
    _onContinue = onContinue;
    _onError = onError;
    _onSentenceIndex = onSentenceIndex;
    _onDeviceWordProgress = onDeviceWordProgress;

    _tts.setStartHandler(_handleStart);
    _tts.setCompletionHandler(_handleComplete);
    _tts.setCancelHandler(_handleCancel);
    _tts.setPauseHandler(_handlePause);
    _tts.setContinueHandler(_handleContinue);
    _tts.setErrorHandler(_handleError);
    try {
      _tts.setProgressHandler((String text, int start, int end, String word) {
        _onDeviceWordProgress?.call(start, end);
      });
    } catch (_) {
      // Some platforms may not support progress handler
    }
  }

  /// Initialize the native TTS engine lazily
  Future<bool> initialize({
    String? voice,
    double speechRate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    TtsEngine engine = TtsEngine.device,
  }) async {
    if (_initialized) {
      return _available;
    }

    try {
      _engine = engine;
      _preferredVoice = voice;
      await _tts.awaitSpeakCompletion(false);

      // Set volume
      await _tts.setVolume(volume);

      // Set speech rate
      await _tts.setSpeechRate(speechRate);

      // Set pitch
      await _tts.setPitch(pitch);

      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ]);
      }

      // Set the voice (specific or default)
      await _setVoiceByName(voice);
      _available = true;
    } catch (e) {
      _available = false;
      _onError?.call(e.toString());
    }

    _initialized = true;
    return _available;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Cannot speak empty text');
    }

    if (!_initialized) {
      await initialize(voice: _preferredVoice, engine: _engine);
    }

    if (_engine == TtsEngine.server && _api != null) {
      // Server-backed TTS with sentence chunking & queued playback
      try {
        await _startServerChunkedPlayback(text);
      } catch (e) {
        _onError?.call(e.toString());
        await _speakOnDevice(text);
      }
      return;
    }

    // Device TTS path
    await _speakOnDevice(text);
  }

  Future<void> _speakOnDevice(String text) async {
    if (!_available) {
      throw StateError('Text-to-speech is unavailable on this device');
    }
    await _tts.stop();
    if (!_voiceConfigured) {
      await _configurePreferredVoice();
    }
    final result = await _tts.speak(text);
    if (result is int && result != 1) {
      _onError?.call('Text-to-speech engine returned code $result');
    }
    _onSentenceIndex?.call(0);
  }

  Future<void> pause() async {
    if (!_initialized) return;
    try {
      if (_engine == TtsEngine.server) {
        await _player.pause();
      } else if (_available) {
        await _tts.pause();
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    if (!_initialized) {
      return;
    }

    try {
      // Cancel any in-flight server work
      _session++;
      _buffered.clear();
      _expectedChunks = 0;
      _currentIndex = -1;
      _waitingNext = false;
      if (_engine == TtsEngine.server) {
        await _player.stop();
      } else {
        await _tts.stop();
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  /// Update TTS settings on-the-fly
  Future<void> updateSettings({
    Object? voice = const _VoiceNotProvided(),
    double? speechRate,
    double? pitch,
    double? volume,
    TtsEngine? engine,
  }) async {
    final voiceProvided = voice is! _VoiceNotProvided;
    final voiceValue = voiceProvided ? voice as String? : null;
    if (!_initialized || !_available) {
      // Allow engine and voice to update before init
      if (engine != null) _engine = engine;
      if (voiceProvided) _preferredVoice = voiceValue;
      return;
    }

    try {
      if (engine != null) {
        _engine = engine;
      }
      if (voiceProvided) {
        _preferredVoice = voiceValue;
      }
      if (volume != null) {
        await _tts.setVolume(volume);
      }
      if (speechRate != null) {
        await _tts.setSpeechRate(speechRate);
      }
      if (pitch != null) {
        await _tts.setPitch(pitch);
      }
      // Set specific voice by name on device engine
      if (_engine == TtsEngine.device && voiceProvided) {
        await _setVoiceByName(_preferredVoice);
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  /// Set voice by name, or use system default if null
  Future<void> _setVoiceByName(String? voiceName) async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return;
    }

    try {
      if (voiceName == null) {
        // Use system default - reset voice configuration
        _voiceConfigured = false;
        await _configurePreferredVoice();
        return;
      }

      // Get all available voices
      final voicesRaw = await _tts.getVoices;
      if (voicesRaw is! List) {
        return;
      }

      // Find the voice by name
      Map<String, dynamic>? targetVoice;
      for (final entry in voicesRaw) {
        if (entry is Map) {
          final normalized = _normalizeVoiceEntry(entry);
          final name = normalized['name'] as String?;
          if (name == voiceName) {
            targetVoice = normalized;
            break;
          }
        }
      }

      // Set the voice if found
      if (targetVoice != null) {
        await _tts.setVoice(_voiceCommandFrom(targetVoice));
        _voiceConfigured = true;
      } else {
        // Voice not found, fall back to default
        _voiceConfigured = false;
        await _configurePreferredVoice();
      }
    } catch (e) {
      _onError?.call(e.toString());
    }
  }

  /// Get available voices from the TTS engine
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    if (!_initialized) {
      await initialize(voice: _preferredVoice, engine: _engine);
    }

    if (_engine == TtsEngine.server && _api != null) {
      try {
        final serverVoices = await _api.getAvailableServerVoices();
        final mapped = serverVoices
            .map((v) {
              final id = (v['id'] ?? v['name'] ?? '').toString();
              final name = (v['name'] ?? v['id'] ?? '').toString();
              final localeValue = (v['locale'] ?? v['language'] ?? '')
                  .toString();
              return {'id': id, 'name': name, 'locale': localeValue};
            })
            .where((entry) {
              final name = entry['name'];
              return name is String && name.trim().isNotEmpty;
            })
            .toList();

        final defaultVoice = await _getServerDefaultVoice();
        if (defaultVoice != null && defaultVoice.isNotEmpty) {
          final normalized = defaultVoice.toLowerCase();
          final exists = mapped.any((voice) {
            final name = voice['name'];
            final id = voice['id'];
            final lowerName = name is String ? name.toLowerCase() : '';
            final lowerId = id is String ? id.toLowerCase() : '';
            return lowerName == normalized || lowerId == normalized;
          });
          if (!exists) {
            mapped.insert(0, {
              'id': defaultVoice,
              'name': defaultVoice,
              'locale': '',
            });
          }
        }

        if (mapped.isEmpty) {
          if (defaultVoice != null && defaultVoice.isNotEmpty) {
            return [
              {'id': defaultVoice, 'name': defaultVoice, 'locale': ''},
            ];
          }
          return const [];
        }
        return mapped;
      } catch (e) {
        _onError?.call(e.toString());
        // Fall back to device voices
      }
    }

    if (!_available) {
      return [];
    }

    try {
      final voicesRaw = await _tts.getVoices;
      if (voicesRaw is! List) {
        return [];
      }

      final parsedVoices = <Map<String, dynamic>>[];
      for (final entry in voicesRaw) {
        if (entry is Map) {
          final normalized = _normalizeVoiceEntry(entry);
          if (normalized.isNotEmpty) {
            parsedVoices.add(normalized);
          }
        }
      }

      return parsedVoices;
    } catch (e) {
      _onError?.call(e.toString());
      return [];
    }
  }

  Future<String?> _resolveServerVoice() async {
    final selected = _preferredVoice?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    final configVoice = await _getServerDefaultVoice();
    if (configVoice != null && configVoice.isNotEmpty) {
      return configVoice;
    }
    return null;
  }

  Future<String?> _getServerDefaultVoice() async {
    if (_api == null) {
      return null;
    }
    if (_serverDefaultVoice != null) {
      return _serverDefaultVoice;
    }
    final pending = _serverDefaultVoiceFuture;
    if (pending != null) {
      return pending;
    }

    final future = _api.getDefaultServerVoice();
    _serverDefaultVoiceFuture = future;

    try {
      final voice = await future;
      final trimmed = voice?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        _serverDefaultVoice = trimmed;
        return _serverDefaultVoice;
      }
      return null;
    } catch (e) {
      _onError?.call(e.toString());
      return null;
    } finally {
      _serverDefaultVoiceFuture = null;
    }
  }

  // ===== Server chunked playback =====

  Future<void> _startServerChunkedPlayback(String text) async {
    final resolvedVoice = await _resolveServerVoice();
    final effectiveVoice = resolvedVoice;

    // Reset queue and create a new session
    _session++;
    final session = _session;
    _buffered.clear();
    _expectedChunks = 0;
    _currentIndex = -1;
    _waitingNext = false;

    final chunks = _splitForTts(text);
    if (chunks.isEmpty) return;
    _expectedChunks = chunks.length;

    // Fetch first chunk to start playback quickly
    final firstBytes = await _fetchServerAudio(
      chunks.first,
      effectiveVoice,
      session,
    );
    if (session != _session) return; // canceled
    if (firstBytes.isEmpty) throw Exception('Empty audio response');

    await _player.stop();
    _buffered.add(Uint8List.fromList(firstBytes));
    _currentIndex = 0;
    await _player.play(BytesSource(_buffered.first));
    _onSentenceIndex?.call(0);

    // Prefetch the rest in background
    unawaited(
      _prefetchRemainingChunks(
        chunks.skip(1).toList(),
        effectiveVoice,
        session,
      ),
    );
  }

  Future<void> _prefetchRemainingChunks(
    List<String> remaining,
    String? voice,
    int session,
  ) async {
    for (final chunk in remaining) {
      if (session != _session) return; // canceled
      try {
        final audio = await _fetchServerAudio(chunk, voice, session);
        if (session != _session) return;
        if (audio.isNotEmpty) {
          _buffered.add(Uint8List.fromList(audio));
          // If the player finished the previous chunk and is waiting, start now
          if (_waitingNext && (_currentIndex + 1) < _buffered.length) {
            _waitingNext = false;
            await _playNextIfBuffered(session);
          }
        }
      } catch (e) {
        _onError?.call(e.toString());
        // continue with other chunks
      }
    }
  }

  Future<List<int>> _fetchServerAudio(
    String text,
    String? voice,
    int session,
  ) async {
    return await _api!.generateSpeech(text: text, voice: voice);
  }

  Future<void> _onAudioComplete() async {
    final session = _session;
    // If there are more expected chunks
    if ((_currentIndex + 1) < _expectedChunks) {
      // If next chunk is already buffered, play it
      if ((_currentIndex + 1) < _buffered.length) {
        await _playNextIfBuffered(session);
      } else {
        // Wait for prefetch to provide it
        _waitingNext = true;
      }
      return;
    }
    // No more chunks – this is the real completion
    _handleComplete();
  }

  Future<void> _playNextIfBuffered(int session) async {
    if (session != _session) return;
    final nextIndex = _currentIndex + 1;
    if (nextIndex < 0 || nextIndex >= _buffered.length) return;
    _currentIndex = nextIndex;
    final bytes = _buffered[nextIndex];
    await _player.play(BytesSource(bytes));
    _onSentenceIndex?.call(_currentIndex);
  }

  List<String> _splitForTts(String text) {
    // Normalize whitespace
    final normalized = text.replaceAll(RegExp(r"\s+"), ' ').trim();
    if (normalized.isEmpty) return const [];

    // Split on sentence-ending punctuation while keeping the delimiter
    final parts = <String>[];
    final sentenceRegex = RegExp(r"(.+?[\.!?]+)(\s+|\$)");
    int index = 0;
    for (final match in sentenceRegex.allMatches('$normalized ')) {
      final s = match.group(1) ?? '';
      if (s.trim().isNotEmpty) parts.add(s.trim());
      index = match.end;
    }
    if (index < normalized.length) {
      final tail = normalized.substring(index).trim();
      if (tail.isNotEmpty) parts.add(tail);
    }

    // Fallback to length-based splits for very long segments
    const maxLen = 300;
    final chunks = <String>[];
    for (final p in parts.isEmpty ? [normalized] : parts) {
      if (p.length <= maxLen) {
        chunks.add(p);
      } else {
        // Try splitting on commas/spaces
        var remaining = p;
        while (remaining.length > maxLen) {
          int cut = remaining.lastIndexOf(RegExp(r",\s|\s"), maxLen);
          cut = cut <= 0 ? maxLen : cut;
          chunks.add(remaining.substring(0, cut).trim());
          remaining = remaining.substring(cut).trim();
        }
        if (remaining.isNotEmpty) chunks.add(remaining);
      }
    }
    return chunks;
  }

  Future<void> _configurePreferredVoice() async {
    if (_voiceConfigured) {
      return;
    }
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      _voiceConfigured = true;
      return;
    }

    var configured = false;
    try {
      Map<String, dynamic>? defaultVoice;
      bool voiceSet = false;

      if (Platform.isIOS) {
        try {
          final rawDefault = await _tts.getDefaultVoice;
          if (rawDefault is Map) {
            defaultVoice = _normalizeVoiceEntry(rawDefault);
            await _tts.setVoice(_voiceCommandFrom(defaultVoice));
            configured = true;
            voiceSet = true;
          }
        } catch (_) {
          defaultVoice = null;
        }
      }

      if (voiceSet) {
        return;
      }

      final voicesRaw = await _tts.getVoices;
      if (voicesRaw is! List) {
        return;
      }

      final parsedVoices = <Map<String, dynamic>>[];
      for (final entry in voicesRaw) {
        if (entry is Map) {
          final normalized = _normalizeVoiceEntry(entry);
          if (normalized.isNotEmpty) {
            parsedVoices.add(normalized);
          }
        }
      }

      if (parsedVoices.isEmpty) {
        return;
      }

      final localeTag = WidgetsBinding.instance.platformDispatcher.locale
          .toLanguageTag()
          .toLowerCase();
      final preferred = _selectPreferredVoice(
        parsedVoices,
        localeTag,
        defaultVoice: defaultVoice,
      );
      if (preferred == null) {
        if (Platform.isIOS) {
          configured = true; // Allow system default voice to be used
        }
        return;
      }

      await _tts.setVoice(_voiceCommandFrom(preferred));
      configured = true;
    } catch (e) {
      _onError?.call(e.toString());
    } finally {
      _voiceConfigured = configured || _voiceConfigured;
    }
  }

  Map<String, dynamic> _normalizeVoiceEntry(Map<dynamic, dynamic> entry) {
    final normalized = <String, dynamic>{};
    entry.forEach((key, value) {
      if (key != null) {
        normalized[key.toString()] = value;
      }
    });
    return normalized;
  }

  Map<String, String> _voiceCommandFrom(Map<String, dynamic> voice) {
    final command = <String, String>{};
    for (final key in [
      'name',
      'locale',
      'identifier',
      'id',
      'voiceIdentifier',
      'engine',
    ]) {
      final value = voice[key];
      if (value != null) {
        command[key] = value.toString();
      }
    }
    if (!command.containsKey('name') && voice['name'] != null) {
      command['name'] = voice['name'].toString();
    }
    if (!command.containsKey('locale') && voice['locale'] != null) {
      command['locale'] = voice['locale'].toString();
    }
    return command;
  }

  int _iosVoiceScore(Map<String, dynamic> voice) {
    final identifier =
        voice['identifier']?.toString().toLowerCase() ??
        voice['id']?.toString().toLowerCase() ??
        '';
    final name = voice['name']?.toString().toLowerCase() ?? '';

    int score = 0;
    if (identifier.contains('premium')) {
      score += 400;
    } else if (identifier.contains('enhanced')) {
      score += 250;
    } else if (identifier.contains('compact')) {
      score += 50;
    }

    if (identifier.contains('siri') || name.contains('siri')) {
      score += 150;
    }

    if (identifier.contains('female') || name.contains('female')) {
      score += 15;
    }
    if (identifier.contains('male') || name.contains('male')) {
      score += 10;
    }

    // Prefer non-compact by default when no other hints are present
    if (!identifier.contains('compact')) {
      score += 25;
    }

    return score;
  }

  Map<String, dynamic>? _selectPreferredVoice(
    List<Map<String, dynamic>> voices,
    String localeTag, {
    Map<String, dynamic>? defaultVoice,
  }) {
    Map<String, dynamic>? matchesLocale(Iterable<Map<String, dynamic>> input) {
      for (final voice in input) {
        final locale = voice['locale']?.toString().toLowerCase();
        if (locale == null) continue;
        if (locale == localeTag) {
          return voice;
        }
        final localePrimary = locale.split(RegExp('[-_]')).first;
        final tagPrimary = localeTag.split(RegExp('[-_]')).first;
        if (localePrimary == tagPrimary) {
          return voice;
        }
      }
      return null;
    }

    Map<String, dynamic>? matchDefaultVoice() {
      final dv = defaultVoice;
      if (dv == null) {
        return null;
      }

      final identifiers = <String>{};
      for (final key in ['identifier', 'id', 'voiceIdentifier', 'voice']) {
        final value = dv[key]?.toString();
        if (value != null && value.isNotEmpty) {
          identifiers.add(value.toLowerCase());
        }
      }

      if (identifiers.isNotEmpty) {
        for (final voice in voices) {
          for (final key in ['identifier', 'id', 'voiceIdentifier', 'voice']) {
            final value = voice[key]?.toString();
            if (value != null && identifiers.contains(value.toLowerCase())) {
              return voice;
            }
          }
        }
      }

      final defaultName = dv['name']?.toString();
      final defaultLocale = dv['locale']?.toString();
      if (defaultName != null && defaultLocale != null) {
        final lowerName = defaultName.toLowerCase();
        final lowerLocale = defaultLocale.toLowerCase();
        for (final voice in voices) {
          final name = voice['name']?.toString();
          final locale = voice['locale']?.toString();
          if (name != null &&
              locale != null &&
              name.toLowerCase() == lowerName &&
              locale.toLowerCase() == lowerLocale) {
            return voice;
          }
        }
      }

      return null;
    }

    Map<String, dynamic>? pickIosVoice() {
      final userDefault = matchDefaultVoice();
      if (userDefault != null) {
        return userDefault;
      }

      final siriCandidates = voices.where((voice) {
        final name = voice['name']?.toString().toLowerCase() ?? '';
        final identifier = voice['identifier']?.toString().toLowerCase() ?? '';
        final voiceId = voice['id']?.toString().toLowerCase() ?? '';
        return name.contains('siri') ||
            identifier.contains('siri') ||
            voiceId.contains('siri');
      }).toList();

      if (siriCandidates.isNotEmpty) {
        siriCandidates.sort((a, b) => _iosVoiceScore(b) - _iosVoiceScore(a));
        final localeMatch = matchesLocale(siriCandidates);
        if (localeMatch != null) {
          return localeMatch;
        }
        return siriCandidates.first;
      }

      final ranked = [...voices];
      ranked.sort((a, b) => _iosVoiceScore(b) - _iosVoiceScore(a));
      final localeMatch = matchesLocale(ranked);
      if (localeMatch != null) {
        return localeMatch;
      }
      return ranked.isNotEmpty ? ranked.first : null;
    }

    Map<String, dynamic>? pickAndroidVoice() {
      int qualityScore(String? quality) {
        switch ((quality ?? '').toLowerCase()) {
          case 'very_high':
          case 'very-high':
            return 3;
          case 'high':
            return 2;
          case 'normal':
            return 1;
          default:
            return 0;
        }
      }

      final preferredEngineVoices = voices
          .where(
            (voice) =>
                (voice['engine']?.toString() ?? '').toLowerCase().contains(
                  'google',
                ) ||
                voice['engine'] is! String,
          )
          .toList();

      preferredEngineVoices.sort((a, b) {
        final qualityDiff =
            qualityScore(b['quality']?.toString()) -
            qualityScore(a['quality']?.toString());
        if (qualityDiff != 0) {
          return qualityDiff;
        }
        final latencyA = a['latency']?.toString() ?? '';
        final latencyB = b['latency']?.toString() ?? '';
        return latencyA.compareTo(latencyB);
      });

      final ordered = preferredEngineVoices.isEmpty
          ? voices
          : preferredEngineVoices;
      return matchesLocale(ordered) ?? matchesLocale(voices);
    }

    Map<String, dynamic>? selected;
    if (Platform.isIOS) {
      selected = pickIosVoice();
    } else if (Platform.isAndroid) {
      selected = pickAndroidVoice();
    }

    if (selected == null) {
      return null;
    }

    final name = selected['name']?.toString();
    final locale = selected['locale']?.toString();
    if (name == null || locale == null) {
      return null;
    }

    return selected;
  }

  void _handleStart() {
    _onStart?.call();
  }

  void _handleComplete() {
    _onComplete?.call();
  }

  void _handleCancel() {
    _onCancel?.call();
  }

  void _handlePause() {
    _onPause?.call();
  }

  void _handleContinue() {
    _onContinue?.call();
  }

  void _handleError(dynamic message) {
    final safeMessage = message == null
        ? 'Unknown TTS error'
        : message.toString();
    _onError?.call(safeMessage);
  }
}

class _VoiceNotProvided {
  const _VoiceNotProvided();
}
