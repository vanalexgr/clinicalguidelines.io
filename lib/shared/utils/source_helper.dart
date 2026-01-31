import 'package:conduit/core/models/chat_message.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper utilities for working with source references.
class SourceHelper {
  const SourceHelper._();

  /// Extracts a URL from a source reference, checking multiple fields.
  static String? getSourceUrl(ChatSourceReference source) {
    String? url = source.url;
    if (url == null || url.isEmpty) {
      if (source.id != null && source.id!.startsWith('http')) {
        url = source.id;
      } else if (source.title != null && source.title!.startsWith('http')) {
        url = source.title;
      } else if (source.metadata != null) {
        url =
            source.metadata!['url']?.toString() ??
            source.metadata!['source']?.toString() ??
            source.metadata!['link']?.toString();
      }
    }
    return (url != null && url.startsWith('http')) ? url : null;
  }

  /// Gets a display title for a source.
  ///
  /// For web sources (with URLs), shows the domain name like "wikipedia.org".
  /// This matches OpenWebUI's behavior where web search results show domains.
  static String getSourceTitle(ChatSourceReference source, int index) {
    // For web sources, prefer showing the URL domain
    final url = getSourceUrl(source);
    if (url != null) {
      return extractDomain(url);
    }

    // If title is a URL, extract domain
    if (source.title != null && source.title!.isNotEmpty) {
      final title = source.title!;
      if (title.startsWith('http')) {
        return extractDomain(title);
      }
      return title;
    }

    // Check if ID is a URL
    if (source.id != null && source.id!.isNotEmpty) {
      final id = source.id!;
      if (id.startsWith('http')) {
        return extractDomain(id);
      }
      return id;
    }

    return 'Source ${index + 1}';
  }

  /// Extracts the domain from a URL for display.
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
  }

  /// Formats a title for display, truncating if needed.
  /// Matches OpenWebUI's getDisplayTitle behavior.
  static String formatDisplayTitle(String title) {
    if (title.isEmpty) return 'N/A';
    if (title.length > 25) {
      return '${title.substring(0, 12)}…${title.substring(title.length - 8)}';
    }
    return title;
  }

  /// Launches a URL in an external browser.
  static Future<void> launchSourceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}
