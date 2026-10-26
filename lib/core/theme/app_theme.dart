import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors: crisp cyan with a near-black dark appearance.
  static const primary = Color(0xFF0891B2);
  static const primaryLight = Color(0xFF22D3EE);
  static const primaryDeep = Color(0xFF0E7490);
  static const skyAccent = Color(0xFF06B6D4);
  static const cyanAccent = Color(0xFF06B6D4); // Cyan 500
  static const electricCyan = Color(0xFF67E8F9);

  // Soft Ice & Sky Tints
  static const iceBlue = Color(0xFFCFFAFE); // Cyan 100
  static const iceBlueSoft = Color(0xFFECFEFF); // Cyan 50
  static const iceBlueMedium = Color(0xFFA5F3FC); // Cyan 200

  // High-Tech Modern Accents
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);
  static const coral = Color(0xFFF97316);
  static const coralSoft = Color(0xFFFFEDD5);
  static const rose = Color(0xFFEF4444);
  static const roseSoft = Color(0xFFFEE2E2);
  static const emerald = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFFD1FAE5);
  static const violet = Color(0xFF8B5CF6);
  static const violetSoft = Color(0xFFEDE9FE);
  static const purple = violet;
  static const purpleSoft = violetSoft;

  // Neutrals - Light Theme (Ultra-Clean Crisp Ice)
  static const bgLight = Color(0xFFF5FCFD);
  static const cardLight = Color(0xFFFFFFFF);
  static const inkLight = Color(0xFF09111E); // Deep Titanium
  static const inkMutedLight = Color(0xFF5A6E85);
  static const borderLight = Color(0xFFDCEFF2);
  static const borderGlassLight = Color(0x66A5F3FC);

  // Neutrals - Dark Theme (Deep Midnight Obsidian)
  static const bgDark = Color(0xFF050607);
  static const cardDark = Color(0xFF101315);
  static const cardDarkElevated = Color(0xFF181C1F);
  static const inkDark = Color(0xFFF2FCFD);
  static const inkMutedDark = Color(0xFFA0B3B7);
  static const borderDark = Color(0xFF293538);
  static const borderGlassDark = Color(0x5522D3EE);

  // Ethereal Gradients
  static const skyGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const primaryGradient = skyGradient;

  static const cyanGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF67E8F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const iceGlassGradient = LinearGradient(
    colors: [Color(0xF5FFFFFF), Color(0xE8ECFEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGlassGradient = LinearGradient(
    colors: [Color(0xF015191B), Color(0xED0D1012)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroSkyGradient = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: iceBlue,
          onPrimaryContainer: primaryDeep,
          surface: cardLight,
          onSurface: inkLight,
          outline: borderLight,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: inkLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: borderGlassLight, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: borderGlassLight, width: 1),
        selectedColor: iceBlue,
        secondarySelectedColor: primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryLight,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primaryLight,
          onPrimary: const Color(0xFF031E35),
          primaryContainer: const Color(0xFF12343A),
          onPrimaryContainer: const Color(0xFFA5F3FC),
          surface: cardDark,
          onSurface: inkDark,
          outline: borderDark,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: inkDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: borderGlassDark, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: borderGlassDark, width: 1),
        selectedColor: primaryLight.withValues(alpha: 0.22),
        secondarySelectedColor: primaryLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDarkElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 1.8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: const Color(0xFF031E35),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Modern Glassmorphism & Shadow Decoration
  static BoxDecoration glassDecoration(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    bool elevated = false,
    bool glow = false,
    Color? glowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(22);
    final gColor = glowColor ?? (isDark ? primaryLight : primary);

    return BoxDecoration(
      borderRadius: r,
      gradient: color != null
          ? null
          : (isDark ? darkGlassGradient : iceGlassGradient),
      color: color,
      border: Border.all(
        color: isDark ? borderGlassDark : borderGlassLight,
        width: 1.2,
      ),
      boxShadow: [
        if (glow)
          BoxShadow(
            color: gColor.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: elevated ? 0.34 : 0.22)
              : const Color(
                  0xFF0E7490,
                ).withValues(alpha: elevated ? 0.055 : 0.025),
          blurRadius: elevated ? 16 : 9,
          offset: Offset(0, elevated ? 6 : 3),
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
    bool elevated = false,
  }) {
    return glassDecoration(context, color: color, elevated: elevated);
  }
}

// Reusable Glass Card with Real BackdropFilter Blur & Specular Rim
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.elevated = false,
    this.glow = false,
    this.glowColor,
    this.color,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final bool glow;
  final Color? glowColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(22);
    return Container(
      decoration: AppTheme.glassDecoration(
        context,
        borderRadius: r,
        elevated: elevated,
        glow: glow,
        glowColor: glowColor,
        color: color,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Ambient Background with Ethereal Floating Mesh Gradient Orbs
class AmbientScaffoldBackground extends StatelessWidget {
  const AmbientScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background
        Container(color: isDark ? AppTheme.bgDark : AppTheme.bgLight),

        // Ethereal blurred background orbs (Spatial lighting)
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF0891B2) : const Color(0xFFA5F3FC))
                      .withValues(alpha: isDark ? 0.08 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 320,
          left: -120,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF22D3EE) : const Color(0xFFCFFAFE))
                      .withValues(alpha: isDark ? 0.05 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF22D3EE) : const Color(0xFFA5F3FC))
                      .withValues(alpha: isDark ? 0.04 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}
