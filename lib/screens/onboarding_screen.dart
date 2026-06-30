import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  static const int _totalPages = 7;

  String _language = 'English';
  String _langCode = 'en';
  String? _userCode;
  String _selectedPlan = 'free';
  int _maxSlots = 1;
  final List<Map<String, String>> _connectedPeople = [];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sosNameController = TextEditingController();
  final _sosPhoneController = TextEditingController();
  final _ambulanceController = TextEditingController();
  final _connectNameController = TextEditingController();
  final _connectCodeController = TextEditingController();

  bool _isSaving = false;
  String? _avatarUrl;
  final Set<String> _errorFields = {};
  final TranslationService _ts = TranslationService();

  static const _fallbacks = {
    'select_language': 'Select Language', 'next': 'Next', 'back': 'Back', 'finish': 'Finish',
    'welcome_title': 'Welcome to LifeKnob', 'what_is_title': 'What is LifeKnob?',
    'what_is_desc': 'A simple app to let your family know you are fine. Press "I AM OKAY" every day.',
    'how_works_title': 'How it works', 'how_works_desc': 'If you stop pressing, your family will know something might be wrong. Silence is the alarm.',
    'connections_title': 'Connections', 'connections_desc': 'Connect with family members using your unique code. They can see when you last pressed OK.',
    'membership_title': 'Membership', 'membership_desc': 'Free: 1 connection with ads. Premium plans: more connections, no ads.',
    'privacy_title': 'Your Privacy', 'privacy_desc': 'Your data is only shared with people you connect with.',
    'your_details': 'Your Details', 'no_auth_required': 'No authentication required',
    'your_name': 'Your Name', 'your_email': 'Your Email', 'your_phone': 'Your Phone Number',
    'emergency_contacts': 'Emergency Contacts', 'emergency_subtitle': 'Whom you want to call in case of emergency',
    'sos_name': '*Name', 'phone_number': 'Phone Number', 'ambulance': 'Ambulance',
    'select_plan': 'Select Your Plan', 'your_code': 'Your Personal Code',
    'save_code_msg': 'Please save it or write it down on a paper.',
    'share_code_msg': 'Share this code with your family so they can connect to you.',
    'copy_code': 'Copy Code', 'code_copied': 'Code copied!',
    'connect_title': 'Connect to People', 'connect_button': 'Connect People',
    'plan_desc': 'Choose how many people you want to watch over. More connections means more family members can see when you press OK.',
    'change_plan_hint': 'You can change your plan anytime in Settings.',
    'upgrade_plan': 'Upgrade your plan for more connection slots.',
  };
  String _t(String key) {
    final val = _ts.t(key);
    return val == key ? (_fallbacks[key] ?? key) : val;
  }

  Widget _logoWidget({double? width, double? height, String logoKey = 'registration'}) {
    final url = _ts.logoUrl(logoKey);
    if (url != null) {
      final cacheBust = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      return Image.network('$url?v=$cacheBust', width: width, height: height, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height));
    }
    return SizedBox(width: width, height: height);
  }

  @override
  void initState() {
    super.initState();
    _loadLanguages();
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

  Future<void> _loadLanguages() async {
    await _ts.init();
    if (mounted) {
      setState(() {
        _langCode = _ts.currentLang;
        final langs = _ts.availableLanguages;
        final match = langs.where((l) => l['code'] == _langCode);
        if (match.isNotEmpty) _language = match.first['name']!;
      });
    }
  }

  Future<void> _changeLanguage(String langName) async {
    final langs = _ts.availableLanguages;
    final match = langs.where((l) => l['name'] == langName);
    if (match.isEmpty) return;
    final code = match.first['code']!;
    setState(() { _language = langName; _langCode = code; });
    await _ts.setLanguage(code);
    if (mounted) setState(() {});
  }

  void _next() {
    if (_page == 2) { _validateProfile(); return; }
    if (_page == 3) { _validateEmergency(); return; }
    if (_page == 4) { _savePlanAndRegister(); return; }
    if (_page == 6) { _finishConnect(); return; }
    if (_page < _totalPages - 1) setState(() => _page++);
  }

  void _back() { if (_page > 0) setState(() => _page--); }

  void _validateProfile() {
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
    setState(() => _page++);
  }

  void _validateEmergency() {
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
    setState(() => _page++);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateProfile({'name': _nameController.text.trim(), 'email': _emailController.text.trim(), 'phone': _phoneController.text.trim()});
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

  Future<void> _addCode() async {
    _errorFields.clear();
    final name = _connectNameController.text.trim();
    final code = _connectCodeController.text.trim();
    String? msg;
    if (name.isEmpty) { _errorFields.add('connectName'); msg ??= 'Enter a name for this person'; }
    if (code.isEmpty) { _errorFields.add('connectCode'); msg ??= 'Enter their code'; }
    if (_errorFields.isNotEmpty) { setState(() {}); _showMessage(msg!); return; }
    if (_connectedPeople.any((p) => p['code'] == code)) { _showMessage('Already connected to this code'); return; }
    if (_connectedPeople.length >= _maxSlots) { _showMessage('Connection limit reached.\nUpgrade your plan for more slots.'); return; }

    setState(() => _isSaving = true);
    try {
      final result = await ApiService().connect(code);
      if (mounted) {
        _errorFields.clear();
        final connectedName = result['data']?['connected_to']?['name'] ?? name;
        final status = result['data']?['connection_status'] ?? 'pending';
        _connectedPeople.add({'name': connectedName, 'code': code});
        _connectNameController.clear();
        _connectCodeController.clear();
        setState(() => _isSaving = false);
        if (status == 'accepted') {
          _showMessage('Connected with $connectedName!\nYou can now see each other\'s check-ins.');
        } else {
          _showMessage('Request sent!\nWaiting for $connectedName to add your code.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      final errMsg = '$e';
      if (errMsg.contains('404') || errMsg.toLowerCase().contains('not found')) {
        if (mounted) _showMessage('This code is not in the system.\nPlease check the code and try again.');
      } else if (errMsg.contains('already')) {
        if (mounted) _showMessage('You are already connected to this person.');
      } else if (errMsg.contains('limit') || errMsg.contains('403')) {
        if (mounted) _showMessage('Connection limit reached.\nUpgrade your plan for more.');
      } else {
        if (mounted) _showMessage('Could not connect.\n$errMsg');
      }
    }
  }

  Future<void> _savePlanAndRegister() async {
    setState(() => _isSaving = true);
    try {
      final isLoggedIn = await AuthService().isLoggedIn();
      if (!isLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        var deviceId = prefs.getString('device_id');
        if (deviceId == null || deviceId.isEmpty) {
          deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000000).toString().padLeft(6, '0')}';
          await prefs.setString('device_id', deviceId);
        }
        final user = await AuthService().autoRegister(deviceId);
        _userCode = user.userCode;
      }
      await ApiService().updateProfile({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      await ApiService().updateSettings({
        'sos_name': _sosNameController.text.trim(),
        'sos_number': _sosPhoneController.text.trim(),
        'ambulance_number': _ambulanceController.text.trim(),
        'plan': _selectedPlan == 'free' ? 'free' : 'paid',
        'max_connections': _maxSlots,
      });
      final user = await AuthService().refreshProfile();
      _userCode = user.userCode;
    } catch (_) {}
    if (mounted) setState(() { _isSaving = false; _page++; });
  }

  bool _noConnectionWarningShown = false;

  Future<void> _finishConnect() async {
    if (_connectedPeople.isEmpty && !_noConnectionWarningShown) {
      _noConnectionWarningShown = true;
      _showMessage('Nobody can see when you press OK yet.\nYou can add connections later in "People".');
      return;
    }
    await AuthService().refreshProfile();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
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

  bool _isValidEmail(String email) {
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final domainParts = parts[1].toLowerCase().split('.');
    if (domainParts.any((p) => p.length < 2)) return false;
    final tld = domainParts.last;
    const validTlds = ['com','net','org','edu','gov','io','co','us','uk','au','de','fr','es','it','nl','se','no','fi','dk','hu','at','ch','be','pt','ru','cn','jp','kr','in','br','mx','ca','nz','za','info','biz','pro','online','site','app','dev','me','tv','cc','club'];
    if (!validTlds.contains(tld) && tld.length > 4) return false;
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose(); _phoneController.dispose();
    _sosNameController.dispose(); _sosPhoneController.dispose(); _ambulanceController.dispose();
    _connectNameController.dispose(); _connectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003049),
      body: SafeArea(
        child: Column(
          children: [
            if (_page > 0) ...[
              SizedBox(
                height: 84,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, right: 2),
                  child: Row(children: [
                    const Spacer(),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset('assets/images/lifeknob_logo_header.svg', colorFilter: const ColorFilter.mode(LKTheme.gold, BlendMode.srcIn), fit: BoxFit.contain),
                    )),
                  ]),
                ),
              ),
              Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(
                gradient: LinearGradient(colors: [LKTheme.gold.withValues(alpha: 0.05), LKTheme.gold, LKTheme.gold, LKTheme.gold.withValues(alpha: 0.05)]),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 6, 32, 4),
                child: Row(
                  children: List.generate(_totalPages - 1, (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _page ? LKTheme.gold : LKTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: [_buildLanguage, _buildWelcome, _buildProfile, _buildEmergency, _buildMembership, _buildCode, _buildConnect][_page](),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(children: [
                if (_page > 0) Expanded(flex: 1, child: SizedBox(height: 52, child: OutlinedButton(
                  onPressed: _back,
                  style: OutlinedButton.styleFrom(foregroundColor: LKTheme.gold, side: BorderSide(color: LKTheme.gold.withValues(alpha: 0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text(_t('back'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ))),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(flex: _page > 0 ? 1 : 1, child: SizedBox(height: 52, child: Container(
                  decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : (_page == 6 ? _finishConnect : _next),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                        : Text(
                            _page == _totalPages - 1 ? _t('finish') : _t('next'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF5A3D10), letterSpacing: 1),
                          ),
                  ),
                ))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _languageNames {
    final langs = _ts.availableLanguages;
    if (langs.isEmpty) return ['English', 'Magyar', 'Deutsch', 'Espanol', 'Francais', 'Italiano', 'Portugues'];
    return langs.map((l) => l['name']!).toList();
  }

  // Page 0: Language
  Widget _buildLanguage() {
    return Padding(key: const ValueKey('lang'), padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const Spacer(flex: 2),
        SizedBox(width: 220, height: 220, child: _logoWidget(width: 220, height: 220, logoKey: 'registration')),
        const Spacer(flex: 1),
        Text(_t('select_language'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: LKTheme.gold, width: 1.5)),
          child: DropdownButton<String>(value: _language, isExpanded: true, dropdownColor: LKTheme.bgCard, underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: LKTheme.gold, size: 28),
            style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
            items: _languageNames.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) { if (v != null) _changeLanguage(v); })),
        const Spacer(flex: 5),
      ]));
  }

  // Page 1: Welcome
  Widget _buildWelcome() {
    return SingleChildScrollView(key: const ValueKey('welcome'), padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 10),
        Center(child: Text(_t('welcome_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: LKTheme.gold))),
        const SizedBox(height: 12),
        _welcomeItem(Icons.favorite_rounded, _t('what_is_title'), _t('what_is_desc')),
        _welcomeItem(Icons.warning_rounded, _t('how_works_title'), _t('how_works_desc')),
        _welcomeItem(Icons.people_rounded, _t('connections_title'), _t('connections_desc')),
        _welcomeItem(Icons.star_rounded, _t('membership_title'), _t('membership_desc')),
        _welcomeItem(Icons.shield_rounded, _t('privacy_title'), _t('privacy_desc')),
        const SizedBox(height: 8),
      ]));
  }

  Widget _welcomeItem(IconData icon, String title, String desc) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.15)),
        child: Icon(icon, size: 24, color: LKTheme.gold)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary, height: 1.4, fontWeight: FontWeight.w400)),
      ])),
    ]));
  }

  // Page 2: Profile
  Widget _buildProfile() {
    return SingleChildScrollView(key: const ValueKey('profile'), padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 12),
        Text(_t('your_details'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(_t('no_auth_required'), style: TextStyle(fontSize: 14, color: LKTheme.gold.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        const Icon(Icons.qr_code_2_rounded, size: 64, color: LKTheme.textMuted),
        const SizedBox(height: 16),
        _label(_t('your_name')), const SizedBox(height: 6),
        TextField(controller: _nameController, maxLength: 30, style: const TextStyle(fontSize: 20, color: LKTheme.textPrimary, fontWeight: FontWeight.w600),
          onChanged: (_) { if (_errorFields.contains('name')) setState(() => _errorFields.remove('name')); },
          decoration: _inputDeco(_t('name_placeholder'), Icons.person_rounded, LKTheme.gold, 'name')),
        const SizedBox(height: 14),
        _label(_t('your_email')), const SizedBox(height: 6),
        TextField(controller: _emailController, maxLength: 100, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          onChanged: (_) { if (_errorFields.contains('email')) setState(() => _errorFields.remove('email')); },
          decoration: _inputDeco(_t('email_placeholder'), Icons.email_rounded, LKTheme.gold, 'email')),
        const SizedBox(height: 14),
        _label(_t('your_phone')), const SizedBox(height: 6),
        TextField(controller: _phoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          onChanged: (_) { if (_errorFields.contains('phone')) setState(() => _errorFields.remove('phone')); },
          decoration: _inputDeco(_t('phone_placeholder'), Icons.phone_rounded, LKTheme.gold, 'phone')),
        const SizedBox(height: 20),
      ]));
  }

  // Page 5: Your Personal Code
  Widget _buildCode() {
    return Padding(key: const ValueKey('code'), padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.save_rounded, size: 48, color: LKTheme.gold),
        const SizedBox(height: 16),
        Text(_t('your_code'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 24),
        Text(_userCode ?? '........', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 8)),
        const SizedBox(height: 24),
        Text(_t('save_code_msg'), textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: LKTheme.gold, fontWeight: FontWeight.w700, height: 1.4)),
        const SizedBox(height: 12),
        Text(_t('share_code_msg'), textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () { if (_userCode != null) { Clipboard.setData(ClipboardData(text: _userCode!)); _showMessage(_t('code_copied')); } },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: LKTheme.gold)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.copy_rounded, size: 20, color: LKTheme.gold), const SizedBox(width: 8),
              Text(_t('copy_code'), style: const TextStyle(fontSize: 17, color: LKTheme.gold, fontWeight: FontWeight.w600)),
            ]))),
      ]));
  }

  // Page 3: Emergency
  Widget _buildEmergency() {
    return SingleChildScrollView(key: const ValueKey('emergency'), padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 12),
        Text(_t('emergency_contacts'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 10),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.red.withValues(alpha: 0.15)),
          child: const Icon(Icons.local_hospital_rounded, size: 32, color: LKTheme.red),
        ),
        const SizedBox(height: 8),
        Text(_t('emergency_subtitle'), style: TextStyle(fontSize: 14, color: LKTheme.gold.withValues(alpha: 0.7)), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        _label(_t('sos_name')), const SizedBox(height: 6),
        TextField(controller: _sosNameController, maxLength: 50, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          onChanged: (_) { if (_errorFields.contains('sosName')) setState(() => _errorFields.remove('sosName')); },
          decoration: _inputDeco(_t('sos_name_placeholder'), Icons.person_rounded, LKTheme.gold, 'sosName')),
        const SizedBox(height: 14),
        _label(_t('phone_number')), const SizedBox(height: 6),
        TextField(controller: _sosPhoneController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          onChanged: (_) { if (_errorFields.contains('sosPhone')) setState(() => _errorFields.remove('sosPhone')); },
          decoration: _inputDeco(_t('sos_phone_placeholder'), Icons.phone_rounded, LKTheme.gold, 'sosPhone')),
        const SizedBox(height: 24),
        Text(_t('ambulance'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.gold)),
        const SizedBox(height: 12),
        _label(_t('phone_number')), const SizedBox(height: 6),
        TextField(controller: _ambulanceController, maxLength: 20, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
          onChanged: (_) { if (_errorFields.contains('ambulance')) setState(() => _errorFields.remove('ambulance')); },
          decoration: _inputDeco(_t('ambulance_placeholder'), Icons.local_hospital_rounded, LKTheme.red, 'ambulance')),
        const SizedBox(height: 20),
      ]));
  }

  // Page 5: Membership Selection
  Widget _buildMembership() {
    return SingleChildScrollView(key: const ValueKey('membership'), padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 16),
        const Icon(Icons.star_rounded, size: 48, color: LKTheme.gold),
        const SizedBox(height: 10),
        Text(_t('select_plan'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(_t('plan_desc'), textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: LKTheme.textSecondary, height: 1.4)),
        const SizedBox(height: 20),
        _planCard('free', 'Free', [
          'Watch over 1 person',
          'With advertising',
          '3-day cooldown when switching',
        ], null, null),
        const SizedBox(height: 12),
        _planCard('plan5', 'Premium', [
          'Watch over up to 3 people',
          'No advertisements',
          'Switch connections freely',
          'Cancel anytime',
        ], '\$5', '\$50/year'),
        const SizedBox(height: 12),
        _planCard('plan8', 'Premium Plus', [
          'Watch over up to 10 people',
          'No advertisements',
          'Switch connections freely',
          'Priority notifications',
          'Best for large families',
          'Cancel anytime',
        ], '\$8', '\$80/year'),
        const SizedBox(height: 10),
        Text(_t('change_plan_hint'), style: const TextStyle(fontSize: 13, color: LKTheme.textMuted)),
        const SizedBox(height: 16),
      ]));
  }

  Widget _planCard(String planKey, String name, List<String> features, String? monthly, String? yearly) {
    final selected = _selectedPlan == planKey;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPlan = planKey;
        _maxSlots = planKey == 'free' ? 1 : planKey == 'plan5' ? 3 : 10;
      }),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? LKTheme.gold.withValues(alpha: 0.1) : const Color(0xFF002035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? LKTheme.gold : LKTheme.gold.withValues(alpha: 0.2), width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? LKTheme.gold : LKTheme.textMuted, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: selected ? LKTheme.gold : LKTheme.textPrimary))),
            if (monthly != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(monthly, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: LKTheme.gold)),
                const Text('/month', style: TextStyle(fontSize: 11, color: LKTheme.textMuted)),
                if (yearly != null) Text('or $yearly', style: const TextStyle(fontSize: 12, color: LKTheme.teal, fontWeight: FontWeight.w600)),
              ])
            else
              const Text('FREE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: LKTheme.textSecondary)),
          ]),
          const SizedBox(height: 10),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(left: 38, bottom: 4),
            child: Row(children: [
              Icon(Icons.check_rounded, size: 16, color: selected ? LKTheme.gold : LKTheme.textMuted),
              const SizedBox(width: 8),
              Text(f, style: TextStyle(fontSize: 14, color: selected ? LKTheme.textPrimary : LKTheme.textSecondary)),
            ]),
          )),
        ]),
      ),
    );
  }

  // Page 6: Connect to People
  Widget _buildConnect() {
    final remaining = _maxSlots - _connectedPeople.length;
    return SingleChildScrollView(key: const ValueKey('connect'), padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 16),
        Text(_t('connect_title'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: LKTheme.textPrimary)),
        const SizedBox(height: 20),

        ..._connectedPeople.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.3))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LKTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(p['code']!, style: const TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w700, color: LKTheme.gold)),
            ])),
            GestureDetector(
              onTap: () => setState(() => _connectedPeople.remove(p)),
              child: const Icon(Icons.cancel_rounded, size: 24, color: LKTheme.textMuted),
            ),
          ]),
        )),

        if (_connectedPeople.length >= _maxSlots && _connectedPeople.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_t('upgrade_plan'), style: const TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w500))),

        if (remaining > 0) ...[
          const SizedBox(height: 8),
          TextField(controller: _connectNameController, maxLength: 50,
            style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            onChanged: (_) { if (_errorFields.contains('connectName')) setState(() => _errorFields.remove('connectName')); },
            decoration: _inputDeco(_t('connect_name_placeholder'), Icons.person_rounded, LKTheme.gold, 'connectName')),
          const SizedBox(height: 12),
          TextField(controller: _connectCodeController, maxLength: 8, textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: LKTheme.gold, letterSpacing: 4),
            onChanged: (_) { if (_errorFields.contains('connectCode')) setState(() => _errorFields.remove('connectCode')); },
            decoration: _inputDeco(_t('connect_code_placeholder'), Icons.link_rounded, LKTheme.gold, 'connectCode')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: Container(
            decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _addCode,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 2))
                : Text(_t('connect_button'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF5A3D10))),
            ),
          )),
        ],
        const SizedBox(height: 16),
      ]));
  }

  Widget _label(String text) {
    return Align(alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w600)));
  }

  InputDecoration _inputDeco(String hint, IconData icon, Color iconColor, String fieldKey) {
    final hasError = _errorFields.contains(fieldKey);
    return InputDecoration(hintText: hint, counterText: '',
      prefixIcon: Icon(icon, color: hasError ? LKTheme.red : iconColor),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? LKTheme.red : LKTheme.border, width: hasError ? 2 : 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: hasError ? LKTheme.red : LKTheme.gold, width: 2)),
      filled: true, fillColor: LKTheme.bgCardLight);
  }
}
