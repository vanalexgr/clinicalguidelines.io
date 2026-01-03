import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/socket_health.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/theme/tweakcn_themes.dart';
import '../../tools/providers/tools_providers.dart';
import '../../../core/models/tool.dart';
import '../../../shared/widgets/conduit_components.dart';
import '../../../shared/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';

class AppCustomizationPage extends ConsumerWidget {
  const AppCustomizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final l10n = AppLocalizations.of(context)!;
    final themeDescription = () {
      if (themeMode == ThemeMode.system) {
        final systemThemeLabel = platformBrightness == Brightness.dark
            ? l10n.themeDark
            : l10n.themeLight;
        return l10n.followingSystem(systemThemeLabel);
      }
      if (themeMode == ThemeMode.dark) {
        return l10n.currentlyUsingDarkTheme;
      }
      return l10n.currentlyUsingLightTheme;
    }();
    final locale = ref.watch(appLocaleProvider);
    final currentLanguageCode = locale?.toLanguageTag() ?? 'system';
    final languageLabel = _resolveLanguageLabel(context, currentLanguageCode);
    final activeTheme = ref.watch(appThemePaletteProvider);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 24;

    return Scaffold(
      backgroundColor: context.conduitTheme.surfaceBackground,
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        leading: canPop ? const FloatingAppBarBackButton() : null,
        title: FloatingAppBarTitle(text: l10n.appCustomization),
      ),
      body: ListView(
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
          _buildThemesDropdownSection(
            context,
            ref,
            themeMode,
            themeDescription,
            activeTheme,
            settings,
          ),
          const SizedBox(height: Spacing.md),
          _buildLanguageSection(
            context,
            ref,
            currentLanguageCode,
            languageLabel,
          ),
          const SizedBox(height: Spacing.xl),
          _buildChatSection(context, ref, settings),
          const SizedBox(height: Spacing.xl),
          _buildSocketHealthSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildThemesDropdownSection(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    String themeDescription,
    TweakcnThemeDefinition activeTheme,
    AppSettings settings,
  ) {
    final theme = context.conduitTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.display,
          style:
              theme.headingSmall?.copyWith(color: theme.sidebarForeground) ??
              TextStyle(color: theme.sidebarForeground, fontSize: 18),
        ),
        const SizedBox(height: Spacing.sm),
        _ExpandableCard(
          title: AppLocalizations.of(context)!.darkMode,
          subtitle: themeDescription,
          icon: UiUtils.platformIcon(
            ios: CupertinoIcons.moon_stars,
            android: Icons.dark_mode,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  _buildThemeChip(
                    context,
                    ref,
                    mode: ThemeMode.system,
                    isSelected: themeMode == ThemeMode.system,
                    label: AppLocalizations.of(context)!.system,
                    icon: UiUtils.platformIcon(
                      ios: CupertinoIcons.sparkles,
                      android: Icons.auto_mode,
                    ),
                  ),
                  _buildThemeChip(
                    context,
                    ref,
                    mode: ThemeMode.light,
                    isSelected: themeMode == ThemeMode.light,
                    label: AppLocalizations.of(context)!.themeLight,
                    icon: UiUtils.platformIcon(
                      ios: CupertinoIcons.sun_max,
                      android: Icons.light_mode,
                    ),
                  ),
                  _buildThemeChip(
                    context,
                    ref,
                    mode: ThemeMode.dark,
                    isSelected: themeMode == ThemeMode.dark,
                    label: AppLocalizations.of(context)!.themeDark,
                    icon: UiUtils.platformIcon(
                      ios: CupertinoIcons.moon_fill,
                      android: Icons.dark_mode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        _buildPaletteSelector(context, ref, activeTheme),
      ],
    );
  }

  Widget _buildLanguageSection(
    BuildContext context,
    WidgetRef ref,
    String currentLanguageTag,
    String languageLabel,
  ) {
    final theme = context.conduitTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomizationTile(
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.globe,
              android: Icons.language,
            ),
            color: theme.buttonPrimary,
          ),
          title: AppLocalizations.of(context)!.appLanguage,
          subtitle: languageLabel,
          onTap: () async {
            final selected = await _showLanguageSelector(
              context,
              currentLanguageTag,
            );
            if (selected == null) return;
            if (selected == 'system') {
              await ref.read(appLocaleProvider.notifier).setLocale(null);
            } else {
              final parsed = _parseLocaleTag(selected);
              await ref
                  .read(appLocaleProvider.notifier)
                  .setLocale(parsed ?? Locale(selected));
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaletteSelector(
    BuildContext context,
    WidgetRef ref,
    TweakcnThemeDefinition activeTheme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final palettes = TweakcnThemes.all;

    return _ExpandableCard(
      title: l10n.themePalette,
      subtitle: activeTheme.label(l10n),
      icon: UiUtils.platformIcon(
        ios: CupertinoIcons.square_fill_on_square_fill,
        android: Icons.palette,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final palette in palettes)
            _PaletteOption(
              themeDefinition: palette,
              l10n: l10n,
              activeId: activeTheme.id,
              onSelect: () => ref
                  .read(appThemePaletteProvider.notifier)
                  .setPalette(palette.id),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required bool isSelected,
    required String label,
    required IconData icon,
  }) {
    return ConduitChip(
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: () => ref.read(appThemeModeProvider.notifier).setTheme(mode),
    );
  }

  Widget _buildChatSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;
    final transportAvailability = ref.watch(socketTransportOptionsProvider);
    var activeTransportMode = settings.socketTransportMode;
    if (!transportAvailability.allowPolling &&
        activeTransportMode == 'polling') {
      activeTransportMode = 'ws';
    } else if (!transportAvailability.allowWebsocketOnly &&
        activeTransportMode == 'ws') {
      activeTransportMode = 'polling';
    }
    final transportLabel = activeTransportMode == 'polling'
        ? l10n.transportModePolling
        : l10n.transportModeWs;
    final assistantTriggerLabel = _androidAssistantTriggerLabel(
      l10n,
      settings.androidAssistantTrigger,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.chatSettings,
          style:
              theme.headingSmall?.copyWith(color: theme.sidebarForeground) ??
              TextStyle(color: theme.sidebarForeground, fontSize: 18),
        ),
        const SizedBox(height: Spacing.sm),
        _CustomizationTile(
          leading: _buildIconBadge(
            context,
            UiUtils.platformIcon(
              ios: CupertinoIcons.arrow_2_circlepath,
              android: Icons.sync,
            ),
            color: theme.buttonPrimary,
          ),
          title: l10n.transportMode,
          subtitle: transportLabel,
          trailing:
              transportAvailability.allowPolling &&
                  transportAvailability.allowWebsocketOnly
              ? _buildValueBadge(context, transportLabel)
              : null,
          onTap:
              transportAvailability.allowPolling &&
                  transportAvailability.allowWebsocketOnly
              ? () => _showTransportModeSheet(
                  context,
                  ref,
                  settings,
                  allowPolling: transportAvailability.allowPolling,
                  allowWebsocketOnly: transportAvailability.allowWebsocketOnly,
                )
              : null,
          showChevron:
              transportAvailability.allowPolling &&
              transportAvailability.allowWebsocketOnly,
        ),
        const SizedBox(height: Spacing.sm),
        _CustomizationTile(
          leading: _buildIconBadge(
            context,
            Platform.isIOS ? CupertinoIcons.paperplane : Icons.keyboard_return,
            color: theme.buttonPrimary,
          ),
          title: l10n.sendOnEnter,
          subtitle: l10n.sendOnEnterDescription,
          trailing: Switch.adaptive(
            value: settings.sendOnEnter,
            onChanged: (value) =>
                ref.read(appSettingsProvider.notifier).setSendOnEnter(value),
          ),
          showChevron: false,
          onTap: () => ref
              .read(appSettingsProvider.notifier)
              .setSendOnEnter(!settings.sendOnEnter),
        ),
        if (Platform.isAndroid) ...[
          const SizedBox(height: Spacing.sm),
          _CustomizationTile(
            leading: _buildIconBadge(
              context,
              Icons.assistant,
              color: theme.buttonPrimary,
            ),
            title: l10n.androidAssistantTitle,
            subtitle: assistantTriggerLabel,
            onTap: () =>
                _showAndroidAssistantTriggerSheet(context, ref, settings),
          ),
        ],
      ],
    );
  }

  Widget _buildSocketHealthSection(BuildContext context, WidgetRef ref) {
    final theme = context.conduitTheme;
    final socketService = ref.watch(socketServiceProvider);

    if (socketService == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection Health',
          style:
              theme.headingSmall?.copyWith(color: theme.sidebarForeground) ??
              TextStyle(color: theme.sidebarForeground, fontSize: 18),
        ),
        const SizedBox(height: Spacing.sm),
        _SocketHealthCard(socketService: socketService),
      ],
    );
  }

