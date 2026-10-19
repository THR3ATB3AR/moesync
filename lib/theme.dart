import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeColorPreset {
  final String name;
  final Color color;

  const ThemeColorPreset({required this.name, required this.color});
}

const themeColorPresets = <ThemeColorPreset>[
  ThemeColorPreset(name: 'Purple (M3)', color: Color(0xFF6750A4)),
  ThemeColorPreset(name: 'Indigo', color: Color(0xFF3F51B5)),
  ThemeColorPreset(name: 'Blue', color: Color(0xFF1E88E5)),
  ThemeColorPreset(name: 'Cyan', color: Color(0xFF00ACC1)),
  ThemeColorPreset(name: 'Teal', color: Color(0xFF00897B)),
  ThemeColorPreset(name: 'Green', color: Color(0xFF43A047)),
  ThemeColorPreset(name: 'Lime', color: Color(0xFF7CB342)),
  ThemeColorPreset(name: 'Amber', color: Color(0xFFFFB300)),
  ThemeColorPreset(name: 'Orange', color: Color(0xFFFB8C00)),
  ThemeColorPreset(name: 'Deep Orange', color: Color(0xFFF4511E)),
  ThemeColorPreset(name: 'Red', color: Color(0xFFE53935)),
  ThemeColorPreset(name: 'Pink', color: Color(0xFFD81B60)),
  ThemeColorPreset(name: 'Sakura Rose', color: Color(0xFFE91E63)),
  ThemeColorPreset(name: 'Deep Purple', color: Color(0xFF5E35B1)),
  ThemeColorPreset(name: 'Blue Grey', color: Color(0xFF546E7A)),
  ThemeColorPreset(name: 'Brown', color: Color(0xFF6D4C41)),
];

class ThemeSettings {
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final Color seedColor;
  final DynamicSchemeVariant schemeVariant;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.seedColor = const Color(0xFF6750A4),
    this.schemeVariant = DynamicSchemeVariant.tonalSpot,
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    Color? seedColor,
    DynamicSchemeVariant? schemeVariant,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColor: seedColor ?? this.seedColor,
      schemeVariant: schemeVariant ?? this.schemeVariant,
    );
  }

  ThemeData buildLightTheme({Color? dynamicSeedColor}) {
    final effectiveSeed = (useDynamicColor && dynamicSeedColor != null)
        ? dynamicSeedColor
        : seedColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: effectiveSeed,
      brightness: Brightness.light,
      dynamicSchemeVariant: schemeVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
    );
  }

  ThemeData buildDarkTheme({Color? dynamicSeedColor}) {
    final effectiveSeed = (useDynamicColor && dynamicSeedColor != null)
        ? dynamicSeedColor
        : seedColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: effectiveSeed,
      brightness: Brightness.dark,
      dynamicSchemeVariant: schemeVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      canvasColor: colorScheme.surface,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    );
  }
}
