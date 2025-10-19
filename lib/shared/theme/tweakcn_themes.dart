import 'package:flutter/material.dart';

/// Represents a single tweakcn theme variant (light or dark) and exposes the
/// standard set of color tokens defined by the registry.
@immutable
class TweakcnThemeVariant {
  const TweakcnThemeVariant({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
    required this.success,
    required this.successForeground,
    required this.warning,
    required this.warningForeground,
    required this.info,
    required this.infoForeground,
    this.radius = 16,
    this.fontSans = const <String>[],
    this.fontSerif = const <String>[],
    this.fontMono = const <String>[],
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;
  final Color success;
  final Color successForeground;
  final Color warning;
  final Color warningForeground;
  final Color info;
  final Color infoForeground;
  final double radius;
  final List<String> fontSans;
  final List<String> fontSerif;
  final List<String> fontMono;
}

/// Definition of a tweakcn theme that provides both light and dark variants.
@immutable
class TweakcnThemeDefinition {
  const TweakcnThemeDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.light,
    required this.dark,
    required this.preview,
  });

  final String id;
  final String label;
  final String description;
  final TweakcnThemeVariant light;
  final TweakcnThemeVariant dark;
  final List<Color> preview;

  TweakcnThemeVariant variantFor(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

Color mix(Color a, Color b, double amount) {
  // No-op for testing so downstream derivations stay at the source color.
  return a;
}

class TweakcnThemes {
  static final TweakcnThemeVariant _conduitLight = TweakcnThemeVariant(
    background: const Color(0xFFFFFFFF),
    foreground: const Color(0xFF0A0A0A),
    card: const Color(0xFFFFFFFF),
    cardForeground: const Color(0xFF0A0A0A),
    popover: const Color(0xFFFFFFFF),
    popoverForeground: const Color(0xFF0A0A0A),
    primary: const Color(0xFF171717),
    primaryForeground: const Color(0xFFFAFAFA),
    secondary: const Color(0xFFF5F5F5),
    secondaryForeground: const Color(0xFF171717),
    muted: const Color(0xFFF5F5F5),
    mutedForeground: const Color(0xFF737373),
    accent: const Color(0xFFF5F5F5),
    accentForeground: const Color(0xFF171717),
    destructive: const Color(0xFFE7000B),
    destructiveForeground: const Color(0xFFFAFAFA),
    border: const Color(0xFFE5E5E5),
    input: const Color(0xFFE5E5E5),
    ring: const Color(0xFFA1A1A1),
    sidebarBackground: const Color(0xFFFAFAFA),
    sidebarForeground: const Color(0xFF0A0A0A),
    sidebarPrimary: const Color(0xFF171717),
    sidebarPrimaryForeground: const Color(0xFFFAFAFA),
    sidebarAccent: const Color(0xFFF5F5F5),
    sidebarAccentForeground: const Color(0xFF171717),
    sidebarBorder: const Color(0xFFE5E5E5),
    sidebarRing: const Color(0xFFA1A1A1),
    success: const Color(0xFF00E6C7),
    successForeground: const Color(0xFF09090B),
    warning: const Color(0xFFF97316),
    warningForeground: const Color(0xFF09090B),
    info: const Color(0xFF2563EB),
    infoForeground: const Color(0xFFFAFAFA),
    radius: 10,
    fontSans: const <String>[
      'ui-sans-serif',
      'system-ui',
      '-apple-system',
      'BlinkMacSystemFont',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'Noto Sans',
      'sans-serif',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Segoe UI Symbol',
      'Noto Color Emoji',
    ],
    fontSerif: const <String>[
      'ui-serif',
      'Georgia',
      'Cambria',
      'Times New Roman',
      'Times',
      'serif',
    ],
    fontMono: const <String>[
      'ui-monospace',
      'SFMono-Regular',
      'SF Mono',
      'Menlo',
      'Monaco',
      'Consolas',
      'Liberation Mono',
      'Courier New',
      'monospace',
    ],
  );

  static final TweakcnThemeVariant _conduitDark = TweakcnThemeVariant(
    background: const Color(0xFF0A0A0A),
    foreground: const Color(0xFFFAFAFA),
    card: const Color(0xFF171717),
    cardForeground: const Color(0xFFFAFAFA),
    popover: const Color(0xFF262626),
    popoverForeground: const Color(0xFFFAFAFA),
    primary: const Color(0xFFE5E5E5),
    primaryForeground: const Color(0xFF171717),
    secondary: const Color(0xFF262626),
    secondaryForeground: const Color(0xFFFAFAFA),
    muted: const Color(0xFF262626),
    mutedForeground: const Color(0xFFA1A1AA),
    accent: const Color(0xFF404040),
    accentForeground: const Color(0xFFFAFAFA),
    destructive: const Color(0xFFFF6467),
    destructiveForeground: const Color(0xFFFAFAFA),
    border: const Color(0xFF282828),
    input: const Color(0xFF343434),
    ring: const Color(0xFF737373),
    sidebarBackground: const Color(0xFF171717),
    sidebarForeground: const Color(0xFFFAFAFA),
    sidebarPrimary: const Color(0xFF1447E6),
    sidebarPrimaryForeground: const Color(0xFFFAFAFA),
    sidebarAccent: const Color(0xFF262626),
    sidebarAccentForeground: const Color(0xFFFAFAFA),
    sidebarBorder: const Color(0xFF282828),
    sidebarRing: const Color(0xFF525252),
    success: const Color(0xFF00E6C7),
    successForeground: const Color(0xFF09090B),
    warning: const Color(0xFFF97316),
    warningForeground: const Color(0xFF09090B),
    info: const Color(0xFF2563EB),
    infoForeground: const Color(0xFFFAFAFA),
    radius: 10,
    fontSans: const <String>[
      'ui-sans-serif',
      'system-ui',
      '-apple-system',
      'BlinkMacSystemFont',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'Noto Sans',
      'sans-serif',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Segoe UI Symbol',
      'Noto Color Emoji',
    ],
    fontSerif: const <String>[
      'ui-serif',
      'Georgia',
      'Cambria',
      'Times New Roman',
      'Times',
      'serif',
    ],
    fontMono: const <String>[
      'ui-monospace',
      'SFMono-Regular',
      'SF Mono',
      'Menlo',
      'Monaco',
      'Consolas',
      'Liberation Mono',
      'Courier New',
      'monospace',
    ],
  );

  static final TweakcnThemeVariant _t3ChatLight = TweakcnThemeVariant(
    background: const Color(0xFFFAF5FA),
    foreground: const Color(0xFF501854),
    card: const Color(0xFFFAF5FA),
    cardForeground: const Color(0xFF501854),
    popover: const Color(0xFFFFFFFF),
    popoverForeground: const Color(0xFF501854),
    primary: const Color(0xFFA84370),
    primaryForeground: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFF1C4E6),
    secondaryForeground: const Color(0xFF77347C),
    muted: const Color(0xFFF6E5F3),
    mutedForeground: const Color(0xFF834588),
    accent: const Color(0xFFF1C4E6),
    accentForeground: const Color(0xFF77347C),
    destructive: const Color(0xFFAB4347),
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFFEFBDEB),
    input: const Color(0xFFE7C1DC),
    ring: const Color(0xFFDB2777),
    sidebarBackground: const Color(0xFFF3E4F6),
    sidebarForeground: const Color(0xFFAC1668),
    sidebarPrimary: const Color(0xFF454554),
    sidebarPrimaryForeground: const Color(0xFFFAF1F7),
    sidebarAccent: const Color(0xFFF8F8F7),
    sidebarAccentForeground: const Color(0xFF454554),
    sidebarBorder: const Color(0xFFECEAE9),
    sidebarRing: const Color(0xFFDB2777),
    success: const Color(0xFFF4A462),
    successForeground: const Color(0xFF501854),
    warning: const Color(0xFFE8C468),
    warningForeground: const Color(0xFF501854),
    info: const Color(0xFF6C12B9),
    infoForeground: const Color(0xFFF8F1F5),
    radius: 8,
  );

