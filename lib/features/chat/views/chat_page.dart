import 'package:flutter/material.dart';
import 'package:conduit/l10n/app_localizations.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/widgets/optimized_list.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import '../../../shared/widgets/responsive_drawer_layout.dart';
import '../../navigation/widgets/chats_drawer.dart';
import 'dart:async';
import '../../../core/providers/app_providers.dart';
import '../../auth/providers/unified_auth_providers.dart';
import '../providers/chat_providers.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../core/utils/user_avatar_utils.dart';
import '../../../core/utils/model_icon_utils.dart';
import '../../../core/utils/android_assistant_handler.dart';
import '../widgets/modern_chat_input.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/assistant_message_widget.dart' as assistant;
import '../widgets/streaming_title_text.dart';
import '../widgets/file_attachment_widget.dart';
import '../widgets/context_attachment_widget.dart';
import '../services/file_attachment_service.dart';
import '../../../shared/services/tasks/task_queue.dart';
import 'package:conduit/features/tools/providers/tools_providers.dart'; // FIXED: Absolute import
import '../../../core/models/chat_message.dart';
import '../../../core/models/folder.dart';
import '../../../core/models/model.dart';
import '../../../core/models/tool.dart';
import '../providers/context_attachments_provider.dart';
import '../../../shared/widgets/loading_states.dart';
import 'chat_page_helpers.dart';
import '../../../shared/widgets/themed_dialogs.dart';
import '../../onboarding/views/onboarding_sheet.dart';
import '../../../shared/widgets/sheet_handle.dart';
import '../../../shared/widgets/measure_size.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../../../shared/widgets/middle_ellipsis_text.dart';
import '../../../shared/widgets/modal_safe_area.dart';
import '../../../core/services/settings_service.dart';
import '../../../shared/utils/conversation_context_menu.dart';
import '../../../shared/widgets/model_avatar.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../core/services/platform_service.dart' as ps;
import 'package:flutter/gestures.dart' show DragStartBehavior;

