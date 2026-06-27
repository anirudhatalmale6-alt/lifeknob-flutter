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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('YOUR CODE', style: GoogleFonts.cinzel(fontSize: 14, color: const Color(0xFF8A7A60), fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 16),
          Text(_userCode!, style: GoogleFonts.cinzel(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFFB08930), letterSpacing: 6)),
          const SizedBox(height: 16),
          Text('Share this code with your family', style: GoogleFonts.cormorantGaramond(fontSize: 16, color: const Color(0xFF8A7A60), fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB08930), side: const BorderSide(color: Color(0xFFD4A843)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
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
    final n = _sosNumber;
    if (n == null || n.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: n);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callAmbulance() async {
    final n = _ambulanceNumber;
    if (n == null || n.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: n);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_rotation / _triggerAngle).clamp(0.0, 1.0);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final contactLabel = (_sosName != null && _sosName!.isNotEmpty) ? _sosName!.toUpperCase() : 'CONTACT';
    final displayName = (_userName != null && _userName!.isNotEmpty) ? _userName!.toUpperCase() : 'USER';

    final knobSize = screenW * 0.82;
    final goldColor = const Color(0xFF8A7A50);
    final darkGold = const Color(0xFF6B5530);

    return Scaffold(
      backgroundColor: const Color(0xFFD0D0D0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Frosted glass background
              Image.asset('assets/images/bg_phone.png', fit: BoxFit.cover),

              // Layer 2: All content
              SafeArea(
            child: Column(
              children: [
                // HEADER ROW
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      // Avatar placeholder (over the bg avatar area)
                      const SizedBox(width: 52),
                      const SizedBox(width: 10),
                      // User info
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.w800, color: darkGold, letterSpacing: 2), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Last verified:', style: GoogleFonts.cormorantGaramond(fontSize: 14, color: goldColor, fontStyle: FontStyle.italic)),
                          Text(_lastCheckIn ?? 'Not yet', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.w600, color: goldColor)),
                        ],
                      )),
                      // Logo area
                      GestureDetector(
                        onTap: _showCodePopup,
                        child: Image.asset('assets/images/logo.png', width: 65, height: 55, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),

                // TURN THE KNOB + QR
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                  child: Row(children: [
                    Expanded(child: Text('TURN THE KNOB', style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w700, color: goldColor, letterSpacing: 3))),
                    GestureDetector(
                      onTap: _showCodePopup,
                      child: Container(width: 48, height: 48, color: Colors.transparent),
                    ),
                  ]),
                ),

                // THE KNOB - gold image that rotates
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                    return GestureDetector(
                      onPanStart: (d) => _onKnobPanStart(d, center),
                      onPanUpdate: (d) => _onKnobPanUpdate(d, center),
                      onPanEnd: _onKnobPanEnd,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gold knob image (rotates)
                          Transform.rotate(
                            angle: _rotation,
                            child: Image.asset('assets/images/knob_gold.png', width: knobSize, height: knobSize, fit: BoxFit.contain),
                          ),
                          // Text overlay (stays upright)
                          _showSuccess
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                                Text('SENT!', style: GoogleFonts.cinzel(fontSize: 40, fontWeight: FontWeight.w800, color: const Color(0xFF27AE60), letterSpacing: 4)),
                                const Icon(Icons.check_rounded, color: Color(0xFF27AE60), size: 44),
                              ])
                            : ShaderMask(
                                shaderCallback: (bounds) {
                                  final fillStop = 1.0 - progress;
                                  return LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [darkGold, darkGold, const Color(0xFF27AE60), const Color(0xFF27AE60)],
                                    stops: [0.0, fillStop, fillStop, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcIn,
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text('I AM', style: GoogleFonts.cinzel(fontSize: 38, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 8)),
                                  Text('OKAY!', style: GoogleFonts.cinzel(fontSize: 68, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6, height: 0.85)),
                                ]),
                              ),
                        ],
                      ),
                    );
                  }),
                ),

                // OR CALL FOR HELP
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text('OR CALL FOR HELP', style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w700, color: goldColor, letterSpacing: 3), textAlign: TextAlign.center),
                ),

                // CALL BUTTONS
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Row(children: [
                    // Direct Line
                    Expanded(child: GestureDetector(
                      onTap: _callContact,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: const DecorationImage(image: AssetImage('assets/images/btn_blue.png'), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('DIRECT LINE:', style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1)),
                          Text(contactLabel, style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Non-Emergency Contact', style: GoogleFonts.cormorantGaramond(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                        ])),
                      ),
                    )),
                    const SizedBox(width: 8),
                    // Emergency
                    Expanded(child: GestureDetector(
                      onTap: _callAmbulance,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: const DecorationImage(image: AssetImage('assets/images/btn_red.png'), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('EMERGENCY:', style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1)),
                          Text('CALL AMBULANCE', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                          Text('Immediate Response Required', style: GoogleFonts.cormorantGaramond(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                        ])),
                      ),
                    )),
                  ]),
                ),

                // BOTTOM NAV
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
