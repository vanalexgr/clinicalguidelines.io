import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:conduit/l10n/app_localizations.dart';
import '../../../core/models/note.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/ui_utils.dart';
import '../../../shared/widgets/improved_loading_states.dart';
import '../../../shared/widgets/themed_dialogs.dart';
import '../../chat/services/voice_input_service.dart';
import '../providers/notes_providers.dart';

/// Page for editing a note with OpenWebUI-style layout.
class NoteEditorPage extends ConsumerStatefulWidget {
  final String noteId;

  const NoteEditorPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode(debugLabel: 'note_title');
  final FocusNode _contentFocusNode = FocusNode(debugLabel: 'note_content');
  final ScrollController _scrollController = ScrollController();

  Timer? _saveDebounce;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isGeneratingTitle = false;
  bool _isEnhancing = false;
  bool _isRecording = false;
  Note? _note;

  // Voice input
  VoiceInputService? _voiceService;
  StreamSubscription<String>? _voiceSub;
  String _voiceBaseText = '';

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
    // Rebuild when title focus changes to show/hide the generate title button
    _titleFocusNode.addListener(_onTitleFocusChanged);
  }

  void _onTitleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _voiceSub?.cancel();
    _voiceService?.stopListening();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final json = await api.getNoteById(widget.noteId);
      final note = Note.fromJson(json);

      if (mounted) {
        setState(() {
          _note = note;
          _titleController.text = note.title;
          _contentController.text = note.markdownContent;
          _isLoading = false;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _onContentChanged() {
    if (!mounted || _isLoading) return;

    // Check if content actually changed from the saved note
    final titleChanged = _note != null && _titleController.text != _note!.title;
    final contentChanged =
        _note != null && _contentController.text != _note!.markdownContent;
    final hasRealChanges = titleChanged || contentChanged;

    if (hasRealChanges != _hasChanges) {
      setState(() => _hasChanges = hasRealChanges);
    }

    if (hasRealChanges) {
      _debounceSave();
    }
  }

  void _debounceSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_note == null || !_hasChanges) return;
    await _saveNote(showFeedback: false);
  }

  Future<void> _saveNote({bool showFeedback = true}) async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text;

      final data = <String, dynamic>{
        'content': <String, dynamic>{
          'json': null,
          'html': _markdownToHtml(content),
          'md': content,
        },
      };

      // Use the server's response to get authoritative data (including updated_at)
      final json = await api.updateNote(
        widget.noteId,
        title: title.isEmpty ? AppLocalizations.of(context)!.untitled : title,
        data: data,
      );

      final updatedNote = Note.fromJson(json);

      ref.read(notesListProvider.notifier).updateNote(updatedNote);

      if (mounted) {
        setState(() {
          _note = updatedNote;
          _isSaving = false;
          _hasChanges = false;
        });

        if (showFeedback) {
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError(e.toString());
      }
    }
  }

  String _markdownToHtml(String markdown) {
    final paragraphs = markdown.split('\n\n');
    final html = paragraphs
        .map((p) {
          if (p.trim().isEmpty) return '';
          if (p.startsWith('# ')) {
            return '<h1>${_escapeHtml(p.substring(2))}</h1>';
          }
          if (p.startsWith('## ')) {
            return '<h2>${_escapeHtml(p.substring(3))}</h2>';
          }
          if (p.startsWith('### ')) {
            return '<h3>${_escapeHtml(p.substring(4))}</h3>';
          }
          // Escape entire paragraph first to prevent XSS, then apply
          // markdown formatting replacements on the escaped text.
          var text = _escapeHtml(p);
          text = text.replaceAllMapped(
            RegExp(r'\*\*(.+?)\*\*'),
            (m) => '<strong>${m.group(1)!}</strong>',
          );
          text = text.replaceAllMapped(
            RegExp(r'\*(.+?)\*'),
            (m) => '<em>${m.group(1)!}</em>',
          );
          return '<p>$text</p>';
        })
        .join('\n');
    return html;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.conduitTheme.error,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      await _saveNote(showFeedback: false);
    }
    return true;
  }

  Future<void> _deleteNote() async {
    if (_note == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ThemedDialogs.confirm(
      context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteMessage(
        _note!.title.isEmpty ? l10n.untitled : _note!.title,
      ),
      confirmText: l10n.delete,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      HapticFeedback.mediumImpact();
      final success = await ref
          .read(noteDeleterProvider.notifier)
          .deleteNote(widget.noteId);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Get the selected model ID for AI operations
  String? _getSelectedModelId() {
    final selectedModel = ref.read(selectedModelProvider);
    return selectedModel?.id;
  }

  // AI title generation
  Future<void> _generateTitle() async {
    if (_note == null || _isGeneratingTitle) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showError(AppLocalizations.of(context)!.noContentToGenerateTitle);
      return;
    }

    final modelId = _getSelectedModelId();
    if (modelId == null) {
      _showError(AppLocalizations.of(context)!.noModelSelected);
      return;
    }

    setState(() => _isGeneratingTitle = true);
    HapticFeedback.lightImpact();

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      setState(() => _isGeneratingTitle = false);
      return;
    }

    try {
      final generatedTitle = await api.generateNoteTitle(
        content,
        modelId: modelId,
      );
      if (mounted && generatedTitle != null && generatedTitle.isNotEmpty) {
        _titleController.text = generatedTitle;
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.failedToGenerateTitle);
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingTitle = false);
      }
    }
  }

  // AI content enhancement
  Future<void> _enhanceContent() async {
    if (_note == null || _isEnhancing) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      _showError(AppLocalizations.of(context)!.noContentToEnhance);
      return;
    }

    final modelId = _getSelectedModelId();
    if (modelId == null) {
      _showError(AppLocalizations.of(context)!.noModelSelected);
      return;
    }

    setState(() => _isEnhancing = true);
    HapticFeedback.lightImpact();

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      setState(() => _isEnhancing = false);
      return;
    }

    try {
      final enhancedContent = await api.enhanceNoteContent(
        content,
        modelId: modelId,
      );
      if (mounted && enhancedContent != null && enhancedContent.isNotEmpty) {
        _contentController.text = enhancedContent;
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noteEnhanced),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.failedToEnhanceNote);
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }

  // Voice dictation
  Future<void> _toggleDictation() async {
    if (_isRecording) {
      await _stopDictation();
    } else {
      await _startDictation();
    }
  }

  Future<void> _startDictation() async {
    _voiceService ??= VoiceInputService(api: ref.read(apiServiceProvider));

    try {
      final ok = await _voiceService!.initialize();
      if (!mounted) return;
      if (!ok) {
        _showError(AppLocalizations.of(context)!.voiceInputUnavailable);
        return;
      }

      final stream = await _voiceService!.beginListening();
      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _voiceBaseText = _contentController.text;
      });

      HapticFeedback.lightImpact();

      _voiceSub?.cancel();
      _voiceSub = stream.listen(
        (text) {
          if (!mounted) return;
          final updated = _voiceBaseText.isEmpty
              ? text
              : '${_voiceBaseText.trimRight()} $text';
          _contentController.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: updated.length),
          );
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _isRecording = false);
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _isRecording = false);
        },
      );
    } catch (e) {
      _showError(AppLocalizations.of(context)!.failedToStartDictation);
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _stopDictation() async {
    await _voiceService?.stopListening();
    _voiceSub?.cancel();
    if (mounted) {
      setState(() => _isRecording = false);
      HapticFeedback.selectionClick();
    }
  }

  void _copyToClipboard() {
    final l10n = AppLocalizations.of(context)!;
    final content = _contentController.text;
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noteCopiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidebarTheme = context.sidebarTheme;

    // Check if notes feature is enabled - redirect to chat if disabled
    final notesEnabled = ref.watch(notesFeatureEnabledProvider);
    if (!notesEnabled) {
      // Redirect back to chat on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/chat');
        }
      });
      // Show empty scaffold while redirecting
      return Scaffold(backgroundColor: sidebarTheme.background);
    }

    return PopScope(
      // Only allow immediate pop when there are no unsaved changes.
      // When there are changes, we intercept, save first, then pop manually.
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already popped, nothing to do
        // Capture navigator before async gap
        final navigator = Navigator.of(context);
        // Save changes before allowing pop
        await _saveNote(showFeedback: false);
        if (!mounted) return;
        navigator.pop();
      },
      child: ErrorBoundary(
        child: Scaffold(
          backgroundColor: sidebarTheme.background,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context),
                    if (!_isLoading && _note != null)
                      _buildMetadataBar(context),
                    Expanded(child: _buildBody(context)),
                  ],
                ),
                // Floating action buttons
                if (!_isLoading && _note != null)
                  _buildFloatingActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.sm,
        Spacing.sm,
        Spacing.xs,
      ),
      color: sidebarTheme.background,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              UiUtils.platformIcon(
                ios: CupertinoIcons.back,
                android: Icons.arrow_back_rounded,
              ),
              color: theme.iconPrimary,
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _onWillPop();
              if (!mounted) return;
              navigator.pop();
            },
            tooltip: l10n.back,
          ),
          const SizedBox(width: Spacing.xs),

          // Title input
          Expanded(
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              enabled: !_isGeneratingTitle,
              style: AppTypography.headlineSmallStyle.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: _isGeneratingTitle
                    ? l10n.generatingTitle
                    : l10n.noteTitle,
                hintStyle: AppTypography.headlineSmallStyle.copyWith(
                  color: theme.textSecondary.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _contentFocusNode.requestFocus(),
            ),
          ),

          // Generate title button - aligned with other header icons
          AnimatedOpacity(
            opacity: _titleFocusNode.hasFocus && !_isGeneratingTitle
                ? 1.0
                : 0.0,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: !_titleFocusNode.hasFocus || _isGeneratingTitle,
              child: IconButton(
                icon: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.sparkles
                      : Icons.auto_awesome_rounded,
                  color: theme.buttonPrimary,
                ),
                onPressed: _generateTitle,
                tooltip: l10n.generateTitle,
              ),
            ),
          ),

          // Save indicator
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: SizedBox(
                width: IconSize.sm,
                height: IconSize.sm,
                child: CircularProgressIndicator(
                  strokeWidth: BorderWidth.medium,
                  valueColor: AlwaysStoppedAnimation(theme.loadingIndicator),
                ),
              ),
            )
          else if (_hasChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // Menu
          PopupMenuButton<String>(
            icon: Icon(
              Platform.isIOS
                  ? CupertinoIcons.ellipsis
                  : Icons.more_vert_rounded,
              color: theme.iconPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyToClipboard();
                case 'delete':
                  _deleteNote();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.doc_on_clipboard
                          : Icons.copy_rounded,
                      color: theme.iconPrimary,
                      size: IconSize.md,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(l10n.copy),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.delete
                          : Icons.delete_rounded,
                      color: theme.error,
                      size: IconSize.md,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(l10n.delete, style: TextStyle(color: theme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataBar(BuildContext context) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;

    final dateFormat = DateFormat.MMMd();
    final timeFormat = DateFormat.jm();
    final createdDate = _note != null
        ? '${dateFormat.format(_note!.createdDateTime)} ${timeFormat.format(_note!.createdDateTime)}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Created date
            _buildMetadataChip(
              context,
              icon: Platform.isIOS
                  ? CupertinoIcons.calendar
                  : Icons.calendar_today_rounded,
              label: createdDate,
            ),
            _buildMetadataSeparator(theme),
            // Word count
            _buildMetadataChip(
              context,
              icon: Platform.isIOS
                  ? CupertinoIcons.doc_text
                  : Icons.article_rounded,
              label: l10n.wordCount(_wordCount),
            ),
            _buildMetadataSeparator(theme),
            // Character count
            _buildMetadataChip(
              context,
              icon: Platform.isIOS
                  ? CupertinoIcons.textformat_abc
                  : Icons.text_fields_rounded,
              label: l10n.charCount(_charCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSeparator(ConduitThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxs),
      child: Text(
        '·',
        style: AppTypography.tiny.copyWith(
          color: theme.textTertiary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = context.conduitTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.xxs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.textTertiary.withValues(alpha: 0.7),
            size: IconSize.xs,
          ),
          const SizedBox(width: Spacing.xxs),
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: theme.textTertiary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: ImprovedLoadingState(
          message: AppLocalizations.of(context)!.loadingNote,
        ),
      );
    }

    if (_note == null) {
      return _buildNotFoundState(context);
    }

    return _buildEditor(context);
  }

  Widget _buildEditor(BuildContext context) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => _contentFocusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          Spacing.inputPadding,
          Spacing.md,
          Spacing.inputPadding,
          120, // Extra padding for floating buttons
        ),
        child: TextField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          style: AppTypography.bodyLargeStyle.copyWith(
            color: theme.textPrimary,
            height: 1.8,
          ),
          decoration: InputDecoration(
            hintText: l10n.writeNote,
            hintStyle: AppTypography.bodyLargeStyle.copyWith(
              color: theme.textSecondary.withValues(alpha: 0.35),
              height: 1.8,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: null,
          minLines: 20,
          textAlignVertical: TextAlignVertical.top,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      left: Spacing.md,
      right: Spacing.md,
      bottom: Spacing.md,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dictation button
          _buildFloatingButton(
            context,
            icon: _isRecording
                ? (Platform.isIOS
                      ? CupertinoIcons.stop_fill
                      : Icons.stop_rounded)
                : (Platform.isIOS
                      ? CupertinoIcons.mic_fill
                      : Icons.mic_rounded),
            color: _isRecording ? theme.error : null,
            isLoading: false,
            tooltip: _isRecording ? l10n.stopRecording : l10n.startDictation,
            onPressed: _toggleDictation,
          ),

          // AI button
          _buildFloatingButton(
            context,
            icon: Platform.isIOS
                ? CupertinoIcons.sparkles
                : Icons.auto_awesome_rounded,
            isLoading: _isEnhancing,
            tooltip: l10n.enhanceWithAI,
            onPressed: _isEnhancing ? null : _enhanceContent,
            showMenu: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
    bool showMenu = false,
  }) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;

    final buttonChild = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: sidebarTheme.border.withValues(alpha: 0.2),
          width: BorderWidth.thin,
        ),
        boxShadow: ConduitShadows.medium(context),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: IconSize.md,
                height: IconSize.md,
                child: CircularProgressIndicator(
                  strokeWidth: BorderWidth.medium,
                  valueColor: AlwaysStoppedAnimation(theme.loadingIndicator),
                ),
              ),
            )
          : Icon(icon, color: color ?? theme.iconPrimary, size: IconSize.lg),
    );

    if (showMenu) {
      return PopupMenuButton<String>(
        tooltip: tooltip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        offset: const Offset(0, -120),
        onSelected: (value) {
          switch (value) {
            case 'enhance':
              _enhanceContent();
            case 'title':
              _generateTitle();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'enhance',
            child: Row(
              children: [
                Icon(
                  Platform.isIOS
                      ? CupertinoIcons.sparkles
                      : Icons.auto_fix_high_rounded,
                  color: theme.buttonPrimary,
                  size: IconSize.md,
                ),
                const SizedBox(width: Spacing.sm),
                Text(l10n.enhanceNote),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'title',
            child: Row(
              children: [
                Icon(
                  Platform.isIOS
                      ? CupertinoIcons.textformat
                      : Icons.title_rounded,
                  color: theme.buttonPrimary,
                  size: IconSize.md,
                ),
                const SizedBox(width: Spacing.sm),
                Text(l10n.generateTitle),
              ],
            ),
          ),
        ],
        child: buttonChild,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: buttonChild,
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: sidebarTheme.accent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.doc_text
                    : Icons.description_outlined,
                size: 36,
                color: sidebarTheme.foreground.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              l10n.noteNotFound,
              style: AppTypography.headlineSmallStyle.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back_rounded,
              ),
              label: Text(l10n.goBack),
              style: OutlinedButton.styleFrom(
                foregroundColor: sidebarTheme.primary,
                side: BorderSide(
                  color: sidebarTheme.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
