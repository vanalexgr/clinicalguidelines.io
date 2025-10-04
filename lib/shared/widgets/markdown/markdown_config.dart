import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/color_tokens.dart';
import '../../theme/theme_extensions.dart';
import 'markdown_latex.dart';

/// Callback invoked when a markdown link is tapped.
typedef MarkdownLinkTapCallback = void Function(String url, String title);

/// Bundles markdown configuration and generator metadata for the app theme.
class ConduitMarkdownTheme {
  const ConduitMarkdownTheme({
    required this.config,
    required this.inlineSyntaxes,
    required this.blockSyntaxes,
    required this.generators,
    required this.linesMargin,
  });

  final MarkdownConfig config;
  final List<m.InlineSyntax> inlineSyntaxes;
  final List<m.BlockSyntax> blockSyntaxes;
  final List<SpanNodeGeneratorWithTag> generators;
  final EdgeInsets linesMargin;

  MarkdownGenerator createGenerator() {
    return MarkdownGenerator(
      inlineSyntaxList: inlineSyntaxes,
      blockSyntaxList: blockSyntaxes,
      linesMargin: linesMargin,
      generators: generators,
    );
  }
}

class ConduitMarkdownConfig {
  static ConduitMarkdownTheme resolve(
    BuildContext context, {
    MarkdownLinkTapCallback? onTapLink,
  }) {
    final theme = context.conduitTheme;
    final materialTheme = Theme.of(context);
    final isDark = materialTheme.brightness == Brightness.dark;

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
    final latex = const ConduitLatex();

    final markdownConfig =
        (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig)
            .copy(
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
                    color: materialTheme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: materialTheme.colorScheme.primary,
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
                  padding: const EdgeInsets.all(Spacing.sm),
                  margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
                  decoration: BoxDecoration(
                    color: codeBackground,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    border: Border.all(
                      color: borderColor,
                      width: BorderWidth.micro,
                    ),
                  ),
                  textStyle: AppTypography.codeStyle.copyWith(
                    color: theme.codeText,
                  ),
                  styleNotMatched: AppTypography.codeStyle.copyWith(
                    color: theme.codeText,
                  ),
                  theme: _codeHighlightTheme(theme, isDark: isDark),
                  language: 'plaintext',
                ),
                BlockquoteConfig(
                  sideColor: materialTheme.colorScheme.primary.withValues(
                    alpha: 0.35,
                  ),
                  textColor: theme.textSecondary,
                  sideWith: BorderWidth.micro,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
                ),
                ListConfig(marginLeft: Spacing.lg, marginBottom: Spacing.xs),
                TableConfig(
                  border: TableBorder.all(
                    color: borderColor,
                    width: BorderWidth.micro,
                  ),
                  headPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  bodyPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  headerStyle: secondaryBody.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                  builder: (url, _) {
                    return Builder(
                      builder: (context) {
                        final uri = Uri.tryParse(url);
                        if (uri == null) {
                          return _buildImageError(
                            context,
                            context.conduitTheme,
                          );
                        }
                        return _buildImage(context, uri);
                      },
                    );
                  },
                ),
              ],
            );

    return ConduitMarkdownTheme(
      config: markdownConfig,
      inlineSyntaxes: [latex.syntax()],
      blockSyntaxes: const [],
      generators: [latex.generator(isDark: isDark)],
      linesMargin: const EdgeInsets.only(bottom: Spacing.sm),
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
    final encoded = jsonEncode(code);
    final primary = _toHex(widget.tokens.brandTone60);
    final secondary = _toHex(widget.tokens.accentTeal60);
    final background = _toHex(widget.tokens.codeBackground);
    final onBackground = _toHex(widget.tokens.codeText);
    final lineColor = _toHex(widget.tokens.codeAccent);
    final errorColor = _toHex(widget.tokens.statusError60);

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body { margin: 0; padding: 0; background: transparent; }
      body { color: $onBackground; font-family: -apple-system, sans-serif; }
      #diagram { padding: 8px; overflow: auto; }
      svg { height: auto; display: block; }
    </style>
    <script type="text/javascript">
$script
    </script>
  </head>
  <body>
    <div id="diagram"></div>
    <script type="text/javascript">
      const graphDefinition = $encoded;
      const themeConfig = {
        startOnLoad: false,
        theme: '$theme',
        securityLevel: 'loose',
        themeVariables: {
          primaryColor: '$primary',
          secondaryColor: '$secondary',
          background: '$background',
          textColor: '$onBackground',
          lineColor: '$lineColor'
        }
      };

      (async () => {
        const target = document.getElementById('diagram');
        try {
          mermaid.initialize(themeConfig);
          const { svg, bindFunctions } = await mermaid.render('graphDiv', graphDefinition);
          target.innerHTML = svg;
          if (typeof bindFunctions === 'function') {
            bindFunctions(target);
          }
        } catch (error) {
          target.innerHTML = '<pre style="color:$errorColor">' + String(error) + '</pre>';
          console.error('Mermaid render failed', error);
        }
      })();
    </script>
  </body>
</html>
''';
  }

  String _toHex(Color color) {
    final value = color.toARGB32();
    return '#'
            '${((value >> 16) & 0xFF).toRadixString(16).padLeft(2, '0')}'
            '${((value >> 8) & 0xFF).toRadixString(16).padLeft(2, '0')}'
            '${(value & 0xFF).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}
