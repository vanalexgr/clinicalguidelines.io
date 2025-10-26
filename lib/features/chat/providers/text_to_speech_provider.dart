import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/settings_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/markdown_to_text.dart';
import '../services/text_to_speech_service.dart';

enum TtsPlaybackStatus { idle, initializing, loading, speaking, paused, error }

class TextToSpeechState {
  final bool initialized;
  final bool available;
  final TtsPlaybackStatus status;
  final String? activeMessageId;
  final String? errorMessage;
  final List<String> sentences;
  final List<int> sentenceOffsets; // start indices in full text
  final int activeSentenceIndex; // -1 when none
  final int? wordStartInSentence; // nullable; only for on-device
  final int? wordEndInSentence; // nullable; only for on-device

  const TextToSpeechState({
    this.initialized = false,
    this.available = false,
    this.status = TtsPlaybackStatus.idle,
    this.activeMessageId,
    this.errorMessage,
    this.sentences = const [],
    this.sentenceOffsets = const [],
    this.activeSentenceIndex = -1,
    this.wordStartInSentence,
    this.wordEndInSentence,
  });

  bool get isSpeaking => status == TtsPlaybackStatus.speaking;
  bool get isBusy =>
      status == TtsPlaybackStatus.loading ||
      status == TtsPlaybackStatus.initializing;

  TextToSpeechState copyWith({
    bool? initialized,
    bool? available,
    TtsPlaybackStatus? status,
    String? activeMessageId,
    bool clearActiveMessageId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<String>? sentences,
    List<int>? sentenceOffsets,
    int? activeSentenceIndex,
    bool clearWord = false,
    int? wordStartInSentence,
    int? wordEndInSentence,
  }) {
    return TextToSpeechState(
      initialized: initialized ?? this.initialized,
      available: available ?? this.available,
      status: status ?? this.status,
      activeMessageId: clearActiveMessageId
          ? null
          : activeMessageId ?? this.activeMessageId,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      sentences: sentences ?? this.sentences,
      sentenceOffsets: sentenceOffsets ?? this.sentenceOffsets,
      activeSentenceIndex: activeSentenceIndex ?? this.activeSentenceIndex,
      wordStartInSentence: clearWord
          ? null
          : (wordStartInSentence ?? this.wordStartInSentence),
      wordEndInSentence: clearWord
          ? null
          : (wordEndInSentence ?? this.wordEndInSentence),
    );
  }
}

class TextToSpeechController extends Notifier<TextToSpeechState> {
  late TextToSpeechService _service;
  bool _handlersBound = false;
  Future<bool>? _initializationFuture;

