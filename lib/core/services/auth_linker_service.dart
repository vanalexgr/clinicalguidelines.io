import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/locked_server.dart';

class AuthLinkerService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void listen(Function(String token) onTokenReceived) {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'clinicalguidelines' && uri.host == 'auth') {
        final token = uri.queryParameters['token'];
        if (token != null) {
          onTokenReceived(token);
          closeInAppWebView();
        }
      }
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  Future<void> launchSSO() async {
    final url = Uri.parse('$kLockedServerUrl/auth');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

final authLinkerServiceProvider = Provider((ref) => AuthLinkerService());
