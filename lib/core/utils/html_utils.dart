/// HTML entity utilities for parsing content.
///
/// Reference: openwebui-src/src/lib/utils/index.ts (unescapeHtml)
library;

import 'package:html_unescape/html_unescape.dart';

/// Utility class for HTML entity handling.
class HtmlUtils {
  /// HTML entity unescaper instance.
  static final _unescape = HtmlUnescape();

  /// Unescape HTML entities in a string.
  ///
  /// Handles all Named, Decimal, and Hexadecimal Character References.
  static String unescapeHtml(String s) => _unescape.convert(s);
}

