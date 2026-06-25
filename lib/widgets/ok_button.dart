import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OkButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const OkButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<OkButton> createState() => _OkButtonState();
}

class _OkButtonState extends State<OkButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pressAnimation;
  late Animation<double> _glowAnimation;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.isLoading) return;
    HapticFeedback.heavyImpact();

    await _pressController.forward();
    await _pressController.reverse();

    setState(() => _showSuccess = true);
    widget.onPressed();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _pressAnimation, _glowAnimation]),
      builder: (context, child) {
        final scale = _pulseAnimation.value * _pressAnimation.value;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: _handleTap,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_showSuccess ? const Color(0xFF2ECC71) : const Color(0xFF27AE60))
                              .withValues(alpha: _glowAnimation.value * 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: (_showSuccess ? const Color(0xFF2ECC71) : const Color(0xFF27AE60))
                              .withValues(alpha: _glowAnimation.value * 0.25),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Light outer ring
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF27AE60).withValues(alpha: 0.15),
                          const Color(0xFF27AE60).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.7, 0.85, 1.0],
                      ),
                    ),
                  ),
                  // Main button
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _showSuccess
                            ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                            : [const Color(0xFF2ECC71), const Color(0xFF229954)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF27AE60).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                                  _showSuccess ? Icons.done_all : Icons.check,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 36,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _showSuccess ? 'Sent!' : 'OK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
