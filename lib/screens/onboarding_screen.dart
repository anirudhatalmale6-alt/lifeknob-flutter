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
  static const int _totalPages = 6;

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
      final name = _nameController.text.trim();
      if (name.isEmpty) { _showMessage('Please enter your name'); return; }
      if (_emailController.text.trim().isEmpty) { _showMessage('Please enter your email'); return; }
      if (_phoneController.text.trim().isEmpty) { _showMessage('Please enter your phone number'); return; }
      _saveProfile();
      return;
    }
    if (_page == 4) {
      _saveEmergency();
      return;
    }
    if (_page == 5) {
      _saveConnection();
      return;
    }
    if (_page < _totalPages - 1) setState(() => _page++);
  }

  void _back() {
    if (_page > 0) setState(() => _page--);
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
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (mounted) setState(() => _isSaving = false);
    }
    if (mounted) {
      await AuthService().refreshProfile();
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
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.info_rounded, size: 56, color: LKTheme.gold),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        )),
      ])),
    ));
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
            // Logo header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Text('LIFE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1)),
                  const Text('KNOB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 2, height: 1)),
                  const Spacer(),
                  // Progress
                  Text('${_page + 1} / $_totalPages', style: const TextStyle(fontSize: 13, color: LKTheme.textMuted)),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _totalPages,
                  backgroundColor: LKTheme.border,
                  valueColor: const AlwaysStoppedAnimation(LKTheme.gold),
                  minHeight: 4,
                ),
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: [
                  _buildLanguage,
                  _buildWelcome,
                  _buildProfile,
                  _buildCode,
                  _buildEmergency,
                  _buildConnect,
                ][_page](),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      flex: 1,
                      child: SizedBox(height: 52, child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('BACK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      )),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(height: 52, child: Container(
                      decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _next,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                            : Text(
                                _page == _totalPages - 1 ? 'FINISH' : 'NEXT',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF5A3D10), letterSpacing: 1),
                              ),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 0: Language (dropdown)
  Widget _buildLanguage() {
    final languages = ['English', 'Magyar', 'Deutsch', 'Espanol', 'Francais', 'Italiano', 'Portugues'];
    return Padding(
      key: const ValueKey('lang'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LKTheme.goldGradient, boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.25), blurRadius: 20)]),
            child: const Icon(Icons.favorite, color: Color(0xFF5A3D10), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('LifeKnob', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 1)),
          const SizedBox(height: 32),
          const Text('Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: LKTheme.gold, width: 1.5)),
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              dropdownColor: LKTheme.bgCard,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: LKTheme.gold, size: 28),
              style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
              items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) { if (v != null) setState(() => _language = v); },
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Welcome
  Widget _buildWelcome() {
    return SingleChildScrollView(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Center(child: Text('Welcome to LifeKnob', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.gold))),
          const SizedBox(height: 24),
          _welcomeItem(Icons.favorite_rounded, 'What is LifeKnob?', 'A simple app to let your family know you are fine. Press "I AM OKAY" every day.'),
          _welcomeItem(Icons.warning_rounded, 'How it works', 'If you stop pressing, your family will know something might be wrong. Silence is the alarm.'),
          _welcomeItem(Icons.people_rounded, 'Connections', 'Connect with family members using your unique code. They can see when you last pressed OK.'),
          _welcomeItem(Icons.star_rounded, 'Membership', 'Free: 1 connection with ads. Premium (\$4.99/mo): up to 5 connections, no ads.'),
          _welcomeItem(Icons.shield_rounded, 'Your Privacy', 'Your data is only shared with people YOU connect with. Read our Terms & Conditions and Privacy Policy in Settings.'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _welcomeItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.15)),
            child: Icon(icon, size: 22, color: LKTheme.gold),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.4)),
            ],
          )),
        ],
      ),
    );
  }

  // Page 2: Personal Details
  Widget _buildProfile() {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Your Details', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.bgCardLight, border: Border.all(color: LKTheme.gold, width: 2),
                  image: _avatarUrl != null ? DecorationImage(image: NetworkImage('https://lifeknob.com$_avatarUrl'), fit: BoxFit.cover) : null),
                child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 40, color: LKTheme.gold) : null,
              ),
              Positioned(bottom: 0, right: 0, child: Container(width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold, border: Border.all(color: LKTheme.bg, width: 2)),
                child: const Icon(Icons.camera_alt, size: 12, color: Color(0xFF5A3D10)))),
            ]),
          ),
          const SizedBox(height: 6),
          const Text('Upload your photo', style: TextStyle(fontSize: 12, color: LKTheme.textMuted)),
          const SizedBox(height: 20),
          _label('Your Name'), const SizedBox(height: 6),
          TextField(controller: _nameController, maxLength: 50, style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'Your name', counterText: '', prefixIcon: Icon(Icons.person_rounded, color: LKTheme.gold))),
          const SizedBox(height: 14),
          _label('Your Email Address'), const SizedBox(height: 6),
          TextField(controller: _emailController, maxLength: 100, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'your@email.com', counterText: '', prefixIcon: Icon(Icons.email_rounded, color: LKTheme.gold))),
          const SizedBox(height: 14),
          _label('Your Phone Number'), const SizedBox(height: 6),
          TextField(controller: _phoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: '+61 400 000 000', counterText: '', prefixIcon: Icon(Icons.phone_rounded, color: LKTheme.gold))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Page 3: Your Code
  Widget _buildCode() {
    return Padding(
      key: const ValueKey('code'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge_rounded, size: 52, color: LKTheme.gold),
          const SizedBox(height: 16),
          const Text('Your Personal Code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: LKTheme.gold, width: 2),
              boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.15), blurRadius: 20)]),
            child: Text(_userCode ?? '........', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 8)),
          ),
          const SizedBox(height: 28),
          const Text('Please save it or\nwrite it down on a paper.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: LKTheme.red, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 16),
          const Text('Share this code with your family\nso they can connect to you.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: LKTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () { if (_userCode != null) { Clipboard.setData(ClipboardData(text: _userCode!)); _showMessage('Code copied!'); } },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.5))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.copy_rounded, size: 20, color: LKTheme.gold),
                SizedBox(width: 8),
                Text('Copy Code', style: TextStyle(fontSize: 17, color: LKTheme.gold, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Emergency
  Widget _buildEmergency() {
    return SingleChildScrollView(
      key: const ValueKey('emergency'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.health_and_safety_rounded, size: 48, color: LKTheme.red),
          const SizedBox(height: 12),
          const Text('Emergency Contact', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 24),
          _label('Name'), const SizedBox(height: 6),
          TextField(controller: _sosNameController, maxLength: 50, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Contact name', counterText: '', prefixIcon: Icon(Icons.person_rounded, color: LKTheme.blue))),
          const SizedBox(height: 14),
          _label('Phone Number'), const SizedBox(height: 6),
          TextField(controller: _sosPhoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Phone number', counterText: '', prefixIcon: Icon(Icons.phone_rounded, color: LKTheme.blue))),
          const SizedBox(height: 24),
          const Divider(color: LKTheme.border),
          const SizedBox(height: 16),
          const Text('Ambulance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.red)),
          const SizedBox(height: 12),
          _label('Phone Number'), const SizedBox(height: 6),
          TextField(controller: _ambulanceController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. 000, 911, 112', counterText: '', prefixIcon: Icon(Icons.local_hospital_rounded, color: LKTheme.red))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Page 5: Connect + Membership
  Widget _buildConnect() {
    return SingleChildScrollView(
      key: const ValueKey('connect'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.people_rounded, size: 48, color: LKTheme.gold),
          const SizedBox(height: 10),
          const Text('Connect to Other Persons', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Enter the code of someone you want to watch over', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
          const SizedBox(height: 20),
          TextField(
            controller: _connectCodeController,
            maxLength: 8, textCapitalization: TextCapitalization.characters, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: LKTheme.gold, letterSpacing: 6),
            decoration: InputDecoration(hintText: 'CODE', counterText: '',
              hintStyle: TextStyle(fontSize: 30, color: LKTheme.textMuted.withValues(alpha: 0.4), letterSpacing: 6)),
          ),
          const SizedBox(height: 8),
          const Text('Free but with advertising', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
          const SizedBox(height: 20),
          // Membership section
          Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.3))),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Membership', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: LKTheme.gold)),
              SizedBox(height: 10),
              Text('Options:', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('  Free - 1 connection, with ads', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
              SizedBox(height: 4),
              Text('  Premium - \$4.99/month', style: TextStyle(fontSize: 15, color: LKTheme.gold, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Advantages:', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('  - Connect up to 5 people', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
              Text('  - No advertisements', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
              Text('  - No cooldown on switching', style: TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
              SizedBox(height: 10),
              Text('You can upgrade anytime in Set Up.', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Align(alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w600)));
  }
}
