import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/socket_service.dart';
import '../providers/chat_providers.dart';
import 'text_to_speech_service.dart';
import 'voice_input_service.dart';

part 'voice_call_service.g.dart';

enum VoiceCallState {
  idle,
  connecting,
  listening,
  processing,
  speaking,
  error,
  disconnected,
}

class VoiceCallService {
  final VoiceInputService _voiceInput;
  final TextToSpeechService _tts;
  final SocketService _socketService;
  final Ref _ref;

  VoiceCallState _state = VoiceCallState.idle;
  String? _sessionId;
  StreamSubscription<String>? _transcriptSubscription;
  StreamSubscription<int>? _intensitySubscription;
  String _accumulatedTranscript = '';
  bool _isDisposed = false;
  SocketEventSubscription? _socketSubscription;

  final StreamController<VoiceCallState> _stateController =
      StreamController<VoiceCallState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  final StreamController<int> _intensityController =
      StreamController<int>.broadcast();

  VoiceCallService({
    required VoiceInputService voiceInput,
    required TextToSpeechService tts,
    required SocketService socketService,
    required Ref ref,
  })  : _voiceInput = voiceInput,
        _tts = tts,
        _socketService = socketService,
        _ref = ref {
    _tts.bindHandlers(
      onStart: _handleTtsStart,
      onComplete: _handleTtsComplete,
      onError: _handleTtsError,
    );
  }

  VoiceCallState get state => _state;
  Stream<VoiceCallState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get responseStream => _responseController.stream;
  Stream<int> get intensityStream => _intensityController.stream;

  Future<void> initialize() async {
    if (_isDisposed) return;

    // ignore: avoid_print
    print('[VoiceCall] Starting initialization...');

    // Initialize voice input
    final voiceInitialized = await _voiceInput.initialize();
    // ignore: avoid_print
    print('[VoiceCall] Voice initialized: $voiceInitialized');
    if (!voiceInitialized) {
      _updateState(VoiceCallState.error);
      throw Exception('Voice input initialization failed');
    }

    // Check if local STT is available
    final hasLocalStt = _voiceInput.hasLocalStt;
    // ignore: avoid_print
    print('[VoiceCall] Has local STT: $hasLocalStt');
    if (!hasLocalStt) {
      _updateState(VoiceCallState.error);
      throw Exception('Speech recognition not available on this device');
    }

    // Check microphone permissions
    final hasMicPermission = await _voiceInput.checkPermissions();
    // ignore: avoid_print
    print('[VoiceCall] Has mic permission: $hasMicPermission');
    if (!hasMicPermission) {
      _updateState(VoiceCallState.error);
      throw Exception('Microphone permission not granted');
    }

    // Initialize TTS
    await _tts.initialize();
    // ignore: avoid_print
    print('[VoiceCall] TTS initialized');
  }

  Future<void> startCall(String? conversationId) async {
    // ignore: avoid_print
    print('[VoiceCall] startCall() entered. _isDisposed=$_isDisposed');

    if (_isDisposed) {
      // ignore: avoid_print
      print('[VoiceCall] EARLY RETURN: Service is disposed');
      return;
    }

    try {
      // ignore: avoid_print
      print('[VoiceCall] Starting call for conversation: $conversationId');
      _updateState(VoiceCallState.connecting);

      // Ensure socket connection
      // ignore: avoid_print
      print('[VoiceCall] Ensuring socket connection...');
      await _socketService.ensureConnected();
      _sessionId = _socketService.sessionId;
      // ignore: avoid_print
      print('[VoiceCall] Session ID: $_sessionId');

      if (_sessionId == null) {
        throw Exception('Failed to establish socket connection');
      }

      // Set up socket event listener for assistant responses
      // ignore: avoid_print
      print('[VoiceCall] Setting up socket event handler...');
      _socketSubscription = _socketService.addChatEventHandler(
        conversationId: conversationId,
        sessionId: _sessionId,
        requireFocus: false,
        handler: _handleSocketEvent,
      );

      // Start listening for user voice input
      // ignore: avoid_print
      print('[VoiceCall] Starting to listen...');
      await _startListening();
      // ignore: avoid_print
      print('[VoiceCall] Listen started successfully');
    } catch (e) {
      // ignore: avoid_print
      print('[VoiceCall] Error in startCall: $e');
      _updateState(VoiceCallState.error);
      rethrow;
    }
  }

