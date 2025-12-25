import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/backend_config.dart';
import '../../../core/models/server_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/services/brand_service.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../../../core/auth/auth_state_manager.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/services/auth_linker_service.dart';
import '../../../core/config/locked_server.dart';
import 'package:conduit/l10n/app_localizations.dart';
import '../providers/unified_auth_providers.dart';

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
  AuthLinkerService? _linkerService;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _linkerService = ref.read(authLinkerServiceProvider);
    _linkerService?.listen(_handleAuthToken);
  }

  @override
  void dispose() {
    _linkerService?.dispose();
    super.dispose();
  }

  Future<void> _handleAuthToken(String token) async {
    if (!mounted) return;
    
    setState(() {
      _isSigningIn = true;
      _loginError = null;
    });

    try {
      if (widget.serverConfig != null && !_serverConfigSaved) {
        await _saveServerConfig(widget.serverConfig!);
        _serverConfigSaved = true;
      }

      final actions = ref.read(authActionsProvider);
      final success = await actions.loginWithApiKey(
        token,
        rememberCredentials: true,
      );

      if (!success && mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _loginError = l10n.genericSignInFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = _formatLoginError(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _launchSSO() async {
    setState(() {
      _isSigningIn = true;
      _loginError = null;
    });

    try {
      if (widget.serverConfig != null && !_serverConfigSaved) {
        await _saveServerConfig(widget.serverConfig!);
        _serverConfigSaved = true;
      }

      await _linkerService?.launchSSO();
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
    ref.listen<AsyncValue<AuthState>>(authStateManagerProvider, (
      previous,
      next,
    ) {
      final nextState = next.asData?.value;
      final prevState = previous?.asData?.value;
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

  Widget _buildLogo() {
    return Center(
      child: BrandService.createBrandIcon(
        size: 80,
        useGradient: false,
        addShadow: false,
        context: context,
      ),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    final theme = context.conduitTheme;
    
    return Column(
      children: [
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: theme.headingLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          l10n.signIn,
          textAlign: TextAlign.center,
          style: theme.bodyMedium?.copyWith(
            color: theme.textSecondary,
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
