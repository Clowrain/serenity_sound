import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BreathingLogo extends StatefulWidget {
  final String svgPath;
  final Color glowColor;
  final bool isBreathing;
  final bool isActive;

  const BreathingLogo({
    super.key,
    required this.svgPath,
    required this.glowColor,
    required this.isBreathing,
    required this.isActive,
  });

  @override
  State<BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<BreathingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isBreathing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBreathing != oldWidget.isBreathing) {
      if (widget.isBreathing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double glowIntensity = _animation.value;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. 底层：物理凹陷感
            Container(
              width: 64, // 缩小尺寸
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
            ),
            
            // 2. 中层：呼吸背光
            if (widget.isBreathing)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.7 * glowIntensity),
                      blurRadius: 30 * glowIntensity,
                      spreadRadius: 10 * glowIntensity,
                    ),
                  ],
                ),
              ),
            
            // 3. 顶层：按钮主体
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60, // 缩小尺寸
              height: 60,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isActive 
                    ? Colors.white.withOpacity(0.15) 
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.isActive 
                      ? widget.glowColor.withOpacity(0.5 + (0.5 * glowIntensity)) 
                      : Colors.white.withOpacity(0.15),
                  width: widget.isActive ? 1.5 : 0.8,
                ),
              ),
              child: SvgPicture.asset(
                widget.svgPath,
                colorFilter: ColorFilter.mode(
                  widget.isActive 
                      ? Colors.white.withOpacity(0.95) 
                      : Colors.white.withOpacity(0.4),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
