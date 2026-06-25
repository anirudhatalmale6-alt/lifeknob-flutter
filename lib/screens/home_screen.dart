import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = AuthService().currentUser ?? await AuthService().getSavedUser();
    if (user != null && mounted) {
      setState(() {
        _userCode = user.userCode;
        _userName = user.name;
        _sosNumber = user.sosNumber;
        _sosName = user.sosName;
        _avatarUrl = user.avatar;
      });
    }

    try {
      final freshUser = await AuthService().refreshProfile();
      if (mounted) {
        setState(() {
          _userCode = freshUser.userCode;
          _userName = freshUser.name;
          _sosNumber = freshUser.sosNumber;
          _sosName = freshUser.sosName;
          _avatarUrl = freshUser.avatar;
        });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('YOUR CONNECTION CODE', style: TextStyle(fontSize: 16, color: Color(0xFF95A5A6), fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Text(
                _userCode!,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF27AE60), letterSpacing: 6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with your family\nso they can connect to you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D), height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _userCode!));
                        Navigator.pop(ctx);
                        if (mounted) {
                          _showBigMessage('Code copied!', '', const Color(0xFF27AE60));
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: const Text('Copy', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF27AE60),
                        side: const BorderSide(color: Color(0xFF27AE60)),
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
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
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
        _showBigMessage('Check-in sent!', 'Your connections have been notified.', const Color(0xFF27AE60));
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not check in', '$e', const Color(0xFFE74C3C));
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _showBigMessage(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                color == const Color(0xFF27AE60) ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 64, color: color,
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, foregroundColor: Colors.white,
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
      _showBigMessage('No contact set', 'Go to Settings to add your emergency contact.', const Color(0xFFF39C12));
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callAmbulance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_hospital_rounded, size: 64, color: Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              const Text('Call Ambulance?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C))),
              const SizedBox(height: 8),
              const Text('This will dial emergency services.\nOnly use in a real emergency.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Call Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    final uri = Uri(scheme: 'tel', path: '000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String get _lastCheckInText {
    if (_lastCheckIn == null) return 'You have not pressed OK yet';
    return 'You pressed OK button $_lastCheckIn';
  }

  @override
  Widget build(BuildContext context) {
    final String callButtonLabel = (_sosName != null && _sosName!.isNotEmpty)
        ? 'CALL\n${_sosName!.toUpperCase()}'
        : 'CALL\nCONTACT';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFF27AE60), width: 2),
                            image: _avatarUrl != null
                                ? DecorationImage(image: NetworkImage('https://lifeknob.com$_avatarUrl'), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _avatarUrl == null
                              ? Center(child: Text(
                                  _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                                ))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF27AE60), border: Border.all(color: Colors.white, width: 1.5)),
                            child: const Icon(Icons.camera_alt, size: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (_userName ?? '').toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  if (_userCode != null)
                    GestureDetector(
                      onTap: _showCodePopup,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF27AE60), width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(_userCode!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF27AE60), letterSpacing: 2)),
                            const Text('TAP TO VIEW', style: TextStyle(fontSize: 8, color: Color(0xFF95A5A6))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // "Click to show your connection code" hint
            if (_userCode != null)
              const Padding(
                padding: EdgeInsets.only(right: 16, top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Click to show your connection code',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE74C3C), fontWeight: FontWeight.w500),
                  ),
                ),
              ),

            // Main content area with OK button
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OkButton(
                    onPressed: _doCheckIn,
                    isLoading: _isCheckingIn,
                  ),

                  const SizedBox(height: 16),

                  // Last check-in status (red text like mockup)
                  Text(
                    _lastCheckInText,
                    style: const TextStyle(fontSize: 15, color: Color(0xFFE74C3C), fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 20),

                  // Instruction text (red, prominent)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'Press the button if everything is fine with you',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFFE74C3C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  // Call contact
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _callContact,
                        icon: const Icon(Icons.phone_rounded, size: 22),
                        label: Text(callButtonLabel, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Call ambulance
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _callAmbulance,
                        icon: const Icon(Icons.add_box_rounded, size: 22),
                        label: const Text('CALL\nAMBULANCE', textAlign: TextAlign.center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "OR Alert if something wrong" text
            const Padding(
              padding: EdgeInsets.only(bottom: 6, top: 2),
              child: Text(
                'OR Alert if something wrong',
                style: TextStyle(fontSize: 13, color: Color(0xFFE74C3C), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
