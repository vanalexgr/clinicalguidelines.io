import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme/theme_extensions.dart';

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
