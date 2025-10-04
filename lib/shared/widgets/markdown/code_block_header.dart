import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

class CodeBlockHeader extends StatelessWidget {
  const CodeBlockHeader({
    super.key,
    required this.language,
    required this.onCopy,
  });

  final String language;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final label = language.isEmpty ? 'code' : language;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.sm),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.codeStyle.copyWith(
              color: theme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: theme.iconPrimary,
            tooltip: 'Copy code',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
