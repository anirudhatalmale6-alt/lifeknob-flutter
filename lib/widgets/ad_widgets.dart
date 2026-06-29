import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdBannerWidget extends StatelessWidget {
  final double height;
  final VoidCallback? onRemoveAds;

  static const Color navy = Color(0xFF003049);
  static const Color gold = Color(0xFFDDA15E);

  const AdBannerWidget({super.key, this.height = 50, this.onRemoveAds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: gold.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(8),
            color: navy.withValues(alpha: 0.5),
          ),
          child: Center(child: Text('AD', style: GoogleFonts.barlowCondensed(fontSize: 14, color: gold.withValues(alpha: 0.3)))),
        ),
        if (onRemoveAds != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: GestureDetector(
                onTap: onRemoveAds,
                child: Text('Remove ads', style: GoogleFonts.robotoSlab(fontSize: 11, color: gold, fontStyle: FontStyle.italic)),
              ),
            ),
          ),
      ]),
    );
  }
}

class AdBannerPair extends StatelessWidget {
  final double singleHeight;
  final VoidCallback? onRemoveAds;

  const AdBannerPair({super.key, this.singleHeight = 50, this.onRemoveAds});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AdBannerWidget(height: singleHeight),
      const SizedBox(height: 6),
      AdBannerWidget(height: singleHeight, onRemoveAds: onRemoveAds),
    ]);
  }
}

class BumperAdOverlay extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onDismiss;

  const BumperAdOverlay({super.key, this.durationSeconds = 6, required this.onDismiss});

  @override
  State<BumperAdOverlay> createState() => _BumperAdOverlayState();
}

class _BumperAdOverlayState extends State<BumperAdOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _countdownCtrl;
  int _remaining = 0;

  static const Color navy = Color(0xFF003049);
  static const Color gold = Color(0xFFDDA15E);

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _countdownCtrl = AnimationController(duration: Duration(seconds: widget.durationSeconds), vsync: this);
    _countdownCtrl.addListener(() {
      final newRemaining = (widget.durationSeconds * (1.0 - _countdownCtrl.value)).ceil();
      if (newRemaining != _remaining && mounted) {
        setState(() => _remaining = newRemaining);
      }
    });
    _countdownCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDismiss();
    });
    _countdownCtrl.forward();
  }

  @override
  void dispose() {
    _countdownCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: gold.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(16),
                    color: navy.withValues(alpha: 0.8),
                  ),
                  child: Center(child: Text('AD', style: GoogleFonts.barlowCondensed(fontSize: 32, color: gold.withValues(alpha: 0.4)))),
                ),
                const SizedBox(height: 24),
                if (_remaining > 0)
                  Text('$_remaining', style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w600, color: gold))
                else
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('CONTINUE', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w700, color: navy)),
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
