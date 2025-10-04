import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/color_tokens.dart';
import '../../theme/theme_extensions.dart';
import 'code_block_header.dart';
import 'markdown_latex.dart';

typedef MarkdownLinkTapCallback = void Function(String url, String title);

class ConduitMarkdown {
  const ConduitMarkdown._();

  static MarkdownWidget build({
    required BuildContext context,
    required String data,
    MarkdownLinkTapCallback? onTapLink,
    bool selectable = true,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    final components = prepare(context, onTapLink: onTapLink);
    return MarkdownWidget(
      data: data,
      selectable: selectable,
      config: components.config,
      markdownGenerator: components.generator,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: EdgeInsets.zero,
    );
  }

  static MarkdownBlock buildBlock({
    required BuildContext context,
    required String data,
    MarkdownLinkTapCallback? onTapLink,
    bool selectable = true,
  }) {
    final components = prepare(context, onTapLink: onTapLink);
    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: components.config,
      generator: components.generator,
    );
  }

  static ({MarkdownConfig config, MarkdownGenerator generator}) prepare(
    BuildContext context, {
    MarkdownLinkTapCallback? onTapLink,
  }) {
    final config = _buildConfig(context, onTapLink: onTapLink);
    final generator = _buildGenerator(context);
    return (config: config, generator: generator);
  }

  static MarkdownConfig _buildConfig(
    BuildContext context, {
    MarkdownLinkTapCallback? onTapLink,
  }) {
    final theme = context.conduitTheme;
    final material = Theme.of(context);
    final isDark = material.brightness == Brightness.dark;

    final baseBody = AppTypography.bodyMediumStyle.copyWith(
      color: theme.textPrimary,
      height: 1.45,
    );
    final secondaryBody = AppTypography.bodySmallStyle.copyWith(
      color: theme.textSecondary,
      height: 1.45,
    );

    final codeBackground = theme.surfaceContainer.withValues(alpha: 0.55);
    final borderColor = theme.cardBorder.withValues(alpha: 0.25);
    final highlightTheme = _codeHighlightTheme(theme, isDark: isDark);

    return MarkdownConfig(
      configs: [
        PConfig(textStyle: baseBody),
        H1Config(
          style: AppTypography.headlineLargeStyle.copyWith(
            color: theme.textPrimary,
          ),
        ),
        H2Config(
          style: AppTypography.headlineMediumStyle.copyWith(
            color: theme.textPrimary,
          ),
        ),
        H3Config(
          style: AppTypography.headlineSmallStyle.copyWith(
            color: theme.textPrimary,
          ),
        ),
        H4Config(
          style: AppTypography.bodyLargeStyle.copyWith(
            color: theme.textPrimary,
          ),
        ),
        H5Config(style: baseBody.copyWith(fontWeight: FontWeight.w600)),
        H6Config(style: secondaryBody),
        LinkConfig(
          style: baseBody.copyWith(
            color: material.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: material.colorScheme.primary,
          ),
          onTap: (url) => onTapLink?.call(url, url),
        ),
        CodeConfig(
          style: AppTypography.codeStyle.copyWith(
            color: theme.codeText,
            backgroundColor: codeBackground,
          ),
        ),
        PreConfig(
          textStyle: AppTypography.codeStyle.copyWith(color: theme.codeText),
          styleNotMatched: AppTypography.codeStyle.copyWith(
            color: theme.codeText,
          ),
          theme: highlightTheme,
          builder: (code, language) {
            final normalizedLanguage = language.trim().isEmpty
                ? 'plaintext'
                : language.trim();
            final highlight = HighlightView(
              code,
              language: normalizedLanguage == 'plaintext'
                  ? null
                  : normalizedLanguage,
              theme: highlightTheme,
              textStyle: AppTypography.codeStyle.copyWith(
                color: theme.codeText,
              ),
              padding: EdgeInsets.zero,
            );
            return _buildCodeWrapper(
              context: context,
              child: highlight,
              backgroundColor: codeBackground,
              borderColor: borderColor,
              language: normalizedLanguage,
              rawCode: code,
            );
          },
        ),
        BlockquoteConfig(
          sideColor: material.colorScheme.primary.withValues(alpha: 0.35),
          textColor: theme.textSecondary,
          sideWith: BorderWidth.small,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
        ),
        ListConfig(marginLeft: Spacing.lg, marginBottom: Spacing.xs),
        TableConfig(
          border: TableBorder.all(color: borderColor, width: BorderWidth.micro),
          headPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          bodyPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          headerStyle: secondaryBody.copyWith(fontWeight: FontWeight.w600),
          bodyStyle: secondaryBody,
          headerRowDecoration: BoxDecoration(
            color: theme.surfaceBackground.withValues(alpha: 0.35),
          ),
          bodyRowDecoration: BoxDecoration(
            color: theme.surfaceContainer.withValues(alpha: 0.2),
          ),
        ),
        HrConfig(color: theme.dividerColor, height: BorderWidth.small),
        ImgConfig(
          builder: (url, attributes) {
            final uri = Uri.tryParse(url);
            if (uri == null) {
              return _buildImageError(context, theme);
            }
            return _buildImage(context, uri);
          },
        ),
      ],
    );
  }

