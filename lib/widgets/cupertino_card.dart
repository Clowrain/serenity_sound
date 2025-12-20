import 'package:flutter/material.dart';
import '../theme/serenity_theme.dart';

/// iOS-style grouped card (like iOS Settings sections)
/// 
/// Provides a rounded container with subtle background
/// that matches Apple's Human Interface Guidelines.
class CupertinoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool hasShadow;

  const CupertinoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? SerenityTheme.secondaryBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? SerenityTheme.radiusMedium),
        boxShadow: hasShadow ? SerenityTheme.subtleShadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? SerenityTheme.radiusMedium),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// Header for grouped list sections (iOS Settings style)
class CupertinoSectionHeader extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const CupertinoSectionHeader({
    super.key,
    required this.text,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(32, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: SerenityTheme.footnote.copyWith(
          color: SerenityTheme.secondaryText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Footer for grouped list sections
class CupertinoSectionFooter extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const CupertinoSectionFooter({
    super.key,
    required this.text,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(32, 8, 16, 24),
      child: Text(
        text,
        style: SerenityTheme.caption1.copyWith(
          color: SerenityTheme.tertiaryText,
        ),
      ),
    );
  }
}
