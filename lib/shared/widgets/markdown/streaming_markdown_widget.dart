import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/utils/citation_parser.dart';
import 'citation_badge.dart';
import 'markdown_config.dart';
import 'markdown_preprocessor.dart';

// Pre-compiled regex for mermaid diagram detection (performance optimization)
final _mermaidRegex = RegExp(r'```mermaid\s*([\s\S]*?)```', multiLine: true);

// Pre-compiled regex for HTML code blocks that may contain ChartJS
final _htmlBlockRegex = RegExp(r'```html\s*([\s\S]*?)```', multiLine: true);

class StreamingMarkdownWidget extends StatelessWidget {
  const StreamingMarkdownWidget({
    super.key,
    required this.content,
    required this.isStreaming,
    this.onTapLink,
    this.imageBuilderOverride,
    this.sources,
    this.onSourceTap,
  });

  final String content;
  final bool isStreaming;
  final MarkdownLinkTapCallback? onTapLink;
  final Widget Function(Uri uri, String? title, String? alt)?
  imageBuilderOverride;

  /// Sources for inline citation badge rendering.
  /// When provided, [1] patterns will be rendered as clickable badges.
  final List<ChatSourceReference>? sources;

  /// Callback when a source badge is tapped.
  final void Function(int sourceIndex)? onSourceTap;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = ConduitMarkdownPreprocessor.normalize(content);

    // Collect all special blocks (Mermaid and ChartJS)
    final specialBlocks = <_SpecialBlock>[];

    // Find mermaid blocks
    for (final match in _mermaidRegex.allMatches(normalized)) {
      final code = match.group(1)?.trim() ?? '';
      if (code.isNotEmpty) {
        specialBlocks.add(
          _SpecialBlock(
            start: match.start,
            end: match.end,
            type: _BlockType.mermaid,
            content: code,
          ),
        );
      }
    }

    // Find HTML blocks that contain ChartJS
    for (final match in _htmlBlockRegex.allMatches(normalized)) {
      final html = match.group(1)?.trim() ?? '';
      if (html.isNotEmpty && ConduitMarkdown.containsChartJs(html)) {
        specialBlocks.add(
          _SpecialBlock(
            start: match.start,
            end: match.end,
            type: _BlockType.chartJs,
            content: html,
          ),
        );
      }
    }

    // Sort by position
    specialBlocks.sort((a, b) => a.start.compareTo(b.start));

    Widget buildMarkdown(String data) {
      return _buildMarkdownWithCitations(context, data);
    }

    Widget result;

    if (specialBlocks.isEmpty) {
      result = buildMarkdown(normalized);
    } else {
      final children = <Widget>[];
      var currentIndex = 0;
      for (final block in specialBlocks) {
        // Skip overlapping blocks
        if (block.start < currentIndex) continue;

        final before = normalized.substring(currentIndex, block.start);
        if (before.trim().isNotEmpty) {
          children.add(buildMarkdown(before));
        }

        switch (block.type) {
          case _BlockType.mermaid:
            children.add(
              ConduitMarkdown.buildMermaidBlock(context, block.content),
            );
          case _BlockType.chartJs:
            children.add(
              ConduitMarkdown.buildChartJsBlock(context, block.content),
            );
        }

        currentIndex = block.end;
      }

      final tail = normalized.substring(currentIndex);
      if (tail.trim().isNotEmpty) {
        children.add(buildMarkdown(tail));
      }

      result = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    // Only wrap in SelectionArea when not streaming to avoid concurrent
    // modification errors in Flutter's selection system during rapid updates
    if (isStreaming) {
      return result;
    }

    return SelectionArea(child: result);
  }

  /// Builds markdown content with citation source references.
  ///
  /// Citations like [1], [2] are kept as text in the markdown to preserve
  /// inline formatting. A source reference footer is added when citations
  /// are detected, providing clickable access to sources.
  Widget _buildMarkdownWithCitations(BuildContext context, String data) {
    // If no sources provided, render plain markdown
    if (sources == null || sources!.isEmpty) {
      return ConduitMarkdown.build(
        context: context,
        data: data,
        onTapLink: onTapLink,
        imageBuilderOverride: imageBuilderOverride,
      );
    }

    // Check if content has citations
    if (!CitationParser.hasCitations(data)) {
      return ConduitMarkdown.build(
        context: context,
        data: data,
        onTapLink: onTapLink,
        imageBuilderOverride: imageBuilderOverride,
      );
    }

    // Extract unique source IDs referenced in the content
    final referencedIds = CitationParser.extractSourceIds(data);
    if (referencedIds.isEmpty) {
      return ConduitMarkdown.build(
        context: context,
        data: data,
        onTapLink: onTapLink,
        imageBuilderOverride: imageBuilderOverride,
      );
    }

    // Render markdown content as-is (preserving all formatting)
    // and add a source references footer
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConduitMarkdown.build(
          context: context,
          data: data,
          onTapLink: onTapLink,
          imageBuilderOverride: imageBuilderOverride,
        ),
        _SourceReferencesFooter(
          referencedIds: referencedIds,
          sources: sources!,
          onSourceTap: onSourceTap,
        ),
      ],
    );
  }
}

/// Footer widget showing source references with clickable badges.
class _SourceReferencesFooter extends StatelessWidget {
  const _SourceReferencesFooter({
    required this.referencedIds,
    required this.sources,
    this.onSourceTap,
  });

  /// 1-based source IDs that are referenced in the content.
  final List<int> referencedIds;

  /// All available sources.
  final List<ChatSourceReference> sources;

  /// Callback when a source is tapped.
  final void Function(int sourceIndex)? onSourceTap;

  @override
  Widget build(BuildContext context) {
    if (referencedIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final id in referencedIds)
            CitationBadge(
              sourceIndex: id - 1, // Convert to 0-based
              sources: sources,
              onTap: onSourceTap != null ? () => onSourceTap!(id - 1) : null,
            ),
        ],
      ),
    );
  }
}

/// Types of special blocks that need custom rendering
enum _BlockType { mermaid, chartJs }

/// Represents a special block in the content
class _SpecialBlock {
  final int start;
  final int end;
  final _BlockType type;
  final String content;

  const _SpecialBlock({
    required this.start,
    required this.end,
    required this.type,
    required this.content,
  });
}

extension StreamingMarkdownExtension on String {
  Widget toMarkdown({
    required BuildContext context,
    bool isStreaming = false,
    MarkdownLinkTapCallback? onTapLink,
    List<ChatSourceReference>? sources,
    void Function(int sourceIndex)? onSourceTap,
  }) {
    return StreamingMarkdownWidget(
      content: this,
      isStreaming: isStreaming,
      onTapLink: onTapLink,
      sources: sources,
      onSourceTap: onSourceTap,
    );
  }
}

class MarkdownWithLoading extends StatelessWidget {
  const MarkdownWithLoading({super.key, this.content, required this.isLoading});

  final String? content;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final value = content ?? '';
    if (isLoading && value.trim().isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamingMarkdownWidget(content: value, isStreaming: isLoading);
  }
}
