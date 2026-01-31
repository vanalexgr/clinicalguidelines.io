import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/chat_message.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/source_helper.dart';
import '../dialogs/source_details_dialog.dart';



/// A compact inline citation badge showing source domain/title.
///
/// Uses the app's design system for consistency with other chips and badges.
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
      return const SizedBox.shrink();
    }

    final source = sources[sourceIndex];
    final url = SourceHelper.getSourceUrl(source);
    final title = SourceHelper.getSourceTitle(source, sourceIndex);
    final displayTitle = SourceHelper.formatDisplayTitle(title);

    return Tooltip(
      message: title,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else if (url != null) {
              SourceHelper.launchSourceUrl(url);
            } else {
              showSourceDetailsDialog(context, source);
            }
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xxs,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppBorderRadius.chip),
              border: Border.all(
                color: theme.cardBorder.withValues(alpha: 0.5),
                width: BorderWidth.thin,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 10,
                  color: theme.textSecondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: Spacing.xxs),
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmall,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

/// A grouped citation badge for multiple sources like [1,2,3].
///
/// Shows first source with +N indicator for additional sources.
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

    final theme = context.conduitTheme;

    // Get first valid source for display
    final firstIndex = sourceIndices.first;
    final isFirstValid = firstIndex >= 0 && firstIndex < sources.length;

    if (!isFirstValid) {
      return const SizedBox.shrink();
    }

    final firstSource = sources[firstIndex];
    final firstTitle = SourceHelper.getSourceTitle(firstSource, firstIndex);
    final displayTitle = SourceHelper.formatDisplayTitle(firstTitle);
    final additionalCount = sourceIndices.length - 1;

    return PopupMenuButton<int>(
      tooltip: 'View sources',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      color: theme.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      elevation: Elevation.medium,
      itemBuilder: (context) {
        return sourceIndices
            .map((index) {
              final isValid = index >= 0 && index < sources.length;
              if (!isValid) return null;

              final source = sources[index];
              final title = SourceHelper.getSourceTitle(source, index);

              return PopupMenuItem<int>(
                value: index,
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 14,
                      color: theme.textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        SourceHelper.formatDisplayTitle(title),
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            })
            .whereType<PopupMenuItem<int>>()
            .toList();
      },
      onSelected: (index) {
        if (onSourceTap != null) {
          onSourceTap!(index);
        } else if (index >= 0 && index < sources.length) {
          final source = sources[index];
          final url = SourceHelper.getSourceUrl(source);
          if (url != null) {
            SourceHelper.launchSourceUrl(url);
          } else {
            showSourceDetailsDialog(context, source);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: theme.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
          border: Border.all(
            color: theme.cardBorder.withValues(alpha: 0.5),
            width: BorderWidth.thin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_rounded,
              size: 10,
              color: theme.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: Spacing.xxs),
            Text(
              displayTitle,
              style: TextStyle(
                fontSize: AppTypography.labelSmall,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: Spacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: theme.buttonPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Text(
                '+$additionalCount',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.buttonPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
