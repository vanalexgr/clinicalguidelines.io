import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/debug_logger.dart';

/// Check if WebView is supported on the current platform.
///
/// webview_flutter only supports iOS and Android.
bool get isWebViewSupported =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// Helper for clearing WebView data on supported platforms.
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

  /// Clears all WebView data including cookies, localStorage, and cache.
  ///
  /// This should be called on logout to ensure SSO sessions are fully cleared.
  /// Returns true if all data was cleared successfully.
  static Future<bool> clearAllWebViewData() async {
    if (!isWebViewSupported) return false;

    var success = true;

    // Clear cookies
    try {
      await WebViewCookieManager().clearCookies();
      DebugLogger.auth('WebView cookies cleared');
    } catch (e) {
      DebugLogger.warning(
        'webview-cookie-clear-failed',
        scope: 'auth/webview',
        data: {'error': e.toString()},
      );
      success = false;
    }

    // Clear localStorage and cache using a temporary controller
    try {
      final controller = WebViewController();
      await controller.clearLocalStorage();
      await controller.clearCache();
      DebugLogger.auth('WebView localStorage and cache cleared');
    } catch (e) {
      DebugLogger.warning(
        'webview-storage-clear-failed',
        scope: 'auth/webview',
        data: {'error': e.toString()},
      );
      success = false;
    }

    return success;
  }
}
