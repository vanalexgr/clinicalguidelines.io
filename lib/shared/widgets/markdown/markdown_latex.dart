import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

import '../../theme/theme_extensions.dart';

const String _latexTag = 'latex';

/// Provides LaTeX parsing support for markdown_widget.
class ConduitLatex {
  const ConduitLatex();

  /// Returns the inline syntax used to identify LaTeX segments.
  m.InlineSyntax syntax() => _LatexSyntax();

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

class _LatexSyntax extends m.InlineSyntax {
  _LatexSyntax() : super(r'(\$\$[\s\S]+?\$\$)|(\$[^\n]+?\$)');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final raw = match.input.substring(match.start, match.end);
    final element = m.Element.text(_latexTag, raw);
    if (raw.startsWith(r'$$') && raw.endsWith(r'$$') && raw.length > 4) {
      element.attributes['content'] = raw.substring(2, raw.length - 2);
      element.attributes['isInline'] = 'false';
    } else if (raw.startsWith(r'$') && raw.endsWith(r'$') && raw.length > 2) {
      element.attributes['content'] = raw.substring(1, raw.length - 1);
      element.attributes['isInline'] = 'true';
    } else {
      element.attributes['content'] = raw;
      element.attributes['isInline'] = 'true';
    }
    parser.addNode(element);
    return true;
  }
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

    final latexWidget = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textStyle: baseStyle,
      textScaleFactor: 1,
      onErrorFallback: (error) {
        return Text(rawText, style: baseStyle.copyWith(color: Colors.red));
      },
    );

    final widget = isInline
        ? latexWidget
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Center(child: latexWidget),
          );

    return WidgetSpan(alignment: PlaceholderAlignment.middle, child: widget);
  }
}
