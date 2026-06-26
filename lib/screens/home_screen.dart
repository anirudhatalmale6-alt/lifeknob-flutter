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

class _HomeScreenState extends State<HomeScreen> {
  bool _isCheckingIn = false;
  String? _lastCheckIn;
  String? _userCode;
  String? _userName;
  String? _sosNumber;
  String? _sosName;
  String? _ambulanceNumber;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastCheckIn();
  }

  Future<void> _loadUserData() async {
    var user = AuthService().currentUser ?? await AuthService().getSavedUser();
    try {
      user = await AuthService().refreshProfile();
    } catch (_) {}

    if (user != null && mounted) {
      setState(() {
        _userCode = user!.userCode;
        _userName = user.name;
        _sosNumber = user.sosNumber;
        _sosName = user.sosName;
        _ambulanceNumber = user.ambulanceNumber;
        _avatarUrl = user.avatar;
      });
    }
  }

  Future<void> _loadLastCheckIn() async {
    try {
      final response = await ApiService().getHistory(page: 1);
      final List data = response['data'] ?? [];
      if (data.isNotEmpty && mounted) {
        final latest = data.first;
        final createdAt = latest['created_at'];
        if (createdAt != null) {
          final dt = DateTime.parse(createdAt);
          final diff = DateTime.now().difference(dt);
          setState(() {
            if (diff.inMinutes < 1) {
              _lastCheckIn = 'Just now';
            } else if (diff.inMinutes < 60) {
              _lastCheckIn = '${diff.inMinutes} minutes ago';
            } else if (diff.inHours < 24) {
              _lastCheckIn = '${diff.inHours} hours ago';
            } else {
              _lastCheckIn = '${diff.inDays} days ago';
            }
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
      if (newUrl != null && mounted) {
        await AuthService().refreshProfile();
        setState(() => _avatarUrl = newUrl);
      }
    } catch (_) {}
  }

  void _showCodePopup() {
    if (_userCode == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('YOUR CONNECTION CODE', style: TextStyle(fontSize: 14, color: LKTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 16),
              Text(
                _userCode!,
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with your family\nso they can connect to you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _userCode!));
                        Navigator.pop(ctx);
                        if (mounted) _showBigMessage('Code copied!', '', LKTheme.gold);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: const Text('Copy', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LKTheme.gold,
                        side: const BorderSide(color: LKTheme.gold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LKTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      await ApiService().checkIn(type: 'ok');
      if (mounted) {
        setState(() => _lastCheckIn = 'Just now');
        _showBigMessage('Check-in sent!', 'Your connections have been notified.', LKTheme.gold);
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not check in', '$e', LKTheme.red);
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _showBigMessage(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == LKTheme.red ? Icons.error_rounded : Icons.check_circle_rounded,
                size: 64, color: color,
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 16, color: LKTheme.textSecondary), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, foregroundColor: color == LKTheme.gold ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callContact() async {
    final number = _sosNumber;
    if (number == null || number.isEmpty) {
      if (!mounted) return;
      _showBigMessage('No contact set', 'Go to Systems to add your emergency contact.', LKTheme.gold);
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callAmbulance() async {
    final number = _ambulanceNumber;
    if (number == null || number.isEmpty) {
      if (!mounted) return;
      _showBigMessage('No ambulance number', 'Go to Systems to set your local ambulance number.', LKTheme.gold);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_hospital_rounded, size: 64, color: LKTheme.red),
              const SizedBox(height: 16),
              const Text('Call Ambulance?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LKTheme.red)),
              const SizedBox(height: 8),
              Text('This will dial $number.\nOnly use in a real emergency.',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: LKTheme.textSecondary)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: LKTheme.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Call Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String contactLabel = (_sosName != null && _sosName!.isNotEmpty)
        ? _sosName!.toUpperCase()
        : 'CONTACT';

    final String verifiedText = _lastCheckIn != null
        ? 'Verified: $_lastCheckIn'
        : 'Not verified yet';

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LKTheme.gold, width: 2),
                        image: _avatarUrl != null
                            ? DecorationImage(image: NetworkImage('https://lifeknob.com$_avatarUrl'), fit: BoxFit.cover)
                            : null,
                        color: LKTheme.bgCardLight,
                      ),
                      child: _avatarUrl == null
                          ? Center(child: Text(
                              _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LKTheme.gold),
                            ))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_userName ?? '').toUpperCase(),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: LKTheme.textPrimary, letterSpacing: 0.5),
                        ),
                        Text(
                          verifiedText,
                          style: TextStyle(fontSize: 12, color: _lastCheckIn != null ? LKTheme.teal : LKTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // LifeKnob logo/brand
                  GestureDetector(
                    onTap: _showCodePopup,
                    child: Column(
                      children: [
                        const Text('LIFE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1)),
                        const Text('KNOB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1.1)),
                        Text(_userCode ?? '', style: const TextStyle(fontSize: 9, color: LKTheme.textMuted, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Are you okay?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: LKTheme.teal, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),

                  OkButton(
                    onPressed: _doCheckIn,
                    isLoading: _isCheckingIn,
                  ),

                  const SizedBox(height: 12),

                  if (_lastCheckIn != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined, size: 18, color: LKTheme.gold.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          'Verified: $_lastCheckIn',
                          style: TextStyle(fontSize: 13, color: LKTheme.gold.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // I NEED HELP section
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'I NEED HELP!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: LKTheme.red, letterSpacing: 1),
              ),
            ),

            // Call buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(
                children: [
                  // Direct Line
                  Expanded(
                    child: GestureDetector(
                      onTap: _callContact,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LKTheme.blueGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Icon(Icons.phone_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DIRECT LINE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                                  Text(contactLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                                  const Text('Non-Emergency Contact', style: TextStyle(fontSize: 9, color: Colors.white54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Emergency
                  Expanded(
                    child: GestureDetector(
                      onTap: _callAmbulance,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LKTheme.redGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('EMERGENCY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                                  Text('CALL AMBULANCE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                                  Text('Immediate Response', style: TextStyle(fontSize: 9, color: Colors.white54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