  String _androidAssistantTriggerLabel(
    AppLocalizations l10n,
    AndroidAssistantTrigger trigger,
  ) {
    switch (trigger) {
      case AndroidAssistantTrigger.overlay:
        return l10n.androidAssistantOverlayOption;
      case AndroidAssistantTrigger.newChat:
        return l10n.androidAssistantNewChatOption;
      case AndroidAssistantTrigger.voiceCall:
        return l10n.androidAssistantNewChatOption;
    }
  }

  Future<void> _showAndroidAssistantTriggerSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;
    final options = <({AndroidAssistantTrigger value, String label})>[
      (
        value: AndroidAssistantTrigger.overlay,
        label: l10n.androidAssistantOverlayOption,
      ),
      (
        value: AndroidAssistantTrigger.newChat,
        label: l10n.androidAssistantNewChatOption,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.sidebarBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.modal),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.androidAssistantTitle,
                            style:
                                theme.headingSmall?.copyWith(
                                  color: theme.sidebarForeground,
                                ) ??
                                TextStyle(
                                  color: theme.sidebarForeground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            l10n.androidAssistantDescription,
                            style:
                                theme.bodySmall?.copyWith(
                                  color: theme.sidebarForeground.withValues(
                                    alpha: 0.7,
                                  ),
                                ) ??
                                TextStyle(
                                  color: theme.sidebarForeground.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.iconPrimary),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < options.length; i++) ...[
                () {
                  final option = options[i];
                  final selected =
                      settings.androidAssistantTrigger == option.value;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected
                          ? theme.buttonPrimary
                          : theme.iconSecondary,
                    ),
                    title: Text(
                      option.label,
                      style: theme.bodyMedium?.copyWith(
                        color: theme.sidebarForeground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      if (!selected) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setAndroidAssistantTrigger(option.value);
                      }
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }(),
                if (i != options.length - 1) const Divider(height: 1),
              ],
              const SizedBox(height: Spacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    final theme = context.conduitTheme;
    return ConduitCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBadge(context, icon, color: theme.buttonPrimary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style:
                      theme.bodyMedium?.copyWith(
                        color: theme.sidebarForeground,
                        fontWeight: FontWeight.w500,
                      ) ??
                      TextStyle(color: theme.sidebarForeground, fontSize: 14),
                ),
              ),
              Text(
                label,
                style:
                    theme.bodyMedium?.copyWith(
                      color: theme.sidebarForeground.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ) ??
                    TextStyle(
                      color: theme.sidebarForeground.withValues(alpha: 0.75),
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _resolveLanguageLabel(BuildContext context, String code) {
    final normalizedCode = code.replaceAll('_', '-');

    switch (code) {
      case 'en':
        return AppLocalizations.of(context)!.english;
      case 'de':
        return AppLocalizations.of(context)!.deutsch;
      case 'fr':
        return AppLocalizations.of(context)!.francais;
      case 'it':
        return AppLocalizations.of(context)!.italiano;
      case 'es':
        return AppLocalizations.of(context)!.espanol;
      case 'nl':
        return AppLocalizations.of(context)!.nederlands;
      case 'ru':
        return AppLocalizations.of(context)!.russian;
      case 'zh':
        return AppLocalizations.of(context)!.chineseSimplified;
      case 'ko':
        return AppLocalizations.of(context)!.korean;
      case 'zh-Hant':
        return AppLocalizations.of(context)!.chineseTraditional;
      default:
        if (normalizedCode == 'zh-hant') {
          return AppLocalizations.of(context)!.chineseTraditional;
        }
        if (normalizedCode == 'zh') {
          return AppLocalizations.of(context)!.chineseSimplified;
        }
        if (normalizedCode == 'ko') {
          return AppLocalizations.of(context)!.korean;
        }
        return AppLocalizations.of(context)!.system;
    }
  }

  Future<void> _showTransportModeSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings, {
    required bool allowPolling,
    required bool allowWebsocketOnly,
  }) async {
    final theme = context.conduitTheme;
    final l10n = AppLocalizations.of(context)!;
    var current = settings.socketTransportMode;

    final options = <({String value, String title, String subtitle})>[];
    if (allowPolling) {
      options.add((
        value: 'polling',
        title: l10n.transportModePolling,
        subtitle: l10n.transportModePollingInfo,
      ));
    }
    if (allowWebsocketOnly) {
      options.add((
        value: 'ws',
        title: l10n.transportModeWs,
        subtitle: l10n.transportModeWsInfo,
      ));
    }

    if (options.isEmpty) {
      return;
    }

    if (!options.any((option) => option.value == current)) {
      current = options.first.value;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.sidebarBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.modal),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.transportMode,
                        style:
                            theme.headingSmall?.copyWith(
                              color: theme.sidebarForeground,
                            ) ??
                            TextStyle(
                              color: theme.sidebarForeground,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.iconPrimary),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (var i = 0; i < options.length; i++) ...[
                () {
                  final option = options[i];
                  final selected = current == option.value;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected
                          ? theme.buttonPrimary
                          : theme.iconSecondary,
                    ),
                    title: Text(option.title),
                    subtitle: Text(option.subtitle),
                    onTap: () {
                      if (!selected) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .setSocketTransportMode(option.value);
                      }
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }(),
                if (i != options.length - 1) const Divider(height: 1),
              ],
              const SizedBox(height: Spacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValueBadge(BuildContext context, String label) {
    final theme = context.conduitTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.buttonPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: theme.buttonPrimary.withValues(alpha: 0.25),
          width: BorderWidth.thin,
        ),
      ),
      child: Text(
        label,
        style:
            theme.bodySmall?.copyWith(
              color: theme.buttonPrimary,
              fontWeight: FontWeight.w600,
            ) ??
            TextStyle(
              color: theme.buttonPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
      ),
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

  Future<String?> _showLanguageSelector(BuildContext context, String current) {
    final normalizedCurrent = current.replaceAll('_', '-');

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.sidebarTheme.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.modal),
          ),
          boxShadow: ConduitShadows.modal(context),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Spacing.sm),
              ListTile(
                title: Text(AppLocalizations.of(context)!.system),
                trailing: normalizedCurrent == 'system'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'system'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.english),
                trailing: normalizedCurrent == 'en'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'en'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.deutsch),
                trailing: normalizedCurrent == 'de'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'de'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.espanol),
                trailing: normalizedCurrent == 'es'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'es'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.francais),
                trailing: normalizedCurrent == 'fr'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'fr'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.italiano),
                trailing: normalizedCurrent == 'it'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'it'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.nederlands),
                trailing: normalizedCurrent == 'nl'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'nl'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.russian),
                trailing: normalizedCurrent == 'ru'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'ru'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.chineseSimplified),
                trailing: normalizedCurrent == 'zh'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'zh'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.chineseTraditional),
                trailing: normalizedCurrent == 'zh-Hant'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'zh-Hant'),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.korean),
                trailing: normalizedCurrent == 'ko'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, 'ko'),
              ),
              const SizedBox(height: Spacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

Locale? _parseLocaleTag(String code) {
  final normalized = code.replaceAll('_', '-');
  final parts = normalized.split('-');
  if (parts.isEmpty || parts.first.isEmpty) return null;

  final language = parts.first;
  String? script;
  String? country;

  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.length == 4) {
      script = '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    } else if (part.length == 2 || part.length == 3) {
      country = part.toUpperCase();
    }
  }

  return Locale.fromSubtags(
    languageCode: language,
    scriptCode: script,
    countryCode: country,
  );
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.themeDefinition,
    required this.activeId,
    required this.onSelect,
    required this.l10n,
  });

  final TweakcnThemeDefinition themeDefinition;
  final String activeId;
  final VoidCallback onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final isSelected = themeDefinition.id == activeId;
    final previewColors = themeDefinition.preview;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(AppBorderRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.buttonPrimary : theme.iconSecondary,
              size: IconSize.small,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          themeDefinition.label(l10n),
                          style: theme.bodyMedium?.copyWith(
                            color: theme.sidebarForeground,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: Spacing.xs),
                          child: Icon(
                            Icons.check_circle,
                            color: theme.buttonPrimary,
                            size: IconSize.small,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    themeDefinition.description(l10n),
                    style:
                        theme.bodySmall?.copyWith(
                          color: theme.sidebarForeground.withValues(
                            alpha: 0.75,
                          ),
                        ) ??
                        TextStyle(
                          color: theme.sidebarForeground.withValues(
                            alpha: 0.75,
                          ),
                        ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: [
                      for (final color in previewColors)
                        _PaletteColorDot(color: color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteColorDot extends StatelessWidget {
  const _PaletteColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    return Container(
      margin: const EdgeInsets.only(right: Spacing.xs),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: BorderWidth.thin,
        ),
      ),
    );
  }
}

class _CustomizationTile extends StatelessWidget {
  const _CustomizationTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
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
                    color: theme.sidebarForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  subtitle,
                  style: theme.bodySmall?.copyWith(
                    color: theme.sidebarForeground.withValues(alpha: 0.75),
                  ),
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

/// Expandable card widget for collapsible settings sections.
class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return ConduitCard(
      padding: EdgeInsets.zero,
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.buttonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    border: Border.all(
                      color: theme.buttonPrimary.withValues(alpha: 0.2),
                      width: BorderWidth.thin,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    color: theme.buttonPrimary,
                    size: IconSize.medium,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.bodyMedium?.copyWith(
                          color: theme.sidebarForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        widget.subtitle,
                        style: theme.bodySmall?.copyWith(
                          color: theme.sidebarForeground.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                // Expand/collapse icon
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    UiUtils.platformIcon(
                      ios: CupertinoIcons.chevron_down,
                      android: Icons.expand_more,
                    ),
                    color: theme.iconSecondary,
                    size: IconSize.small,
                  ),
                ),
              ],
            ),
          ),
          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget that displays socket connection health with real-time updates.
class _SocketHealthCard extends StatefulWidget {
  const _SocketHealthCard({required this.socketService});

  final SocketService socketService;

  @override
  State<_SocketHealthCard> createState() => _SocketHealthCardState();
}

class _SocketHealthCardState extends State<_SocketHealthCard> {
  SocketHealth? _health;
  StreamSubscription<SocketHealth>? _subscription;

  @override
  void initState() {
    super.initState();
    _initHealth();
  }

  void _initHealth() {
    _health = widget.socketService.currentHealth;
    _subscription = widget.socketService.healthStream.listen((health) {
      if (mounted) {
        setState(() => _health = health);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SocketHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.socketService != widget.socketService) {
      _subscription?.cancel();
      _initHealth();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;
    final health = _health;

    if (health == null) {
      return ConduitCard(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              color: theme.iconSecondary,
              size: IconSize.medium,
            ),
            const SizedBox(width: Spacing.md),
            Text(
              'Not connected',
              style: theme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ],
        ),
      );
    }

    final statusColor = health.isConnected ? theme.success : theme.error;
    final qualityColor = _getQualityColor(theme, health.quality);

    return ConduitCard(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.2),
                    width: BorderWidth.thin,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  health.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: statusColor,
                  size: IconSize.medium,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health.isConnected ? 'Connected' : 'Disconnected',
                      style: theme.bodyMedium?.copyWith(
                        color: theme.sidebarForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      _getTransportLabel(health.transport),
                      style: theme.bodySmall?.copyWith(
                        color: theme.sidebarForeground.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              // Connection quality indicator
              if (health.isConnected && health.hasLatencyInfo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: qualityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    border: Border.all(
                      color: qualityColor.withValues(alpha: 0.3),
                      width: BorderWidth.thin,
                    ),
                  ),
                  child: Text(
                    _getQualityLabel(health.quality),
                    style: theme.bodySmall?.copyWith(
                      color: qualityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (health.isConnected) ...[
            const SizedBox(height: Spacing.md),
            const Divider(height: 1),
            const SizedBox(height: Spacing.md),
            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.speed,
                    label: 'Latency',
                    value: health.hasLatencyInfo
                        ? '${health.latencyMs}ms'
                        : '—',
                    color: qualityColor,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.refresh,
                    label: 'Reconnects',
                    value: '${health.reconnectCount}',
                    color: health.reconnectCount > 0
                        ? theme.warning
                        : theme.success,
                  ),
                ),
              ],
            ),
            if (health.lastHeartbeat != null) ...[
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: theme.error.withValues(alpha: 0.7),
                    size: IconSize.small,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    'Last heartbeat: ${_formatLastHeartbeat(health.lastHeartbeat!)}',
                    style: theme.bodySmall?.copyWith(
                      color: theme.sidebarForeground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _getTransportLabel(String transport) {
    switch (transport) {
      case 'websocket':
        return 'WebSocket transport';
      case 'polling':
        return 'HTTP polling transport';
      default:
        return 'Unknown transport';
    }
  }

  String _getQualityLabel(String quality) {
    switch (quality) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return '—';
    }
  }

  Color _getQualityColor(ConduitThemeExtension theme, String quality) {
    switch (quality) {
      case 'excellent':
        return theme.success;
      case 'good':
        return theme.success.withValues(alpha: 0.8);
      case 'fair':
        return theme.warning;
      case 'poor':
        return theme.error;
      default:
        return theme.textSecondary;
    }
  }

  String _formatLastHeartbeat(DateTime lastHeartbeat) {
    final now = DateTime.now();
    final diff = now.difference(lastHeartbeat);

    if (diff.inSeconds < 5) {
      return 'just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = context.conduitTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: theme.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(
          color: theme.cardBorder.withValues(alpha: 0.3),
          width: BorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: IconSize.small),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.bodySmall?.copyWith(
                    color: theme.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
