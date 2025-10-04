import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

import 'latex_block_widget.dart';

const String _latexTag = 'latex';

/// Provides LaTeX parsing support for markdown_widget.
class ConduitLatex {
  const ConduitLatex();

  /// Returns the inline syntax used to identify LaTeX segments.
  List<m.InlineSyntax> syntaxes() => [
    _LatexDollarSyntax(),
    _LatexEscapedSyntax(),
  ];

  /// Returns the span generator that renders LaTeX expressions.
  SpanNodeGeneratorWithTag generator({required bool isDark}) {
    return SpanNodeGeneratorWithTag(
      tag: _latexTag,
      generator: (element, config, visitor) {
        return _LatexNode(
          attributes: element.attributes,
          rawText: element.textContent,
          config: config,
          isDark: isDark,
        );
      },
    );
  }
}

class _LatexDollarSyntax extends m.InlineSyntax {
  _LatexDollarSyntax()
    : super(
        r'(\$\$[\s\S]+?\$\$)|(\$[^\n]+?\$)',
        startCharacter: r'$'.codeUnitAt(0),
      );

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    return _handleMatch(parser, match.input.substring(match.start, match.end));
  }
}

class _LatexEscapedSyntax extends m.InlineSyntax {
  _LatexEscapedSyntax()
    : super(
        r'(\\\\\([\s\S]+?\\\\\))|(\\\\\[[\s\S]+?\\\\\])',
        startCharacter: r'\'.codeUnitAt(0),
      );

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    return _handleMatch(parser, match.input.substring(match.start, match.end));
  }
}

bool _handleMatch(m.InlineParser parser, String raw) {
  final element = m.Element.text(_latexTag, raw);
  String content = raw;
  var isInline = true;

  if (raw.startsWith(r'$$') && raw.endsWith(r'$$') && raw.length > 4) {
    content = raw.substring(2, raw.length - 2);
    isInline = false;
  } else if (raw.startsWith(r'$') && raw.endsWith(r'$') && raw.length > 2) {
    content = raw.substring(1, raw.length - 1);
    isInline = true;
  } else if (raw.startsWith(r'\\(') && raw.endsWith(r'\\)') && raw.length > 4) {
    content = raw.substring(2, raw.length - 2);
    isInline = true;
  } else if (raw.startsWith(r'\\[') && raw.endsWith(r'\\]') && raw.length > 4) {
    content = raw.substring(2, raw.length - 2);
    isInline = false;
  }

  element.attributes['content'] = content;
  element.attributes['isInline'] = '$isInline';
  parser.addNode(element);
  return true;
}

class _LatexNode extends SpanNode {
  _LatexNode({
    required this.attributes,
    required this.rawText,
    required this.config,
    required this.isDark,
  });

  final Map<String, String> attributes;
  final String rawText;
  final MarkdownConfig config;
  final bool isDark;

  @override
  InlineSpan build() {
    final content = attributes['content']?.trim();
    final isInline = attributes['isInline'] == 'true';
    final baseStyle = (parentStyle ?? config.p.textStyle).copyWith(
      color:
          (parentStyle ?? config.p.textStyle).color ??
          (isDark ? Colors.white : Colors.black),
    );

    if (content == null || content.isEmpty) {
      return TextSpan(text: rawText, style: baseStyle);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: LatexBlockWidget(
        content: content,
        isInline: isInline,
        style: baseStyle,
        isDark: isDark,
      ),
    );
  }
}
