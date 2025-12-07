import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/models/chat_message.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../core/utils/debug_logger.dart';

/// A modern, mobile-first streaming status widget that displays
/// live status updates during AI response generation.
class StreamingStatusWidget extends StatefulWidget {
  const StreamingStatusWidget({
    super.key,
    required this.updates,
    this.isStreaming = true,
  });

  final List<ChatStatusUpdate> updates;
  final bool isStreaming;

  @override
  State<StreamingStatusWidget> createState() => _StreamingStatusWidgetState();
}

class _StreamingStatusWidgetState extends State<StreamingStatusWidget>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isStreaming) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StreamingStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isStreaming && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.updates
        .where((u) => u.hidden != true)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    final current = visible.last;
    final hasPrevious = visible.length > 1;

    final theme = context.conduitTheme;

    return InkWell(
      onTap: hasPrevious ? () => setState(() => _expanded = !_expanded) : null,
      borderRadius: BorderRadius.circular(AppBorderRadius.small),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: BorderWidth.thin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status header (always visible)
            _StatusRow(
              update: current,
              isPending: current.done != true && widget.isStreaming,
              shimmerController: _shimmerController,
              showExpandIcon: hasPrevious,
              isExpanded: _expanded,
            ),

            // Expandable timeline with full history
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: hasPrevious
                  ? _HistoryTimeline(
                      updates: visible,
                      shimmerController: _shimmerController,
                      isStreaming: widget.isStreaming,
                    )
                  : const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status row with expand chevron (header when collapsed).
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.update,
    required this.isPending,
    required this.shimmerController,
    this.showExpandIcon = false,
    this.isExpanded = false,
  });

  final ChatStatusUpdate update;
  final bool isPending;
  final AnimationController shimmerController;
  final bool showExpandIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final queries = _collectQueries(update);
    final links = _collectLinks(update);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expand chevron
            if (showExpandIcon)
              Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: theme.textSecondary,
              ),
            if (showExpandIcon) const SizedBox(width: Spacing.xs),
            // Status icon
            _StatusIcon(
              action: update.action,
              isPending: isPending,
              shimmerController: shimmerController,
            ),
            const SizedBox(width: Spacing.xs),
            // Status text
            Flexible(
              child: _StatusText(
                update: update,
                isPending: isPending,
                shimmerController: shimmerController,
              ),
            ),
          ],
        ),

        // Query pills (only when collapsed)
        if (!isExpanded && queries.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          _QueryChips(queries: queries),
        ],

        // Source links (only when collapsed)
        if (!isExpanded && links.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          _SourceLinks(links: links),
        ],
      ],
    );
  }
}

/// Full history timeline matching the web client.
class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({
    required this.updates,
    required this.shimmerController,
    required this.isStreaming,
  });

  final List<ChatStatusUpdate> updates;
  final AnimationController shimmerController;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...updates.asMap().entries.map((entry) {
            final index = entry.key;
            final update = entry.value;
            final isLast = index == updates.length - 1;
            final isPending = isLast && update.done != true && isStreaming;

            return _TimelineItem(
              update: update,
              isPending: isPending,
              shimmerController: shimmerController,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

/// Single timeline item with dot and connecting line.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.update,
    required this.isPending,
    required this.shimmerController,
    required this.isLast,
  });

  final ChatStatusUpdate update;
  final bool isPending;
  final AnimationController shimmerController;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final queries = _collectQueries(update);
    final links = _collectLinks(update);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (dot + line)
          SizedBox(
            width: 16,
            child: Column(
              children: [
                // Dot
                Container(
                  margin: const EdgeInsets.only(top: Spacing.xs),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPending
                        ? theme.buttonPrimary
                        : theme.textTertiary.withValues(alpha: 0.6),
                  ),
                ),
                // Connecting line (not on last item)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.xs),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status text
                  _StatusText(
                    update: update,
                    isPending: isPending,
                    shimmerController: shimmerController,
                  ),
                  // Query chips
                  if (queries.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    _QueryChips(queries: queries),
                  ],
                  // Source links
                  if (links.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    _SourceLinks(links: links),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status icon matching the reasoning tile style.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.action,
    required this.isPending,
    required this.shimmerController,
  });

  final String? action;
  final bool isPending;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final iconData = _getIconForAction(action);
    final iconColor = theme.buttonPrimary;

    // Simple icon matching reasoning tile (14px, primary color)
    if (!isPending) {
      return Icon(iconData, size: 14, color: iconColor);
    }

    // Subtle pulse animation for pending state
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final opacity = 0.6 + (0.4 * (1.0 - shimmerController.value));
        return Icon(
          iconData,
          size: 14,
          color: iconColor.withValues(alpha: opacity),
        );
      },
    );
  }

  IconData _getIconForAction(String? action) {
    switch (action) {
      case 'web_search':
      case 'web_search_queries_generated':
      case 'queries_generated':
        return Icons.search_rounded;
      case 'knowledge_search':
        return Icons.menu_book_rounded;
      case 'sources_retrieved':
        return Icons.source_rounded;
      case 'generating':
        return Icons.edit_note_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}

/// Status text matching the reasoning tile style.
class _StatusText extends StatelessWidget {
  const _StatusText({
    required this.update,
    required this.isPending,
    required this.shimmerController,
  });

  final ChatStatusUpdate update;
  final bool isPending;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final description = _resolveStatusDescription(update);

    // Match reasoning tile text style
    final textStyle = TextStyle(
      fontSize: AppTypography.bodySmall,
      color: theme.textSecondary,
      fontWeight: FontWeight.w500,
    );

    if (!isPending) {
      return Text(
        description,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    // Shimmer effect for pending state
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final opacity = 0.5 + (0.5 * (1.0 - shimmerController.value));
        return Text(
          description,
          overflow: TextOverflow.ellipsis,
          style: textStyle.copyWith(
            color: theme.textSecondary.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}

/// Horizontally scrollable query chips.
class _QueryChips extends StatelessWidget {
  const _QueryChips({required this.queries});

  final List<String> queries;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: queries.length,
        separatorBuilder: (_, index) => const SizedBox(width: Spacing.xs),
        itemBuilder: (context, index) {
          final query = queries[index];
          return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchSearch(query),
                  borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.buttonPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                      border: Border.all(
                        color: theme.buttonPrimary.withValues(alpha: 0.2),
                        width: BorderWidth.thin,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 14,
                          color: theme.buttonPrimary,
                        ),
                        const SizedBox(width: Spacing.xxs),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            query,
                            style: TextStyle(
                              fontSize: AppTypography.labelSmall,
                              fontWeight: FontWeight.w500,
                              color: theme.buttonPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms, delay: (50 * index).ms)
              .slideX(
                begin: 0.1,
                end: 0,
                duration: 200.ms,
                delay: (50 * index).ms,
              );
        },
      ),
    );
  }

  void _launchSearch(String query) async {
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      DebugLogger.log('Failed to launch search: $e', scope: 'status');
    }
  }
}

/// Source link chips with favicons.
class _SourceLinks extends StatelessWidget {
  const _SourceLinks({required this.links});

  final List<_LinkData> links;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    // Show max 4 links, with a "+N more" indicator
    final displayLinks = links.take(4).toList();
    final remaining = links.length - 4;

    return Wrap(
      spacing: Spacing.xs,
      runSpacing: Spacing.xs,
      children: [
        ...displayLinks.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          return _SourceLinkChip(link: link)
              .animate()
              .fadeIn(duration: 200.ms, delay: (50 * index).ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 200.ms,
                delay: (50 * index).ms,
              );
        }),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: AppTypography.labelSmall,
                color: theme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(
            duration: 200.ms,
            delay: (50 * displayLinks.length).ms,
          ),
      ],
    );
  }
}

