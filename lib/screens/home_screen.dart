import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/ok_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isCheckingIn = false;
  String? _lastCheckIn;
  String? _lastCheckInTime;
  String? _userCode;
  String? _userName;
  String? _sosNumber;
  String? _sosName;
  String? _ambulanceNumber;
  String? _avatarUrl;
  late AnimationController _pulseCtrl;
  late AnimationController _heartbeatCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 2200), vsync: this)..repeat(reverse: true);
    _heartbeatCtrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
    _loadUserData();
    _loadLastCheckIn();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _heartbeatCtrl.dispose(); super.dispose(); }

  void _setUserData(dynamic user) {
    if (user == null || !mounted) return;
    setState(() {
      _userCode = user.userCode; _userName = user.name; _sosNumber = user.sosNumber;
      _sosName = user.sosName; _ambulanceNumber = user.ambulanceNumber; _avatarUrl = user.avatar;
    });
  }

  Future<void> _loadUserData() async {
    final cached = AuthService().currentUser ?? await AuthService().getSavedUser();
    _setUserData(cached);
    try { final fresh = await AuthService().refreshProfile(); _setUserData(fresh); } catch (_) {}
  }

  Future<void> _loadLastCheckIn() async {
    try {
      final response = await ApiService().getHistory(page: 1);
      final List data = response['data'] ?? [];
      if (data.isNotEmpty && mounted) {
        final createdAt = data.first['created_at'];
        if (createdAt != null) {
          final dt = DateTime.parse(createdAt);
          final diff = DateTime.now().difference(dt);
          final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final amPm = dt.hour >= 12 ? 'PM' : 'AM';
          setState(() {
            _lastCheckInTime = '$hour:${dt.minute.toString().padLeft(2, '0')} $amPm';
            if (diff.inMinutes < 1) _lastCheckIn = 'Just now';
            else if (diff.inMinutes < 60) _lastCheckIn = '${diff.inMinutes}m ago';
            else if (diff.inHours < 24) _lastCheckIn = '${diff.inHours}h ago';
            else _lastCheckIn = '${diff.inDays}d ago';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (image == null) return;
    try {
      final bytes = await image.readAsBytes();
      final result = await ApiService().uploadAvatar(bytes, image.name);
      final newUrl = result['avatar_url'] as String?;
      if (newUrl != null && mounted) { await AuthService().refreshProfile(); setState(() => _avatarUrl = newUrl); }
    } catch (_) {}
  }

  void _showCodePopup() {
    if (_userCode == null) return;
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: LKTheme.glassCard(borderColor: LKTheme.gold.withValues(alpha: 0.3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.1)),
            child: const Icon(Icons.link_rounded, size: 32, color: LKTheme.gold)),
          const SizedBox(height: 16),
          const Text('YOUR CONNECTION CODE', style: TextStyle(fontSize: 14, color: LKTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(_userCode!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 6)),
          const SizedBox(height: 16),
          const Text('Share this code with your family\nso they can connect to you.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: LKTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); if (mounted) _showBigMessage('Code copied!', '', LKTheme.gold); },
              icon: const Icon(Icons.copy_rounded, size: 22), label: const Text('Copy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.gold, side: BorderSide(color: LKTheme.gold.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF5A3D10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            )),
          ]),
        ]),
      ),
    ));
  }

  Future<void> _doCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      await ApiService().checkIn(type: 'ok');
      if (mounted) { setState(() { _lastCheckIn = 'Just now'; _lastCheckInTime = 'Now'; }); _showBigMessage('Check-in sent!', 'Your connections have been notified.', LKTheme.teal); }
    } catch (e) { if (mounted) _showBigMessage('Could not check in', '$e', LKTheme.red); }
    finally { if (mounted) setState(() => _isCheckingIn = false); }
  }

  void _showBigMessage(String title, String message, Color color) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: LKTheme.glassCard(borderColor: color.withValues(alpha: 0.3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
            child: Icon(color == LKTheme.red ? Icons.error_rounded : Icons.check_circle_rounded, size: 64, color: color)),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 18, color: LKTheme.textSecondary), textAlign: TextAlign.center)],
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 56, child: Container(
            decoration: BoxDecoration(gradient: color == LKTheme.red ? LKTheme.redGradient : LinearGradient(colors: [color, color.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(16)),
            child: ElevatedButton(onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('OK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          )),
        ]),
      ),
    ));
  }

  Future<void> _callContact() async {
    final number = _sosNumber;
    if (number == null || number.isEmpty) { if (!mounted) return; _showBigMessage('No contact set', 'Go to Systems to add your emergency contact.', LKTheme.gold); return; }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callAmbulance() async {
    final number = _ambulanceNumber;
    if (number == null || number.isEmpty) { if (!mounted) return; _showBigMessage('No ambulance number', 'Go to Systems to set your local ambulance number.', LKTheme.gold); return; }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: LKTheme.glassCard(borderColor: LKTheme.red.withValues(alpha: 0.3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.red.withValues(alpha: 0.1)),
            child: const Icon(Icons.local_hospital_rounded, size: 64, color: LKTheme.red)),
          const SizedBox(height: 20),
          const Text('Call Ambulance?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LKTheme.red)),
          const SizedBox(height: 8),
          Text('This will dial $number.\nOnly use in a real emergency.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: LKTheme.textSecondary, height: 1.4)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Cancel', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(gradient: LKTheme.redGradient, borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Call Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            )),
          ]),
        ]),
      ),
    ));
    if (confirmed != true) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final String contactLabel = (_sosName != null && _sosName!.isNotEmpty) ? _sosName!.toUpperCase() : 'CONTACT';
    final displayName = (_userName != null && _userName!.isNotEmpty) ? _userName!.toUpperCase() : 'USER';

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - bigger, more premium
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LKTheme.gold, width: 3),
                        boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.25), blurRadius: 16)],
                        image: _avatarUrl != null ? DecorationImage(image: NetworkImage('https://lifeknob.com$_avatarUrl'), fit: BoxFit.cover) : null,
                        color: LKTheme.bgCardLight,
                      ),
                      child: _avatarUrl == null ? Center(child: Text(
                        _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: LKTheme.gold))) : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: LKTheme.textPrimary, letterSpacing: 1)),
                      const SizedBox(height: 3),
                      Row(children: [
                        if (_lastCheckIn != null) Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.teal,
                            boxShadow: [BoxShadow(color: LKTheme.teal.withValues(alpha: 0.5), blurRadius: 6)]),
                        ),
                        if (_lastCheckIn != null) const SizedBox(width: 6),
                        Text(
                          _lastCheckIn != null ? 'Verified: $_lastCheckIn' : 'Not verified yet',
                          style: TextStyle(fontSize: 14, color: _lastCheckIn != null ? LKTheme.teal : LKTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ]),
                  ),
                  // Logo - gold knob icon
                  GestureDetector(
                    onTap: _showCodePopup,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Column(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LKTheme.goldGradient,
                            boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 12)],
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            const Icon(Icons.favorite, color: Color(0xFF5A3D10), size: 24),
                            Positioned(top: 6, child: Container(width: 6, height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5A3D10)))),
                          ]),
                        ),
                        const SizedBox(height: 3),
                        const Text('LIFE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1)),
                        const Text('KNOB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1.2)),
                        if (_userCode != null)
                          Text(_userCode!, style: TextStyle(fontSize: 7, color: LKTheme.gold.withValues(alpha: 0.4), letterSpacing: 0.5)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // MAIN - Are you okay + BIG knob
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Text(
                        'Are you okay?',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: LKTheme.teal.withValues(alpha: 0.6 + _pulseCtrl.value * 0.4),
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),

                  OkButton(onPressed: _doCheckIn, isLoading: _isCheckingIn),

                  const SizedBox(height: 4),

                  // Heartbeat + verification
                  if (_lastCheckIn != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _heartbeatCtrl,
                            builder: (context, _) => CustomPaint(
                              size: const Size(44, 22),
                              painter: _HeartbeatPainter(progress: _heartbeatCtrl.value, color: LKTheme.gold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(
                            'Verified @ ${_lastCheckInTime ?? _lastCheckIn} - ${_userName ?? "User"}\'s Check-in',
                            style: TextStyle(fontSize: 12, color: LKTheme.gold.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // I NEED HELP
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Column(
                children: [
                  const Text('I NEED HELP!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: LKTheme.red, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Direct Line
                      Expanded(child: GestureDetector(
                        onTap: _callContact,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: LKTheme.gold.withValues(alpha: 0.3)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(children: [
                            Container(
                              margin: const EdgeInsets.only(left: 14),
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, gradient: LKTheme.goldGradient,
                                boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 8)],
                              ),
                              child: const Icon(Icons.phone_rounded, color: Color(0xFF5A3D10), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DIRECT LINE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LKTheme.gold, letterSpacing: 0.5)),
                                Text(contactLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: LKTheme.textPrimary), overflow: TextOverflow.ellipsis),
                                const Text('Non-Emergency', style: TextStyle(fontSize: 10, color: LKTheme.textMuted)),
                              ],
                            )),
                          ]),
                        ),
                      )),
                      const SizedBox(width: 10),
                      // Emergency
                      Expanded(child: GestureDetector(
                        onTap: _callAmbulance,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFAA2222), Color(0xFF6B1515)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: LKTheme.red.withValues(alpha: 0.4)),
                            boxShadow: [BoxShadow(color: LKTheme.red.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(children: [
                            Container(
                              margin: const EdgeInsets.only(left: 14),
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMERGENCY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                                Text('AMBULANCE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('Immediate Response', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              ],
                            )),
                          ]),
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;
  _HeartbeatPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final path = Path();
    final w = size.width; final h = size.height; final mid = h / 2;
    path.moveTo(0, mid);
    path.lineTo(w * 0.25, mid);
    path.lineTo(w * 0.35, mid - h * 0.4);
    path.lineTo(w * 0.45, mid + h * 0.3);
    path.lineTo(w * 0.55, mid - h * 0.15);
    path.lineTo(w * 0.65, mid);
    path.lineTo(w, mid);
    canvas.drawPath(path, paint);
    final dotX = w * progress;
    canvas.drawCircle(Offset(dotX, _getY(progress, w, h, mid)), 2.5, Paint()..color = color);
  }

  double _getY(double t, double w, double h, double mid) {
    final x = t * w;
    if (x < w * 0.25) return mid;
    if (x < w * 0.35) return mid - h * 0.4 * ((x - w * 0.25) / (w * 0.1));
    if (x < w * 0.45) return mid - h * 0.4 + (mid + h * 0.3 - (mid - h * 0.4)) * ((x - w * 0.35) / (w * 0.1));
    if (x < w * 0.55) return mid + h * 0.3 - (mid + h * 0.3 - (mid - h * 0.15)) * ((x - w * 0.45) / (w * 0.1));
    if (x < w * 0.65) return mid - h * 0.15 + (mid - (mid - h * 0.15)) * ((x - w * 0.55) / (w * 0.1));
    return mid;
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) => old.progress != progress;
}