  @override
  TextToSpeechState build() {
    _service = ref.watch(textToSpeechServiceProvider);

    if (!_handlersBound) {
      _handlersBound = true;
      _service.bindHandlers(
        onStart: _handleStart,
        onComplete: _handleCompletion,
        onCancel: _handleCancellation,
        onPause: _handlePause,
        onContinue: _handleContinue,
        onError: _handleError,
        onSentenceIndex: _handleSentenceIndex,
        onDeviceWordProgress: _handleDeviceWordProgress,
      );

      ref.onDispose(() {
        unawaited(_service.stop());
      });
    }

    // Listen to settings changes and update TTS when initialized
    ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
      if (_service.isInitialized && _service.isAvailable) {
        final selectedVoice = next.ttsEngine == TtsEngine.server
            ? next.ttsServerVoiceId
            : next.ttsVoice;
        _service.updateSettings(
          voice: selectedVoice,
          speechRate: next.ttsSpeechRate,
          pitch: next.ttsPitch,
          volume: next.ttsVolume,
          engine: next.ttsEngine,
        );
      }
    }, fireImmediately: false);

    return const TextToSpeechState();
  }

  Future<bool> _ensureInitialized() {
    final existing = _initializationFuture;
    if (existing != null) {
      return existing;
    }

    state = state.copyWith(
      status: TtsPlaybackStatus.initializing,
      clearErrorMessage: true,
    );

    final settings = ref.read(appSettingsProvider);
    final future = _service
        .initialize(
          voice: settings.ttsEngine == TtsEngine.server
              ? settings.ttsServerVoiceId
              : settings.ttsVoice,
          speechRate: settings.ttsSpeechRate,
          pitch: settings.ttsPitch,
          volume: settings.ttsVolume,
          engine: settings.ttsEngine,
        )
        .then((available) {
          if (!ref.mounted) {
            return available;
          }

          state = state.copyWith(
            initialized: true,
            available: available,
            status: TtsPlaybackStatus.idle,
          );
          return available;
        })
        .catchError((error, _) {
          if (!ref.mounted) {
            return false;
          }

          state = state.copyWith(
            initialized: true,
            available: false,
            status: TtsPlaybackStatus.error,
            errorMessage: error.toString(),
            clearActiveMessageId: true,
          );
          return false;
        });

    _initializationFuture = future;
    future.whenComplete(() {
      _initializationFuture = null;
    });

    return future;
  }

  Future<void> toggleForMessage({
    required String messageId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    final isCurrentlyActive =
        state.activeMessageId == messageId &&
        state.status != TtsPlaybackStatus.idle &&
        state.status != TtsPlaybackStatus.error;

    if (isCurrentlyActive) {
      await stop();
      return;
    }

    final available = await _ensureInitialized();
    if (!available) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        status: TtsPlaybackStatus.error,
        errorMessage: 'Text-to-speech unavailable',
        clearActiveMessageId: true,
      );
      return;
    }

    // Prepare sentence split for highlighting
    final cleanText = MarkdownToText.convert(text);
    final sentences = _splitForTts(cleanText);
    final offsets = _computeOffsets(sentences);

    state = state.copyWith(
      status: TtsPlaybackStatus.loading,
      activeMessageId: messageId,
      clearErrorMessage: true,
      sentences: sentences,
      sentenceOffsets: offsets,
      activeSentenceIndex: sentences.isEmpty ? -1 : 0,
      clearWord: true,
    );

    try {
      // Convert markdown to clean text for TTS
      if (cleanText.isEmpty) {
        // No speakable content
        if (!ref.mounted) {
          return;
        }
        state = state.copyWith(
          status: TtsPlaybackStatus.idle,
          clearActiveMessageId: true,
        );
        return;
      }

      await _service.speak(cleanText);
      if (!ref.mounted) {
        return;
      }
      if (state.status == TtsPlaybackStatus.loading) {
        state = state.copyWith(status: TtsPlaybackStatus.speaking);
      }
    } catch (e) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        status: TtsPlaybackStatus.error,
        errorMessage: e.toString(),
        clearActiveMessageId: true,
      );
    }
  }

  List<String> _splitForTts(String text) {
    final normalized = text.replaceAll(RegExp(r"\s+"), ' ').trim();
    if (normalized.isEmpty) return const [];
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
    return parts;
  }

  List<int> _computeOffsets(List<String> sentences) {
    final offsets = <int>[];
    int acc = 0;
    for (final s in sentences) {
      offsets.add(acc);
      acc += s.length + 1; // assume a space or punctuation between
    }
    return offsets;
  }

  Future<void> pause() async {
    if (!state.initialized || !state.available) {
      return;
    }
    await _service.pause();
  }

  Future<void> stop() async {
    await _service.stop();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.idle,
      clearActiveMessageId: true,
      clearErrorMessage: true,
    );
  }

  void _handleStart() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(status: TtsPlaybackStatus.speaking);
  }

  void _handleCompletion() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.idle,
      clearActiveMessageId: true,
    );
  }

  void _handleCancellation() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.idle,
      clearActiveMessageId: true,
    );
  }

  void _handlePause() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(status: TtsPlaybackStatus.paused);
  }

  void _handleContinue() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(status: TtsPlaybackStatus.speaking);
  }

  void _handleError(String message) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      status: TtsPlaybackStatus.error,
      errorMessage: message,
      clearActiveMessageId: true,
    );
  }

  void _handleSentenceIndex(int index) {
    if (!ref.mounted) return;
    final clamped = index.clamp(
      -1,
      state.sentences.isEmpty ? -1 : state.sentences.length - 1,
    );
    state = state.copyWith(
      activeSentenceIndex: clamped,
      // clear per-word highlight when sentence switches (server or device)
      clearWord: true,
    );
  }

  void _handleDeviceWordProgress(int start, int end) {
    if (!ref.mounted) return;
    // Map global offsets to sentence index
    final offsets = state.sentenceOffsets;
    if (offsets.isEmpty) return;
    int idx = 0;
    for (var i = 0; i < offsets.length; i++) {
      final sStart = offsets[i];
      final sEnd = i + 1 < offsets.length ? offsets[i + 1] : 1 << 30;
      if (start >= sStart && start < sEnd) {
        idx = i;
        break;
      }
    }
    final sentenceStart = offsets[idx];
    state = state.copyWith(
      activeSentenceIndex: idx,
      wordStartInSentence: (start - sentenceStart).clamp(0, 1 << 20),
      wordEndInSentence: (end - sentenceStart).clamp(0, 1 << 20),
    );
  }
}

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final service = TextToSpeechService(api: api);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final textToSpeechControllerProvider =
    NotifierProvider<TextToSpeechController, TextToSpeechState>(
      TextToSpeechController.new,
    );
