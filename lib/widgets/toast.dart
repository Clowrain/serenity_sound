import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/serenity_theme.dart';

/// Shows a Cupertino-style toast notification (iOS snackbar alternative)
void showToast(BuildContext context, String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  
  final entry = OverlayEntry(
    builder: (context) => _ToastOverlay(
      message: message,
      isError: isError,
    ),
  );
  
  overlay.insert(entry);
  
  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final bool isError;

  const _ToastOverlay({
    required this.message,
    this.isError = false,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isError 
                    ? SerenityTheme.systemRed.withOpacity(0.9)
                    : SerenityTheme.secondaryBackground.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.message,
                style: SerenityTheme.callout.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
