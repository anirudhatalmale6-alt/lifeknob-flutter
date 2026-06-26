import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  static const int _totalPages = 5;

  String _language = 'English';
  String? _userCode;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _sosNameController = TextEditingController();
  final _sosPhoneController = TextEditingController();
  final _ambulanceController = TextEditingController();

  final _connectCodeController = TextEditingController();

  bool _isSaving = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) _userCode = user.userCode;
  }

  void _next() {
    if (_page == 2) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage('Please enter your name');
        return;
      }
      _saveProfile();
      return;
    }
    if (_page == 3) {
      _saveEmergency();
      return;
    }
    if (_page == 4) {
      _saveConnection();
      return;
    }
    if (_page < _totalPages - 1) {
      setState(() => _page++);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      await AuthService().refreshProfile();
    } catch (_) {}
    if (mounted) setState(() { _isSaving = false; _page++; });
  }

  Future<void> _saveEmergency() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateSettings({
        'sos_name': _sosNameController.text.trim(),
        'sos_number': _sosPhoneController.text.trim(),
        'ambulance_number': _ambulanceController.text.trim(),
      });
    } catch (_) {}
    if (mounted) setState(() { _isSaving = false; _page++; });
  }

  Future<void> _saveConnection() async {
    final code = _connectCodeController.text.trim();
    if (code.isNotEmpty) {
      setState(() => _isSaving = true);
      try {
        await ApiService().connect(code);
      } catch (e) {
        if (mounted) _showMessage('$e');
      }
      if (mounted) setState(() => _isSaving = false);
    }
    if (mounted) {
      await AuthService().refreshProfile();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _skip() {
    if (_page < _totalPages - 1) {
      setState(() => _page++);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
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

  void _showMessage(String msg) {
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
              const Icon(Icons.info_rounded, size: 56, color: LKTheme.gold),
              const SizedBox(height: 16),
              Text(msg, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sosNameController.dispose();
    _sosPhoneController.dispose();
    _ambulanceController.dispose();
    _connectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) => Container(
                  width: i == _page ? 28 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i <= _page ? LKTheme.gold : LKTheme.border,
                  ),
                )),
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: [
                  _buildLanguage,
                  _buildCode,
                  _buildProfile,
                  _buildEmergency,
                  _buildConnect,
                ][_page](),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 4, 32, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _next,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                        : Text(
                            _page == _totalPages - 1 ? 'FINISH' : 'NEXT',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5A3D10), letterSpacing: 1),
                          ),
                  ),
                ),
              ),
            ),
            if (_page >= 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _skip,
                  child: const Text('Skip for now', style: TextStyle(fontSize: 14, color: LKTheme.textMuted)),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Page 0: Language
  Widget _buildLanguage() {
    final languages = ['English', 'Magyar', 'Deutsch', 'Espanol', 'Francais', 'Italiano', 'Portugues'];
    return Padding(
      key: const ValueKey('lang'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.language_rounded, size: 52, color: LKTheme.gold),
          const SizedBox(height: 12),
          const Text('Select Language', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: languages.map((lang) => GestureDetector(
                onTap: () => setState(() => _language = lang),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _language == lang ? LKTheme.gold.withValues(alpha: 0.15) : LKTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _language == lang ? LKTheme.gold : LKTheme.border, width: _language == lang ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _language == lang ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _language == lang ? LKTheme.gold : LKTheme.textMuted, size: 24,
                      ),
                      const SizedBox(width: 14),
                      Text(lang, style: TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: _language == lang ? FontWeight.w700 : FontWeight.normal)),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Your Code
  Widget _buildCode() {
    return Padding(
      key: const ValueKey('code'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge_rounded, size: 56, color: LKTheme.gold),
          const SizedBox(height: 16),
          const Text('Your Personal Code', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: LKTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LKTheme.gold, width: 2),
              boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.15), blurRadius: 20)],
            ),
            child: Text(
              _userCode ?? '........',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 8),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'This is YOUR unique code.',
            style: TextStyle(fontSize: 22, color: LKTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'Share this code with your family\nso they can connect to you\nand see when you press OK.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: LKTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              if (_userCode != null) {
                Clipboard.setData(ClipboardData(text: _userCode!));
                _showMessage('Code copied!');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.5))),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 20, color: LKTheme.gold),
                  SizedBox(width: 8),
                  Text('Copy Code', style: TextStyle(fontSize: 17, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: Profile
  Widget _buildProfile() {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('Your Details', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 20),

          // Avatar
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LKTheme.bgCardLight,
                    border: Border.all(color: LKTheme.gold, width: 2),
                    image: _avatarUrl != null ? DecorationImage(image: NetworkImage('https://lifeknob.com$_avatarUrl'), fit: BoxFit.cover) : null,
                  ),
                  child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 40, color: LKTheme.gold) : null,
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold, border: Border.all(color: LKTheme.bg, width: 2)),
                  child: const Icon(Icons.camera_alt, size: 12, color: Color(0xFF5A3D10)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('Tap to add photo', style: TextStyle(fontSize: 12, color: LKTheme.textMuted)),
          const SizedBox(height: 20),

          _label('Your Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            maxLength: 50,
            style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'e.g. Grandma Rose', counterText: '', prefixIcon: Icon(Icons.person_rounded, color: LKTheme.gold)),
          ),
          const SizedBox(height: 16),

          _label('Email (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            maxLength: 100,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'grandma@email.com', counterText: '', prefixIcon: Icon(Icons.email_rounded, color: LKTheme.textMuted)),
          ),
          const SizedBox(height: 16),

          _label('Phone Number (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: '+61 400 000 000', counterText: '', prefixIcon: Icon(Icons.phone_rounded, color: LKTheme.textMuted)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Page 2: Emergency
  Widget _buildEmergency() {
    return SingleChildScrollView(
      key: const ValueKey('emergency'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.health_and_safety_rounded, size: 52, color: LKTheme.red),
          const SizedBox(height: 12),
          const Text('Emergency Setup', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Set up your emergency contacts', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
          const SizedBox(height: 28),

          _label('Emergency Contact Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _sosNameController,
            maxLength: 50,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. Tom', counterText: '', prefixIcon: Icon(Icons.person_rounded, color: LKTheme.blue)),
          ),
          const SizedBox(height: 16),

          _label('Emergency Contact Number'),
          const SizedBox(height: 6),
          TextField(
            controller: _sosPhoneController,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: '+61 400 000 000', counterText: '', prefixIcon: Icon(Icons.phone_rounded, color: LKTheme.blue)),
          ),
          const SizedBox(height: 6),
          const Text('This is the blue "DIRECT LINE" button', style: TextStyle(fontSize: 12, color: LKTheme.textMuted)),
          const SizedBox(height: 24),

          _label('Ambulance Number'),
          const SizedBox(height: 6),
          TextField(
            controller: _ambulanceController,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. 000, 911, 112', counterText: '', prefixIcon: Icon(Icons.local_hospital_rounded, color: LKTheme.red)),
          ),
          const SizedBox(height: 6),
          const Text('This is the red "CALL AMBULANCE" button', style: TextStyle(fontSize: 12, color: LKTheme.textMuted)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Page 3: Connect + Subscription
  Widget _buildConnect() {
    return SingleChildScrollView(
      key: const ValueKey('connect'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.people_rounded, size: 52, color: LKTheme.gold),
          const SizedBox(height: 12),
          const Text('Connect Someone', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Enter the code of the person\nyou want to watch over', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.4)),
          const SizedBox(height: 28),

          TextField(
            controller: _connectCodeController,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: LKTheme.gold, letterSpacing: 6),
            decoration: InputDecoration(
              hintText: 'CODE',
              counterText: '',
              hintStyle: TextStyle(fontSize: 32, color: LKTheme.textMuted.withValues(alpha: 0.4), letterSpacing: 6),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Ask them for the code on their screen', style: TextStyle(fontSize: 14, color: LKTheme.textMuted)),
          const SizedBox(height: 32),

          // Subscription info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LKTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LKTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.star_rounded, color: LKTheme.gold, size: 22),
                  SizedBox(width: 8),
                  Text('Free Plan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                ]),
                const SizedBox(height: 8),
                const Text('You can connect to 1 person for free.', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
                const SizedBox(height: 12),
                const Row(children: [
                  Icon(Icons.diamond_rounded, color: LKTheme.gold, size: 22),
                  SizedBox(width: 8),
                  Text('Premium - \$4.99/month', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.gold)),
                ]),
                const SizedBox(height: 8),
                const Text('Connect up to 5 people, no ads, no cooldown.', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
                const SizedBox(height: 12),
                Text('You can upgrade anytime in Systems.', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w600)),
    );
  }
}
