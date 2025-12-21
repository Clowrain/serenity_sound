import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_provider.dart';
import '../theme/serenity_theme.dart';

class TimerPanel extends ConsumerStatefulWidget {
  const TimerPanel({super.key});

  @override
  ConsumerState<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends ConsumerState<TimerPanel> {
  Duration _selectedDuration = const Duration(minutes: 30);

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    return Container(
      decoration: BoxDecoration(
        color: SerenityTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SerenityTheme.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // iOS-style drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: SerenityTheme.tertiaryText,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('睡眠定时', style: SerenityTheme.title2),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: SerenityTheme.tertiaryBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: SerenityTheme.secondaryText,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            if (timerState.isRunning) ...[
              // Active timer display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Text(
                      timerState.formattedTime,
                      style: SerenityTheme.largeTitle.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '剩余时间',
                      style: SerenityTheme.subheadline,
                    ),
                  ],
                ),
              ),
              
              // Cancel button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: SerenityTheme.systemRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(SerenityTheme.radiusMedium),
                    onPressed: () {
                      ref.read(timerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    child: Text(
                      '取消定时',
                      style: SerenityTheme.headline.copyWith(
                        color: SerenityTheme.systemRed,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Timer picker
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _selectedDuration,
                  onTimerDurationChanged: (duration) {
                    setState(() => _selectedDuration = duration);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Start button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: SerenityTheme.accent,
                    borderRadius: BorderRadius.circular(SerenityTheme.radiusMedium),
                    onPressed: _selectedDuration.inMinutes > 0
                        ? () {
                            ref.read(timerProvider.notifier).setTimer(_selectedDuration.inMinutes);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      '开始',
                      style: SerenityTheme.headline.copyWith(
                        color: SerenityTheme.background,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
