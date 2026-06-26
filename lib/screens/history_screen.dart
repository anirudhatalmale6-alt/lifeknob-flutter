import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/connection_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const HistoryScreen({super.key, this.onGoHome});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Connection> _connections = [];
  bool _isLoading = true;
  String? _error;
  int _maxConnections = 1;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void ensureLoaded() { _loadData(); }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = AuthService().currentUser ?? await AuthService().getSavedUser();
      if (user != null) _maxConnections = user.maxConnections;

      try {
        final siteResp = await ApiService().getSiteSettings();
        final days = int.tryParse('${siteResp['data']?['alert_threshold_days'] ?? '2'}') ?? 2;
        Connection.alertThresholdDays = days;
      } catch (_) {}

      final connResp = await ApiService().getConnections();
      final List connData = connResp['data'] ?? [];

      if (mounted) setState(() {
        _connections = connData.map((e) => Connection.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _connectPeople() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      _showMsg('Please enter both name and code');
      return;
    }
    setState(() => _isAdding = true);
    try {
      final result = await ApiService().connect(code);
      _nameCtrl.clear();
      _codeCtrl.clear();
      if (mounted) {
        setState(() => _isAdding = false);
        final status = result['data']?['connection_status'] ?? 'pending';
        if (status == 'accepted') {
          _showMsg('Connected with $name!\nYou can now see each other\'s check-ins.');
        } else {
          _showMsg('Connection request sent!\nWaiting for $name to add your code.');
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) setState(() => _isAdding = false);
      final msg = '$e';
      if (msg.contains('not found') || msg.contains('404')) {
        _showMsg('This code is not in the system.\nPlease check the code and try again.');
      } else if (msg.contains('already')) {
        _showMsg('You already sent a request to this person.');
      } else if (msg.contains('limit') || msg.contains('403')) {
        _showMsg("You can't connect more people.\nUpgrade your membership plan.");
      } else if (msg.contains('yourself')) {
        _showMsg("You can't connect to yourself.");
      } else {
        _showMsg('Could not connect.\nPlease try again.');
      }
    }
  }

  Future<void> _deleteConnection(Connection conn) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.delete_rounded, size: 48, color: LKTheme.red),
        const SizedBox(height: 12),
        Text('Remove ${conn.name}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: LKTheme.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Remove', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ]),
      ])),
    ));
    if (confirmed != true) return;
    try {
      await ApiService().disconnect(conn.userId);
      if (mounted) _loadData();
    } catch (e) { _showMsg('Error: $e'); }
  }

  Future<void> _editConnection(Connection conn) async {
    final ctrl = TextEditingController(text: conn.name);
    final newName = await showDialog<String>(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Edit name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: LKTheme.bgCardLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: LKTheme.border)),
          child: TextField(controller: ctrl, autofocus: true, maxLength: 50,
            style: const TextStyle(fontSize: 16, color: LKTheme.textPrimary),
            decoration: const InputDecoration(counterText: '', border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ]),
      ])),
    ));
    ctrl.dispose();
    if (newName == null || newName.isEmpty || newName == conn.name) return;
    try {
      await ApiService().updateConnectionName(conn.id, newName);
      if (mounted) _loadData();
    } catch (e) { _showMsg('Error: $e'); }
  }

  void _showMsg(String msg) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.info_rounded, size: 48, color: LKTheme.gold),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(fontSize: 16, color: LKTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LKTheme.gold))
          : _error != null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$_error', style: const TextStyle(color: LKTheme.textMuted, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                GestureDetector(onTap: _loadData, child: const Text('Try Again', style: TextStyle(color: LKTheme.gold, fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
              ]))
            : RefreshIndicator(color: LKTheme.gold, backgroundColor: LKTheme.bgCard, onRefresh: _loadData,
                child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [

                  // Connection rows
                  ..._connections.map(_buildConnectionRow),

                  // Limit message
                  if (_connections.length >= _maxConnections && _connections.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(onGoHome: () { Navigator.pop(context); widget.onGoHome?.call(); }))),
                        child: const Text("You can't connect more people, need membership plan",
                          style: TextStyle(fontSize: 14, color: LKTheme.red, fontWeight: FontWeight.w500)))),

                  // Add new connection row
                  if (_connections.length < _maxConnections) ...[
                    const SizedBox(height: 8),
                    _buildAddRow(),
                  ],

                  // Empty state
                  if (_connections.isEmpty)
                    const Padding(padding: EdgeInsets.only(top: 40),
                      child: Text('Add someone\'s code to connect', style: TextStyle(fontSize: 14, color: LKTheme.textMuted), textAlign: TextAlign.center)),
                ])))),
      ),
    );
  }

  Widget _buildConnectionRow(Connection conn) {
    final isOverdue = conn.isAccepted && conn.isOverdue;
    final isPending = conn.isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LKTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue ? Border.all(color: LKTheme.red, width: 2) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(conn.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isOverdue ? LKTheme.red : LKTheme.textPrimary))),
          Text(conn.userCode, style: TextStyle(fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: isOverdue ? LKTheme.red : LKTheme.gold)),
        ]),
        const SizedBox(height: 6),
        if (isPending)
          const Text('Waiting for the other side to add your code...', style: TextStyle(fontSize: 14, color: LKTheme.textMuted, fontStyle: FontStyle.italic))
        else ...[
          Text('Connected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isOverdue ? LKTheme.red : LKTheme.green)),
          const SizedBox(height: 2),
          Text(
            'Last verified: ${conn.lastCheckInText}',
            style: TextStyle(fontSize: 13, color: isOverdue ? LKTheme.red : LKTheme.green),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          GestureDetector(onTap: () => _editConnection(conn),
            child: const Text('edit', style: TextStyle(fontSize: 13, color: LKTheme.gold, decoration: TextDecoration.underline))),
          const SizedBox(width: 20),
          GestureDetector(onTap: () => _deleteConnection(conn),
            child: const Text('remove', style: TextStyle(fontSize: 13, color: LKTheme.textMuted, decoration: TextDecoration.underline))),
        ]),
      ]),
    );
  }

  InputDecoration _fieldDeco(String hint, IconData icon) {
    return InputDecoration(hintText: hint, counterText: '',
      prefixIcon: Icon(icon, color: LKTheme.gold),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LKTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LKTheme.gold, width: 2)),
      filled: true, fillColor: LKTheme.bgCardLight);
  }

  Widget _buildAddRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Enter the other person's details:", style: TextStyle(fontSize: 14, color: LKTheme.textMuted)),
      const SizedBox(height: 8),
      TextField(controller: _nameCtrl, maxLength: 50,
        style: const TextStyle(fontSize: 16, color: LKTheme.textPrimary),
        decoration: _fieldDeco('Their name (e.g. My Son)', Icons.person_rounded)),
      const SizedBox(height: 10),
      TextField(controller: _codeCtrl, maxLength: 8, textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: LKTheme.gold, letterSpacing: 4),
        decoration: _fieldDeco('Their code', Icons.link_rounded)),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
        onPressed: _isAdding ? null : _connectPeople,
        child: _isAdding
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 2))
          : const Text('+ CONNECT PEOPLE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      )),
    ]);
  }
}
