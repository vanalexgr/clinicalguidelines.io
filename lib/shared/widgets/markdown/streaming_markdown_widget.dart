import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme/theme_extensions.dart';
import 'markdown_config.dart';
import 'markdown_preprocessor.dart';

typedef MarkdownLinkTapCallback = void Function(String url, String title);

class StreamingMarkdownWidget extends StatelessWidget {
  const StreamingMarkdownWidget({
    super.key,
    required this.content,
    required this.isStreaming,
    this.onTapLink,
  });

  final String content;
  final bool isStreaming;
  final MarkdownLinkTapCallback? onTapLink;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = ConduitMarkdownPreprocessor.normalize(content);
    final markdownTheme = ConduitMarkdownConfig.resolve(context);
    final markdownBody = MarkdownBody(
      data: normalized,
      styleSheet: markdownTheme.styleSheet,
      selectable: false,
      imageBuilder: markdownTheme.imageBuilder,
      onTapLink: (text, href, title) {
        final target = href ?? '';
        if (target.isEmpty) {
          return;
        }
        final resolvedTitle = title.isNotEmpty ? title : text;
        onTapLink?.call(target, resolvedTitle);
      },
    );

    return SelectionArea(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: context.conduitTheme.buttonPrimary,
          ),
        ),
        child: markdownBody,
      ),
    );
  }
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
