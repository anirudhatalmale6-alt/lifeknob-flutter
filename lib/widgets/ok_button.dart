import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
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
                  // Outer gold glow
                  Container(
                    width: 236,
                    height: 236,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LKTheme.gold.withValues(alpha: _glowAnimation.value * 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: LKTheme.gold.withValues(alpha: _glowAnimation.value * 0.15),
                          blurRadius: 80,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  // Silver rim
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD0D0D0), Color(0xFF8A8A8A), Color(0xFFB0B0B0), Color(0xFF707070)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  // Gold coin face
                  Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEDD87C),
                          Color(0xFFD4A843),
                          Color(0xFFB08930),
                          Color(0xFFD4A843),
                        ],
                        stops: [0.0, 0.35, 0.65, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB08930).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        const BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Color(0xFF5A3D10),
                                strokeWidth: 4,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showSuccess ? 'SENT!' : 'I AM',
                                  style: TextStyle(
                                    color: const Color(0xFF6B4D1E),
                                    fontSize: _showSuccess ? 28 : 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    shadows: const [
                                      Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1),
                                    ],
                                  ),
                                ),
                                if (!_showSuccess)
                                  const Text(
                                    'OKAY!',
                                    style: TextStyle(
                                      color: Color(0xFF5A3D10),
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1),
                                      ],
                                    ),
                                  ),
                                if (_showSuccess)
                                  const Icon(Icons.check_rounded, color: Color(0xFF5A3D10), size: 40),
                              ],
                            ),
                    ),
                  ),
                  // Highlight shine
                  Positioned(
                    top: 28,
                    left: 50,
                    child: Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
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
