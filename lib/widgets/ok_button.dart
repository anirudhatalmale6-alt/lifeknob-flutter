import 'dart:math';
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
  static const double _triggerAngle = 3 * pi / 2;

  double _rotation = 0.0;
  double _prevAngle = 0.0;
  bool _isDragging = false;
  bool _showSuccess = false;
  int _lastHapticTick = 0;
  bool _hintPlayed = false;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _springCtrl;
  late AnimationController _hintCtrl;
  double _springStart = 0;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _springCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _springCtrl.addListener(() {
      if (!_isDragging && !_showSuccess) {
        setState(() {
          _rotation = _springStart * (1.0 - Curves.easeOut.transform(_springCtrl.value));
        });
      }
    });

    _hintCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _hintCtrl.addListener(() {
      if (!_isDragging && !_showSuccess && !_hintPlayed) {
        final t = _hintCtrl.value;
        final angle = sin(t * pi) * (pi / 3);
        setState(() => _rotation = angle);
      }
    });
    _hintCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hintPlayed = true;
        setState(() => _rotation = 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_isDragging && !_showSuccess) {
        _hintCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _springCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  double _getAngle(Offset localPos, double totalSize) {
    final center = Offset(totalSize / 2, totalSize / 2);
    return atan2(localPos.dy - center.dy, localPos.dx - center.dx);
  }

  void _onPanStart(DragStartDetails d, double totalSize) {
    if (widget.isLoading || _showSuccess) return;
    _springCtrl.stop();
    _hintCtrl.stop();
    _hintPlayed = true;
    _lastHapticTick = 0;
    setState(() {
      _isDragging = true;
      _prevAngle = _getAngle(d.localPosition, totalSize);
    });
  }

  void _onPanUpdate(DragUpdateDetails d, double totalSize) {
    if (!_isDragging || widget.isLoading || _showSuccess) return;

    final newAngle = _getAngle(d.localPosition, totalSize);
    var delta = newAngle - _prevAngle;
    while (delta > pi) delta -= 2 * pi;
    while (delta < -pi) delta += 2 * pi;

    final newRotation = (_rotation + delta).clamp(0.0, _triggerAngle + 0.15);

    final tick = (newRotation / _triggerAngle * 4).floor();
    if (tick > _lastHapticTick && tick <= 3) {
      HapticFeedback.selectionClick();
      _lastHapticTick = tick;
    }

    setState(() {
      _rotation = newRotation;
      _prevAngle = newAngle;
    });

    if (_rotation >= _triggerAngle) {
      _trigger();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_isDragging) return;
    _isDragging = false;
    if (!_showSuccess) {
      _springStart = _rotation;
      _springCtrl.forward(from: 0);
    }
  }

  void _trigger() {
    if (_showSuccess) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isDragging = false;
      _showSuccess = true;
      _rotation = _triggerAngle;
    });
    widget.onPressed();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
          _rotation = 0;
          _lastHapticTick = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_rotation / _triggerAngle).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.of(context).size.width;
    final totalSize = (screenWidth * 0.88).clamp(280.0, 380.0);
    final rimSize = totalSize * 0.85;
    final faceSize = totalSize * 0.74;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return GestureDetector(
              onPanStart: (d) => _onPanStart(d, totalSize),
              onPanUpdate: (d) => _onPanUpdate(d, totalSize),
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: totalSize,
                height: totalSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: _TrackPainter(
                        progress: progress,
                        glowAlpha: _glowAnim.value,
                        isSuccess: _showSuccess,
                      ),
                    ),
                    // Silver/platinum rim
                    Container(
                      width: rimSize,
                      height: rimSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFFC8C8C8), Color(0xFF808080), Color(0xFFB0B0B0)],
                          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 8)),
                          BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(-2, -2)),
                        ],
                      ),
                    ),
                    // Gold face (rotates)
                    Transform.rotate(
                      angle: _rotation,
                      child: _buildFace(faceSize),
                    ),
                    // Shine highlight
                    Positioned(
                      top: totalSize * 0.12,
                      left: totalSize * 0.18,
                      child: Container(
                        width: totalSize * 0.22,
                        height: totalSize * 0.07,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.0)],
                          ),
                        ),
                      ),
                    ),
                    // Center text (stays upright)
                    _buildCenterContent(faceSize),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Hint arrow animation
        AnimatedOpacity(
          opacity: _isDragging || _showSuccess ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: sin(value * 2 * pi) * 0.3,
                    child: child,
                  );
                },
                child: Icon(Icons.rotate_right_rounded, size: 20, color: LKTheme.gold.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 6),
              Text(
                'Turn the knob',
                style: TextStyle(fontSize: 14, color: LKTheme.gold.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFace(double faceSize) {
    return SizedBox(
      width: faceSize,
      height: faceSize,
      child: Stack(
        children: [
          // Gold face with beveled rim
          Container(
            width: faceSize,
            height: faceSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [Color(0xFFE8C96A), Color(0xFFB08930), Color(0xFFD4A843), Color(0xFFEDD87C), Color(0xFFB08930), Color(0xFFD4A843), Color(0xFFE8C96A)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFB08930).withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
                const BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(3, 3)),
              ],
            ),
          ),
          // Inner face with brushed metal
          Center(
            child: Container(
              width: faceSize - 16,
              height: faceSize - 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.2),
                  radius: 0.85,
                  colors: [Color(0xFFF0E080), Color(0xFFDDB94E), Color(0xFFBE9530), Color(0xFFD4A843), Color(0xFFE8C96A)],
                  stops: [0.0, 0.3, 0.55, 0.8, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _BrushedMetalPainter(),
              ),
            ),
          ),
          // Grip notches
          ...List.generate(20, (i) {
            final a = i * (2 * pi / 20) - pi / 2;
            final r = faceSize / 2 - 12;
            return Positioned(
              left: faceSize / 2 + r * cos(a) - 3,
              top: faceSize / 2 + r * sin(a) - 3,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF8B6914).withValues(alpha: 0.5), const Color(0xFF8B6914).withValues(alpha: 0.15)],
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 1, offset: const Offset(0.5, 0.5))],
                ),
              ),
            );
          }),
          // Indicator arrow at top
          Positioned(
            left: faceSize / 2 - 10,
            top: 2,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _ArrowPainter(color: _showSuccess ? LKTheme.teal : const Color(0xFF5A3D10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(double faceSize) {
    if (widget.isLoading) {
      return SizedBox(
        width: faceSize * 0.3, height: faceSize * 0.3,
        child: const CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 4),
      );
    }

    final fontSize1 = faceSize * 0.14;
    final fontSize2 = faceSize * 0.24;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showSuccess
          ? Column(
              key: const ValueKey('success'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SENT!', style: TextStyle(color: const Color(0xFF6B4D1E), fontSize: fontSize1 * 1.1, fontWeight: FontWeight.w800, letterSpacing: 2,
                    shadows: const [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
                Icon(Icons.check_rounded, color: const Color(0xFF5A3D10), size: faceSize * 0.22),
              ],
            )
          : Column(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('I AM', style: TextStyle(color: const Color(0xFF6B4D1E), fontSize: fontSize1, fontWeight: FontWeight.w800, letterSpacing: 3,
                    shadows: const [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
                Text('OKAY!', style: TextStyle(color: const Color(0xFF5A3D10), fontSize: fontSize2, fontWeight: FontWeight.w900, letterSpacing: 4, height: 1.0,
                    shadows: const [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
              ],
            ),
    );
  }
}

class _BrushedMetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 72; i++) {
      final angle = i * (2 * pi / 72);
      final alpha = (i % 2 == 0) ? 0.08 : 0.04;
      paint.color = const Color(0xFF8B6914).withValues(alpha: alpha);
      canvas.drawLine(
        Offset(center.dx + 20 * cos(angle), center.dy + 20 * sin(angle)),
        Offset(center.dx + (r - 8) * cos(angle), center.dy + (r - 8) * sin(angle)),
        paint,
      );
    }

    // Center star/cross
    final starPaint = Paint()
      ..color = const Color(0xFF8B6914).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 4) + pi / 8;
      canvas.drawLine(
        Offset(center.dx + 8 * cos(angle), center.dy + 8 * sin(angle)),
        Offset(center.dx + 25 * cos(angle), center.dy + 25 * sin(angle)),
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.8, size.height * 0.7)
      ..lineTo(size.width / 2, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawCircle(Offset(size.width / 2, size.height * 0.6), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}

class _TrackPainter extends CustomPainter {
  final double progress;
  final double glowAlpha;
  final bool isSuccess;

  _TrackPainter({required this.progress, required this.glowAlpha, required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final trackR = size.width / 2 - 6;

    canvas.drawCircle(
      center, trackR,
      Paint()
        ..color = const Color(0xFF1A2235)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    final tickPaint = Paint()
      ..color = const Color(0xFF2A3548)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 36; i++) {
      final a = i * (2 * pi / 36) - pi / 2;
      final inner = trackR - 6;
      final outer = trackR + 6;
      canvas.drawLine(
        Offset(center.dx + inner * cos(a), center.dy + inner * sin(a)),
        Offset(center.dx + outer * cos(a), center.dy + outer * sin(a)),
        tickPaint,
      );
    }

    if (progress > 0.005) {
      final arcColor = isSuccess
          ? const Color(0xFF4ECDC4)
          : Color.lerp(const Color(0xFFD4A843), const Color(0xFF4ECDC4), progress)!;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackR),
        -pi / 2,
        progress * (3 * pi / 2),
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );

      final endAngle = -pi / 2 + progress * (3 * pi / 2);
      final dotX = center.dx + trackR * cos(endAngle);
      final dotY = center.dy + trackR * sin(endAngle);
      canvas.drawCircle(Offset(dotX, dotY), 7, Paint()..color = arcColor);
      canvas.drawCircle(
        Offset(dotX, dotY), 14,
        Paint()
          ..color = arcColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    if (progress > 0.5 || isSuccess) {
      canvas.drawCircle(
        center, trackR,
        Paint()
          ..color = (isSuccess ? const Color(0xFF4ECDC4) : const Color(0xFFD4A843))
              .withValues(alpha: isSuccess ? 0.25 : glowAlpha * progress * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
      );
    } else if (progress < 0.01) {
      canvas.drawCircle(
        center, trackR - 15,
        Paint()
          ..color = const Color(0xFFD4A843).withValues(alpha: glowAlpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) =>
      old.progress != progress || old.glowAlpha != glowAlpha || old.isSuccess != isSuccess;
}