  static final TweakcnThemeVariant _t3ChatDark = TweakcnThemeVariant(
    background: const Color(0xFF221D27),
    foreground: const Color(0xFFD2C4DE),
    card: const Color(0xFF2C2632),
    cardForeground: const Color(0xFFDBC5D2),
    popover: const Color(0xFF100A0E),
    popoverForeground: const Color(0xFFF8F1F5),
    primary: const Color(0xFFA3004C),
    primaryForeground: const Color(0xFFEFC0D8),
    secondary: const Color(0xFF362D3D),
    secondaryForeground: const Color(0xFFD4C7E1),
    muted: const Color(0xFF28222D),
    mutedForeground: const Color(0xFFC2B6CF),
    accent: const Color(0xFF463753),
    accentForeground: const Color(0xFFF8F1F5),
    destructive: const Color(0xFF301015),
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFF3B3237),
    input: const Color(0xFF3E343C),
    ring: const Color(0xFFDB2777),
    sidebarBackground: const Color(0xFF181117),
    sidebarForeground: const Color(0xFFE0CAD6),
    sidebarPrimary: const Color(0xFF1D4ED8),
    sidebarPrimaryForeground: const Color(0xFFFFFFFF),
    sidebarAccent: const Color(0xFF261922),
    sidebarAccentForeground: const Color(0xFFF4F4F5),
    sidebarBorder: const Color(0xFF000000),
    sidebarRing: const Color(0xFFDB2777),
    success: const Color(0xFFE88C30),
    successForeground: const Color(0xFF181117),
    warning: const Color(0xFFAF57DB),
    warningForeground: const Color(0xFF181117),
    info: const Color(0xFF934DCB),
    infoForeground: const Color(0xFFF8F1F5),
    radius: 8,
  );

  static final TweakcnThemeVariant _claudeLight = TweakcnThemeVariant(
    background: const Color(0xFFFAF9F5),
    foreground: const Color(0xFF3D3929),
    card: const Color(0xFFFAF9F5),
    cardForeground: const Color(0xFF141413),
    popover: const Color(0xFFFFFFFF),
    popoverForeground: const Color(0xFF28261B),
    primary: const Color(0xFFC96442),
    primaryForeground: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFE9E6DC),
    secondaryForeground: const Color(0xFF535146),
    muted: const Color(0xFFEDE9DE),
    mutedForeground: const Color(0xFF83827D),
    accent: const Color(0xFFE9E6DC),
    accentForeground: const Color(0xFF28261B),
    destructive: const Color(0xFF141413),
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFFDAD9D4),
    input: const Color(0xFFB4B2A7),
    ring: const Color(0xFFC96442),
    sidebarBackground: const Color(0xFFF5F4EE),
    sidebarForeground: const Color(0xFF3D3D3A),
    sidebarPrimary: const Color(0xFFC96442),
    sidebarPrimaryForeground: const Color(0xFFFBFBFB),
    sidebarAccent: const Color(0xFFE9E6DC),
    sidebarAccentForeground: const Color(0xFF343434),
    sidebarBorder: const Color(0xFFEBEBEB),
    sidebarRing: const Color(0xFFB5B5B5),
    success: const Color(0xFF4C7A63),
    successForeground: const Color(0xFFFAF9F5),
    warning: const Color(0xFFD4A645),
    warningForeground: const Color(0xFF141413),
    info: const Color(0xFF9C87F5),
    infoForeground: const Color(0xFF141413),
    radius: 8,
    fontSans: const <String>[
      'ui-sans-serif',
      'system-ui',
      '-apple-system',
      'BlinkMacSystemFont',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'Noto Sans',
      'sans-serif',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Segoe UI Symbol',
      'Noto Color Emoji',
    ],
    fontSerif: const <String>[
      'ui-serif',
      'Georgia',
      'Cambria',
      'Times New Roman',
      'Times',
      'serif',
    ],
    fontMono: const <String>[
      'ui-monospace',
      'SFMono-Regular',
      'Menlo',
      'Monaco',
      'Consolas',
      'Liberation Mono',
      'Courier New',
      'monospace',
    ],
  );

  static final TweakcnThemeVariant _claudeDark = TweakcnThemeVariant(
    background: const Color(0xFF262624),
    foreground: const Color(0xFFC3C0B6),
    card: const Color(0xFF262624),
    cardForeground: const Color(0xFFFAF9F5),
    popover: const Color(0xFF30302E),
    popoverForeground: const Color(0xFFE5E5E2),
    primary: const Color(0xFFD97757),
    primaryForeground: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFFAF9F5),
    secondaryForeground: const Color(0xFF30302E),
    muted: const Color(0xFF1B1B19),
    mutedForeground: const Color(0xFFB7B5A9),
    accent: const Color(0xFF1A1915),
    accentForeground: const Color(0xFFF5F4EE),
    destructive: const Color(0xFFEF4444),
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFF3E3E38),
    input: const Color(0xFF52514A),
    ring: const Color(0xFFD97757),
    sidebarBackground: const Color(0xFF1F1E1D),
    sidebarForeground: const Color(0xFFC3C0B6),
    sidebarPrimary: const Color(0xFF343434),
    sidebarPrimaryForeground: const Color(0xFFFBFBFB),
    sidebarAccent: const Color(0xFF0F0F0E),
    sidebarAccentForeground: const Color(0xFFC3C0B6),
    sidebarBorder: const Color(0xFFEBEBEB),
    sidebarRing: const Color(0xFFB5B5B5),
    success: const Color(0xFF6AA884),
    successForeground: const Color(0xFF1B1B19),
    warning: const Color(0xFFE0B456),
    warningForeground: const Color(0xFF1B1B19),
    info: const Color(0xFFB39CFF),
    infoForeground: const Color(0xFF1B1B19),
    radius: 8,
    fontSans: const <String>[
      'ui-sans-serif',
      'system-ui',
      '-apple-system',
      'BlinkMacSystemFont',
      'Segoe UI',
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'Noto Sans',
      'sans-serif',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'Segoe UI Symbol',
      'Noto Color Emoji',
    ],
    fontSerif: const <String>[
      'ui-serif',
      'Georgia',
      'Cambria',
      'Times New Roman',
      'Times',
      'serif',
    ],
    fontMono: const <String>[
      'ui-monospace',
      'SFMono-Regular',
      'Menlo',
      'Monaco',
      'Consolas',
      'Liberation Mono',
      'Courier New',
      'monospace',
    ],
  );

  static final TweakcnThemeDefinition claude = TweakcnThemeDefinition(
    id: 'claude',
    label: 'Claude',
    description: 'Warm, tactile palette lifted from the Claude web client.',
    light: _claudeLight,
    dark: _claudeDark,
    preview: const <Color>[
      Color(0xFFC96442),
      Color(0xFFE9E6DC),
      Color(0xFF1A1915),
    ],
  );

  static final TweakcnThemeDefinition t3Chat = TweakcnThemeDefinition(
    id: 't3_chat',
    label: 'T3 Chat',
    description: 'Playful gradients inspired by the T3 Stack brand.',
    light: _t3ChatLight,
    dark: _t3ChatDark,
    preview: const <Color>[
      Color(0xFFA84370),
      Color(0xFFF1C4E6),
      Color(0xFFDB2777),
    ],
  );

  static final TweakcnThemeDefinition conduit = TweakcnThemeDefinition(
    id: 'conduit',
    label: 'Conduit',
    description: 'Clean neutral theme designed for Conduit.',
    light: _conduitLight,
    dark: _conduitDark,
    preview: const <Color>[
      Color(0xFFA1A1AA),
      Color(0xFFF4F4F5),
      Color(0xFF404040),
    ],
  );

  static List<TweakcnThemeDefinition> all = [conduit, claude, t3Chat];

  static TweakcnThemeDefinition byId(String? id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => conduit);
  }
}

@immutable
class AppPaletteThemeExtension
    extends ThemeExtension<AppPaletteThemeExtension> {
  const AppPaletteThemeExtension({required this.palette});

  final TweakcnThemeDefinition palette;

  @override
  AppPaletteThemeExtension copyWith({TweakcnThemeDefinition? palette}) {
    return AppPaletteThemeExtension(palette: palette ?? this.palette);
  }

  @override
  AppPaletteThemeExtension lerp(
    covariant ThemeExtension<AppPaletteThemeExtension>? other,
    double t,
  ) {
    if (other is! AppPaletteThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}
