import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Check if WebView is supported on the current platform.
///
/// webview_flutter only supports iOS and Android.
bool get isWebViewSupported =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Helper for clearing WebView cookies on supported platforms.
///
/// This is isolated in its own file to prevent platform coupling issues
/// when the webview_flutter package isn't available.
class WebViewCookieHelper {
  /// Clears all WebView cookies.
  ///
  /// Returns true if cookies were cleared, false if not supported or failed.
  /// Checks platform support internally, so safe to call on any platform.
  static Future<bool> clearCookies() async {
    // Only supported on mobile platforms
    if (!isWebViewSupported) return false;

    try {
      return await WebViewCookieManager().clearCookies();
    } catch (e) {
      // Silently fail - WebView may not be available
      return false;
    }
  }
}

