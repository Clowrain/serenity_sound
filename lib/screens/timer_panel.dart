import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sound_provider.dart';
import '../widgets/control_buttons.dart';

class TimerPanel extends ConsumerStatefulWidget {
  const TimerPanel({super.key});

  @override
  ConsumerState<TimerPanel> createState() => _TimerPanelState();
}

class _TimerPanelState extends ConsumerState<TimerPanel> {
  double _currentValue = 30;

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),
              const Text('SLEEP TIMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 6, color: Colors.white30)),
              const SizedBox(height: 30),
              if (timerState.isRunning)
                Column(
                  children: [
                    Text(timerState.formattedTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: 2)),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => ref.read(timerProvider.notifier).cancel(),
                      child: const Text('CANCEL TIMER', style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text('${_currentValue.toInt()} MINUTES', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white)),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        activeTrackColor: Colors.white24,
                        inactiveTrackColor: Colors.white10,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _currentValue,
                        min: 1,
                        max: 240,
                        onChanged: (val) => setState(() => _currentValue = val),
                      ),
                    ),
                    const SizedBox(height: 30),
                    MasterButton(
                      isPlaying: false,
                      onPressed: () {
                        ref.read(timerProvider.notifier).setTimer(_currentValue.toInt());
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
