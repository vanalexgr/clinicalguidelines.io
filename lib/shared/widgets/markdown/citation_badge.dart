import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/chat_message.dart';
import '../../theme/theme_extensions.dart';

/// Helper utilities for working with source references.
class _SourceHelper {
  const _SourceHelper._();

  /// Extracts a URL from a source reference, checking multiple fields.
  static String? getSourceUrl(ChatSourceReference source) {
    String? url = source.url;
    if (url == null || url.isEmpty) {
      if (source.id != null && source.id!.startsWith('http')) {
        url = source.id;
      } else if (source.title != null && source.title!.startsWith('http')) {
        url = source.title;
      } else if (source.metadata != null) {
        url =
            source.metadata!['url']?.toString() ??
            source.metadata!['source']?.toString() ??
            source.metadata!['link']?.toString();
      }
    }
    return (url != null && url.startsWith('http')) ? url : null;
  }

  /// Gets a display title for a source.
  static String getSourceTitle(ChatSourceReference source, int index) {
    if (source.title != null && source.title!.isNotEmpty) {
      return source.title!;
    }
    final url = getSourceUrl(source);
    if (url != null) {
      return _extractDomain(url);
    }
    if (source.id != null && source.id!.isNotEmpty) {
      return source.id!;
    }
    return 'Source ${index + 1}';
  }

  /// Extracts the domain from a URL for display.
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
  }

  /// Launches a URL in an external browser.
  static Future<void> launchSourceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

/// A compact badge showing a citation reference that links to a source.
///
/// Mirrors OpenWebUI's Source.svelte and SourceToken.svelte behavior.
class CitationBadge extends StatelessWidget {
  const CitationBadge({
    super.key,
    required this.sourceIndex,
    required this.sources,
    this.onTap,
  });

  /// 0-based index into the sources list.
  final int sourceIndex;

  /// List of sources from the message.
  final List<ChatSourceReference> sources;

  /// Optional tap callback. If null, will try to launch URL.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    // Check if index is valid
    if (sourceIndex < 0 || sourceIndex >= sources.length) {
      // Invalid source index - show placeholder
      return _buildBadge(
        theme: theme,
        displayNumber: sourceIndex + 1,
        isValid: false,
      );
    }

    final source = sources[sourceIndex];
    final url = _SourceHelper.getSourceUrl(source);
    final title = _SourceHelper.getSourceTitle(source, sourceIndex);

    return Tooltip(
      message: title,
      preferBelow: false,
      child: _buildBadge(
        theme: theme,
        displayNumber: sourceIndex + 1,
        isValid: true,
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (url != null) {
            _SourceHelper.launchSourceUrl(url);
          }
        },
      ),
    );
  }

  Widget _buildBadge({
    required ConduitThemeExtension theme,
    required int displayNumber,
    required bool isValid,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isValid
              ? theme.surfaceContainer.withValues(alpha: 0.6)
              : theme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          displayNumber.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isValid
                ? theme.textPrimary.withValues(alpha: 0.8)
                : theme.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// A grouped citation badge for multiple sources like [1,2,3].
class CitationBadgeGroup extends StatelessWidget {
  const CitationBadgeGroup({
    super.key,
    required this.sourceIndices,
    required this.sources,
    this.onSourceTap,
  });

  /// 0-based indices into the sources list.
  final List<int> sourceIndices;

  /// List of sources from the message.
  final List<ChatSourceReference> sources;

  /// Optional callback when a source is tapped.
  final void Function(int index)? onSourceTap;

  @override
  Widget build(BuildContext context) {
    if (sourceIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    // For single citation, use simple badge
    if (sourceIndices.length == 1) {
      return CitationBadge(
        sourceIndex: sourceIndices.first,
        sources: sources,
        onTap: onSourceTap != null
            ? () => onSourceTap!(sourceIndices.first)
            : null,
      );
    }

    // For multiple citations, show grouped badge
    final theme = context.conduitTheme;
    final validCount = sourceIndices
        .where((i) => i >= 0 && i < sources.length)
        .length;

    return PopupMenuButton<int>(
      tooltip: 'View sources',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: theme.surfaceBackground,
      itemBuilder: (context) {
        return sourceIndices.map((index) {
          final isValid = index >= 0 && index < sources.length;
          final title = isValid
              ? _SourceHelper.getSourceTitle(sources[index], index)
              : 'Invalid source';

          return PopupMenuItem<int>(
            value: index,
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, color: theme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (index) {
        if (onSourceTap != null) {
          onSourceTap!(index);
        } else if (index >= 0 && index < sources.length) {
          final url = _SourceHelper.getSourceUrl(sources[index]);
          if (url != null) {
            _SourceHelper.launchSourceUrl(url);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (sourceIndices.first + 1).toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            if (validCount > 1) ...[
              Text(
                '+${validCount - 1}',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
