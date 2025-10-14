import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../brand/locked_config.dart';
import 'authentication_page.dart';
import 'server_connection_page.dart';

/// Entry point for the connection and sign-in flow.
/// We now forward directly to the server connection experience.
class ConnectAndSignInPage extends ConsumerWidget {
  const ConnectAndSignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!LockedConfig.allowCustomServer) {
      return const AuthenticationPage();
    }
    return const ServerConnectionPage();
  }
}
