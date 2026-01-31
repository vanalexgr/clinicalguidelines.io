import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:conduit/core/models/chat_message.dart';
import 'package:conduit/shared/theme/theme_extensions.dart';
import 'package:conduit/shared/utils/source_helper.dart';

/// Shows a dialog with details about a source reference.
void showSourceDetailsDialog(BuildContext context, ChatSourceReference source) {
  final theme = context.conduitTheme;
  final title =
      source.title ??
      ((source.id != null && !source.id!.startsWith('http'))
          ? source.id
          : 'Source Details');
  final snippet = source.snippet ?? '';
  final url = SourceHelper.getSourceUrl(source);
  final metadata = source.metadata;

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: theme.surfaceContainer,
          title: Text(
            title ?? 'Source',
            style: TextStyle(color: theme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snippet.isNotEmpty) ...[
                  Text(
                    'Content:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surfaceBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      snippet,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (metadata != null && metadata.isNotEmpty) ...[
                  Text(
                    'Metadata:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in metadata.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                if (url != null) ...[
                  Text(
                    'URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => SourceHelper.launchSourceUrl(url),
                    child: Text(
                      url,
                      style: TextStyle(
                        color: theme.navigationSelected,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (url != null)
              TextButton(
                onPressed: () => SourceHelper.launchSourceUrl(url),
                child: const Text('Open URL'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
  );
}