  static MarkdownGenerator _buildGenerator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latex = ConduitLatex();
    return MarkdownGenerator(
      inlineSyntaxList: latex.syntaxes(),
      generators: [latex.generator(isDark: isDark)],
      linesMargin: const EdgeInsets.symmetric(vertical: Spacing.xs),
    );
  }

  static Map<String, TextStyle> _codeHighlightTheme(
    ConduitThemeExtension theme, {
    required bool isDark,
  }) {
    final baseTheme = isDark ? a11yDarkTheme : a11yLightTheme;
    final codeStyle = AppTypography.codeStyle.copyWith(color: theme.codeText);

    return {
      for (final entry in baseTheme.entries)
        entry.key: entry.value.copyWith(
          color: entry.value.color ?? theme.codeText,
          fontFamily: AppTypography.monospaceFontFamily,
          fontSize: codeStyle.fontSize,
          height: codeStyle.height,
        ),
    };
  }

  static Widget _buildCodeWrapper({
    required BuildContext context,
    required Widget child,
    required Color backgroundColor,
    required Color borderColor,
    required String language,
    required String rawCode,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            border: Border.all(color: borderColor, width: BorderWidth.micro),
          ),
          child: ClipRect(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CodeBlockHeader(
                  language: language,
                  onCopy: () async {
                    await Clipboard.setData(ClipboardData(text: rawCode));
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard.'),
                      ),
                    );
                  },
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: width),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildMermaidBlock(BuildContext context, String code) {
    final conduitTheme = context.conduitTheme;
    final materialTheme = Theme.of(context);

    if (MermaidDiagram.isSupported) {
      return _buildMermaidContainer(
        context: context,
        conduitTheme: conduitTheme,
        materialTheme: materialTheme,
        code: code,
      );
    }

    return _buildUnsupportedMermaidContainer(
      context: context,
      conduitTheme: conduitTheme,
      code: code,
    );
  }

  static Widget _buildImage(BuildContext context, Uri uri) {
    final theme = context.conduitTheme;
    if (uri.scheme == 'data') {
      return _buildBase64Image(uri.toString(), context, theme);
    }

    if (uri.scheme.isEmpty || uri.scheme == 'http' || uri.scheme == 'https') {
      return _buildNetworkImage(uri.toString(), context, theme);
    }

    return _buildImageError(context, theme);
  }

  static Widget _buildBase64Image(
    String dataUrl,
    BuildContext context,
    ConduitThemeExtension theme,
  ) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) {
        throw const FormatException('Invalid data URL format');
      }

      final base64String = dataUrl.substring(commaIndex + 1);
      final imageBytes = base64.decode(base64String);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageError(context, theme);
            },
          ),
        ),
      );
    } catch (_) {
      return _buildImageError(context, theme);
    }
  }

  static Widget _buildNetworkImage(
    String url,
    BuildContext context,
    ConduitThemeExtension theme,
  ) {
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, _) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.surfaceBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.loadingIndicator,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildImageError(context, theme),
      imageBuilder: (context, imageProvider) => Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          image: DecorationImage(image: imageProvider, fit: BoxFit.contain),
        ),
      ),
    );
  }

  static Widget _buildImageError(
    BuildContext context,
    ConduitThemeExtension theme,
  ) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.surfaceBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: theme.cardBorder.withValues(alpha: 0.4),
          width: BorderWidth.micro,
        ),
      ),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: theme.iconSecondary),
      ),
    );
  }
}

