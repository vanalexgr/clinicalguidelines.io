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
import '../../../core/services/navigation_service.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/ui_utils.dart';
import '../../../shared/widgets/improved_loading_states.dart';
import '../../../shared/widgets/themed_dialogs.dart';
import '../../../shared/widgets/middle_ellipsis_text.dart';
import '../../../shared/utils/conversation_context_menu.dart';
import '../providers/notes_providers.dart';

/// Page displaying the list of all notes with search and time grouping.
class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({super.key});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'notes_search');
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';

  // Section expansion state
  final Map<TimeRange, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    // Default all sections to expanded
    for (final range in TimeRange.values) {
      _expandedSections[range] = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim());
    });
  }

  Future<void> _refreshNotes() async {
    HapticFeedback.lightImpact();
    await ref.read(notesListProvider.notifier).refresh();
  }

  Future<void> _createNewNote() async {
    HapticFeedback.lightImpact();

    final dateFormat = DateFormat('yyyy-MM-dd');
    final defaultTitle = dateFormat.format(DateTime.now());

    final note = await ref
        .read(noteCreatorProvider.notifier)
        .createNote(title: defaultTitle);

    if (note != null && mounted) {
      context.pushNamed(RouteNames.noteEditor, pathParameters: {'id': note.id});
    }
  }

  Future<void> _deleteNote(Note note) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await ThemedDialogs.confirm(
      context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteMessage(
        note.title.isEmpty ? l10n.untitled : note.title,
      ),
      confirmText: l10n.delete,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      HapticFeedback.mediumImpact();
      await ref.read(noteDeleterProvider.notifier).deleteNote(note.id);
    }
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

    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: sidebarTheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildSearchField(context),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
        canPop ? Spacing.xs : Spacing.inputPadding,
        Spacing.md,
        Spacing.inputPadding,
        Spacing.sm,
      ),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              icon: Icon(
                UiUtils.platformIcon(
                  ios: CupertinoIcons.back,
                  android: Icons.arrow_back,
                ),
                color: sidebarTheme.foreground.withValues(alpha: 0.8),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: l10n.back,
            ),
            const SizedBox(width: Spacing.xs),
          ],
          Icon(
            Platform.isIOS ? CupertinoIcons.doc_text_fill : Icons.notes_rounded,
            color: sidebarTheme.foreground.withValues(alpha: 0.7),
            size: IconSize.lg,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              l10n.notes,
              style: AppTypography.headlineSmallStyle.copyWith(
                color: sidebarTheme.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.inputPadding,
        Spacing.xs,
        Spacing.inputPadding,
        Spacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => _onSearchChanged(),
          style: AppTypography.standard.copyWith(
            color: sidebarTheme.foreground,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.searchNotes,
            hintStyle: AppTypography.standard.copyWith(
              color: sidebarTheme.foreground.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Platform.isIOS ? CupertinoIcons.search : Icons.search_rounded,
              color: sidebarTheme.foreground.withValues(alpha: 0.6),
              size: IconSize.input,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: TouchTarget.minimum,
              minHeight: TouchTarget.minimum,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                      _searchFocusNode.unfocus();
                    },
                    icon: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.clear_circled_solid
                          : Icons.clear_rounded,
                      color: sidebarTheme.foreground.withValues(alpha: 0.6),
                      size: IconSize.input,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: TouchTarget.minimum,
              minHeight: TouchTarget.minimum,
            ),
            filled: true,
            fillColor: sidebarTheme.accent.withValues(alpha: 0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: BorderSide(
                color: sidebarTheme.border.withValues(alpha: 0.2),
                width: BorderWidth.thin,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: BorderSide(
                color: sidebarTheme.ring.withValues(alpha: 0.5),
                width: BorderWidth.regular,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final notesAsync = ref.watch(notesListProvider);

    return notesAsync.when(
      data: (notes) => _buildNotesList(context, notes),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildNotesList(BuildContext context, List<Note> allNotes) {
    final notes = _query.isEmpty
        ? allNotes
        : ref.watch(filteredNotesProvider(_query));

    if (notes.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group notes by time range
    final grouped = <TimeRange, List<Note>>{};
    for (final note in notes) {
      final range = getTimeRangeForTimestamp(note.updatedDateTime);
      grouped.putIfAbsent(range, () => []).add(note);
    }

    // Build slivers
    final slivers = <Widget>[];

    for (final range in TimeRange.values) {
      final rangeNotes = grouped[range];
      if (rangeNotes != null && rangeNotes.isNotEmpty) {
        // Section header
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            sliver: SliverToBoxAdapter(
              child: _buildSectionHeader(context, range, rangeNotes.length),
            ),
          ),
        );

        // Notes in section
        if (_expandedSections[range] ?? true) {
          slivers.add(
            const SliverToBoxAdapter(child: SizedBox(height: Spacing.xs)),
          );
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildNoteCard(context, rangeNotes[index]),
                  childCount: rangeNotes.length,
                ),
              ),
            ),
          );
        }

        slivers.add(
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.md)),
        );
      }
    }

    // Add bottom padding for FAB
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 80)));

    return _buildRefreshableScrollView(slivers);
  }

  Widget _buildRefreshableScrollView(List<Widget> slivers) {
    if (Platform.isIOS) {
      return CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _refreshNotes),
          ...slivers,
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNotes,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, TimeRange range, int count) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedSections[range] ?? true;

    String label;
    switch (range) {
      case TimeRange.today:
        label = l10n.today;
      case TimeRange.yesterday:
        label = l10n.yesterday;
      case TimeRange.previousSevenDays:
        label = l10n.previous7Days;
      case TimeRange.previousThirtyDays:
        label = l10n.previous30Days;
      case TimeRange.older:
        label = l10n.older;
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expandedSections[range] = !isExpanded);
      },
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.sm,
          horizontal: Spacing.xs,
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: AnimationDuration.fast,
              curve: Curves.easeOutCubic,
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.chevron_right
                    : Icons.chevron_right_rounded,
                color: sidebarTheme.foreground.withValues(alpha: 0.5),
                size: IconSize.sm,
              ),
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              label,
              style: AppTypography.labelStyle.copyWith(
                color: sidebarTheme.foreground.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.buttonPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppBorderRadius.pill),
              ),
              child: Text(
                '$count',
                style: AppTypography.tiny.copyWith(
                  color: theme.buttonPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;

    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.MMMd();
    final isToday = _isToday(note.updatedDateTime);
    final timeText = isToday
        ? timeFormat.format(note.updatedDateTime)
        : dateFormat.format(note.updatedDateTime);

    final title = note.title.isEmpty ? l10n.untitled : note.title;
    final preview = note.markdownContent.replaceAll('\n', ' ').trim();
    final hasContent = preview.isNotEmpty;

    Color? overlayForStates(Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return theme.buttonPrimary.withValues(alpha: Alpha.buttonPressed);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return theme.buttonPrimary.withValues(alpha: Alpha.hover);
      }
      return Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: sidebarTheme.accent.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: sidebarTheme.border.withValues(alpha: 0.15),
            width: BorderWidth.thin,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            overlayColor: WidgetStateProperty.resolveWith(overlayForStates),
            onTap: () {
              HapticFeedback.selectionClick();
              context.pushNamed(
                RouteNames.noteEditor,
                pathParameters: {'id': note.id},
              );
            },
            onLongPress: () => _showNoteContextMenu(context, note),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Note icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sidebarTheme.accent,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      border: Border.all(
                        color: sidebarTheme.border.withValues(alpha: 0.2),
                        width: BorderWidth.thin,
                      ),
                    ),
                    child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.doc_text_fill
                          : Icons.description_rounded,
                      color: sidebarTheme.foreground.withValues(alpha: 0.6),
                      size: IconSize.md,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        MiddleEllipsisText(
                          title,
                          style: AppTypography.bodyMediumStyle.copyWith(
                            color: sidebarTheme.foreground,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (hasContent) ...[
                          const SizedBox(height: Spacing.xxs),
                          Text(
                            preview,
                            style: AppTypography.bodySmallStyle.copyWith(
                              color: sidebarTheme.foreground.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: Spacing.sm),
                        // Metadata row
                        Row(
                          children: [
                            Icon(
                              Platform.isIOS
                                  ? CupertinoIcons.clock
                                  : Icons.schedule_rounded,
                              color: sidebarTheme.foreground.withValues(alpha: 0.4),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeText,
                              style: AppTypography.tiny.copyWith(
                                color: sidebarTheme.foreground.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (note.user != null && note.user!.name != null) ...[
                              const SizedBox(width: Spacing.sm),
                              Text(
                                '·',
                                style: AppTypography.tiny.copyWith(
                                  color: sidebarTheme.foreground.withValues(alpha: 0.3),
                                ),
                              ),
                              const SizedBox(width: Spacing.sm),
                              Flexible(
                                child: Text(
                                  note.user!.name!,
                                  style: AppTypography.tiny.copyWith(
                                    color: sidebarTheme.foreground.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More button
                  Builder(
                    builder: (buttonContext) => IconButton(
                      icon: Icon(
                        Platform.isIOS
                            ? CupertinoIcons.ellipsis
                            : Icons.more_vert_rounded,
                        color: sidebarTheme.foreground.withValues(alpha: 0.5),
                        size: IconSize.md,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: TouchTarget.badge,
                        minHeight: TouchTarget.badge,
                      ),
                      onPressed: () => _showNoteContextMenu(buttonContext, note),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showNoteContextMenu(BuildContext context, Note note) {
    final l10n = AppLocalizations.of(context)!;

    showConduitContextMenu(
      context: context,
      actions: [
        ConduitContextMenuAction(
          cupertinoIcon: CupertinoIcons.pencil,
          materialIcon: Icons.edit_rounded,
          label: l10n.edit,
          onBeforeClose: () => HapticFeedback.selectionClick(),
          onSelected: () async {
            context.pushNamed(
              RouteNames.noteEditor,
              pathParameters: {'id': note.id},
            );
          },
        ),
        ConduitContextMenuAction(
          cupertinoIcon: CupertinoIcons.doc_on_clipboard,
          materialIcon: Icons.copy_rounded,
          label: l10n.copy,
          onBeforeClose: () => HapticFeedback.selectionClick(),
          onSelected: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: note.markdownContent));
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.noteCopiedToClipboard),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        ConduitContextMenuAction(
          cupertinoIcon: CupertinoIcons.delete,
          materialIcon: Icons.delete_rounded,
          label: l10n.delete,
          destructive: true,
          onBeforeClose: () => HapticFeedback.mediumImpact(),
          onSelected: () async => _deleteNote(note),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = context.conduitTheme;
    final sidebarTheme = context.sidebarTheme;
    final l10n = AppLocalizations.of(context)!;
    final isSearchActive = _query.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: sidebarTheme.accent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                isSearchActive
                    ? (Platform.isIOS
                          ? CupertinoIcons.search
                          : Icons.search_off_rounded)
                    : (Platform.isIOS
                          ? CupertinoIcons.doc_text
                          : Icons.note_add_rounded),
                size: 32,
                color: sidebarTheme.foreground.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              isSearchActive ? l10n.noNotesFound : l10n.noNotesYet,
              style: AppTypography.bodyLargeStyle.copyWith(
                color: sidebarTheme.foreground.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              isSearchActive
                  ? l10n.tryDifferentSearch
                  : l10n.createFirstNoteHint,
              style: AppTypography.bodySmallStyle.copyWith(
                color: sidebarTheme.foreground.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isSearchActive) ...[
              const SizedBox(height: Spacing.lg),
              FilledButton.icon(
                onPressed: _createNewNote,
                icon: Icon(
                  Platform.isIOS ? CupertinoIcons.add : Icons.add_rounded,
                ),
                label: Text(l10n.createNote),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.buttonPrimary,
                  foregroundColor: theme.buttonPrimaryText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.button),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(child: ImprovedLoadingState(message: l10n.loadingNotes));
  }

  Widget _buildError(BuildContext context, Object error) {
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: sidebarTheme.accent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.exclamationmark_triangle
                    : Icons.error_outline_rounded,
                size: 32,
                color: theme.error,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              l10n.failedToLoadNotes,
              style: AppTypography.bodyMediumStyle.copyWith(
                color: sidebarTheme.foreground.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: _refreshNotes,
              icon: Icon(
                Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh_rounded,
              ),
              label: Text(l10n.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: sidebarTheme.foreground.withValues(alpha: 0.8),
                side: BorderSide(
                  color: sidebarTheme.border.withValues(alpha: 0.5),
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

  Widget _buildFAB(BuildContext context) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.buttonPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.buttonPrimary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _createNewNote,
        backgroundColor: theme.buttonPrimary,
        foregroundColor: theme.buttonPrimaryText,
        elevation: 0,
        highlightElevation: 2,
        tooltip: l10n.createNote,
        child: Icon(Platform.isIOS ? CupertinoIcons.add : Icons.add_rounded),
      ),
    );
  }
}