  Future<void> _startListening() async {
    if (_isDisposed) return;

    try {
      _accumulatedTranscript = '';

      // ignore: avoid_print
      print('[VoiceCall] _startListening called');

      // Check if voice input is available
      if (!_voiceInput.hasLocalStt) {
        // ignore: avoid_print
        print('[VoiceCall] ERROR: No local STT available');
        _updateState(VoiceCallState.error);
        throw Exception('Voice input not available on this device');
      }

      // ignore: avoid_print
      print('[VoiceCall] Setting state to listening...');
      _updateState(VoiceCallState.listening);

      // ignore: avoid_print
      print('[VoiceCall] Calling beginListening...');
      final stream = await _voiceInput.beginListening();
      // ignore: avoid_print
      print('[VoiceCall] Got stream from beginListening');

      _transcriptSubscription = stream.listen(
        (text) {
          // ignore: avoid_print
          print('[VoiceCall] Transcript received: $text');
          if (_isDisposed) return;
          _accumulatedTranscript = text;
          _transcriptController.add(text);
        },
        onError: (error) {
          // ignore: avoid_print
          print('[VoiceCall] Stream error: $error');
          if (_isDisposed) return;
          _updateState(VoiceCallState.error);
        },
        onDone: () async {
          // ignore: avoid_print
          print('[VoiceCall] Stream done. Transcript: $_accumulatedTranscript');
          if (_isDisposed) return;
          // User stopped speaking, send message to assistant
          if (_accumulatedTranscript.trim().isNotEmpty) {
            await _sendMessageToAssistant(_accumulatedTranscript);
          } else {
            // No input, restart listening
            await _startListening();
          }
        },
      );

      // ignore: avoid_print
      print('[VoiceCall] Setting up intensity stream...');
      // Forward intensity stream for waveform visualization
      _intensitySubscription = _voiceInput.intensityStream.listen(
        (intensity) {
          if (_isDisposed) return;
          _intensityController.add(intensity);
        },
      );
      // ignore: avoid_print
      print('[VoiceCall] _startListening completed successfully');
    } catch (e) {
      // ignore: avoid_print
      print('[VoiceCall] ERROR in _startListening: $e');
      _updateState(VoiceCallState.error);
      rethrow;
    }
  }

  Future<void> _sendMessageToAssistant(String text) async {
    if (_isDisposed) return;

    try {
      _updateState(VoiceCallState.processing);

      // Send message using the existing chat infrastructure
      sendMessageFromService(_ref, text, null);
    } catch (e) {
      _updateState(VoiceCallState.error);
      rethrow;
    }
  }

  void _handleSocketEvent(
    Map<String, dynamic> event,
    void Function(dynamic response)? ack,
  ) {
    if (_isDisposed) return;

    final type = event['type']?.toString();
    final data = event['data'];

    if (data is Map<String, dynamic>) {
      // Handle streaming response chunks
      if (type == 'message' || type == 'delta') {
        final content = data['content']?.toString() ?? '';
        if (content.isNotEmpty) {
          _responseController.add(content);
        }
      }

      // Handle completion
      if (data['done'] == true || type == 'completion') {
        final fullResponse = data['content']?.toString() ??
            data['message']?.toString() ??
            '';
        if (fullResponse.isNotEmpty) {
          _speakResponse(fullResponse);
        } else {
          // No response, restart listening
          _startListening();
        }
      }
    }
  }

  Future<void> _speakResponse(String response) async {
    if (_isDisposed) return;

    try {
      _updateState(VoiceCallState.speaking);
      await _tts.speak(response);
      // After speaking completes, _handleTtsComplete will restart listening
    } catch (e) {
      _updateState(VoiceCallState.error);
      // Restart listening even if TTS fails
      await _startListening();
    }
  }

  void _handleTtsStart() {
    if (_isDisposed) return;
    _updateState(VoiceCallState.speaking);
  }

  void _handleTtsComplete() {
    if (_isDisposed) return;
    // After assistant finishes speaking, start listening for user again
    _startListening();
  }

  void _handleTtsError(String error) {
    if (_isDisposed) return;
    _updateState(VoiceCallState.error);
    // Try to recover by restarting listening
    _startListening();
  }

  Future<void> stopCall() async {
    if (_isDisposed) return;

    await _transcriptSubscription?.cancel();
    await _intensitySubscription?.cancel();
    _socketSubscription?.dispose();

    await _voiceInput.stopListening();
    await _tts.stop();

    _sessionId = null;
    _accumulatedTranscript = '';
    _updateState(VoiceCallState.disconnected);
  }

  Future<void> pauseListening() async {
    if (_isDisposed) return;
    await _voiceInput.stopListening();
    await _transcriptSubscription?.cancel();
    await _intensitySubscription?.cancel();
  }

  Future<void> resumeListening() async {
    if (_isDisposed) return;
    await _startListening();
  }

  Future<void> cancelSpeaking() async {
    if (_isDisposed) return;
    await _tts.stop();
    // Immediately restart listening
    await _startListening();
  }

  void _updateState(VoiceCallState newState) {
    if (_isDisposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> dispose() async {
    _isDisposed = true;

    await _transcriptSubscription?.cancel();
    await _intensitySubscription?.cancel();
    _socketSubscription?.dispose();

    _voiceInput.dispose();
    await _tts.dispose();

    await _stateController.close();
    await _transcriptController.close();
    await _responseController.close();
    await _intensityController.close();
  }
}

@Riverpod(keepAlive: true)
VoiceCallService voiceCallService(Ref ref) {
  final voiceInput = ref.watch(voiceInputServiceProvider);
  final tts = TextToSpeechService();
  final socketService = ref.watch(socketServiceProvider);

  if (socketService == null) {
    throw Exception('Socket service not available');
  }

  final service = VoiceCallService(
    voiceInput: voiceInput,
    tts: tts,
    socketService: socketService,
    ref: ref,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
