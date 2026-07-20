import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';
import '../models/connection_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../widgets/ad_widgets.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

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
  bool _isFreeUser = true;
  String? _bannerAdImage;
  String? _bannerAdUrl;
  String? _bumperAdImage;
  String? _bumperAdUrl;

  static const double _triggerAngle = pi;
  double _rotation = 0.0;
  double _prevAngle = 0.0;
  bool _isDragging = false;
  bool _showSuccess = false;
  bool _showFailed = false;
  DateTime? _lastSuccessTime;
  bool _dataLoaded = false;
  int _lastHapticTick = 0;
  bool _showBumperAd = false;

  late AnimationController _springCtrl;
  late AnimationController _hintCtrl;
  late AnimationController _ekgCtrl;
  late AnimationController _rockCtrl;
  double _springStart = 0;
  bool _hintPlayed = false;

  static Color get navy => LKTheme.navy;
  static const Color navyMid = Color(0xFF08394F);
  static const Color gold = Color(0xFFDDA15E);
  static const Color silver = Color(0xFFADB5C0);
  static const Color cream = Color(0xFFFDF0D5);
  static const Color green = Color(0xFF386641);
  static const Color red = Color(0xFFC1121F);
  static const Color textGray = Color(0xFF8A9AAA);
  static const Color faceGray = Color(0xFFDCDCDC);
  static const Color faceDarkGray = Color(0xFFC4C4C4);

  // Per Tom's appfaces sheet: gold accent on all plans (free screen shows gold too);
  // the free/paid difference is the ad area, not the colour.
  Color get _accent => gold;
  Color get _accentSub => const Color(0xFFE8BE80);

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _springCtrl.addListener(() {
      if (!_isDragging && !_showSuccess) {
        setState(() => _rotation = _springStart * (1.0 - Curves.easeOut.transform(_springCtrl.value)));
      }
    });
    _hintCtrl = AnimationController(duration: const Duration(milliseconds: 7000), vsync: this);
    _hintCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _hintPlayed = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _rockCtrl.repeat();
        });
      }
    });
    _ekgCtrl = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this)..repeat();
    _rockCtrl = AnimationController(duration: const Duration(milliseconds: 4500), vsync: this);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) _hintCtrl.forward();
    });
    _loadUserData();
    _loadLastCheckIn();
    _loadAdConfig();
  }

  @override
  void dispose() { _springCtrl.dispose(); _hintCtrl.dispose(); _ekgCtrl.dispose(); _rockCtrl.dispose(); super.dispose(); }

  void _setUserData(dynamic user) {
    if (user == null || !mounted) return;
    setState(() {
      _userCode = user.userCode; _userName = user.name; _sosNumber = user.sosNumber;
      _sosName = user.sosName; _ambulanceNumber = user.ambulanceNumber;
      _isFreeUser = user.isFree;
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
      if (mounted) {
        if (data.isNotEmpty) {
          final dt = DateTime.parse(data.first['created_at']);
          setState(() {
            _lastSuccessTime = dt; _dataLoaded = true;
            _lastCheckIn = Connection.relativeVerified(dt);
          });
        } else {
          setState(() => _dataLoaded = true);
        }
      }
    } catch (_) { if (mounted) setState(() => _dataLoaded = true); }
  }

  Future<void> _loadAdConfig() async {
    try {
      final resp = await ApiService().getSiteSettings();
      final data = resp['data'] ?? {};
      if (mounted) {
        setState(() {
          final img = data['banner_ad_image'] ?? '';
          _bannerAdImage = img.isNotEmpty ? 'https://lifeknob.com$img' : null;
          _bannerAdUrl = data['banner_ad_url'];
          final bImg = data['bumper_ad_image'] ?? '';
          _bumperAdImage = bImg.isNotEmpty ? 'https://lifeknob.com$bImg' : null;
          _bumperAdUrl = data['bumper_ad_url'];
        });
      }
    } catch (_) {}
  }

  bool get _isRecentSuccess => _lastSuccessTime != null && DateTime.now().difference(_lastSuccessTime!).inMinutes < 60;
  bool get _isOverdue => _dataLoaded && (_lastSuccessTime == null || DateTime.now().difference(_lastSuccessTime!).inHours >= 24);

  double _getAngle(Offset pos, Offset center) => atan2(pos.dy - center.dy, pos.dx - center.dx);

  void _onKnobPanStart(DragStartDetails d, Offset center) {
    if (_isCheckingIn || _showSuccess) return;
    _springCtrl.stop(); _hintCtrl.stop(); _hintPlayed = true; _lastHapticTick = 0;
    setState(() { _isDragging = true; _showFailed = false; _prevAngle = _getAngle(d.localPosition, center); });
  }

  void _onKnobPanUpdate(DragUpdateDetails d, Offset center) {
    if (!_isDragging || _isCheckingIn || _showSuccess) return;
    final newAngle = _getAngle(d.localPosition, center);
    var delta = newAngle - _prevAngle;
    while (delta > pi) delta -= 2 * pi;
    while (delta < -pi) delta += 2 * pi;
    final newRot = (_rotation + delta).clamp(-_triggerAngle - 0.15, _triggerAngle + 0.15);
    final tick = (newRot.abs() / _triggerAngle * 4).floor();
    if (tick > _lastHapticTick && tick <= 3) { HapticFeedback.selectionClick(); _lastHapticTick = tick; }
    setState(() { _rotation = newRot; _prevAngle = newAngle; });
    if (_rotation.abs() >= _triggerAngle) _triggerCheckIn();
  }

  void _onKnobPanEnd(DragEndDetails d) {
    if (!_isDragging) return;
    _isDragging = false;
    if (!_showSuccess) {
      if (_rotation.abs() > 0.3) {
        setState(() => _showFailed = true);
      }
      _springStart = _rotation; _springCtrl.forward(from: 0);
    }
  }

  void _triggerCheckIn() {
    if (_showSuccess) return;
    HapticFeedback.heavyImpact();
    setState(() { _isDragging = false; _showSuccess = true; _showFailed = false; _lastSuccessTime = DateTime.now(); _rotation = _triggerAngle; });
    _doCheckIn();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() { _showSuccess = false; _rotation = 0; _lastHapticTick = 0; });
        if (_isFreeUser) setState(() => _showBumperAd = true);
      }
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
    final accent = _accent;
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent, width: 2)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('YOUR CODE', style: GoogleFonts.barlowCondensed(fontSize: 14, color: accent, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 16),
          Text(_userCode!, style: GoogleFonts.barlowCondensed(fontSize: 48, fontWeight: FontWeight.w900, color: cream, letterSpacing: 6)),
          const SizedBox(height: 12),
          Text('Share this code with your family', style: GoogleFonts.barlowCondensed(fontSize: 16, color: cream.withValues(alpha: 0.7), fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
              style: OutlinedButton.styleFrom(foregroundColor: accent, side: BorderSide(color: accent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('COPY', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('OK', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: navy)),
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
    final progress = (_rotation.abs() / _triggerAngle).clamp(0.0, 1.0);
    final contactLabel = (_sosName != null && _sosName!.isNotEmpty) ? _sosName!.toUpperCase() : '';
    final displayName = (_userName != null && _userName!.isNotEmpty) ? _userName!.toUpperCase() : 'USER';
    final lastVerified = _lastCheckIn ?? 'Not yet';

    return Scaffold(
      backgroundColor: navy,
      body: Stack(children: [
        Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: navy,
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;

                  return Column(
                    children: [
                      // ═══ HEADER — avatar + name | logo ═══
                      SizedBox(
                        height: _isFreeUser ? h * 0.10 : h * 0.13,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, right: 2),
                          child: Row(children: [
                            GestureDetector(
                              onTap: _showCodePopup,
                              child: Container(
                                width: h * 0.085, height: h * 0.085,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _accent, width: 2.5),
                                  color: _accent.withValues(alpha: 0.1),
                                ),
                                child: Icon(Icons.qr_code_2, color: Colors.white, size: h * 0.05),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: GestureDetector(
                              onTap: _showCodePopup,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(displayName, style: GoogleFonts.barlowCondensed(fontSize: max(h * 0.032, 20), fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('Last verified:', style: GoogleFonts.robotoSlab(fontSize: min(h * 0.016, 12.0), fontWeight: FontWeight.w300, color: Colors.white.withValues(alpha: 0.45)), maxLines: 1),
                                  Text(lastVerified, style: GoogleFonts.robotoSlab(fontSize: min(h * 0.02, 16.0), fontWeight: FontWeight.w600, color: _accent), maxLines: 1),
                                ],
                              ),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: GestureDetector(
                                onTap: _showCodePopup,
                                child: Builder(builder: (_) {
                                  final url = TranslationService().logoUrl('header');
                                  if (url != null) {
                                    final cb = DateTime.now().millisecondsSinceEpoch ~/ 60000;
                                    return Image.network('$url?v=$cb', fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => SvgPicture.asset('assets/images/lifeknob_logo_header.svg', colorFilter: ColorFilter.mode(_accent, BlendMode.srcIn), fit: BoxFit.contain));
                                  }
                                  return SvgPicture.asset('assets/images/lifeknob_logo_header.svg', colorFilter: ColorFilter.mode(_accent, BlendMode.srcIn), fit: BoxFit.contain);
                                }),
                              ),
                            )),
                          ]),
                        ),
                      ),

                      Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.05), _accent, _accent, _accent.withValues(alpha: 0.05)]),
                      )),

                      // ═══ TURN THE KNOB ═══
                      SizedBox(
                        height: _isFreeUser ? max(h * 0.045, 34) : max(h * 0.065, 48),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Center(
                            child: FittedBox(fit: BoxFit.scaleDown, child: Text('TURN THE KNOB', style: GoogleFonts.dosis(fontSize: max(h * 0.036, 22), fontWeight: FontWeight.w700, color: _accent, letterSpacing: 1))),
                          ),
                        ),
                      ),

                      // ═══ KNOB — own section ═══
                      SizedBox(
                        height: _isFreeUser ? h * 0.28 : h * 0.36,
                        child: LayoutBuilder(builder: (context, kc) {
                          final areaW = kc.maxWidth;
                          final areaH = kc.maxHeight;
                          final center = Offset(areaW / 2, areaH / 2);
                          final knobSize = min(areaW * 0.92, areaH * 0.98);
                          final goldRingW = knobSize * 0.058;
                          final dialSize = knobSize - goldRingW * 2;
                          final faceSize = knobSize * 0.75;

                          return GestureDetector(
                            onPanStart: (d) => _onKnobPanStart(d, center),
                            onPanUpdate: (d) => _onKnobPanUpdate(d, center),
                            onPanEnd: _onKnobPanEnd,
                            child: Container(
                              color: Colors.transparent,
                              child: Center(child: AnimatedBuilder(
                                animation: Listenable.merge([_hintCtrl, _rockCtrl]),
                                builder: (context, child) {
                                  double rockAngle = 0.0;
                                  if (!_isDragging && !_showFailed && !_showSuccess && progress < 0.01) {
                                    if (!_hintPlayed) {
                                      final ht = _hintCtrl.value;
                                      rockAngle = sin(ht * 5 * pi) * (pi / 3) * exp(-4 * ht);
                                    } else {
                                      final t = _rockCtrl.value;
                                      if (t < 0.65) {
                                        final st = t / 0.65;
                                        rockAngle = sin(st * 3 * pi) * (pi / 18) * exp(-2 * st);
                                      }
                                    }
                                  }
                                  return Transform.rotate(angle: rockAngle, child: child);
                                },
                                child: SizedBox(
                                width: knobSize, height: knobSize,
                                child: Stack(alignment: Alignment.center, children: [
                                  Container(
                                    width: knobSize, height: knobSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                        colors: [_accent.withValues(alpha: 0.9), _accent, _accent, _accent.withValues(alpha: 0.85)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 25, spreadRadius: 3),
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: _rotation,
                                    child: CustomPaint(
                                      size: Size(dialSize, dialSize),
                                      painter: _DialPainter(navy: navy, tickColor: cream.withValues(alpha: 0.8), progress: progress, trackColor: _accent.withValues(alpha: 0.25)),
                                    ),
                                  ),
                                  Container(
                                    width: faceSize, height: faceSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: _showFailed ? [red, const Color(0xFFAA0E19)] : _showSuccess ? [green, const Color(0xFF2D5234)] : [faceGray, faceDarkGray],
                                        stops: const [0.7, 1.0],
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                  ),
                                  SizedBox(
                                    width: faceSize * 0.65, height: faceSize * 0.65,
                                    child: _showFailed
                                      ? Center(child: Text('TRY\nAGAIN', style: GoogleFonts.barlowCondensed(fontSize: faceSize * 0.14, fontWeight: FontWeight.w700, color: cream), textAlign: TextAlign.center))
                                      : _showSuccess
                                      ? Center(child: Text('THANK\nYOU', style: GoogleFonts.barlowCondensed(fontSize: faceSize * 0.14, fontWeight: FontWeight.w700, color: cream), textAlign: TextAlign.center))
                                      : (_isDragging || progress > 0.01)
                                      ? Center(child: Text('${(progress * 100).round()}%', style: GoogleFonts.barlowCondensed(fontSize: faceSize * 0.25, fontWeight: FontWeight.w700, color: progress >= 1.0 ? green : Color.lerp(red, _accent, progress)!)))
                                      : ClipRect(child: ShaderMask(
                                      // Resting knob face is a plain grey monochrome logo per the
                                      // appfaces sheet (M1/M2 stay grey even when overdue). Green/red
                                      // only appear transiently on a successful/failed turn (face above).
                                      shaderCallback: (bounds) =>
                                        const LinearGradient(colors: [Color(0xFFA0A0A0), Color(0xFFA0A0A0)]).createShader(bounds),
                                      blendMode: BlendMode.srcIn,
                                      child: Transform.translate(offset: const Offset(10, 0), child: SvgPicture.asset('assets/images/lifeknob_logo.svg', fit: BoxFit.contain)),
                                    )),
                                  ),
                                ]),
                              ))),
                            ),
                          );
                        }),
                      ),

                      // Push the call/ad/nav block to the bottom (knob sits in the upper area,
                      // per the sheet) so there's no empty gap under the nav on free plans.
                      if (_isFreeUser) const Spacer(),

                      // ═══ OR CALL FOR HELP | EKG ═══
                      SizedBox(
                        height: _isFreeUser ? max(h * 0.04, 32) : max(h * 0.06, 42),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FittedBox(fit: BoxFit.scaleDown, child: Text('OR CALL FOR HELP', style: GoogleFonts.barlowCondensed(fontSize: max(h * 0.036, 22), fontWeight: FontWeight.w500, color: _accent))),
                              Expanded(child: Padding(
                                padding: const EdgeInsets.only(left: 12, right: 4),
                                child: SizedBox(
                                  height: max(h * 0.04, 28),
                                  child: AnimatedBuilder(
                                    animation: _ekgCtrl,
                                    builder: (context, _) => CustomPaint(painter: _EkgPainter(progress: _ekgCtrl.value, color: _accent)),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),

                      // ═══ Call buttons ═══
                      _isFreeUser
                        ? Padding(
                            padding: const EdgeInsets.only(left: 3, right: 3, bottom: 3),
                            child: Row(children: [
                              Expanded(child: GestureDetector(
                                onTap: _callContact,
                                child: Container(
                                  height: h * 0.06,
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A5276),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.phone, color: _accent, size: 22),
                                    const SizedBox(width: 8),
                                    Flexible(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('DIRECT LINE', style: GoogleFonts.robotoSlab(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      if (contactLabel.isNotEmpty)
                                        Text(contactLabel, style: GoogleFonts.barlowCondensed(fontSize: 13, color: _accentSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ])),
                                  ]),
                                ),
                              )),
                              Expanded(child: GestureDetector(
                                onTap: _callAmbulance,
                                child: Container(
                                  height: h * 0.06,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: red,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.health_and_safety, color: _accent, size: 22),
                                    const SizedBox(width: 8),
                                    Flexible(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('EMERGENCY', style: GoogleFonts.robotoSlab(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      Text(_ambulanceNumber ?? 'AMBULANCE', style: GoogleFonts.barlowCondensed(fontSize: 13, color: _accentSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ])),
                                  ]),
                                ),
                              )),
                            ]),
                          )
                        : SizedBox(
                            height: h * 0.20,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 3, right: 3, bottom: 3),
                              child: Row(children: [
                                Expanded(child: GestureDetector(
                                  onTap: _callContact,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A5276),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                                        BoxShadow(color: const Color(0xFF1A5276).withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 1),
                                      ],
                                    ),
                                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                        Icon(Icons.phone, color: gold, size: h * 0.05),
                                        SizedBox(height: h * 0.01),
                                        FittedBox(fit: BoxFit.scaleDown, child: Text('DIRECT LINE', style: GoogleFonts.robotoSlab(fontSize: max(h * 0.026, 17), fontWeight: FontWeight.w700, color: Colors.white))),
                                        SizedBox(height: h * 0.006),
                                        contactLabel.isNotEmpty
                                          ? Text(contactLabel, style: GoogleFonts.barlowCondensed(fontSize: max(h * 0.026, 16), fontWeight: FontWeight.w400, color: const Color(0xFFE8BE80)), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)
                                          : Text('........', style: TextStyle(fontSize: h * 0.024, color: const Color(0xFFE8BE80).withValues(alpha: 0.5), letterSpacing: 5)),
                                      ]),
                                  ),
                                )),
                                Expanded(child: GestureDetector(
                                  onTap: _callAmbulance,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 2),
                                    decoration: BoxDecoration(
                                      color: red,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                                        BoxShadow(color: red.withValues(alpha: 0.3), blurRadius: 6, spreadRadius: 1),
                                      ],
                                    ),
                                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                        Icon(Icons.health_and_safety, color: gold, size: h * 0.05),
                                        SizedBox(height: h * 0.01),
                                        FittedBox(fit: BoxFit.scaleDown, child: Text('EMERGENCY', style: GoogleFonts.robotoSlab(fontSize: max(h * 0.026, 17), fontWeight: FontWeight.w700, color: Colors.white))),
                                        SizedBox(height: h * 0.006),
                                        Text(_ambulanceNumber ?? 'AMBULANCE', style: GoogleFonts.barlowCondensed(fontSize: max(h * 0.026, 16), fontWeight: FontWeight.w400, color: const Color(0xFFE8BE80)), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                      ]),
                                  ),
                                )),
                              ]),
                            ),
                          ),

                      // ═══ AD (free users) — single 3:1 banner below the call buttons per sheet ═══
                      if (_isFreeUser)
                        AdBannerPair(
                          onRemoveAds: () => widget.onTabChange?.call(2),
                          bannerImageUrl: _bannerAdImage,
                          bannerClickUrl: _bannerAdUrl,
                        ),

                      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.05), _accent.withValues(alpha: 0.5), _accent.withValues(alpha: 0.5), _accent.withValues(alpha: 0.05)]),
                      )),

                      // ═══ Nav ═══
                      SizedBox(
                        height: _isFreeUser ? h * 0.08 : h * 0.10,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 3, right: 3),
                          // Bottom nav is PEOPLE | SETUP only (2 items) per the appfaces sheet —
                          // the home/knob screen itself is the "LIFE KNOB" tab, no self-link.
                          child: Row(children: [
                            _navZone(Icons.people, 'PEOPLE', 1, h),
                            _navZone(Icons.tune, 'SETUP', 2, h),
                          ]),
                        ),
                      ),
                      SafeArea(top: false, child: const SizedBox(height: 2)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      if (_showBumperAd)
        BumperAdOverlay(onDismiss: () => setState(() => _showBumperAd = false), imageUrl: _bumperAdImage, clickUrl: _bumperAdUrl),
      ]),
    );
  }

  Widget _navZone(IconData icon, String label, int index, double h) {
    return Expanded(child: GestureDetector(
      onTap: () => widget.onTabChange?.call(index),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _accent, size: h * 0.045),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.robotoSlab(fontSize: h * 0.02, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _DialPainter extends CustomPainter {
  final Color navy;
  final Color tickColor;
  final double progress;
  final Color progressColor;
  final Color trackColor;
  _DialPainter({required this.navy, required this.tickColor, this.progress = 0.0, this.progressColor = const Color(0xFF386641), this.trackColor = const Color(0x40DDA15E)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, Paint()..color = navy);

    final arcRadius = radius * 0.78;
    final arcPaint = Paint()..color = trackColor..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: arcRadius), -pi / 2, pi, false, arcPaint);

    if (progress > 0.01) {
      final fillPaint = Paint()..color = progressColor..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: arcRadius), -pi / 2, pi * progress, false, fillPaint);
    }

    final tickPaint = Paint()..color = tickColor..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final longTickPaint = Paint()..color = tickColor..strokeWidth = 2.5..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final isLong = i % 5 == 0;
      final outerR = radius - 3;
      final innerR = isLong ? radius - 20 : radius - 10;

      final p1 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));
      final p2 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      canvas.drawLine(p2, p1, isLong ? longTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.progress != progress;
}

class _EkgPainter extends CustomPainter {
  final double progress;
  final Color color;
  _EkgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height / 2;
    final w = size.width;

    final basePaint = Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h), Offset(w, h), basePaint);

    final paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, h)..lineTo(w * 0.15, h)
      ..lineTo(w * 0.2, h - 4)..lineTo(w * 0.22, h + 2)
      ..lineTo(w * 0.26, h - h * 0.8)..lineTo(w * 0.32, h + h * 0.4)
      ..lineTo(w * 0.36, h - 3)..lineTo(w * 0.4, h)
      ..lineTo(w * 0.55, h)
      ..lineTo(w * 0.58, h - 3)..lineTo(w * 0.6, h + 2)
      ..lineTo(w * 0.64, h - h * 0.5)..lineTo(w * 0.7, h + h * 0.3)
      ..lineTo(w * 0.74, h - 2)..lineTo(w * 0.78, h)
      ..lineTo(w, h);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress, size.height));
    canvas.drawPath(path, paint);
    canvas.restore();

    if (progress > 0.05 && progress < 0.95) {
      canvas.drawCircle(Offset(w * progress, h), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _EkgPainter old) => old.progress != progress;
}
