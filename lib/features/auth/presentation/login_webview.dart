import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 👇 IMPORT THE CONFIG FILE WE JUST CREATED
import '../../../config/locked_server.dart';

class LoginWebView extends ConsumerWidget {
  const LoginWebView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Target URL: Direct to OIDC (SSO) login to skip the menu
    final String loginUrl = "$kLockedServerUrl/oauth/oidc/login";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Log In"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(), // Allow manual close
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(loginUrl),
        ),
        initialSettings: InAppWebViewSettings(
          // 2. CRITICAL: Spoof User Agent to look like Chrome on Android
          // This prevents Google/Auth0 from blocking the login.
          userAgent: "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",
          
          javaScriptEnabled: true,
          domStorageEnabled: true, // Required for localStorage
          useHybridComposition: true, // Better keyboard support on Android
          
          // iOS Specifics
          sharedCookiesEnabled: true,
          thirdPartyCookiesEnabled: true, 
        ),

        // 3. The "Spy" Logic
        onLoadStop: (controller, url) async {
          if (url == null) return;
          final urlString = url.toString();

          // Debug: print(urlString); 

          // 4. Detect redirection to the Dashboard
          // OpenWebUI redirects to root ('/') after a successful login.
          if (urlString == "$kLockedServerUrl/" || urlString == kLockedServerUrl) {
            
            // 5. Extract Token from LocalStorage
            var token = await controller.evaluateJavascript(
              source: "localStorage.getItem('token');"
            );

            if (token != null && token.toString() != "null") {
              // We have the token!
              // Close the WebView and return the token to the previous screen
              if (context.mounted) {
                Navigator.of(context).pop(token.toString());
              }
            }
          }
        },
      ),
    );
  }
}
