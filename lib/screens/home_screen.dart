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
  String? _avatarUrl;
  bool _isStatusSafe = true;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated!', style: TextStyle(fontSize: 14)),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not upload: $e', style: const TextStyle(fontSize: 14)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _doCheckIn() async {
    setState(() => _isCheckingIn = true);
    try {
      await ApiService().checkIn(type: 'ok');
      if (mounted) {
        setState(() {
          _lastCheckIn = 'Just now';
          _isStatusSafe = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in sent! Your connections have been notified.', style: TextStyle(fontSize: 16)),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check in: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _callHelp() async {
    final number = _sosNumber;
    if (number == null || number.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency number set. Go to Settings to add one.', style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C), size: 28),
            SizedBox(width: 8),
            Text('Call Ambulance?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will dial emergency services. Only use in a real emergency.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Call Now', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uri = Uri(scheme: 'tel', path: '000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF27AE60).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFF27AE60), width: 2),
                            image: _avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage('https://lifeknob.com$_avatarUrl'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _avatarUrl == null
                              ? Center(
                                  child: Text(
                                    _userName != null && _userName!.isNotEmpty
                                        ? _userName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF27AE60),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF27AE60),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_userName ?? '').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_userCode != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _userCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!', style: TextStyle(fontSize: 14)),
                            backgroundColor: Color(0xFF27AE60),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FAF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _userCode!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF27AE60),
                                letterSpacing: 2,
                              ),
                            ),
                            const Text(
                              'YOUR CODE',
                              style: TextStyle(fontSize: 9, color: Color(0xFF7F8C8D)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // OK Button
                  OkButton(
                    onPressed: _doCheckIn,
                    isLoading: _isCheckingIn,
                  ),

                  const SizedBox(height: 20),

                  // Hint text
                  const Text(
                    'Press if everything is fine',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF95A5A6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isStatusSafe ? Icons.check_circle : Icons.warning,
                              size: 20,
                              color: _isStatusSafe ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isStatusSafe ? 'Your status is currently safe.' : 'Status needs attention.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isStatusSafe ? const Color(0xFF2C3E50) : const Color(0xFFE74C3C),
                              ),
                            ),
                          ],
                        ),
                        if (_lastCheckIn != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last check-in: $_lastCheckIn',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF95A5A6)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  // I Need Help
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _callHelp,
                        icon: const Icon(Icons.health_and_safety_rounded, size: 22),
                        label: const Text('I NEED HELP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Call Ambulance
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _callAmbulance,
                        icon: const Icon(Icons.local_hospital_rounded, size: 22),
                        label: const Text('CALL\nAMBULANCE', textAlign: TextAlign.center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1.2),
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
