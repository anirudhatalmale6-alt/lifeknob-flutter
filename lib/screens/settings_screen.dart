import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const SettingsScreen({super.key, this.onGoHome});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sosNameController = TextEditingController();
  final _sosPhoneController = TextEditingController();
  final _ambulanceController = TextEditingController();
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userCode;
  String? _plan;
  bool _isSaving = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = AuthService().currentUser ?? await AuthService().getSavedUser();
    if (user != null && mounted) {
      setState(() {
        _sosNameController.text = user.sosName ?? '';
        _sosPhoneController.text = user.sosNumber ?? '';
        _ambulanceController.text = user.ambulanceNumber ?? '';
        _userName = user.name;
        _userEmail = user.email;
        _userPhone = user.phone;
        _userCode = user.userCode;
        _plan = user.plan;
      });
    }
    try {
      final freshUser = await AuthService().refreshProfile();
      if (mounted) {
        setState(() {
          _sosNameController.text = freshUser.sosName ?? '';
          _sosPhoneController.text = freshUser.sosNumber ?? '';
          _ambulanceController.text = freshUser.ambulanceNumber ?? '';
          _userName = freshUser.name;
          _userEmail = freshUser.email;
          _userPhone = freshUser.phone;
          _userCode = freshUser.userCode;
          _plan = freshUser.plan;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateSettings({
        'sos_number': _sosPhoneController.text.trim(),
        'sos_name': _sosNameController.text.trim(),
        'ambulance_number': _ambulanceController.text.trim(),
      });
      await AuthService().refreshProfile();
      if (mounted) _showBigMessage('Settings saved!', '', LKTheme.gold);
    } catch (e) {
      if (mounted) _showBigMessage('Could not save', '$e', LKTheme.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              Icon(color == LKTheme.red ? Icons.error_rounded : Icons.check_circle_rounded, size: 72, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 18, color: LKTheme.textSecondary), textAlign: TextAlign.center)],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: color == LKTheme.gold ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('OK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
      ),
    );
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
              const Text('YOUR CODE', style: TextStyle(fontSize: 18, color: LKTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Text(_userCode!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 6)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
                  icon: const Icon(Icons.copy_rounded, size: 22),
                  label: const Text('Copy', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(foregroundColor: LKTheme.gold, side: const BorderSide(color: LKTheme.gold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: LKTheme.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = ['English', 'Magyar', 'Deutsch', 'Espanol', 'Francais'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
              const SizedBox(height: 16),
              ...languages.map((lang) => ListTile(
                leading: Icon(lang == _language ? Icons.radio_button_checked : Icons.radio_button_off, color: lang == _language ? LKTheme.gold : LKTheme.textMuted),
                title: Text(lang, style: TextStyle(fontSize: 18, color: LKTheme.textPrimary, fontWeight: lang == _language ? FontWeight.w700 : FontWeight.normal)),
                onTap: () { setState(() => _language = lang); Navigator.pop(ctx); },
              )),
              const SizedBox(height: 8),
              const Text('More languages coming soon', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegalPage(String title) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _LegalPage(title: title)));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 64, color: LKTheme.red),
              const SizedBox(height: 16),
              const Text('Log Out?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('You will need to sign in again.', style: TextStyle(fontSize: 18, color: LKTheme.textSecondary)),
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
                  child: const Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    await AuthService().logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void dispose() {
    _sosNameController.dispose();
    _sosPhoneController.dispose();
    _ambulanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                const Icon(Icons.settings_rounded, color: LKTheme.textSecondary, size: 28),
                const SizedBox(width: 10),
                const Expanded(child: Text('Systems', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LKTheme.textPrimary))),
                if (widget.onGoHome != null)
                  GestureDetector(
                    onTap: widget.onGoHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 18, color: Color(0xFF5A3D10)),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5A3D10))),
                      ]),
                    ),
                  ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card([
                      Row(children: [
                        Container(width: 56, height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.15)),
                          child: Center(child: Text(
                            _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LKTheme.gold),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_userName ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
                          Text(_userEmail ?? '-', style: const TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: _plan == 'paid' ? LKTheme.gold : LKTheme.border), borderRadius: BorderRadius.circular(12)),
                          child: Text(_plan == 'paid' ? 'Premium' : 'Free', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _plan == 'paid' ? LKTheme.gold : LKTheme.textMuted)),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _infoRow(Icons.phone_rounded, 'Phone', _userPhone ?? '-'),
                      const SizedBox(height: 8),
                      GestureDetector(onTap: _showCodePopup, child: _infoRow(Icons.link_rounded, 'Your Code', _userCode ?? '-', isCode: true)),
                    ]),
                    const SizedBox(height: 12),

                    _card([
                      const Row(children: [
                        Icon(Icons.local_hospital_rounded, color: LKTheme.red, size: 24),
                        SizedBox(width: 10),
                        Text('Ambulance Number', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
                      ]),
                      const SizedBox(height: 12),
                      _inputField(controller: _ambulanceController, hint: 'e.g. 000, 911, 112', icon: Icons.phone_rounded, iconColor: LKTheme.red, maxLength: 20, keyboard: TextInputType.phone),
                      const Padding(padding: EdgeInsets.only(top: 6), child: Text('Red "CALL AMBULANCE" button on home', style: TextStyle(fontSize: 12, color: LKTheme.textMuted))),
                    ]),
                    const SizedBox(height: 12),

                    _card([
                      const Row(children: [
                        Icon(Icons.phone_in_talk_rounded, color: LKTheme.blue, size: 24),
                        SizedBox(width: 10),
                        Text('Emergency Contact', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
                      ]),
                      const SizedBox(height: 12),
                      _inputField(controller: _sosNameController, hint: 'Contact name', icon: Icons.person_rounded, iconColor: LKTheme.blue, maxLength: 50),
                      const SizedBox(height: 8),
                      _inputField(controller: _sosPhoneController, hint: 'Phone number', icon: Icons.phone_rounded, iconColor: LKTheme.blue, maxLength: 20, keyboard: TextInputType.phone),
                      const Padding(padding: EdgeInsets.only(top: 6), child: Text('Blue "DIRECT LINE" button on home', style: TextStyle(fontSize: 12, color: LKTheme.textMuted))),
                    ]),
                    const SizedBox(height: 12),

                    _card([
                      GestureDetector(
                        onTap: _showLanguageSelector,
                        child: Row(children: [
                          const Icon(Icons.language_rounded, color: LKTheme.gold, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Language', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: LKTheme.textPrimary))),
                          Text(_language, style: const TextStyle(fontSize: 16, color: LKTheme.gold, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: LKTheme.textMuted, size: 22),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    _card([
                      GestureDetector(onTap: () => _showLegalPage('Terms and Conditions'), child: _linkRow(Icons.description_rounded, 'Terms and Conditions')),
                      Divider(color: LKTheme.border, height: 1),
                      GestureDetector(onTap: () => _showLegalPage('Privacy Policy'), child: _linkRow(Icons.lock_rounded, 'Privacy Policy')),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(height: 60, child: Container(
                      decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF5A3D10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                            : const Text('Save Settings'),
                      ),
                    )),

                    const SizedBox(height: 16),
                    Center(child: GestureDetector(onTap: _logout, child: const Text('Log Out', style: TextStyle(fontSize: 12, color: LKTheme.textMuted)))),
                    const SizedBox(height: 8),
                    const Center(child: Text('LifeKnob v1.0.0', style: TextStyle(fontSize: 10, color: LKTheme.textMuted))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: LKTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isCode = false}) {
    return Row(children: [
      Icon(icon, size: 20, color: isCode ? LKTheme.gold : LKTheme.textMuted),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 15, color: LKTheme.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: isCode ? FontWeight.w800 : FontWeight.w500, color: isCode ? LKTheme.gold : LKTheme.textPrimary, letterSpacing: isCode ? 2 : 0)),
      if (isCode) ...[const SizedBox(width: 4), const Icon(Icons.zoom_in_rounded, size: 16, color: LKTheme.textMuted)],
    ]);
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, required Color iconColor, int? maxLength, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
      decoration: InputDecoration(hintText: hint, counterText: '', prefixIcon: Icon(icon, color: iconColor, size: 22)),
    );
  }

  Widget _linkRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: LKTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: LKTheme.textPrimary))),
        const Icon(Icons.chevron_right_rounded, color: LKTheme.textMuted, size: 22),
      ]),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  const _LegalPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final bool isTerms = title.contains('Terms');
    final String content = isTerms ? _termsContent : _privacyContent;

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.bgCard), child: const Icon(Icons.arrow_back_rounded, size: 24, color: LKTheme.textPrimary)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary))),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Text(content, style: const TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.6)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
              child: SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK - Go Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )),
            ),
          ],
        ),
      ),
    );
  }

  static const String _termsContent = '''Terms and Conditions for LifeKnob\n\nLast updated: June 2026\n\n1. Acceptance of Terms\nBy using LifeKnob, you agree to these Terms and Conditions.\n\n2. Service Description\nLifeKnob is a daily check-in app designed for elderly users and their families. Users press "I'm OK" to let connected people know they are fine. The app is not a medical device.\n\n3. User Accounts\nYou must provide accurate information when creating an account.\n\n4. Connections\nFree users may connect to 1 person. Premium users may connect to up to 5 people.\n\n5. Subscriptions\nPremium features are available through monthly or yearly subscriptions.\n\n6. Emergency Features\nThe call buttons dial phone numbers you have configured. LifeKnob is not responsible for emergency response.\n\n7. Privacy\nYour check-in data is shared only with your connected users.\n\n8. Limitation of Liability\nLifeKnob is provided "as is" without warranties.\n\n9. Contact\nFor questions, please contact us through the app.''';

  static const String _privacyContent = '''Privacy Policy for LifeKnob\n\nLast updated: June 2026\n\n1. Information We Collect\nAccount information: name, email, phone number.\nCheck-in data: timestamps of your OK presses.\nConnection data: who you are connected to.\n\n2. How We Use Your Information\nTo provide the check-in service and notify your connected people.\n\n3. Information Sharing\nWe share your check-in status ONLY with people you have explicitly connected with.\n\n4. Data Storage\nYour data is stored securely on our servers.\n\n5. Your Rights\nYou can view, update, or delete your information at any time.\n\n6. Security\nWe use industry-standard security measures.\n\n7. Contact\nFor privacy-related questions, please contact us through the app.''';
}
