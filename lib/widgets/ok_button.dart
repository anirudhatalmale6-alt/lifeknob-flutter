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
  static const double _totalSize = 260.0;
  static const double _rimSize = 220.0;
  static const double _faceSize = 192.0;
  static const double _triggerAngle = 3 * pi / 2; // 270 degrees

  double _rotation = 0.0;
  double _prevAngle = 0.0;
  bool _isDragging = false;
  bool _showSuccess = false;
  int _lastHapticTick = 0;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _springCtrl;
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
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _springCtrl.dispose();
    super.dispose();
  }

  double _getAngle(Offset localPos) {
    final center = Offset(_totalSize / 2, _totalSize / 2);
    return atan2(localPos.dy - center.dy, localPos.dx - center.dx);
  }

  void _onPanStart(DragStartDetails d) {
    if (widget.isLoading || _showSuccess) return;
    _springCtrl.stop();
    _lastHapticTick = 0;
    setState(() {
      _isDragging = true;
      _prevAngle = _getAngle(d.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isDragging || widget.isLoading || _showSuccess) return;

    final newAngle = _getAngle(d.localPosition);
    var delta = newAngle - _prevAngle;
    while (delta > pi) delta -= 2 * pi;
    while (delta < -pi) delta += 2 * pi;

    final newRotation = (_rotation + delta).clamp(0.0, _triggerAngle + 0.15);

    // Haptic ticks at quarter marks
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            return GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: SizedBox(
                width: _totalSize,
                height: _totalSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress track + arc
                    CustomPaint(
                      size: const Size(_totalSize, _totalSize),
                      painter: _TrackPainter(
                        progress: progress,
                        glowAlpha: _glowAnim.value,
                        isSuccess: _showSuccess,
                      ),
                    ),
                    // Silver rim
                    Container(
                      width: _rimSize,
                      height: _rimSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD0D0D0), Color(0xFF8A8A8A), Color(0xFFB0B0B0), Color(0xFF707070)],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                    ),
                    // Gold face (rotates with user)
                    Transform.rotate(
                      angle: _rotation,
                      child: _buildFace(),
                    ),
                    // Shine highlight (stays still)
                    Positioned(
                      top: 36,
                      left: 60,
                      child: Container(
                        width: 64,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.0)],
                          ),
                        ),
                      ),
                    ),
                    // Center text (stays upright)
                    _buildCenterContent(),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        AnimatedOpacity(
          opacity: _isDragging || _showSuccess ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rotate_right_rounded, size: 16, color: LKTheme.textMuted.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                'Turn the knob',
                style: TextStyle(fontSize: 13, color: LKTheme.textMuted.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFace() {
    return Container(
      width: _faceSize,
      height: _faceSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDD87C), Color(0xFFD4A843), Color(0xFFB08930), Color(0xFFD4A843)],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB08930).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
          const BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Stack(
        children: [
          // Grip notches around edge
          ...List.generate(16, (i) {
            final a = i * (2 * pi / 16) - pi / 2;
            final r = _faceSize / 2 - 12;
            return Positioned(
              left: _faceSize / 2 + r * cos(a) - 2.5,
              top: _faceSize / 2 + r * sin(a) - 2.5,
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B6914).withValues(alpha: 0.35),
                ),
              ),
            );
          }),
          // Indicator dot at top
          Positioned(
            left: _faceSize / 2 - 9,
            top: 3,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _showSuccess ? LKTheme.teal : const Color(0xFF5A3D10),
                border: Border.all(color: const Color(0xFFEDD87C).withValues(alpha: 0.7), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 3, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 50, height: 50,
        child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 4),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showSuccess
          ? Column(
              key: const ValueKey('success'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('SENT!', style: TextStyle(color: Color(0xFF6B4D1E), fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2,
                    shadows: [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
                Icon(Icons.check_rounded, color: Color(0xFF5A3D10), size: 40),
              ],
            )
          : Column(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('I AM', style: TextStyle(color: Color(0xFF6B4D1E), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2,
                    shadows: [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
                Text('OKAY!', style: TextStyle(color: Color(0xFF5A3D10), fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 3, height: 1.0,
                    shadows: [Shadow(color: Color(0x40FFFFFF), offset: Offset(0, 1), blurRadius: 1)])),
              ],
            ),
    );
  }
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

    // Background track ring
    canvas.drawCircle(
      center, trackR,
      Paint()
        ..color = const Color(0xFF1C2237)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Tick marks on track
    final tickPaint = Paint()
      ..color = const Color(0xFF2A3040)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 24; i++) {
      final a = i * (2 * pi / 24) - pi / 2;
      final inner = trackR - 5;
      final outer = trackR + 5;
      canvas.drawLine(
        Offset(center.dx + inner * cos(a), center.dy + inner * sin(a)),
        Offset(center.dx + outer * cos(a), center.dy + outer * sin(a)),
        tickPaint,
      );
    }

    // Progress arc
    if (progress > 0.005) {
      final arcColor = isSuccess
          ? const Color(0xFF4ECDC4)
          : Color.lerp(const Color(0xFFD4A843), const Color(0xFF4ECDC4), progress)!;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackR),
        -pi / 2,
        progress * (3 * pi / 2), // 270 degrees at full
        false,
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );

      // Glow dot at arc end
      final endAngle = -pi / 2 + progress * (3 * pi / 2);
      final dotX = center.dx + trackR * cos(endAngle);
      final dotY = center.dy + trackR * sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY), 6,
        Paint()..color = arcColor,
      );
      canvas.drawCircle(
        Offset(dotX, dotY), 10,
        Paint()
          ..color = arcColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Ambient glow
    if (progress > 0.5 || isSuccess) {
      canvas.drawCircle(
        center, trackR,
        Paint()
          ..color = (isSuccess ? const Color(0xFF4ECDC4) : const Color(0xFFD4A843))
              .withValues(alpha: isSuccess ? 0.2 : glowAlpha * progress * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    } else if (progress < 0.01) {
      // Subtle idle glow
      canvas.drawCircle(
        center, trackR - 12,
        Paint()
          ..color = const Color(0xFFD4A843).withValues(alpha: glowAlpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) =>
      old.progress != progress || old.glowAlpha != glowAlpha || old.isSuccess != isSuccess;
}
