import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:conduit/l10n/app_localizations.dart';
import '../../../core/widgets/error_boundary.dart';
import '../../../shared/widgets/improved_loading_states.dart';

import '../../../shared/utils/ui_utils.dart';
import '../../../shared/widgets/themed_dialogs.dart';
import '../../../shared/widgets/sheet_handle.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/navigation_service.dart';
import '../../auth/providers/unified_auth_providers.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user.dart' as models;
import 'dart:async';
import 'dart:io';
import '../../chat/views/chat_page_helpers.dart';
import '../../../shared/widgets/modal_safe_area.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../core/utils/user_avatar_utils.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Profile page (You tab) showing user info and main actions
/// Enhanced with production-grade design tokens for better cohesion
class ProfilePage extends ConsumerWidget {
  static const _websiteUrl = 'https://clinicalguidelines.io';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider2);
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.maybeWhen(
      data: (value) => value ?? authUser,
      orElse: () => authUser,
    );
    final isAuthLoading = ref.watch(isAuthLoadingProvider2);
    final api = ref.watch(apiServiceProvider);

    Widget body;
    if (isAuthLoading && user == null) {
      body = _buildCenteredState(
        context,
        ImprovedLoadingState(
          message: AppLocalizations.of(context)!.loadingProfile,
        ),
      );
    } else {
      body = _buildProfileBody(context, ref, user, api);
    }

    return ErrorBoundary(child: _buildScaffold(context, body: body));
  }

  Scaffold _buildScaffold(BuildContext context, {required Widget body}) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.conduitTheme.surfaceBackground,
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        leading: canPop ? const FloatingAppBarBackButton() : null,
        title: FloatingAppBarTitle(text: l10n.you),
      ),
      body: body,
    );
  }

  Widget _buildCenteredState(BuildContext context, Widget child) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 24;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.pagePadding,
        topPadding,
        Spacing.pagePadding,
        Spacing.pagePadding + MediaQuery.of(context).padding.bottom,
      ),
      child: Center(child: child),
    );
  }

  Widget _buildProfileBody(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
    ApiService? api,
  ) {
    // Calculate top padding to account for app bar + safe area
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 24;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        Spacing.pagePadding,
        topPadding,
        Spacing.pagePadding,
        Spacing.pagePadding + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _buildProfileHeader(context, userData, api),
        const SizedBox(height: Spacing.xl),
        _buildAccountSection(context, ref),
        const SizedBox(height: Spacing.xl),
        _buildSupportSection(context),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final theme = context.conduitTheme;
    final textTheme =
        theme.bodySmall?.copyWith(
          color: theme.sidebarForeground.withValues(alpha: 0.75),
        ) ??
        TextStyle(color: theme.sidebarForeground.withValues(alpha: 0.75));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.supportConduit,
          style: theme.headingSmall?.copyWith(color: theme.sidebarForeground),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          AppLocalizations.of(context)!.supportConduitSubtitle,
          style: textTheme,
        ),
        const SizedBox(height: Spacing.sm),
        _ProfileSettingTile(
          onTap: () => _openExternalLink(context, _websiteUrl),
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.globe,
              android: Icons.language,
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: AppLocalizations.of(context)!.websiteTitle,
          subtitle: AppLocalizations.of(context)!.websiteSubtitle,
          trailing: Icon(
            UiUtils.platformIcon(
              ios: CupertinoIcons.arrow_up_right,
              android: Icons.open_in_new,
            ),
            color: theme.iconSecondary,
            size: IconSize.small,
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalLink(BuildContext context, String url) async {
    try {
      final launched = await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        UiUtils.showMessage(
          context,
          AppLocalizations.of(context)!.errorMessage,
        );
      }
    } on PlatformException catch (_) {
      if (!context.mounted) return;
      UiUtils.showMessage(context, AppLocalizations.of(context)!.errorMessage);
    } catch (_) {
      if (!context.mounted) return;
      UiUtils.showMessage(context, AppLocalizations.of(context)!.errorMessage);
    }
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    ApiService? api,
  ) {
    final displayName = deriveUserDisplayName(user);
    final characters = displayName.characters;
    final initial = characters.isNotEmpty
        ? characters.first.toUpperCase()
        : 'U';
    final avatarUrl = resolveUserAvatarUrlForUser(api, user);

    String? extractEmail(dynamic source) {
      if (source is models.User) {
        return source.email;
      }
      if (source is Map) {
        final value = source['email'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        final nested = source['user'];
        if (nested is Map) {
          final nestedValue = nested['email'];
          if (nestedValue is String && nestedValue.trim().isNotEmpty) {
            return nestedValue.trim();
          }
        }
      }
      return null;
    }

    final email = extractEmail(user) ?? 'No email';
    final theme = context.conduitTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.sidebarAccent.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border: Border.all(
          color: theme.sidebarBorder.withValues(alpha: 0.6),
          width: BorderWidth.thin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(size: 56, imageUrl: avatarUrl, fallbackText: initial),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.headingMedium?.copyWith(
                        color: theme.sidebarForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Icon(
                          UiUtils.platformIcon(
                            ios: CupertinoIcons.envelope,
                            android: Icons.mail_outline,
                          ),
                          size: IconSize.small,
                          color: theme.sidebarForeground.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Flexible(
                          child: Text(
                            email,
                            style: theme.bodySmall?.copyWith(
                              color: theme.sidebarForeground.withValues(
                                alpha: 0.75,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final items = [
      // Default Model tile removed from here
      _buildAccountOption(
        context,
        icon: UiUtils.platformIcon(
          ios: CupertinoIcons.slider_horizontal_3,
          android: Icons.tune,
        ),
        title: AppLocalizations.of(context)!.appCustomization,
        subtitle: AppLocalizations.of(context)!.appCustomizationSubtitle,
        onTap: () {
          context.pushNamed(RouteNames.appCustomization);
        },
      ),
      _buildAboutTile(context),
      _buildAccountOption(
        context,
        icon: UiUtils.platformIcon(
          ios: CupertinoIcons.square_arrow_left,
          android: Icons.logout,
        ),
        title: AppLocalizations.of(context)!.signOut,
        subtitle: AppLocalizations.of(context)!.endYourSession,
        onTap: () => _signOut(context, ref),
        showChevron: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }

  Widget _buildAccountOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    final theme = context.conduitTheme;
    final color = theme.buttonPrimary;
    return _ProfileSettingTile(
      onTap: onTap,
      leading: _buildIconBadge(context, icon, color: color),
      title: title,
      subtitle: subtitle,
      trailing: showChevron
          ? Icon(
              UiUtils.platformIcon(
                ios: CupertinoIcons.chevron_right,
                android: Icons.chevron_right,
              ),
              color: theme.iconSecondary,
              size: IconSize.small,
            )
          : null,
    );
  }

  Widget _buildIconBadge(
    BuildContext context,
    IconData icon, {
    required Color color,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: BorderWidth.thin,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: IconSize.medium),
    );
  }

  // Theme and language controls moved to AppCustomizationPage.

  Widget _buildAboutTile(BuildContext context) {
    return _buildAccountOption(
      context,
      icon: UiUtils.platformIcon(
        ios: CupertinoIcons.info,
        android: Icons.info_outline,
      ),
      title: AppLocalizations.of(context)!.aboutApp,
      subtitle: AppLocalizations.of(context)!.aboutAppSubtitle,
      onTap: () => _showAboutDialog(context),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      // Update dialog with dynamic version each time
      // GitHub repo URL source of truth
      const githubUrl = 'https://github.com/cogwheel0/conduit';

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: ctx.sidebarTheme.background,
            title: Text(
              AppLocalizations.of(ctx)!.aboutConduit,
              style: ctx.conduitTheme.headingSmall?.copyWith(
                color: ctx.sidebarTheme.foreground,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    ctx,
                  )!.versionLabel(info.version, info.buildNumber),
                  style: ctx.conduitTheme.bodyMedium?.copyWith(
                    color: ctx.sidebarTheme.foreground.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                InkWell(
                  onTap: () => launchUrlString(
                    githubUrl,
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        UiUtils.platformIcon(
                          ios: CupertinoIcons.link,
                          android: Icons.link,
                        ),
                        size: IconSize.small,
                        color: ctx.conduitTheme.buttonPrimary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        AppLocalizations.of(ctx)!.githubRepository,
                        style: ctx.conduitTheme.bodyMedium?.copyWith(
                          color: ctx.conduitTheme.buttonPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(ctx)!.closeButtonSemantic),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      UiUtils.showMessage(
        context,
        AppLocalizations.of(context)!.unableToLoadAppInfo,
      );
    }
  }

  void _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await ThemedDialogs.confirm(
      context,
      title: AppLocalizations.of(context)!.signOut,
      message: AppLocalizations.of(context)!.endYourSession,
      confirmText: AppLocalizations.of(context)!.signOut,
      isDestructive: true,
    );

    if (confirm) {
      await ref.read(authActionsProvider).logout();
    }
  }
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final textColor = theme.sidebarForeground;
    final subtitleColor = theme.sidebarForeground.withValues(alpha: 0.75);

    return ConduitCard(
      padding: const EdgeInsets.all(Spacing.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  subtitle,
                  style: theme.bodySmall?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            trailing!,
          ] else if (showChevron && onTap != null) ...[
            const SizedBox(width: Spacing.sm),
            Icon(
              UiUtils.platformIcon(
                ios: CupertinoIcons.chevron_right,
                android: Icons.chevron_right,
              ),
              color: theme.iconSecondary,
              size: IconSize.small,
            ),
          ],
        ],
      ),
    );
  }
}
