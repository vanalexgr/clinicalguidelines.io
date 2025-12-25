import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/locked_server.dart';

class AuthLinkerService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Function(String token)? _onTokenReceived;

  Future<void> listen(Function(String token) onTokenReceived) async {
    _onTokenReceived = onTokenReceived;
    
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'clinicalguidelines' && uri.host == 'auth') {
      final token = uri.queryParameters['token'];
      if (token != null && _onTokenReceived != null) {
        _onTokenReceived!(token);
        closeInAppWebView();
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _onTokenReceived = null;
  }

  Future<void> launchSSO() async {
    final url = Uri.parse('$kLockedServerUrl/auth');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

final authLinkerServiceProvider = Provider((ref) => AuthLinkerService());
