import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AdBannerPair extends StatelessWidget {
  final VoidCallback? onRemoveAds;
  final String? bannerImageUrl;
  final String? bannerClickUrl;

  static const Color navy = Color(0xFF003049);
  static const Color gold = Color(0xFFDDA15E);
  static const Color red = Color(0xFFC1121F);

  const AdBannerPair({super.key, this.onRemoveAds, this.bannerImageUrl, this.bannerClickUrl});

  void _onAdTap() async {
    if (bannerClickUrl != null && bannerClickUrl!.isNotEmpty) {
      final uri = Uri.tryParse(bannerClickUrl!);
      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBanner({bool hasImage = false}) {
    return AspectRatio(
      aspectRatio: 3.2,
      child: GestureDetector(
        onTap: hasImage ? _onAdTap : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: red.withValues(alpha: 0.5), width: 1),
            color: navy.withValues(alpha: 0.3),
          ),
          child: hasImage && bannerImageUrl != null
            ? Image.network(bannerImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return CustomPaint(
      painter: _AdPlaceholderPainter(lineColor: red.withValues(alpha: 0.25)),
      child: Center(child: Text('AD', style: GoogleFonts.barlowCondensed(fontSize: 16, color: red.withValues(alpha: 0.35)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = bannerImageUrl != null && bannerImageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (onRemoveAds != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3, right: 2),
            child: GestureDetector(
              onTap: onRemoveAds,
              child: Text('Remove ads', style: GoogleFonts.robotoSlab(fontSize: 11, color: gold, fontStyle: FontStyle.italic)),
            ),
          ),
        _buildBanner(hasImage: hasImage),
      ]),
    );
  }
}

class _AdPlaceholderPainter extends CustomPainter {
  final Color lineColor;
  _AdPlaceholderPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 1.0;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class BumperAdOverlay extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onDismiss;
  final String? imageUrl;
  final String? clickUrl;

  const BumperAdOverlay({super.key, this.durationSeconds = 6, required this.onDismiss, this.imageUrl, this.clickUrl});

  @override
  State<BumperAdOverlay> createState() => _BumperAdOverlayState();
}

class _BumperAdOverlayState extends State<BumperAdOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _countdownCtrl;
  int _remaining = 0;

  static const Color navy = Color(0xFF003049);
  static const Color gold = Color(0xFFDDA15E);
  static const Color red = Color(0xFFC1121F);

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

  void _onAdTap() async {
    if (widget.clickUrl != null && widget.clickUrl!.isNotEmpty) {
      final uri = Uri.tryParse(widget.clickUrl!);
      if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
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
                GestureDetector(
                  onTap: hasImage ? _onAdTap : null,
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: red.withValues(alpha: 0.4), width: 1),
                      borderRadius: BorderRadius.circular(16),
                      color: navy.withValues(alpha: 0.8),
                    ),
                    child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(widget.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bumperPlaceholder()),
                        )
                      : _bumperPlaceholder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (_remaining > 0)
                  Text('$_remaining', style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w600, color: gold))
                else
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(12)),
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

  Widget _bumperPlaceholder() {
    return CustomPaint(
      painter: _AdPlaceholderPainter(lineColor: red.withValues(alpha: 0.2)),
      child: Center(child: Text('AD', style: GoogleFonts.barlowCondensed(fontSize: 32, color: red.withValues(alpha: 0.3)))),
    );
  }
}