Widget _buildMermaidContainer({
  required BuildContext context,
  required ConduitThemeExtension conduitTheme,
  required ThemeData materialTheme,
  required String code,
}) {
  final tokens = context.colorTokens;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      border: Border.all(
        color: conduitTheme.cardBorder.withValues(alpha: 0.4),
        width: BorderWidth.micro,
      ),
    ),
    height: 360,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      child: MermaidDiagram(
        code: code,
        brightness: materialTheme.brightness,
        colorScheme: materialTheme.colorScheme,
        tokens: tokens,
      ),
    ),
  );
}

Widget _buildUnsupportedMermaidContainer({
  required BuildContext context,
  required ConduitThemeExtension conduitTheme,
  required String code,
}) {
  final textStyle = AppTypography.bodySmallStyle.copyWith(
    color: conduitTheme.codeText.withValues(alpha: 0.7),
  );

  return Container(
    margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
    padding: const EdgeInsets.all(Spacing.sm),
    decoration: BoxDecoration(
      color: conduitTheme.surfaceContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      border: Border.all(
        color: conduitTheme.cardBorder.withValues(alpha: 0.4),
        width: BorderWidth.micro,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mermaid preview is not available on this platform.',
          style: textStyle,
        ),
        const SizedBox(height: Spacing.xs),
        SelectableText(
          code,
          maxLines: null,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.parent,
          style: AppTypography.codeStyle.copyWith(color: conduitTheme.codeText),
        ),
      ],
    ),
  );
}

class MermaidDiagram extends StatefulWidget {
  const MermaidDiagram({
    super.key,
    required this.code,
    required this.brightness,
    required this.colorScheme,
    required this.tokens,
  });

  final String code;
  final Brightness brightness;
  final ColorScheme colorScheme;
  final AppColorTokens tokens;

  static bool get isSupported => !kIsWeb;

  static Future<String> _loadScript() {
    return _scriptFuture ??= rootBundle.loadString('assets/mermaid.min.js');
  }

  static Future<String>? _scriptFuture;

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  WebViewController? _controller;
  String? _script;
  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    if (!MermaidDiagram.isSupported) {
      return;
    }
    MermaidDiagram._loadScript().then((value) {
      if (!mounted) {
        return;
      }
      _script = value;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent);
      _loadHtml();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null || _script == null) {
      return;
    }
    final codeChanged = oldWidget.code != widget.code;
    final themeChanged =
        oldWidget.brightness != widget.brightness ||
        oldWidget.colorScheme != widget.colorScheme ||
        oldWidget.tokens != widget.tokens;
    if (codeChanged || themeChanged) {
      _loadHtml();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: WebViewWidget(
        controller: _controller!,
        gestureRecognizers: _gestureRecognizers,
      ),
    );
  }

  void _loadHtml() {
    if (_controller == null || _script == null) {
      return;
    }
    _controller!.loadHtmlString(_buildHtml(widget.code, _script!));
  }

  String _buildHtml(String code, String script) {
    final theme = widget.brightness == Brightness.dark ? 'dark' : 'default';
    final primary = _toHex(widget.tokens.brandTone60);
    final secondary = _toHex(widget.tokens.accentTeal60);
    final background = _toHex(widget.tokens.codeBackground);
    final onBackground = _toHex(widget.tokens.codeText);

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<style>
  body {
    margin: 0;
    background-color: transparent;
  }
  #container {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: transparent;
  }
</style>
</head>
<body>
<div id="container">
  <div class="mermaid">$code</div>
</div>
<script>$script</script>
<script>
  mermaid.initialize({
    theme: '$theme',
    themeVariables: {
      primaryColor: '$primary',
      primaryTextColor: '$onBackground',
      primaryBorderColor: '$secondary',
      background: '$background'
    },
  });
  mermaid.contentLoaded();
</script>
</body>
</html>
''';
  }

  String _toHex(Color color) {
    int channel(double value) {
      final scaled = (value * 255).round();
      if (scaled < 0) {
        return 0;
      }
      if (scaled > 255) {
        return 255;
      }
      return scaled;
    }

    final argb =
        (channel(color.a) << 24) |
        (channel(color.r) << 16) |
        (channel(color.g) << 8) |
        channel(color.b);
    return '#${argb.toRadixString(16).padLeft(8, '0')}';
  }
}
