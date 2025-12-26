import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/locked_server.dart';
import '../../../core/providers/app_providers.dart';
import 'authentication_page.dart';
import 'server_connection_page.dart';

/// Entry point for the connection and sign-in flow.
/// When server is locked, skip server selection and go directly to authentication.
class ConnectAndSignInPage extends ConsumerWidget {
  const ConnectAndSignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When server is locked, skip server connection and go to authentication immediately
    if (kServerLockEnabled) {
      // Watch backend config but don't block on it - show auth form immediately
      final backendConfigAsync = ref.watch(backendConfigProvider);
	final backendConfig = backendConfigAsync.asData?.value;
      
      return AuthenticationPage(
        serverConfig: lockedServerConfig,
        backendConfig: backendConfig,
      );
    }
    
    return const ServerConnectionPage();
  }
}
