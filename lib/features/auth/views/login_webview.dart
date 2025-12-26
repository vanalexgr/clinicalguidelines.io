import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:conduit/core/config/locked_server.dart'; 

class LoginWebView extends ConsumerStatefulWidget {
  const LoginWebView({super.key});

  @override
  ConsumerState<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends ConsumerState<LoginWebView> {
  InAppWebViewController? _webViewController;
  Timer? _checkTimer;

  @override
  void dispose() {
    // Stop the timer when the screen closes
    _checkTimer?.cancel();
    super.dispose();
  }

  // This function keeps asking: "Do you have the token yet?"
  void _startTokenPolling() {
    _checkTimer?.cancel(); // Safety check
    
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_webViewController == null) return;

      try {
        // 1. Check for token in LocalStorage
        var token = await _webViewController!.evaluateJavascript(
          source: "localStorage.getItem('token');"
        );

        // 2. If we found it, SUCCESS!
        if (token != null && token.toString() != "null" && token.toString().isNotEmpty) {
          debugPrint("✅ Token Detected via Polling! Closing WebView...");
          
          timer.cancel(); // Stop asking
          
          if (mounted) {
            Navigator.of(context).pop(token.toString());
          }
        }
      } catch (e) {
        // Javascript error or view not ready; just ignore and try again next second
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Target URL
    final String loginUrl = "$kLockedServerUrl/oauth/oidc/login";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Log In"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(), 
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(loginUrl),
        ),
        initialSettings: InAppWebViewSettings(
          userAgent: "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",
          javaScriptEnabled: true,
          domStorageEnabled: true,
          useHybridComposition: true,
          sharedCookiesEnabled: true,
          thirdPartyCookiesEnabled: true, 
        ),
        
        onWebViewCreated: (controller) {
          _webViewController = controller;
          // Start checking immediately upon creation
          _startTokenPolling();
        },

        onLoadStop: (controller, url) {
          // We don't rely strictly on this anymore, but it's good for debugging
          debugPrint("WebView loaded: $url");
        },
      ),
    );
  }
}
