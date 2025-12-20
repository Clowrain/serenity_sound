import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Serenity Sound Cupertino Theme
/// 
/// SwiftUI-inspired design system with SF Pro typography,
/// glassmorphism effects, and iOS-native aesthetics.

class SerenityTheme {
  SerenityTheme._();

  // ─────────────────────────────────────────────────────────────────
  // Colors
  // ─────────────────────────────────────────────────────────────────
  
  /// Background colors
  static const Color background = Color(0xFF0D0D0D);
  static const Color secondaryBackground = Color(0xFF1C1C1E);
  static const Color tertiaryBackground = Color(0xFF2C2C2E);
  
  /// Text colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0x99EBEBF5); // 60% white
  static const Color tertiaryText = Color(0x4DEBEBF5);  // 30% white
  
  /// Accent colors
  static const Color accent = Color(0xFF38F9D7);       // Serenity teal
  static const Color accentSecondary = Color(0xFF43E97B);
  
  /// System colors (iOS-style)
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  
  /// Separator colors
  static const Color separator = Color(0xFF38383A);
  static const Color separatorOpaque = Color(0x29787880);

  // ─────────────────────────────────────────────────────────────────
  // Typography (SF Pro equivalents)
  // ─────────────────────────────────────────────────────────────────
  
  static const String fontFamily = '.SF Pro Text';
  static const String fontFamilyDisplay = '.SF Pro Display';
  
  /// Large Title (34pt, Bold)
  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    color: primaryText,
  );
  
  /// Title 1 (28pt, Bold)
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    color: primaryText,
  );
  
  /// Title 2 (22pt, Bold)
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
    color: primaryText,
  );
  
  /// Title 3 (20pt, Semibold)
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    color: primaryText,
  );
  
  /// Headline (17pt, Semibold)
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: primaryText,
  );
  
  /// Body (17pt, Regular)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    color: primaryText,
  );
  
  /// Callout (16pt, Regular)
  static const TextStyle callout = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    color: primaryText,
  );
  
  /// Subheadline (15pt, Regular)
  static const TextStyle subheadline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    color: secondaryText,
  );
  
  /// Footnote (13pt, Regular)
  static const TextStyle footnote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    color: secondaryText,
  );
  
  /// Caption 1 (12pt, Regular)
  static const TextStyle caption1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: tertiaryText,
  );
  
  /// Caption 2 (11pt, Regular)
  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    color: tertiaryText,
  );

  // ─────────────────────────────────────────────────────────────────
  // Spacing (iOS standard spacing)
  // ─────────────────────────────────────────────────────────────────
  
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  
  /// Standard iOS content padding
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16);
  
  /// Standard iOS list insets
  static const EdgeInsets listInsets = EdgeInsets.symmetric(horizontal: 16);

  // ─────────────────────────────────────────────────────────────────
  // Corner Radius
  // ─────────────────────────────────────────────────────────────────
  
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;

  // ─────────────────────────────────────────────────────────────────
  // Glassmorphism / Blur Effects
  // ─────────────────────────────────────────────────────────────────
  
  /// Standard blur for sheets and overlays
  static const double blurSigma = 25.0;
  
  /// Thin material blur
  static const double blurSigmaThin = 10.0;
  
  /// Ultra-thin material
  static const double blurSigmaUltraThin = 5.0;
  
  /// Creates a frosted glass decoration
  static BoxDecoration frostedGlass({
    Color? color,
    double borderRadius = radiusMedium,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 0.5,
      ),
    );
  }
  
  /// Creates a grouped list section decoration (like iOS Settings)
  static BoxDecoration groupedSection({
    double borderRadius = radiusMedium,
  }) {
    return BoxDecoration(
      color: secondaryBackground,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Animation Curves (iOS-style springs)
  // ─────────────────────────────────────────────────────────────────
  
  /// Standard iOS spring animation
  static const Curve springCurve = Curves.easeOutCubic;
  
  /// iOS interactive spring (for gestures)
  static const Curve interactiveSpring = Curves.easeOutExpo;
  
  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 350);
  
  /// Fast animation duration
  static const Duration animationDurationFast = Duration(milliseconds: 200);

  // ─────────────────────────────────────────────────────────────────
  // Shadows
  // ─────────────────────────────────────────────────────────────────
  
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}

/// Blur backdrop widget for iOS-style materials
class BlurBackdrop extends StatelessWidget {
  final Widget child;
  final double sigma;
  final Color? color;
  final BorderRadius? borderRadius;

  const BlurBackdrop({
    super.key,
    required this.child,
    this.sigma = SerenityTheme.blurSigma,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(SerenityTheme.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.black.withOpacity(0.5),
            borderRadius: borderRadius ?? BorderRadius.circular(SerenityTheme.radiusMedium),
          ),
          child: child,
        ),
      ),
    );
  }
}
