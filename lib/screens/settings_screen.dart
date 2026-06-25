import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        _userName = user.name;
        _userEmail = user.email;
        _userPhone = user.phone;
        _userCode = user.userCode;
        _plan = user.plan;
      });
    }
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
      if (mounted) _showBigMessage('Settings saved!', '', const Color(0xFF27AE60));
    } catch (e) {
      if (mounted) _showBigMessage('Could not save', '$e', const Color(0xFFE74C3C));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              Icon(color == const Color(0xFF27AE60) ? Icons.check_circle_rounded : Icons.error_rounded, size: 72, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 18, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center)],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('YOUR CODE', style: TextStyle(fontSize: 18, color: Color(0xFF95A5A6), fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Text(_userCode!, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFF27AE60), letterSpacing: 6)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Clipboard.setData(ClipboardData(text: _userCode!)); Navigator.pop(ctx); },
                  icon: const Icon(Icons.copy_rounded, size: 22),
                  label: const Text('Copy', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF27AE60), side: const BorderSide(color: Color(0xFF27AE60)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 64, color: Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              const Text('Log Out?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You will need to sign in again.', style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                const Icon(Icons.settings_rounded, color: Color(0xFF7F8C8D), size: 28),
                const SizedBox(width: 10),
                const Expanded(child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                if (widget.onGoHome != null)
                  GestureDetector(
                    onTap: widget.onGoHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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
                    // Profile
                    _card([
                      Row(children: [
                        Container(width: 56, height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF27AE60).withValues(alpha: 0.12)),
                          child: Center(child: Text(
                            _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_userName ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          Text(_userEmail ?? '-', style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                          child: Text(_plan == 'paid' ? 'Premium' : 'Free', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _plan == 'paid' ? const Color(0xFFF39C12) : Colors.grey[500])),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _infoRow(Icons.phone_rounded, 'Phone', _userPhone ?? '-', editable: true),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showCodePopup,
                        child: _infoRow(Icons.link_rounded, 'Your Code', _userCode ?? '-', isCode: true),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Ambulance Number (RED section)
                    _card([
                      const Row(children: [
                        Icon(Icons.local_hospital_rounded, color: Color(0xFFE74C3C), size: 24),
                        SizedBox(width: 10),
                        Text('Ambulance Number', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      ]),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: _ambulanceController,
                        hint: 'e.g. 000, 911, 112',
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xFFE74C3C),
                        maxLength: 20,
                        keyboard: TextInputType.phone,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('This is the red "CALL AMBULANCE" button on home screen', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Emergency Contact (BLUE section)
                    _card([
                      const Row(children: [
                        Icon(Icons.phone_in_talk_rounded, color: Color(0xFF3498DB), size: 24),
                        SizedBox(width: 10),
                        Text('Emergency Contact', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      ]),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: _sosNameController,
                        hint: 'Contact name (e.g. Tom)',
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF3498DB),
                        maxLength: 50,
                      ),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: _sosPhoneController,
                        hint: 'Phone number',
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xFF3498DB),
                        maxLength: 20,
                        keyboard: TextInputType.phone,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('This is the blue "CALL" button on home screen.\nIf empty, uses connected person\'s number.', style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.3)),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Language
                    _card([
                      GestureDetector(
                        onTap: () {},
                        child: Row(children: [
                          const Icon(Icons.language_rounded, color: Color(0xFF27AE60), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Language', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)))),
                          const Text('English', style: TextStyle(fontSize: 16, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Legal
                    _card([
                      _linkRow(Icons.description_rounded, 'Terms and Conditions'),
                      Divider(color: Colors.grey[200], height: 1),
                      _linkRow(Icons.lock_rounded, 'Privacy Policy'),
                    ]),
                    const SizedBox(height: 20),

                    // Save button (BIG)
                    SizedBox(height: 60, child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Save Settings'),
                    )),

                    // Logout (tiny)
                    const SizedBox(height: 16),
                    Center(child: GestureDetector(
                      onTap: _logout,
                      child: Text('Log Out', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    )),

                    const SizedBox(height: 8),
                    Center(child: Text('LifeKnob v1.0.0', style: TextStyle(fontSize: 10, color: Colors.grey[300]))),
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
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool editable = false, bool isCode = false}) {
    return Row(children: [
      Icon(icon, size: 20, color: isCode ? const Color(0xFF27AE60) : const Color(0xFF95A5A6)),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[500])),
      const Spacer(),
      if (editable)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), color: Colors.white),
          child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
        )
      else
        Text(value, style: TextStyle(
          fontSize: 15,
          fontWeight: isCode ? FontWeight.w800 : FontWeight.w500,
          color: isCode ? const Color(0xFF27AE60) : const Color(0xFF2C3E50),
          letterSpacing: isCode ? 2 : 0,
        )),
      if (editable) ...[const SizedBox(width: 4), Icon(Icons.edit_rounded, size: 14, color: Colors.grey[400])],
      if (isCode) ...[const SizedBox(width: 4), Icon(Icons.zoom_in_rounded, size: 16, color: Colors.grey[400])],
    ]);
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    int? maxLength,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[350]),
        prefixIcon: Icon(icon, color: iconColor, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[250]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _linkRow(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)))),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
        ]),
      ),
    );
  }
}
