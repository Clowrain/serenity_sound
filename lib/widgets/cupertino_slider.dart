import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/serenity_theme.dart';

/// iOS-style slider with custom theming
/// 
/// Thin track, round thumb, and optional label display.
class CupertinoVolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final Color? activeColor;
  final bool showValue;

  const CupertinoVolumeSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.activeColor,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: activeColor ?? SerenityTheme.accent.withOpacity(0.6),
              inactiveTrackColor: SerenityTheme.separator,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              overlayColor: (activeColor ?? SerenityTheme.accent).withOpacity(0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        if (showValue) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(value * 100).round()}%',
              style: SerenityTheme.caption1.copyWith(
                color: SerenityTheme.secondaryText,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }
}

/// iOS-style toggle with label
class CupertinoLabeledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;

  const CupertinoLabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: SerenityTheme.body),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: SerenityTheme.subheadline),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: SerenityTheme.accent,
          ),
        ],
      ),
    );
  }
}
