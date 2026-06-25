import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OkButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? lastCheckInTime;

  const OkButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.lastCheckInTime,
  });

  @override
  State<OkButton> createState() => _OkButtonState();
}

class _OkButtonState extends State<OkButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pressAnimation;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    // Gentle pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.isLoading) return;

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Press animation
    await _pressController.forward();
    await _pressController.reverse();

    // Show success briefly
    setState(() => _showSuccess = true);
    widget.onPressed();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _pressAnimation]),
      builder: (context, child) {
        final scale = _pulseAnimation.value * _pressAnimation.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _showSuccess ? const Color(0xFF2ECC71) : const Color(0xFF27AE60),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF27AE60).withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showSuccess ? Icons.check : Icons.favorite,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showSuccess ? 'Sent!' : "I'm OK",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
