import 'package:flutter/material.dart';

/// 控制旋钮按钮
class ControlKnob extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ControlKnob({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 24, color: Colors.white60),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        backgroundColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}

/// 主播放/暂停按钮
class MasterButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const MasterButton({super.key, required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isPlaying ? Colors.white : Colors.white24,
            width: 2,
          ),
          boxShadow: isPlaying ? [
            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
          ] : [],
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 45,
            color: isPlaying ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

/// 定时器结束时的闪烁动画
class EndingFlicker extends StatefulWidget {
  final Widget child;
  final bool isEnding;
  
  const EndingFlicker({super.key, required this.child, required this.isEnding});
  
  @override
  State<EndingFlicker> createState() => _EndingFlickerState();
}

class _EndingFlickerState extends State<EndingFlicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.isEnding) _controller.repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(EndingFlicker oldWidget) {
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
