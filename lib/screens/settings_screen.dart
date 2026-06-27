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
      if (mounted) _showBigMessage('Settings saved!', '', LKTheme.teal);
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
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: LKTheme.glassCard(borderColor: color.withValues(alpha: 0.3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
                child: Icon(color == LKTheme.red ? Icons.error_rounded : Icons.check_circle_rounded, size: 56, color: color),
              ),
              const SizedBox(height: 20),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 16, color: LKTheme.textSecondary), textAlign: TextAlign.center)],
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, height: 52, child: Container(
                decoration: BoxDecoration(
                  gradient: color == LKTheme.red ? LKTheme.redGradient : LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('OK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
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
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: LKTheme.glassCard(borderColor: LKTheme.gold.withValues(alpha: 0.3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('YOUR CODE', style: TextStyle(fontSize: 16, color: LKTheme.textSecondary, fontWeight: FontWeight.w500, letterSpacing: 1)),
              const SizedBox(height: 16),
              Text(_userCode!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: LKTheme.gold, letterSpacing: 6)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
                  icon: const Icon(Icons.copy_rounded, size: 22),
                  label: const Text('Copy', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(foregroundColor: LKTheme.gold, side: BorderSide(color: LKTheme.gold.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF5A3D10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
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
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: LKTheme.glassCard(borderColor: LKTheme.gold.withValues(alpha: 0.2)),
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

  Future<void> _startAgain() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: LKTheme.glassCard(borderColor: LKTheme.gold.withValues(alpha: 0.2)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.1)),
                child: const Icon(Icons.refresh_rounded, size: 48, color: LKTheme.gold),
              ),
              const SizedBox(height: 20),
              const Text('Start Again?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('Go through the setup steps\nagain to review or update\nyour details.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: LKTheme.textSecondary, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: Container(
                decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF5A3D10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Start Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(height: 8),
              Center(child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 15, color: LKTheme.textMuted)),
              )),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LKTheme.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: LKTheme.textSecondary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Set Up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: LKTheme.textPrimary))),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LKTheme.premiumCard,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 56, height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LKTheme.goldGradient,
                              boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.2), blurRadius: 8)],
                            ),
                            child: Center(child: Text(
                              _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A3D10)),
                            )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_userName ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(_userEmail ?? '-', style: const TextStyle(fontSize: 13, color: LKTheme.textSecondary)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _plan == 'paid' ? LKTheme.gold.withValues(alpha: 0.1) : Colors.transparent,
                              border: Border.all(color: _plan == 'paid' ? LKTheme.gold.withValues(alpha: 0.4) : LKTheme.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_plan == 'paid' ? 'Premium' : 'Free', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _plan == 'paid' ? LKTheme.gold : LKTheme.textMuted)),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: LKTheme.bgCardLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(children: [
                            _infoRow(Icons.phone_rounded, 'Phone', _userPhone ?? '-'),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: LKTheme.border.withValues(alpha: 0.5), height: 1)),
                            GestureDetector(onTap: _showCodePopup, child: _infoRow(Icons.link_rounded, 'Your Code', _userCode ?? '-', isCode: true)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // Ambulance card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LKTheme.premiumCard,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.red.withValues(alpha: 0.1)),
                            child: const Icon(Icons.local_hospital_rounded, color: LKTheme.red, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Ambulance Number', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 14),
                        _inputField(controller: _ambulanceController, hint: 'e.g. 000, 911, 112', icon: Icons.phone_rounded, iconColor: LKTheme.red, maxLength: 20, keyboard: TextInputType.phone),
                        const Padding(padding: EdgeInsets.only(top: 8), child: Text('Red "CALL AMBULANCE" button on home', style: TextStyle(fontSize: 12, color: LKTheme.textMuted))),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // Emergency contact card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: LKTheme.premiumCard,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.blue.withValues(alpha: 0.1)),
                            child: const Icon(Icons.phone_in_talk_rounded, color: LKTheme.blue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Emergency Contact', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LKTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 14),
                        _inputField(controller: _sosNameController, hint: 'Contact name', icon: Icons.person_rounded, iconColor: LKTheme.blue, maxLength: 50),
                        const SizedBox(height: 10),
                        _inputField(controller: _sosPhoneController, hint: 'Phone number', icon: Icons.phone_rounded, iconColor: LKTheme.blue, maxLength: 20, keyboard: TextInputType.phone),
                        const Padding(padding: EdgeInsets.only(top: 8), child: Text('Blue "DIRECT LINE" button on home', style: TextStyle(fontSize: 12, color: LKTheme.textMuted))),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // Language + Legal
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: LKTheme.premiumCard,
                      child: Column(children: [
                        GestureDetector(
                          onTap: _showLanguageSelector,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(children: [
                              Icon(Icons.language_rounded, color: LKTheme.gold.withValues(alpha: 0.7), size: 22),
                              const SizedBox(width: 14),
                              const Expanded(child: Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LKTheme.textPrimary))),
                              Text(_language, style: TextStyle(fontSize: 15, color: LKTheme.gold.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, color: LKTheme.textMuted, size: 22),
                            ]),
                          ),
                        ),
                        Divider(color: LKTheme.border.withValues(alpha: 0.5), height: 1, indent: 20, endIndent: 20),
                        GestureDetector(onTap: () => _showLegalPage('Terms and Conditions'), child: _linkRow(Icons.description_rounded, 'Terms and Conditions')),
                        Divider(color: LKTheme.border.withValues(alpha: 0.5), height: 1, indent: 20, endIndent: 20),
                        GestureDetector(onTap: () => _showLegalPage('Privacy Policy'), child: _linkRow(Icons.lock_rounded, 'Privacy Policy')),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(height: 56, child: Container(
                      decoration: BoxDecoration(
                        gradient: LKTheme.goldGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: LKTheme.gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: const Color(0xFF5A3D10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 3))
                            : const Text('Save Settings'),
                      ),
                    )),

                    const SizedBox(height: 20),
                    Center(child: GestureDetector(onTap: _startAgain, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LKTheme.border),
                      ),
                      child: const Text('Start Again', style: TextStyle(fontSize: 13, color: LKTheme.textMuted, fontWeight: FontWeight.w500)),
                    ))),
                    const SizedBox(height: 12),
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

  Widget _infoRow(IconData icon, String label, String value, {bool isCode = false}) {
    return Row(children: [
      Icon(icon, size: 18, color: isCode ? LKTheme.gold : LKTheme.textMuted),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: isCode ? FontWeight.w800 : FontWeight.w500, color: isCode ? LKTheme.gold : LKTheme.textPrimary, letterSpacing: isCode ? 2 : 0)),
      if (isCode) ...[const SizedBox(width: 4), Icon(Icons.zoom_in_rounded, size: 14, color: LKTheme.textMuted.withValues(alpha: 0.6))],
    ]);
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, required Color iconColor, int? maxLength, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 17, color: LKTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LKTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 2)),
        filled: true,
        fillColor: LKTheme.bgCardLight,
      ),
    );
  }

  Widget _linkRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(children: [
        Icon(icon, size: 18, color: LKTheme.textMuted),
        const SizedBox(width: 14),
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
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: LKTheme.bgCard, border: Border.all(color: LKTheme.border)), child: const Icon(Icons.arrow_back_rounded, size: 22, color: LKTheme.textPrimary)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary))),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Text(content, style: const TextStyle(fontSize: 15, color: LKTheme.textSecondary, height: 1.6)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
              child: SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('BACK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