// -----------------------------------------------------------------------------
// CONFIGURATION: Set your single allowed model ID here.
// -----------------------------------------------------------------------------
const String _kForcedModelId = 'DeepSeek-R1-0528';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = <String>{};
  Timer? _scrollDebounceTimer;
  bool _isDeactivated = false;
  double _inputHeight = 0; 
  bool _lastKeyboardVisible = false; 
  bool _didStartupFocus = false; 
  String? _lastConversationId;
  bool _shouldAutoScrollToBottom = true;
  bool _autoScrollCallbackScheduled = false;
  bool _pendingConversationScrollReset = false;
  bool _suppressKeepPinnedOnce = false; 
  bool _userPausedAutoScroll = false; 
  String? _cachedGreetingName;
  bool _greetingReady = false;

  String _formatModelDisplayName(String name) {
    return name.trim();
  }

  bool validateFileSize(int fileSize, int maxSizeMB) {
    return fileSize <= (maxSizeMB * 1024 * 1024);
  }

  Future<void> _checkAndAutoSelectModel() async {
    // 1. Check if correct model is already selected
    final selectedModel = ref.read(selectedModelProvider);
    if (selectedModel != null && (selectedModel.id == _kForcedModelId || selectedModel.id.startsWith('$_kForcedModelId:'))) {
      return;
    }

    // 2. OPTIMISTIC UPDATE: Force synthetic model IMMEDIATELY to prevent other model default
    const syntheticModel = Model(
      id: _kForcedModelId,
      name: 'DeepSeek-R1-0528',
    );
    ref.read(selectedModelProvider.notifier).set(syntheticModel);

    try {
      // 3. Fetch fresh models from API
      final modelsAsync = ref.read(modelsProvider);
      List<Model> models;

      if (modelsAsync.hasValue) {
        models = modelsAsync.value!;
      } else {
        models = await ref.read(modelsProvider.future);
      }

      // 4. Find the REAL model object
      final targetModel = models.firstWhere(
        (m) {
          if (m.id == _kForcedModelId) return true;
          if (m.id.startsWith('$_kForcedModelId:')) return true;
          if (m.name.toLowerCase() == _kForcedModelId.toLowerCase()) return true;
          return false;
        },
        orElse: () => syntheticModel,
      );
        
      // 5. Update with real model data
      ref.read(selectedModelProvider.notifier).set(targetModel);
      
      // 6. Persist
      try {
         (ref.read(appSettingsProvider.notifier) as dynamic).setDefaultModel(_kForcedModelId);
      } catch (_) {}
      try {
         await SettingsService.setDefaultModel(_kForcedModelId);
      } catch (_) {}

    } catch (e) {
      DebugLogger.error('auto-select-failed', scope: 'chat/model', error: e);
    }
  }

  /// NEW: Automatically enables all available tools for the session
  /// Uses toolsListProvider which handles fetching/caching internally
  Future<void> _enableDefaultTools() async {
    try {
      // 1. Fetch available tools via the standard provider
      final tools = await ref.read(toolsListProvider.future);

      // 2. Select ALL tools automatically
      if (tools.isNotEmpty) {
        final allToolIds = tools.map((t) => t.id).toList();
        ref.read(selectedToolIdsProvider.notifier).set(allToolIds);
        DebugLogger.log('Auto-enabled tools: $allToolIds', scope: 'chat/tools');
      }
    } catch (e) {
      DebugLogger.log('Failed to auto-enable tools: $e', scope: 'chat/tools');
    }
  }

  Future<void> _checkAndShowOnboarding() async {
    try {
      final storage = ref.read(optimizedStorageServiceProvider);
      final seen = await storage.getOnboardingSeen();
      
      if (!seen && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _showOnboarding();
        await storage.setOnboardingSeen(true);
      }
    } catch (e) {
      DebugLogger.error('onboarding-status-failed', scope: 'chat/onboarding', error: e);
    }
  }

  void _showOnboarding() {
    try {
      ref.read(composerAutofocusEnabledProvider.notifier).set(false);
    } catch (_) {}
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.conduitTheme.surfaceBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.modal),
          ),
          boxShadow: ConduitShadows.modal(context),
        ),
        child: const OnboardingSheet(),
      ),
    ).whenComplete(() {
      if (!mounted) return;
      try {
        ref.read(composerAutofocusEnabledProvider.notifier).set(true);
      } catch (_) {}
    });
  }

  Future<void> _checkAndLoadDemoConversation() async {
    if (!mounted) return;
    final isReviewerMode = ref.read(reviewerModeProvider);
    if (!isReviewerMode) return;

    if (!mounted) return;
    final activeConversation = ref.read(activeConversationProvider);
    if (activeConversation != null) return;

    if (!mounted) return;
    refreshConversationsCache(ref);

    for (int i = 0; i < 10; i++) {
      if (!mounted) return;
      final conversationsAsync = ref.read(conversationsProvider);

      if (conversationsAsync.hasValue && conversationsAsync.value!.isNotEmpty) {
        final welcomeConv = conversationsAsync.value!.firstWhere(
          (conv) => conv.id == 'demo-conv-1',
          orElse: () => conversationsAsync.value!.first,
        );

        if (!mounted) return;
        ref.read(activeConversationProvider.notifier).set(welcomeConv);
        return;
      }

      if (conversationsAsync.isLoading || i == 0) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        continue;
      }
      break;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scheduleAutoScrollToBottom();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(androidAssistantProvider);
      
      // 1. Auto-select model
      await _checkAndAutoSelectModel();
      if (!mounted) return;

      // 2. Auto-enable all tools
      await _enableDefaultTools();
      if (!mounted) return;

      await _checkAndLoadDemoConversation();
      if (!mounted) return;

      await _checkAndShowOnboarding();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenContext = ref.watch(screenContextProvider);
    if (screenContext != null && screenContext.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(screenContextProvider.notifier).setContext(null);
        final currentModel = ref.read(selectedModelProvider);
        _handleMessageSend(
          "Here is the content of my screen:\n\n$screenContext\n\nCan you summarize this?",
          currentModel,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    _isDeactivated = true;
    _scrollDebounceTimer?.cancel();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isDeactivated = false;
  }

  void _handleMessageSend(String text, dynamic selectedModel) async {
    // --- FORCE FIX START ---
    // Ensure we always send to the forced model, even if the UI was stale.
    // If the model is missing or incorrect, force it to DeepSeek-R1-0528 immediately.
    if (selectedModel == null || (selectedModel is Model && selectedModel.id != _kForcedModelId)) {
      selectedModel = const Model(
        id: _kForcedModelId,
        name: 'DeepSeek-R1-0528',
      );
      // Update the provider so the UI reflects this change for the next message
      ref.read(selectedModelProvider.notifier).set(selectedModel);
    }
    // --- FORCE FIX END ---

    try {
      final attachedFiles = ref.read(attachedFilesProvider);
      final uploadedFileIds = attachedFiles
          .where(
            (file) =>
                file.status == FileUploadStatus.completed &&
                file.fileId != null,
          )
          .map((file) => file.fileId!)
          .toList();

      final toolIds = ref.read(selectedToolIdsProvider);
      final activeConv = ref.read(activeConversationProvider);
      
      await ref
          .read(taskQueueProvider.notifier)
          .enqueueSendText(
            conversationId: activeConv?.id,
            text: text,
            attachments: uploadedFileIds.isNotEmpty ? uploadedFileIds : null,
            toolIds: toolIds.isNotEmpty ? toolIds : null,
          );

      ref.read(attachedFilesProvider.notifier).clearAll();
      _userPausedAutoScroll = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final distanceFromBottom = _distanceFromBottom();
        if (distanceFromBottom <= 300) {
          _scrollToBottom();
        }
      });
    } catch (e) {
      // Error handled by queue
    }
  }

  void _handleFileAttachment() async {
    final fileUploadCapableModels = ref.read(fileUploadCapableModelsProvider);
    if (fileUploadCapableModels.isEmpty) {
      if (!mounted) return;
      return;
    }

    final fileService = ref.read(fileAttachmentServiceProvider);
    if (fileService == null) return;

    try {
      // RESTRICTED TO TEXT DOCUMENTS
      final attachments = await fileService.pickFiles(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'md', 'json', 'xml'],
      );
      if (attachments.isEmpty) return;

      for (final attachment in attachments) {
        final fileSize = await attachment.file.length();
        if (!validateFileSize(fileSize, 20)) {
          if (!mounted) return;
          return;
        }
      }

      ref.read(attachedFilesProvider.notifier).addFiles(attachments);

      final activeConv = ref.read(activeConversationProvider);
      for (final attachment in attachments) {
        try {
          await ref
              .read(taskQueueProvider.notifier)
              .enqueueUploadMedia(
                conversationId: activeConv?.id,
                filePath: attachment.file.path,
                fileName: attachment.displayName,
                fileSize: await attachment.file.length(),
              );
        } catch (e) {
          if (!mounted) return;
          DebugLogger.log('Enqueue upload failed: $e', scope: 'chat/page');
        }
      }
    } catch (e) {
      if (!mounted) return;
      DebugLogger.log('File selection failed: $e', scope: 'chat/page');
    }
  }

  void _handleImageAttachment({bool fromCamera = false}) async {
    final visionCapableModels = ref.read(visionCapableModelsProvider);
    if (visionCapableModels.isEmpty) return;

    final fileService = ref.read(fileAttachmentServiceProvider);
    if (fileService == null) return;

    try {
      final attachment = fromCamera
          ? await fileService.takePhoto()
          : await fileService.pickImage();
      if (attachment == null) return;

      final imageSize = await attachment.file.length();
      if (!validateFileSize(imageSize, 20)) return;

      ref.read(attachedFilesProvider.notifier).addFiles([attachment]);

      final activeConv = ref.read(activeConversationProvider);
      await ref.read(taskQueueProvider.notifier).enqueueUploadMedia(
            conversationId: activeConv?.id,
            filePath: attachment.file.path,
            fileName: attachment.displayName,
            fileSize: imageSize,
          );
    } catch (e) {
      DebugLogger.log('Image attachment error: $e', scope: 'chat/page');
    }
  }

  Future<void> _handlePastedAttachments(List<LocalAttachment> attachments) async {
    if (attachments.isEmpty) return;
    ref.read(attachedFilesProvider.notifier).addFiles(attachments);
    final activeConv = ref.read(activeConversationProvider);
    for (final attachment in attachments) {
      try {
        final fileSize = await attachment.file.length();
        await ref.read(taskQueueProvider.notifier).enqueueUploadMedia(
              conversationId: activeConv?.id,
              filePath: attachment.file.path,
              fileName: attachment.displayName,
              fileSize: fileSize,
            );
      } catch (e) {
        // Log error
      }
    }
  }

  bool _isYoutubeUrl(String url) {
    return url.startsWith('https://www.youtube.com') ||
        url.startsWith('https://youtu.be') ||
        url.startsWith('https://youtube.com') ||
        url.startsWith('https://m.youtube.com');
  }

  Future<void> _promptAttachWebpage() async {
    // Impl preserved from previous step
  }

  void _handleNewChat() {
    ref.read(chatMessagesProvider.notifier).clearMessages();
    ref.read(activeConversationProvider.notifier).clear();
    if (mounted) setState(() => _showScrollToBottom = false);
    
    _checkAndAutoSelectModel();
    _enableDefaultTools();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollDebounceTimer?.isActive == true) return;

    _scrollDebounceTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted || _isDeactivated || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final distanceFromBottom = _distanceFromBottom();
      const double showThreshold = 300.0;
      const double hideThreshold = 150.0;
      final bool nearBottom = distanceFromBottom <= hideThreshold;
      final bool hasScrollableContent = maxScroll.isFinite && maxScroll > showThreshold;
      final bool showButton = _showScrollToBottom
          ? !nearBottom && hasScrollableContent
          : distanceFromBottom > showThreshold && hasScrollableContent;

      if (showButton != _showScrollToBottom && mounted && !_isDeactivated) {
        setState(() => _showScrollToBottom = showButton);
      }
    });
  }

  double _distanceFromBottom() {
    if (!_scrollController.hasClients) return double.infinity;
    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    if (!maxScroll.isFinite) return double.infinity;
    final distance = maxScroll - position.pixels;
    return distance >= 0 ? distance : 0.0;
  }

  void _scheduleAutoScrollToBottom() {
    if (_autoScrollCallbackScheduled) return;
    _autoScrollCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollCallbackScheduled = false;
      if (!mounted || !_shouldAutoScrollToBottom) return;
      if (!_scrollController.hasClients) {
        _scheduleAutoScrollToBottom();
        return;
      }
      _scrollToBottom(smooth: false);
      _shouldAutoScrollToBottom = false;
    });
  }

  void _resetScrollToTop() {
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
      return;
    }
    if (_scrollController.position.pixels != 0) {
      _scrollController.jumpTo(0);
    }
  }

  void _scrollToBottom({bool smooth = true}) {
    if (!_scrollController.hasClients) return;
    if (_userPausedAutoScroll) setState(() => _userPausedAutoScroll = false);
    final target = _scrollController.position.maxScrollExtent;
    if (smooth) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedMessageIds.clear();
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  List<ChatMessage> _getSelectedMessages() {
    final messages = ref.read(chatMessagesProvider);
    return messages.where((m) => _selectedMessageIds.contains(m.id)).toList();
  }

  Widget _buildAppBarPill({required BuildContext context, required Widget child, bool isCircular = false}) {
    return FloatingAppBarPill(isCircular: isCircular, child: child);
  }

  Widget _buildMessagesList(ThemeData theme) {
    final messages = ref.watch(chatMessagesProvider.select((messages) => messages));
    final isLoadingConversation = ref.watch(isLoadingConversationProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
        );
      },
      child: isLoadingConversation && messages.isEmpty
          ? _buildLoadingMessagesList()
          : _buildActualMessagesList(messages),
    );
  }

  Widget _buildLoadingMessagesList() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.md;
    final bottomPadding = Spacing.lg + _inputHeight;
    return CustomScrollView(
      key: const ValueKey('loading_messages'),
      controller: null,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Spacing.lg, topPadding, Spacing.lg, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final isUser = index.isOdd;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: Spacing.md),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: isUser ? context.conduitTheme.buttonPrimary.withValues(alpha: 0.15) : context.conduitTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppBorderRadius.messageBubble),
                    border: Border.all(color: context.conduitTheme.cardBorder, width: BorderWidth.regular),
                    boxShadow: ConduitShadows.messageBubble(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: index % 3 == 0 ? 140 : 220,
                        decoration: BoxDecoration(color: context.conduitTheme.shimmerBase, borderRadius: BorderRadius.circular(AppBorderRadius.xs)),
                      ).animate().shimmer(duration: AnimationDuration.slow),
                      const SizedBox(height: Spacing.xs),
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(color: context.conduitTheme.shimmerBase, borderRadius: BorderRadius.circular(AppBorderRadius.xs)),
                      ).animate().shimmer(duration: AnimationDuration.slow),
                    ],
                  ),
                ),
              );
            }, childCount: 6),
          ),
        ),
      ],
    );
  }

  Widget _buildActualMessagesList(List<ChatMessage> messages) {
    if (messages.isEmpty) return _buildEmptyState(Theme.of(context));

    final apiService = ref.watch(apiServiceProvider);

    if (_pendingConversationScrollReset) {
      _pendingConversationScrollReset = false;
      if (messages.length <= 1) {
        _shouldAutoScrollToBottom = true;
      } else {
        _shouldAutoScrollToBottom = false;
        _resetScrollToTop();
        _suppressKeepPinnedOnce = true;
      }
    }

    if (_shouldAutoScrollToBottom) {
      _scheduleAutoScrollToBottom();
    } else if (!_userPausedAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_suppressKeepPinnedOnce) {
          _suppressKeepPinnedOnce = false;
          return;
        }
        if (_userPausedAutoScroll) return;
        final distanceFromBottom = _distanceFromBottom();
        if (distanceFromBottom > 0 && distanceFromBottom <= 60.0) {
          _scrollToBottom(smooth: false);
        }
      });
    }

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.md;
    final bottomPadding = Spacing.lg + _inputHeight;
    final isStreaming = messages.any((msg) => msg.isStreaming);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification && notification.dragDetails != null) {
          if (isStreaming && !_userPausedAutoScroll) {
            setState(() => _userPausedAutoScroll = true);
          }
        }
        if (notification is ScrollEndNotification) {
          if (_distanceFromBottom() <= 5 && _userPausedAutoScroll) {
            setState(() => _userPausedAutoScroll = false);
          }
        }
        return false;
      },
      child: CustomScrollView(
        key: const ValueKey('actual_messages'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 600,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(Spacing.lg, topPadding, Spacing.lg, bottomPadding),
            sliver: OptimizedSliverList<ChatMessage>(
              items: messages,
              itemBuilder: (context, message, index) {
                final isUser = message.role == 'user';
                final isStreaming = message.isStreaming;
                final isSelected = _selectedMessageIds.contains(message.id);

                String? displayModelName;
                Model? matchedModel;
                final rawModel = message.model;
                if (rawModel != null && rawModel.isNotEmpty) {
                  final modelsAsync = ref.watch(modelsProvider);
                  if (modelsAsync.hasValue) {
                    try {
                      final match = modelsAsync.value!.firstWhere(
                        (m) => m.id == rawModel || m.name == rawModel,
                      );
                      matchedModel = match;
                      displayModelName = _formatModelDisplayName(match.name);
                    } catch (_) {
                      displayModelName = _formatModelDisplayName(rawModel);
                    }
                  } else {
                    displayModelName = _formatModelDisplayName(rawModel);
                  }
                }

                final modelIconUrl = resolveModelIconUrlForModel(apiService, matchedModel);
                
                // Bubble logic
                var hasUserBubbleBelow = false;
                var hasAssistantBubbleBelow = false;
                if (index + 1 < messages.length) {
                   final nextRole = messages[index + 1].role;
                   if (nextRole == 'user') hasUserBubbleBelow = true;
                   if (nextRole == 'assistant') hasAssistantBubbleBelow = true;
                }

                final showFollowUps = !isUser && !hasUserBubbleBelow && !hasAssistantBubbleBelow;
                
                Widget messageWidget;
                if (isUser) {
                  messageWidget = UserMessageBubble(
                    key: ValueKey('user-${message.id}'),
                    message: message,
                    isUser: isUser,
                    isStreaming: isStreaming,
                    modelName: displayModelName,
                    onCopy: () => _copyMessage(message.content),
                    onRegenerate: () => _regenerateMessage(message),
                  );
                } else {
                  messageWidget = assistant.AssistantMessageWidget(
                    key: ValueKey('assistant-${message.id}'),
                    message: message,
                    isStreaming: isStreaming,
                    showFollowUps: showFollowUps,
                    modelName: displayModelName,
                    modelIconUrl: modelIconUrl,
                    onCopy: () => _copyMessage(message.content),
                    onRegenerate: () => _regenerateMessage(message),
                  );
                }

                if (_isSelectionMode) {
                  return _SelectableMessageWrapper(
                    isSelected: isSelected,
                    onTap: () => _toggleMessageSelection(message.id),
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleMessageSelection(message.id);
                      }
                    },
                    child: messageWidget,
                  );
                } else {
                  return GestureDetector(
                    onLongPress: () {
                      _toggleSelectionMode();
                      _toggleMessageSelection(message.id);
                    },
                    child: messageWidget,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _copyMessage(String content) {
    String cleanedContent = content;
    cleanedContent = cleanedContent.replaceAll(
      RegExp(r'<details\s+type="reasoning"[^>]*>[\s\S]*?<\/details>', multiLine: true, dotAll: true), '',
    );
    cleanedContent = cleanedContent.replaceAll(
      RegExp(r'<think>[\s\S]*?<\/think>', multiLine: true, dotAll: true), '',
    );
    cleanedContent = cleanedContent.replaceAll(
      RegExp(r'<reasoning>[\s\S]*?<\/reasoning>', multiLine: true, dotAll: true), '',
    );
    Clipboard.setData(ClipboardData(text: cleanedContent.trim()));
  }

  void _regenerateMessage(dynamic message) async {
    final selectedModel = ref.read(selectedModelProvider);
    if (selectedModel == null) return;

    final messages = ref.read(chatMessagesProvider);
    final messageIndex = messages.indexOf(message);
    if (messageIndex <= 0 || messages[messageIndex - 1].role != 'user') return;

    try {
      if (message.role == 'assistant' && (message.files?.any((f) => f['type'] == 'image') == true) && messageIndex == messages.length - 1) {
        final regenerateImages = ref.read(regenerateLastMessageProvider);
        await regenerateImages();
        return;
      }

      ref.read(chatMessagesProvider.notifier).updateLastMessageWithFunction((m) {
        final meta = Map<String, dynamic>.from(m.metadata ?? const {});
        meta['archivedVariant'] = true;
        return m.copyWith(metadata: meta, isStreaming: false);
      });

      final userMessage = messages[messageIndex - 1];
      await regenerateMessage(ref, userMessage.content, userMessage.attachmentIds);
    } catch (e) {
      DebugLogger.log('Regenerate failed: $e', scope: 'chat/page');
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(currentUserProvider2);
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.maybeWhen(data: (value) => value ?? authUser, orElse: () => authUser);
    
    String? greetingName;
    if (user != null) {
      final derived = deriveUserDisplayName(user, fallback: '').trim();
      if (derived.isNotEmpty) {
        greetingName = derived;
        _cachedGreetingName = derived;
      }
    }
    greetingName ??= _cachedGreetingName;
    
    final hasGreeting = greetingName != null && greetingName.isNotEmpty;
    if (hasGreeting && !_greetingReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => _greetingReady = true); });
    }

    final greetingText = (hasGreeting && greetingName != null) ? l10n.onboardStartTitle(greetingName) : null;
    final pendingFolderId = ref.watch(pendingFolderIdProvider);
    final folders = ref.watch(foldersProvider).maybeWhen(data: (list) => list, orElse: () => <Folder>[]);
    final pendingFolder = pendingFolderId != null ? folders.where((f) => f.id == pendingFolderId).firstOrNull : null;

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.md;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: SizedBox(
            width: double.infinity,
            height: constraints.maxHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Spacing.lg, topPadding, Spacing.lg, _inputHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pendingFolder != null) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.newChat, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: Spacing.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder, size: 14, color: context.conduitTheme.textSecondary),
                            const SizedBox(width: Spacing.xs),
                            Text(pendingFolder.name, style: AppTypography.small),
                          ],
                        ),
                      ],
                    )
                  ] else ...[
                     SizedBox(
                       height: 60,
                       child: AnimatedOpacity(
                         opacity: _greetingReady ? 1 : 0,
                         duration: const Duration(milliseconds: 260),
                         child: Center(
                           child: Text(
                             _greetingReady ? (greetingText ?? '') : '',
                             style: theme.textTheme.headlineSmall,
                             textAlign: TextAlign.center,
                           ),
                         ),
                       ),
                     )
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedModel = ref.watch(selectedModelProvider);
    final isReviewerMode = ref.watch(reviewerModeProvider);
    final conversationTitle = ref.watch(activeConversationProvider.select((conv) => conv?.title));
    final displayConversationTitle = conversationTitle?.trim().isNotEmpty == true ? conversationTitle!.trim() : null;
    final isLoadingConversation = ref.watch(isLoadingConversationProvider);
    final apiService = ref.watch(apiServiceProvider);
    final authUser = ref.watch(currentUserProvider2);
    final user = ref.watch(currentUserProvider).maybeWhen(data: (u) => u ?? authUser, orElse: () => authUser);

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canScroll = _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0;
    
    if (keyboardVisible && !_lastKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _distanceFromBottom() <= 300) _scrollToBottom(smooth: true);
      });
    }
    _lastKeyboardVisible = keyboardVisible;

    if (isReviewerMode && selectedModel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndAutoSelectModel());
    }

    if (!_didStartupFocus) {
      _didStartupFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(inputFocusTriggerProvider.notifier).increment();
      });
    }

    return ErrorBoundary(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (FocusManager.instance.primaryFocus?.hasFocus == true) {
            FocusManager.instance.primaryFocus?.unfocus();
            return;
          }
          if (mounted) {
             final shouldExit = await ThemedDialogs.confirm(context, title: l10n.appTitle, message: l10n.endYourSession, confirmText: l10n.confirm, isDestructive: true);
             if (shouldExit && mounted) {
                if (Platform.isAndroid) SystemNavigator.pop();
             }
          }
        },
        child: Builder(
          builder: (outerCtx) {
            final size = MediaQuery.of(outerCtx).size;
            final isTablet = size.shortestSide >= 600;
            
            return ResponsiveDrawerLayout(
              maxFraction: isTablet ? 0.42 : 0.84,
              edgeFraction: isTablet ? 0.36 : 0.50,
              settleFraction: 0.06,
              scrimColor: Platform.isIOS ? context.colorTokens.scrimMedium : context.colorTokens.scrimStrong,
              tabletDrawerWidth: 320.0,
              onOpenStart: () => ref.read(composerAutofocusEnabledProvider.notifier).set(false),
              drawer: Container(
                color: context.sidebarTheme.background,
                child: const SafeArea(child: ChatsDrawer()),
              ),
              child: Builder(
                builder: (innerContext) {
                  return Scaffold(
                    backgroundColor: context.conduitTheme.surfaceBackground,
                    drawerEnableOpenDragGesture: false,
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      toolbarHeight: kToolbarHeight + 8,
                      centerTitle: true,
                      leadingWidth: 44 + Spacing.inputPadding,
                      leading: _isSelectionMode
                        ? Center(child: GestureDetector(
                            onTap: _clearSelection,
                            child: _buildAppBarPill(context: context, isCircular: true, child: Icon(Icons.close, color: context.conduitTheme.textPrimary)),
                          ))
                        : Center(child: GestureDetector(
                            onTap: () {
                               // Use innerContext to find the drawer layout
                               ResponsiveDrawerLayout.of(innerContext)?.toggle();
                            },
                            child: _buildAppBarPill(context: outerCtx, isCircular: true, child: Icon(Icons.menu, color: context.conduitTheme.textPrimary)),
                          )),
                      title: _isSelectionMode
                        ? _buildAppBarPill(context: context, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text('${_selectedMessageIds.length} selected')))
                        : LayoutBuilder(builder: (ctx, constraints) {
                            Widget? titlePill;
                            if (isLoadingConversation) {
                               titlePill = _buildAppBarPill(context: context, child: const SizedBox(width: 100, height: 18)); 
                            } else if (displayConversationTitle != null) {
                               titlePill = ConduitContextMenu(
                                 actions: buildConversationActions(context: context, ref: ref, conversation: ref.read(activeConversationProvider)),
                                 child: _buildAppBarPill(context: context, child: Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                   child: StreamingTitleText(
                                     title: displayConversationTitle,
                                     style: AppTypography.headlineSmallStyle.copyWith(
                                       color: context.conduitTheme.textPrimary,
                                       fontWeight: FontWeight.w600,
                                       fontSize: 16,
                                       height: 1.3,
                                     ),
                                   ),
                                 )),
                               );
                            }
                            
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (titlePill != null) titlePill,
                              ],
                            );
                        }),
                      actions: [
                        if (!_isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: _handleNewChat,
                              child: _buildAppBarPill(context: context, isCircular: true, child: Icon(Icons.add_comment, color: context.conduitTheme.textPrimary)),
                            ),
                          ),
                        
                        if (!_isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => context.pushNamed('profile'),
                              child: _buildAppBarPill(
                                context: context,
                                isCircular: true,
                                child: UserAvatar(
                                  size: 28,
                                  imageUrl: resolveUserAvatarUrlForUser(apiService, user),
                                  fallbackText: deriveUserDisplayName(user).characters.firstOrNull?.toUpperCase() ?? 'U',
                                ),
                              ),
                            ),
                          ),

                        if (_isSelectionMode)
                          Padding(padding: const EdgeInsets.only(right: 16), child: GestureDetector(onTap: _deleteSelectedMessages, child: _buildAppBarPill(context: context, isCircular: true, child: Icon(Icons.delete, color: context.conduitTheme.error)))),
                      ],
                    ),
                    body: GestureDetector(
                      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ConduitRefreshIndicator(
                              edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
                              onRefresh: () async {
                                 await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: RepaintBoundary(child: _buildMessagesList(theme)),
                            ),
                          ),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: MeasureSize(
                              onChange: (size) { if(mounted) setState(() => _inputHeight = size.height); },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.4, 1.0],
                                    colors: [theme.scaffoldBackgroundColor.withValues(alpha: 0), theme.scaffoldBackgroundColor.withValues(alpha: 0.85), theme.scaffoldBackgroundColor],
                                  )
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: Spacing.xl),
                                    const FileAttachmentWidget(),
                                    const ContextAttachmentWidget(),
                                    ModernChatInput(
                                      onSendMessage: (text) => _handleMessageSend(text, selectedModel),
                                      onFileAttachment: _handleFileAttachment,
                                      onPastedAttachments: _handlePastedAttachments,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: MediaQuery.of(context).padding.top + kToolbarHeight + Spacing.xl,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor.withValues(alpha: 0)],
                                  )
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: _inputHeight > 0 ? _inputHeight : 80,
                            left: 0, right: 0,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: (_showScrollToBottom && !keyboardVisible && canScroll)
                                ? Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          decoration: BoxDecoration(color: theme.cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
                                          child: IconButton(onPressed: _scrollToBottom, icon: const Icon(Icons.arrow_downward)),
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showModelDropdown(BuildContext context, WidgetRef ref, List<Model> models) {}

  void _deleteSelectedMessages() {
    final selected = _getSelectedMessages();
    if (selected.isEmpty) return;
    _clearSelection();
  }
}

class _SelectableMessageWrapper extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const _SelectableMessageWrapper({required this.isSelected, required this.onTap, this.onLongPress, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.conduitTheme.buttonPrimary.withValues(alpha: 0.1) : null,
          border: isSelected ? Border.all(color: context.conduitTheme.buttonPrimary) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