/// Individual source link chip with favicon.
class _SourceLinkChip extends StatelessWidget {
  const _SourceLinkChip({required this.link});

  final _LinkData link;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final domain = _extractDomain(link.url);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(link.url),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: BorderWidth.thin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favicon
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  'https://www.google.com/s2/favicons?sz=32&domain=$domain',
                  width: 14,
                  height: 14,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.public_rounded,
                    size: 14,
                    color: theme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.xs),
              // Domain or title
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  link.title ?? domain,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmall,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.xxs),
              Icon(
                Icons.open_in_new_rounded,
                size: 10,
                color: theme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      DebugLogger.log('Failed to launch URL: $e', scope: 'status');
    }
  }

  String _extractDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    var host = uri.host;
    if (host.startsWith('www.')) host = host.substring(4);
    return host;
  }
}

// Helper classes and functions

class _LinkData {
  const _LinkData({required this.url, this.title});
  final String url;
  final String? title;
}

List<String> _collectQueries(ChatStatusUpdate update) {
  final merged = <String>[];
  for (final query in update.queries) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty && !merged.contains(trimmed)) {
      merged.add(trimmed);
    }
  }
  final single = update.query?.trim();
  if (single != null && single.isNotEmpty && !merged.contains(single)) {
    merged.add(single);
  }
  return merged;
}

List<_LinkData> _collectLinks(ChatStatusUpdate update) {
  final links = <_LinkData>[];

  // Collect from items
  for (final item in update.items) {
    final url = item.link;
    if (url != null && url.isNotEmpty) {
      links.add(_LinkData(url: url, title: item.title));
    }
  }

  // Collect from urls
  for (final url in update.urls) {
    if (url.isNotEmpty && !links.any((l) => l.url == url)) {
      links.add(_LinkData(url: url));
    }
  }

  return links;
}

String _resolveStatusDescription(ChatStatusUpdate update) {
  final description = update.description?.trim();
  final action = update.action?.trim();

  // Match OpenWebUI copy exactly
  if (action == 'knowledge_search' && update.query?.isNotEmpty == true) {
    return 'Searching Knowledge for "${update.query}"';
  }

  if (action == 'web_search_queries_generated' && update.queries.isNotEmpty) {
    return 'Searching';
  }

  if (action == 'queries_generated' && update.queries.isNotEmpty) {
    return 'Querying';
  }

  if (action == 'sources_retrieved' && update.count != null) {
    final count = update.count!;
    if (count == 0) return 'No sources found';
    if (count == 1) return 'Retrieved 1 source';
    return 'Retrieved $count sources';
  }

  // Handle description with placeholders
  if (description != null && description.isNotEmpty) {
    // Handle known OpenWebUI descriptions
    if (description == 'Generating search query') {
      return 'Generating search query';
    }
    if (description == 'No search query generated') {
      return 'No search query generated';
    }
    if (description == 'Searching the web') {
      return 'Searching the web';
    }
    return _replaceStatusPlaceholders(description, update);
  }

  if (action != null && action.isNotEmpty) {
    // Convert action to readable text
    return action.replaceAll('_', ' ').capitalize();
  }

  return 'Processing';
}

String _replaceStatusPlaceholders(String template, ChatStatusUpdate update) {
  var result = template;

  if (result.contains('{{count}}')) {
    final count = update.count ?? update.urls.length + update.items.length;
    result = result.replaceAll(
      '{{count}}',
      count > 0 ? count.toString() : 'multiple',
    );
  }

  if (result.contains('{{searchQuery}}')) {
    final query = update.query?.trim();
    if (query != null && query.isNotEmpty) {
      result = result.replaceAll('{{searchQuery}}', query);
    }
  }

  return result;
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

