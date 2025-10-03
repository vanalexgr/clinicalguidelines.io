import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/theme_extensions.dart';
import '../../theme/color_tokens.dart';

class ConduitMarkdownTheme {
  const ConduitMarkdownTheme({
    required this.styleSheet,
    required this.imageBuilder,
    required this.linkColor,
    required this.linkHoverColor,
  });

  final MarkdownStyleSheet styleSheet;
  final MarkdownImageBuilder imageBuilder;
  final Color linkColor;
  final Color linkHoverColor;
}

class ConduitMarkdownConfig {
  static ConduitMarkdownTheme resolve(BuildContext context) {
    final theme = context.conduitTheme;
    final materialTheme = Theme.of(context);

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

    final styleSheet = MarkdownStyleSheet(
      a: baseBody.copyWith(
        color: materialTheme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: materialTheme.colorScheme.primary,
      ),
      p: baseBody,
      blockSpacing: Spacing.sm,
      listIndent: Spacing.lg,
      listBullet: baseBody.copyWith(color: theme.textSecondary),
      listBulletPadding: const EdgeInsets.only(right: Spacing.xs),
      checkbox: baseBody.copyWith(color: theme.textSecondary),
      em: baseBody.copyWith(fontStyle: FontStyle.italic),
      strong: baseBody.copyWith(fontWeight: FontWeight.w600),
      del: baseBody.copyWith(decoration: TextDecoration.lineThrough),
      h1: AppTypography.headlineLargeStyle.copyWith(color: theme.textPrimary),
      h2: AppTypography.headlineMediumStyle.copyWith(color: theme.textPrimary),
      h3: AppTypography.headlineSmallStyle.copyWith(color: theme.textPrimary),
      h4: AppTypography.bodyLargeStyle.copyWith(color: theme.textPrimary),
      h5: baseBody.copyWith(fontWeight: FontWeight.w600),
      h6: secondaryBody,
      blockquote: baseBody.copyWith(color: theme.textSecondary),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border(
          left: BorderSide(
            width: BorderWidth.standard,
            color: materialTheme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
      code: AppTypography.codeStyle.copyWith(
        color: theme.codeText,
        backgroundColor: codeBackground,
      ),
      codeblockPadding: const EdgeInsets.all(Spacing.sm),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: borderColor, width: BorderWidth.micro),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: BorderWidth.small),
        ),
      ),
      tableHead: secondaryBody.copyWith(fontWeight: FontWeight.w600),
      tableBody: secondaryBody,
      tableBorder: TableBorder.all(
        color: borderColor,
        width: BorderWidth.micro,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      tableCellsDecoration: BoxDecoration(
        color: theme.surfaceBackground.withValues(alpha: 0.35),
      ),
      tableHeadAlign: TextAlign.left,
      tablePadding: const EdgeInsets.only(bottom: Spacing.xs),
    );

    return ConduitMarkdownTheme(
      styleSheet: styleSheet,
      imageBuilder: (uri, title, alt) => _buildImage(context, uri),
      linkColor: materialTheme.colorScheme.primary,
      linkHoverColor: materialTheme.colorScheme.primary.withValues(alpha: 0.8),
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
