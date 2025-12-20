import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/serenity_theme.dart';

/// iOS-style list tile
/// 
/// Matches Apple's HIG list rows with proper spacing,
/// optional chevron, and subtle separator.
class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showSeparator;
  final EdgeInsetsGeometry? contentPadding;

  const CupertinoListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.showSeparator = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Leading widget
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: SerenityTheme.body,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: SerenityTheme.subheadline,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Trailing widget or chevron
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: SerenityTheme.tertiaryText,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
        
        // Separator
        if (showSeparator)
          Container(
            margin: EdgeInsets.only(left: leading != null ? 56 : 16),
            height: 0.5,
            color: SerenityTheme.separator,
          ),
      ],
    );
  }
}

/// Destructive action list tile (red text)
class CupertinoDestructiveListTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showSeparator;

  const CupertinoDestructiveListTile({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.showSeparator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: SerenityTheme.systemRed, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: SerenityTheme.body.copyWith(
                    color: SerenityTheme.systemRed,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showSeparator)
          Container(
            margin: const EdgeInsets.only(left: 16),
            height: 0.5,
            color: SerenityTheme.separator,
          ),
      ],
    );
  }
}
