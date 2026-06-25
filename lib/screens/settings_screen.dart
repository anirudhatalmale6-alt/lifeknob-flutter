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
  final _sosController = TextEditingController();
  final _sosNameController = TextEditingController();
  bool _quietHoursEnabled = false;
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
        _sosController.text = user.sosNumber ?? '';
        _sosNameController.text = user.sosName ?? '';
        _quietHoursEnabled = user.quietHoursEnabled;
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
        'sos_number': _sosController.text.trim(),
        'sos_name': _sosNameController.text.trim(),
        'quiet_hours_enabled': _quietHoursEnabled,
      });
      await AuthService().refreshProfile();
      if (mounted) {
        _showBigMessage('Settings saved!', '', const Color(0xFF27AE60));
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not save', '$e', const Color(0xFFE74C3C));
      }
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
              Icon(color == const Color(0xFF27AE60) ? Icons.check_circle_rounded : Icons.error_rounded, size: 64, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('OK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
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
              const Text('Log Out?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              const Text('You will need to sign in again.', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
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
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _sosController.dispose();
    _sosNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
              child: Row(children: [
                const Icon(Icons.settings_rounded, color: Color(0xFF27AE60), size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)))),
                if (widget.onGoHome != null)
                  GestureDetector(
                    onTap: widget.onGoHome,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  ),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(children: [
                      Row(children: [
                        Container(width: 56, height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF27AE60).withValues(alpha: 0.15)),
                          child: Center(child: Text(
                            _userName != null && _userName!.isNotEmpty ? _userName![0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_userName ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 2),
                          Text(_userEmail ?? '-', style: const TextStyle(fontSize: 14, color: Color(0xFF95A5A6))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _plan == 'paid' ? const Color(0xFFFFF8E1) : const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
                          child: Text(_plan == 'paid' ? 'Premium' : 'Free',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _plan == 'paid' ? const Color(0xFFF39C12) : Colors.grey[500])),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _infoRow(Icons.phone_rounded, 'Phone', _userPhone ?? '-'),
                      if (_userCode != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _userCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied!', style: TextStyle(fontSize: 14)), backgroundColor: Color(0xFF27AE60), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                            );
                          },
                          child: _infoRow(Icons.qr_code_rounded, 'Your Code', _userCode!, highlight: true),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 12),

                    _card(children: [
                      const Row(children: [
                        Icon(Icons.emergency_rounded, color: Color(0xFFE74C3C), size: 22),
                        SizedBox(width: 8),
                        Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      ]),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _sosNameController,
                        maxLength: 50,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Contact name (e.g. Tom)',
                          counterText: '',
                          hintStyle: TextStyle(fontSize: 16, color: Colors.grey[300]),
                          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF3498DB), size: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sosController,
                        keyboardType: TextInputType.phone,
                        maxLength: 20,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          counterText: '',
                          hintStyle: TextStyle(fontSize: 16, color: Colors.grey[300]),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFE74C3C), size: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('This is the "Call" button on your home screen.', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ]),
                    const SizedBox(height: 12),

                    _card(children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Quiet Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                        subtitle: Text('Silence notifications at night', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                        value: _quietHoursEnabled,
                        activeTrackColor: const Color(0xFF27AE60),
                        onChanged: (value) => setState(() => _quietHoursEnabled = value),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    SizedBox(height: 52, child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Save Settings'),
                    )),
                    const SizedBox(height: 12),
                    SizedBox(height: 52, child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE74C3C), side: const BorderSide(color: Color(0xFFE74C3C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      child: const Text('Log Out'),
                    )),
                    const SizedBox(height: 24),
                    Center(child: Text('LifeKnob v1.0.0', style: TextStyle(fontSize: 13, color: Colors.grey[400]))),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(children: [
      Icon(icon, size: 20, color: highlight ? const Color(0xFF27AE60) : const Color(0xFF95A5A6)),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
        color: highlight ? const Color(0xFF27AE60) : const Color(0xFF2C3E50), letterSpacing: highlight ? 2 : 0)),
      if (highlight) ...[const SizedBox(width: 4), Icon(Icons.copy_rounded, size: 14, color: Colors.grey[400])],
    ]);
  }
}
