                  timerState.formattedTime,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: 2),
                ),
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
                Text(
                  '${_currentValue.toInt()} MINUTES',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white),
                ),
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
                const SizedBox(height: 40),
                _MasterButton(
                  isPlaying: false, // 借用此按钮样式作为开始按钮
                  onPressed: () {
                    ref.read(timerProvider.notifier).setTimer(_currentValue.toInt());
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EndingFlicker extends StatefulWidget {
  final Widget child;
  final bool isEnding;

  const _EndingFlicker({required this.child, required this.isEnding});

  @override
  State<_EndingFlicker> createState() => _EndingFlickerState();
}

class _EndingFlickerState extends State<_EndingFlicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isEnding) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_EndingFlicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnding) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnding) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: widget.child,
    );
  }
}
