import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isCheckingIn = false;
  String? _lastCheckIn;
  String? _userCode;
  String? _userName;
  String? _sosNumber;
  String? _sosName;
  String? _ambulanceNumber;

  // Knob rotation
  static const double _triggerAngle = 3 * pi / 2;
  double _rotation = 0.0;
  double _prevAngle = 0.0;
  bool _isDragging = false;
  bool _showSuccess = false;
  int _lastHapticTick = 0;

  late AnimationController _springCtrl;
  late AnimationController _hintCtrl;
  double _springStart = 0;
  bool _hintPlayed = false;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _springCtrl.addListener(() {
      if (!_isDragging && !_showSuccess) {
        setState(() => _rotation = _springStart * (1.0 - Curves.easeOut.transform(_springCtrl.value)));
      }
    });
    _hintCtrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _hintCtrl.addListener(() {
      if (!_isDragging && !_showSuccess && !_hintPlayed) {
        setState(() => _rotation = sin(_hintCtrl.value * pi) * (pi / 3));
      }
    });
    _hintCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) { _hintPlayed = true; setState(() => _rotation = 0); }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_isDragging) _hintCtrl.forward();
    });
    _loadUserData();
    _loadLastCheckIn();
  }

  @override
  void dispose() { _springCtrl.dispose(); _hintCtrl.dispose(); super.dispose(); }

  void _setUserData(dynamic user) {
    if (user == null || !mounted) return;
    setState(() {
      _userCode = user.userCode; _userName = user.name; _sosNumber = user.sosNumber;
      _sosName = user.sosName; _ambulanceNumber = user.ambulanceNumber;
    });
  }

  Future<void> _loadUserData() async {
    final cached = AuthService().currentUser ?? await AuthService().getSavedUser();
    _setUserData(cached);
    try { _setUserData(await AuthService().refreshProfile()); } catch (_) {}
  }

  Future<void> _loadLastCheckIn() async {
    try {
      final response = await ApiService().getHistory(page: 1);
      final List data = response['data'] ?? [];
      if (data.isNotEmpty && mounted) {
        final dt = DateTime.parse(data.first['created_at']);
        final diff = DateTime.now().difference(dt);
        setState(() {
          if (diff.inMinutes < 1) _lastCheckIn = 'Just now';
          else if (diff.inMinutes < 60) _lastCheckIn = '${diff.inMinutes}m ago';
          else if (diff.inHours < 24) _lastCheckIn = '${diff.inHours}h ago';
          else _lastCheckIn = '${diff.inDays}d ago';
        });
      }
    } catch (_) {}
  }

  // Knob gesture handling
  double _getAngle(Offset pos, Offset center) => atan2(pos.dy - center.dy, pos.dx - center.dx);

  void _onKnobPanStart(DragStartDetails d, Offset center) {
    if (_isCheckingIn || _showSuccess) return;
    _springCtrl.stop(); _hintCtrl.stop(); _hintPlayed = true; _lastHapticTick = 0;
    setState(() { _isDragging = true; _prevAngle = _getAngle(d.localPosition, center); });
  }

  void _onKnobPanUpdate(DragUpdateDetails d, Offset center) {
    if (!_isDragging || _isCheckingIn || _showSuccess) return;
    final newAngle = _getAngle(d.localPosition, center);
    var delta = newAngle - _prevAngle;
    while (delta > pi) delta -= 2 * pi;
    while (delta < -pi) delta += 2 * pi;
    final newRot = (_rotation + delta).clamp(0.0, _triggerAngle + 0.15);
    final tick = (newRot / _triggerAngle * 4).floor();
    if (tick > _lastHapticTick && tick <= 3) { HapticFeedback.selectionClick(); _lastHapticTick = tick; }
    setState(() { _rotation = newRot; _prevAngle = newAngle; });
    if (_rotation >= _triggerAngle) _triggerCheckIn();
  }

  void _onKnobPanEnd(DragEndDetails d) {
    if (!_isDragging) return;
    _isDragging = false;
    if (!_showSuccess) { _springStart = _rotation; _springCtrl.forward(from: 0); }
  }

  void _triggerCheckIn() {
    if (_showSuccess) return;
    HapticFeedback.heavyImpact();
    setState(() { _isDragging = false; _showSuccess = true; _rotation = _triggerAngle; });
    _doCheckIn();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _showSuccess = false; _rotation = 0; _lastHapticTick = 0; });
    });
  }

  Future<void> _doCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      await ApiService().checkIn(type: 'ok');
      if (mounted) setState(() => _lastCheckIn = 'Just now');
    } catch (_) {}
    finally { if (mounted) setState(() => _isCheckingIn = false); }
  }

  void _showCodePopup() {
    if (_userCode == null) return;
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: LKTheme.glassCard(borderColor: LKTheme.gold.withValues(alpha: 0.3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('YOUR CODE', style: GoogleFonts.cinzel(fontSize: 14, color: LKTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 16),
          Text(_userCode!, style: GoogleFonts.cinzel(fontSize: 48, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 6)),
          const SizedBox(height: 16),
          Text('Share this code with your family', style: GoogleFonts.cormorantGaramond(fontSize: 16, color: LKTheme.textSecondary, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.gold, side: BorderSide(color: LKTheme.gold.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('COPY', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text('OK', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF5A3D10)))),
            )),
          ]),
        ]),
      ),
    ));
  }

  Future<void> _callContact() async {
    final number = _sosNumber;
    if (number == null || number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callAmbulance() async {
    final number = _ambulanceNumber;
    if (number == null || number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_rotation / _triggerAngle).clamp(0.0, 1.0);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final contactLabel = (_sosName != null && _sosName!.isNotEmpty) ? _sosName!.toUpperCase() : 'CONTACT';
    final displayName = (_userName != null && _userName!.isNotEmpty) ? _userName!.toUpperCase() : 'USER';

    // Knob center position (relative to screen)
    final knobCenterY = screenH * 0.42;
    final knobSize = screenW * 0.78;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Background image
          Image.asset('assets/images/bg_main.jpg', fit: BoxFit.cover, width: screenW, height: screenH),

          // Layer 2: Interactive overlays
          SafeArea(
            child: Column(
              children: [
                // Zone 1: Header - user info (tappable to setup)
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF6B5530), letterSpacing: 2), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Last verified:', style: GoogleFonts.cormorantGaramond(fontSize: 13, color: const Color(0xFF8A7A60), fontStyle: FontStyle.italic)),
                            Text(_lastCheckIn ?? 'Not yet', style: GoogleFonts.cormorantGaramond(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8A7A60))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Zone 3: "TURN THE KNOB" + QR
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('TURN THE KNOB', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF8A7A50), letterSpacing: 3)),
                      ),
                      GestureDetector(
                        onTap: _showCodePopup,
                        child: const SizedBox(width: 50, height: 50),
                      ),
                    ],
                  ),
                ),

                // Zone 4: Knob area (interactive turn)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.42);
                      return GestureDetector(
                        onPanStart: (d) => _onKnobPanStart(d, center),
                        onPanUpdate: (d) => _onKnobPanUpdate(d, center),
                        onPanEnd: _onKnobPanEnd,
                        child: Stack(
                          children: [
                            // Transparent gesture area
                            Container(color: Colors.transparent),

                            // Knob text overlay (centered on the knob area)
                            Positioned(
                              left: 0, right: 0,
                              top: center.dy - 50,
                              child: _showSuccess
                                ? Column(
                                    children: [
                                      Text('SENT!', style: GoogleFonts.cinzel(fontSize: 36, fontWeight: FontWeight.w800, color: const Color(0xFF27AE60), letterSpacing: 4)),
                                      const Icon(Icons.check_rounded, color: Color(0xFF27AE60), size: 40),
                                    ],
                                  )
                                : ShaderMask(
                                    shaderCallback: (bounds) {
                                      final fillStop = 1.0 - progress;
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: const [Color(0xFF6B5530), Color(0xFF6B5530), Color(0xFF27AE60), Color(0xFF27AE60)],
                                        stops: [0.0, fillStop, fillStop, 1.0],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcIn,
                                    child: Column(
                                      children: [
                                        Text('I AM', style: GoogleFonts.cinzel(fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 6)),
                                        Text('OKAY!', style: GoogleFonts.cinzel(fontSize: 62, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5, height: 0.9)),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // "OR CALL FOR HELP" text overlay
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('OR CALL FOR HELP', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF8A7A50), letterSpacing: 2)),
                    ],
                  ),
                ),

                // Zone 5 & 6: Call buttons (tap zones with text)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: SizedBox(
                    height: screenH * 0.1,
                    child: Row(
                      children: [
                        // Direct Line
                        Expanded(child: GestureDetector(
                          onTap: _callContact,
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('DIRECT LINE:', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD4C8B0), letterSpacing: 1)),
                                Text(contactLabel, style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('Non-Emergency Contact', style: GoogleFonts.cormorantGaramond(fontSize: 12, color: const Color(0xFFB0A890), fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        )),
                        // Emergency
                        Expanded(child: GestureDetector(
                          onTap: _callAmbulance,
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('EMERGENCY:', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFD4B8B0), letterSpacing: 1)),
                                Text('CALL AMBULANCE', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                Text('Immediate Response Required', style: GoogleFonts.cormorantGaramond(fontSize: 12, color: const Color(0xFFC0A0A0), fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                // Nav labels
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(child: GestureDetector(
                          child: Center(child: Text('LIFE KNOB', style: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB09840), letterSpacing: 2))),
                        )),
                        Expanded(child: Center(child: Text('PEOPLE', style: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8A7A60), letterSpacing: 2)))),
                        Expanded(child: Center(child: Text('SETUP', style: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8A7A60), letterSpacing: 2)))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
