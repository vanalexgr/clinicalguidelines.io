import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_intents/flutter_app_intents.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_providers.dart';
import '../utils/debug_logger.dart';
import 'navigation_service.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/auth/providers/unified_auth_providers.dart';
import '../../features/chat/views/voice_call_page.dart';
import '../../features/chat/services/file_attachment_service.dart';
import '../../shared/services/tasks/task_queue.dart';

part 'app_intents_service.g.dart';

const _askIntentId = 'app.cogwheel.conduit.ask_chat';
const _voiceCallIntentId = 'app.cogwheel.conduit.start_voice_call';
const _sendTextIntentId = 'app.cogwheel.conduit.send_text';
const _sendUrlIntentId = 'app.cogwheel.conduit.send_url';
const _sendImageIntentId = 'app.cogwheel.conduit.send_image';

/// Registers and handles iOS App Intents for Siri/Shortcuts.
@Riverpod(keepAlive: true)
class AppIntentCoordinator extends _$AppIntentCoordinator {
  @override
  FutureOr<void> build() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    unawaited(_registerAskIntent());
    unawaited(_registerVoiceCallIntent());
    unawaited(_registerSendTextIntent());
    unawaited(_registerSendUrlIntent());
    unawaited(_registerSendImageIntent());
  }

  Future<void> _registerAskIntent() async {
    final client = FlutterAppIntentsClient.instance;
    final intent = AppIntentBuilder()
        .identifier(_askIntentId)
        .title('Ask Conduit')
        .description('Start a chat with an optional prompt.')
        .parameter(
          const AppIntentParameter(
            name: 'prompt',
            title: 'Prompt',
            description: 'What should Conduit answer?',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .build();

    try {
      await client.registerIntent(intent, _handleAskIntent);
      await FlutterAppIntentsService.donateIntentWithMetadata(
        _askIntentId,
        const {},
        relevanceScore: 0.7,
        context: {'feature': 'chat', 'source': 'app_intent'},
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-register',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerVoiceCallIntent() async {
    final client = FlutterAppIntentsClient.instance;
    final intent = AppIntentBuilder()
        .identifier(_voiceCallIntentId)
        .title('Start Voice Call')
        .description('Start a live voice call with Conduit.')
        .build();

    try {
      await client.registerIntent(intent, _handleVoiceCallIntent);
      await FlutterAppIntentsService.donateIntentWithMetadata(
        _voiceCallIntentId,
        const {},
        relevanceScore: 0.8,
        context: {'feature': 'voice_call', 'source': 'app_intent'},
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-register-voice',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerSendTextIntent() async {
    final client = FlutterAppIntentsClient.instance;
    final intent = AppIntentBuilder()
        .identifier(_sendTextIntentId)
        .title('Send to Conduit')
        .description('Start a new chat with provided text.')
        .parameter(
          const AppIntentParameter(
            name: 'text',
            title: 'Text',
            description: 'Text to send into Conduit.',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .build();

    try {
      await client.registerIntent(intent, _handleSendTextIntent);
      await FlutterAppIntentsService.donateIntentWithMetadata(
        _sendTextIntentId,
        const {},
        relevanceScore: 0.75,
        context: {'feature': 'share_text', 'source': 'app_intent'},
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-register-text',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerSendUrlIntent() async {
    final client = FlutterAppIntentsClient.instance;
    final intent = AppIntentBuilder()
        .identifier(_sendUrlIntentId)
        .title('Send Link to Conduit')
        .description('Start a chat with a link to summarize or analyze.')
        .parameter(
          const AppIntentParameter(
            name: 'url',
            title: 'URL',
            description: 'Link to summarize or process.',
            type: AppIntentParameterType.url,
            isOptional: false,
          ),
        )
        .build();

    try {
      await client.registerIntent(intent, _handleSendUrlIntent);
      await FlutterAppIntentsService.donateIntentWithMetadata(
        _sendUrlIntentId,
        const {},
        relevanceScore: 0.75,
        context: {'feature': 'share_url', 'source': 'app_intent'},
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-register-url',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerSendImageIntent() async {
    final client = FlutterAppIntentsClient.instance;
    final intent = AppIntentBuilder()
        .identifier(_sendImageIntentId)
        .title('Send Image to Conduit')
        .description('Start a chat with an attached image.')
        .parameter(
          const AppIntentParameter(
            name: 'filename',
            title: 'Filename',
            description: 'Preferred filename for the image.',
            type: AppIntentParameterType.string,
            isOptional: true,
          ),
        )
        .parameter(
          const AppIntentParameter(
            name: 'bytes',
            title: 'Image Bytes',
            description: 'Base64 encoded image bytes.',
            type: AppIntentParameterType.string,
            isOptional: false,
          ),
        )
        .build();

    try {
      await client.registerIntent(intent, _handleSendImageIntent);
      await FlutterAppIntentsService.donateIntentWithMetadata(
        _sendImageIntentId,
        const {},
        relevanceScore: 0.85,
        context: {'feature': 'share_image', 'source': 'app_intent'},
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-register-image',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AppIntentResult> _handleAskIntent(
    Map<String, dynamic> parameters,
  ) async {
    final prompt = (parameters['prompt'] as String?)?.trim();

    try {
      await _prepareChat(prompt: prompt);
      final summary = prompt != null && prompt.isNotEmpty
          ? 'Opening chat for "$prompt"'
          : 'Opening Conduit chat';

      return AppIntentResult.successful(
        value: summary,
        needsToContinueInApp: true,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-handle',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return AppIntentResult.failed(error: 'Unable to open chat: $error');
    }
  }

  Future<AppIntentResult> _handleVoiceCallIntent(
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _startVoiceCall();
      return AppIntentResult.successful(
        value: 'Starting Conduit voice call',
        needsToContinueInApp: true,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-voice',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return AppIntentResult.failed(
        error: 'Unable to start voice call: $error',
      );
    }
  }

  Future<AppIntentResult> _handleSendTextIntent(
    Map<String, dynamic> parameters,
  ) async {
    final text = (parameters['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      return AppIntentResult.failed(error: 'No text provided.');
    }

    try {
      await _prepareChatWithOptions(
        prompt: text,
        focusComposer: true,
        resetChat: true,
      );
      return AppIntentResult.successful(
        value: 'Sent to Conduit',
        needsToContinueInApp: true,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-text',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return AppIntentResult.failed(error: 'Unable to send text: $error');
    }
  }

  Future<AppIntentResult> _handleSendUrlIntent(
    Map<String, dynamic> parameters,
  ) async {
    final url = (parameters['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      return AppIntentResult.failed(error: 'No URL provided.');
    }

    final prompt = 'Please summarize or analyze:\n$url';
    try {
      await _prepareChatWithOptions(
        prompt: prompt,
        focusComposer: true,
        resetChat: true,
      );
      return AppIntentResult.successful(
        value: 'Opening Conduit for this link',
        needsToContinueInApp: true,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-url',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return AppIntentResult.failed(error: 'Unable to send URL: $error');
    }
  }

  Future<AppIntentResult> _handleSendImageIntent(
    Map<String, dynamic> parameters,
  ) async {
    final base64 = parameters['bytes'] as String?;
    if (base64 == null || base64.isEmpty) {
      return AppIntentResult.failed(error: 'No image data provided.');
    }
    final filenameRaw = (parameters['filename'] as String?)?.trim();

    try {
      final file = await _materializeTempFile(
        base64,
        preferredName: filenameRaw,
      );
      await _attachFiles([file]);
      await _prepareChatWithOptions(focusComposer: true, resetChat: true);
      return AppIntentResult.successful(
        value: 'Image attached in Conduit',
        needsToContinueInApp: true,
      );
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-image',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return AppIntentResult.failed(error: 'Unable to send image: $error');
    }
  }

  Future<void> _prepareChat({String? prompt}) async {
    await _prepareChatWithOptions(
      prompt: prompt,
      focusComposer: false,
      resetChat: false,
    );
  }

  Future<void> openChatFromExternal({
    String? prompt,
    bool focusComposer = false,
    bool resetChat = false,
  }) {
    return _prepareChatWithOptions(
      prompt: prompt,
      focusComposer: focusComposer,
      resetChat: resetChat,
    );
  }

  Future<void> startVoiceCallFromExternal() => _startVoiceCall();

  Future<void> _prepareChatWithOptions({
    String? prompt,
    bool focusComposer = false,
    bool resetChat = false,
  }) async {
    if (!ref.mounted) return;

    NavigationService.navigateToChat();

    final navState = ref.read(authNavigationStateProvider);
    if (prompt != null && prompt.isNotEmpty) {
      ref.read(prefilledInputTextProvider.notifier).set(prompt);
    }

    if (navState == AuthNavigationState.authenticated && resetChat) {
      startNewChat(ref);
    }

    if (focusComposer) {
      final tick = ref.read(inputFocusTriggerProvider);
      ref.read(inputFocusTriggerProvider.notifier).set(tick + 1);
    }
  }

  Future<void> _startVoiceCall() async {
    if (!ref.mounted) return;

    final navState = ref.read(authNavigationStateProvider);
    if (navState != AuthNavigationState.authenticated) {
      throw StateError('Sign in to start a voice call.');
    }

    final model = ref.read(selectedModelProvider);
    if (model == null) {
      throw StateError('Choose a model before starting a voice call.');
    }

    await NavigationService.navigateToChat();

    // Wait a tick for navigation to settle so navigator/context are present.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final navigator = NavigationService.navigator;
    final context = NavigationService.navigatorKey.currentContext;
    if (navigator == null || context == null) {
      throw StateError('Navigation is not available.');
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => const VoiceCallPage(startNewConversation: true),
        fullscreenDialog: true,
      ),
    );
  }

  Future<File> _materializeTempFile(
    String base64Data, {
    String? preferredName,
  }) async {
    final bytes = base64Decode(base64Data);
    const maxBytes = 20 * 1024 * 1024; // 20 MB guardrail
    if (bytes.length > maxBytes) {
      throw StateError('Image too large (max 20 MB).');
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = (preferredName != null && preferredName.isNotEmpty)
        ? preferredName
        : 'conduit_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final sanitizedName = safeName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final file = File(p.join(tempDir.path, sanitizedName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _attachFiles(List<File> files) async {
    if (files.isEmpty) return;
    // Warm the attachment service to ensure dependencies are ready.
    final _ = ref.read(fileAttachmentServiceProvider);
    final notifier = ref.read(attachedFilesProvider.notifier);
    final taskQueue = ref.read(taskQueueProvider.notifier);
    final activeConv = ref.read(activeConversationProvider);

    final attachments = files
        .map((f) => LocalAttachment(file: f, displayName: p.basename(f.path)))
        .toList();

    notifier.addFiles(attachments);

    for (final attachment in attachments) {
      try {
        await taskQueue.enqueueUploadMedia(
          conversationId: activeConv?.id,
          filePath: attachment.file.path,
          fileName: attachment.displayName,
          fileSize: await attachment.file.length(),
        );
      } catch (error, stackTrace) {
        DebugLogger.error(
          'app-intents-upload',
          scope: 'siri',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
