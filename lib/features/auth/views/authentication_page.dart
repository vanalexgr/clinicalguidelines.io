import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core & Config
import '../../../core/models/backend_config.dart';
import '../../../core/models/server_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/auth/auth_state_manager.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/config/locked_server.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../core/services/navigation_service.dart';

// Shared UI
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/widgets/conduit_components.dart';

// Localization
import 'package:conduit/l10n/app_localizations.dart';

// Auth Providers
import '../providers/unified_auth_providers.dart';

// Login WebView
import 'package:conduit/features/auth/views/login_webview.dart';

class AuthenticationPage extends ConsumerStatefulWidget {
  final ServerConfig? serverConfig;
  final BackendConfig? backendConfig;

  const AuthenticationPage({super.key, this.serverConfig, this.backendConfig});

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  bool _isSigningIn = false;
  String? _loginError;
  bool _serverConfigSaved = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ✅ NEW LOGIC: Open WebView inside the app
  Future<void> _launchSSO() async {
    setState(() {
      _isSigningIn = true;
      _loginError = null;
    });

    try {
      // 1. Save Server Config (Legacy support)
      if (widget.serverConfig != null && !_serverConfigSaved) {
        await _saveServerConfig(widget.serverConfig!);
        _serverConfigSaved = true;
      }

      // 2. Push the WebView Screen and WAIT for the result (Token)
      if (!mounted) return;
      final token = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const LoginWebView()),
      );

      // 3. Handle the result
      if (token != null && token.isNotEmpty && mounted) {
        DebugLogger.auth('Token received from WebView. Attempting login...');
        
        final actions = ref.read(authActionsProvider);
        final success = await actions.loginWithApiKey(
          token,
          rememberCredentials: true,
        );

        if (!success && mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _loginError = l10n.genericSignInFailed;
            _isSigningIn = false;
          });
        }
        // Note: If success, the listener in build() will handle navigation.
      } else {
        // User cancelled login (closed the WebView)
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = _formatLoginError(e.toString());
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _saveServerConfig(ServerConfig config) async {
    final storage = ref.read(optimizedStorageServiceProvider);
    await storage.saveServerConfigs([config]);
    await storage.setActiveServerId(config.id);
    ref.invalidate(serverConfigsProvider);
    ref.invalidate(activeServerProvider);
  }

  String _formatLoginError(String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('401') || error.contains('Unauthorized')) {
      return l10n.invalidCredentials;
    } else if (error.contains('SocketException')) {
      return l10n.unableToConnectServer;
    } else if (error.contains('timeout')) {
      return l10n.requestTimedOut;
    }
    return l10n.genericSignInFailed;
  }

  @override
  Widget build(BuildContext context) {
    // Watch for Auth Success to Navigate
    ref.listen<AsyncValue<AuthState>>(authStateManagerProvider, (
      previous,
      next,
    ) {
      final nextState = next.asData?.value;
      final prevState = previous?.asData?.value;
      
      // If we just became authenticated, navigate to Chat
      if (mounted &&
          nextState?.isAuthenticated == true &&
          prevState?.isAuthenticated != true) {
        DebugLogger.auth('Authentication successful, navigating to chat');
        context.go(Routes.chat); 
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final theme = context.conduitTheme;

    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: theme.surfaceBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.pagePadding,
                vertical: Spacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: Spacing.xxxl),
                    // 👇 UPDATED WELCOME SECTION
                    _buildWelcomeSection(l10n),
                    const SizedBox(height: Spacing.xl),
                    _buildServerStatus(),
                    const SizedBox(height: Spacing.xxxl),
                    _buildSsoButton(l10n),
                    if (_loginError != null) ...[
                      const SizedBox(height: Spacing.lg),
                      _buildErrorMessage(_loginError!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 👇 UPDATED LOGO LOGIC
  Widget _buildLogo() {
    // Check if Dark Mode is active
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Image.asset(
        'assets/icons/icon.png',
        width: 100,
        height: 100,
        // 👇 MAGIC TRICK: 
        // If Dark Mode, we use 'difference' blending with White.
        // This turns White Background -> Black, and Black Logo -> White.
        color: isDarkMode ? Colors.white : null,
        colorBlendMode: isDarkMode ? BlendMode.difference : null,
      ),
    );
  }

  // 👇 UPDATED: Added Subtitle and Hardcoded "Clinical Guidelines"
  Widget _buildWelcomeSection(AppLocalizations l10n) {
    final theme = context.conduitTheme;
    
    return Column(
      children: [
        // 1. Main Title
        Text(
          "Clinical Guidelines", // Hardcoded per request
          textAlign: TextAlign.center,
          style: theme.headingLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: Spacing.xs),
        
        // 2. NEW SUBTITLE
        Text(
          "Proof backed evidence, on tap",
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(
            color: theme.textSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
        ),
        
        const SizedBox(height: Spacing.xl),

        // 3. "Sign In / Sign Up" Label
        Text(
          l10n.signIn,
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildServerStatus() {
    final theme = context.conduitTheme;
    final hostText = Uri.parse(kLockedServerUrl).host;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: theme.success.withValues(alpha: 0.2),
          width: BorderWidth.standard,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.checkmark_circle
                : Icons.check_circle_outline,
            color: theme.success,
            size: IconSize.small,
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            hostText,
            style: theme.bodySmall?.copyWith(
              color: theme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSsoButton(AppLocalizations l10n) {
    return ConduitButton(
      // 👇 Uses "Continue with Work Account" from ARB
      text: _isSigningIn ? l10n.signingIn : l10n.signInWithSso,
      icon: _isSigningIn
          ? null
          : (Platform.isIOS ? CupertinoIcons.lock_shield : Icons.login),
      onPressed: _isSigningIn ? null : _launchSSO,
      isLoading: _isSigningIn,
      isFullWidth: true,
    );
  }

  Widget _buildErrorMessage(String message) {
    final theme = context.conduitTheme;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
          border: Border.all(
            color: theme.error.withValues(alpha: 0.2),
            width: BorderWidth.standard,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.exclamationmark_circle
                  : Icons.error_outline,
              color: theme.error,
              size: IconSize.small,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.bodySmall?.copyWith(
                  color: theme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
