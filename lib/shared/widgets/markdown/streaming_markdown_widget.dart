import 'package:flutter/material.dart';

import '../../theme/theme_extensions.dart';
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
  });

  final String content;
  final bool isStreaming;
  final MarkdownLinkTapCallback? onTapLink;
  final Widget Function(Uri uri, String? title, String? alt)?
  imageBuilderOverride;

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
      return ConduitMarkdown.buildBlock(
        context: context,
        data: data,
        onTapLink: onTapLink,
        selectable: false,
        imageBuilderOverride: imageBuilderOverride,
      );
    }

    if (specialBlocks.isEmpty) {
      return SelectionArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: context.conduitTheme.buttonPrimary,
            ),
          ),
          child: buildMarkdown(normalized),
        ),
      );
    }

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

    return SelectionArea(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: context.conduitTheme.buttonPrimary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
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
  }) {
    return StreamingMarkdownWidget(
      content: this,
      isStreaming: isStreaming,
      onTapLink: onTapLink,
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
