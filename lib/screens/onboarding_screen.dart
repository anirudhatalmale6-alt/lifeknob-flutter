import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'subscription_screen.dart';

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
  final Set<String> _errorFields = {};

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      _userCode = user.userCode;
      if (user.name.isNotEmpty) _nameController.text = user.name;
      if (user.email.isNotEmpty) _emailController.text = user.email;
      if (user.phone.isNotEmpty) _phoneController.text = user.phone;
      if (user.sosName != null && user.sosName!.isNotEmpty) _sosNameController.text = user.sosName!;
      if (user.sosNumber != null && user.sosNumber!.isNotEmpty) _sosPhoneController.text = user.sosNumber!;
      if (user.ambulanceNumber != null && user.ambulanceNumber!.isNotEmpty) _ambulanceController.text = user.ambulanceNumber!;
      _avatarUrl = user.avatar;
    }
  }

  void _next() {
    if (_page == 2) {
      _errorFields.clear();
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      String? msg;
      if (name.isEmpty) { _errorFields.add('name'); msg ??= 'Please enter your name'; }
      if (email.isEmpty) { _errorFields.add('email'); msg ??= 'Please enter your email'; }
      else if (!_isValidEmail(email)) { _errorFields.add('email'); msg ??= 'Invalid email address'; }
      if (phone.isEmpty) { _errorFields.add('phone'); msg ??= 'Please enter your phone number'; }
      else if (!RegExp(r'^\+?[0-9]{6,20}$').hasMatch(phone)) { _errorFields.add('phone'); msg ??= 'Phone: only + and numbers, no spaces'; }
      if (_errorFields.isNotEmpty) { setState(() {}); _showMessage(msg!); return; }
      _saveProfile();
      return;
    }
    if (_page == 4) {
      _errorFields.clear();
      final sosName = _sosNameController.text.trim();
      final sosPhone = _sosPhoneController.text.trim();
      final ambNum = _ambulanceController.text.trim();
      String? msg;
      if (sosName.isEmpty) { _errorFields.add('sosName'); msg ??= 'Please enter emergency contact name'; }
      if (sosPhone.isEmpty) { _errorFields.add('sosPhone'); msg ??= 'Please enter emergency contact number'; }
      else if (!RegExp(r'^\+?[0-9]{3,20}$').hasMatch(sosPhone)) { _errorFields.add('sosPhone'); msg ??= 'Emergency number: only + and numbers'; }
      if (ambNum.isEmpty) { _errorFields.add('ambulance'); msg ??= 'Please enter ambulance number'; }
      else if (!RegExp(r'^[0-9]{1,10}$').hasMatch(ambNum)) { _errorFields.add('ambulance'); msg ??= 'Ambulance: numbers only (e.g. 000, 911)'; }
      if (_errorFields.isNotEmpty) { setState(() {}); _showMessage(msg!); return; }
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
            onChanged: (_) { if (_errorFields.contains('name')) setState(() => _errorFields.remove('name')); },
            decoration: _inputDeco('Your name', Icons.person_rounded, LKTheme.gold, 'name')),
          const SizedBox(height: 14),
          _label('Your Email Address'), const SizedBox(height: 6),
          TextField(controller: _emailController, maxLength: 100, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            onChanged: (_) { if (_errorFields.contains('email')) setState(() => _errorFields.remove('email')); },
            decoration: _inputDeco('your@email.com', Icons.email_rounded, LKTheme.gold, 'email')),
          const SizedBox(height: 14),
          _label('Your Phone Number'), const SizedBox(height: 6),
          TextField(controller: _phoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            onChanged: (_) { if (_errorFields.contains('phone')) setState(() => _errorFields.remove('phone')); },
            decoration: _inputDeco('+61400000000', Icons.phone_rounded, LKTheme.gold, 'phone')),
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
            onChanged: (_) { if (_errorFields.contains('sosName')) setState(() => _errorFields.remove('sosName')); },
            decoration: _inputDeco('Contact name', Icons.person_rounded, LKTheme.blue, 'sosName')),
          const SizedBox(height: 14),
          _label('Phone Number'), const SizedBox(height: 6),
          TextField(controller: _sosPhoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            onChanged: (_) { if (_errorFields.contains('sosPhone')) setState(() => _errorFields.remove('sosPhone')); },
            decoration: _inputDeco('+61400000000', Icons.phone_rounded, LKTheme.blue, 'sosPhone')),
          const SizedBox(height: 24),
          const Divider(color: LKTheme.border),
          const SizedBox(height: 16),
          const Text('Ambulance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.red)),
          const SizedBox(height: 12),
          _label('Phone Number'), const SizedBox(height: 6),
          TextField(controller: _ambulanceController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            onChanged: (_) { if (_errorFields.contains('ambulance')) setState(() => _errorFields.remove('ambulance')); },
            decoration: _inputDeco('e.g. 000, 911, 112', Icons.local_hospital_rounded, LKTheme.red, 'ambulance')),
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
          const SizedBox(height: 6),
          const Text('Free: 1 connection with advertising', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
          const SizedBox(height: 20),
          // Membership link
          GestureDetector(
            onTap: _openMembership,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.star_rounded, color: LKTheme.gold, size: 24),
                  SizedBox(width: 8),
                  Text('Want to connect more people?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                ]),
                const SizedBox(height: 10),
                const Text('  \$5/month or \$50/year - 3 people', style: TextStyle(fontSize: 15, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('  \$8/month or \$80/year - 10 people', style: TextStyle(fontSize: 15, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Buy Membership', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5A3D10))),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _openMembership() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SubscriptionScreen(onGoHome: () => Navigator.pop(context)),
    ));
  }

  bool _isValidEmail(String email) {
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final domain = parts[1].toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.any((p) => p.length < 2)) return false;
    final tld = domainParts.last;
    const validTlds = ['com','net','org','edu','gov','io','co','us','uk','au','de','fr','es','it','nl','se','no','fi','dk','hu','at','ch','be','pt','ru','cn','jp','kr','in','br','mx','ca','nz','za','info','biz','pro','online','site','app','dev','me','tv','cc','club'];
    if (!validTlds.contains(tld) && tld.length > 4) return false;
    return true;
  }

  Widget _label(String text) {
    return Align(alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w600)));
  }

  InputDecoration _inputDeco(String hint, IconData icon, Color iconColor, String fieldKey) {
    final hasError = _errorFields.contains(fieldKey);
    return InputDecoration(
      hintText: hint, counterText: '',
      prefixIcon: Icon(icon, color: hasError ? LKTheme.red : iconColor),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? LKTheme.red : LKTheme.border, width: hasError ? 2 : 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? LKTheme.red : LKTheme.gold, width: 2)),
      filled: true, fillColor: LKTheme.bgCardLight,
    );
  }
}
