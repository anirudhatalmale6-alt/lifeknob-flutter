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
  List<Map<String, dynamic>> _pendingRequests = [];
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

  void ensureLoaded() {
    _loadData();
  }

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

      final connResp = await ApiService().getConnections();
      final List connData = connResp['data'] ?? [];

      List<Map<String, dynamic>> pendData = [];
      try {
        final pendResp = await ApiService().getPendingRequests();
        pendData = (pendResp['data'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      } catch (_) {}

      if (mounted) setState(() {
        _connections = connData.map((e) => Connection.fromJson(e)).toList();
        _pendingRequests = pendData;
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
      await ApiService().connect(code);
      _nameCtrl.clear();
      _codeCtrl.clear();
      if (mounted) {
        setState(() => _isAdding = false);
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
        _showMsg('Could not connect: $msg');
      }
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> req) async {
    try {
      await ApiService().acceptRequest(req['connection_id']);
      if (mounted) _loadData();
    } catch (e) { _showMsg('Error: $e'); }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req) async {
    try {
      await ApiService().rejectRequest(req['connection_id']);
      if (mounted) _loadData();
    } catch (_) {}
  }

  Future<void> _deleteConnection(Connection conn) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.delete_rounded, size: 48, color: LKTheme.red),
        const SizedBox(height: 12),
        Text('Delete ${conn.name}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: LKTheme.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ]),
      ])),
    ));
    if (confirmed != true) return;
    try {
      await ApiService().disconnect(conn.userId);
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
    final hasOverdue = _connections.any((c) => c.isAccepted && c.isOverdue);

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
              Icon(hasOverdue ? Icons.warning_rounded : Icons.people_rounded, color: hasOverdue ? LKTheme.red : LKTheme.gold, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(hasOverdue ? 'ALERT' : 'People',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: hasOverdue ? LKTheme.red : LKTheme.textPrimary))),
              if (widget.onGoHome != null) GestureDetector(onTap: widget.onGoHome, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home_rounded, size: 18, color: Color(0xFF5A3D10)),
                  SizedBox(width: 6),
                  Text('Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5A3D10))),
                ]))),
            ])),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: LKTheme.gold))
                : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_rounded, size: 48, color: LKTheme.red),
                      const SizedBox(height: 12),
                      Text('$_error', style: const TextStyle(color: LKTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      SizedBox(width: 180, height: 44, child: ElevatedButton(onPressed: _loadData, child: const Text('Try Again'))),
                    ]))
                  : RefreshIndicator(color: LKTheme.gold, backgroundColor: LKTheme.bgCard, onRefresh: _loadData,
                      child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 16), children: [

                        // Incoming requests
                        if (_pendingRequests.isNotEmpty) ...[
                          const Padding(padding: EdgeInsets.only(bottom: 8, left: 4),
                            child: Text('Requests for you:', style: TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w600))),
                          ..._pendingRequests.map(_buildRequestCard),
                          const SizedBox(height: 12),
                        ],

                        // Connection rows
                        ..._connections.map(_buildConnectionRow),

                        // Limit message
                        if (_connections.length >= _maxConnections && _connections.isNotEmpty)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(onGoHome: () { Navigator.pop(context); widget.onGoHome?.call(); }))),
                              child: const Text("You can't connect more people, need membership plan",
                                style: TextStyle(fontSize: 14, color: LKTheme.red, fontWeight: FontWeight.w500)))),

                        // Add new row
                        if (_connections.length < _maxConnections) ...[
                          const SizedBox(height: 8),
                          _buildAddRow(),
                        ],
                      ])),
            ),
          ],
        ),
      ),
    );
  }

  // Each connection as a row: [name] [code] status delete
  Widget _buildConnectionRow(Connection conn) {
    final isOverdue = conn.isAccepted && conn.isOverdue;
    final isPending = conn.isPending;

    String statusText;
    Color statusColor;
    if (isPending) {
      statusText = 'Connection request\nset up. Waiting\nfor response.';
      statusColor = LKTheme.textMuted;
    } else if (isOverdue) {
      statusText = 'Connected.\nLast verified:\n${conn.lastCheckInText}';
      statusColor = LKTheme.red;
    } else {
      statusText = 'Connected.\nLast verified:\n${conn.lastCheckInText}';
      statusColor = LKTheme.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: LKTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isOverdue ? LKTheme.red : LKTheme.border, width: isOverdue ? 2 : 1),
      ),
      child: Row(children: [
        // Name + Code stacked
        Expanded(flex: 5, child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: LKTheme.bgCardLight, borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isOverdue ? LKTheme.red : LKTheme.border)),
            child: Text(conn.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isOverdue ? LKTheme.red : LKTheme.textPrimary)),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: LKTheme.bgCardLight, borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isOverdue ? LKTheme.red : LKTheme.border)),
            child: Text(conn.userCode, style: TextStyle(fontSize: 13, letterSpacing: 1, color: isOverdue ? LKTheme.red : LKTheme.gold)),
          ),
        ])),
        const SizedBox(width: 6),
        // Status
        Expanded(flex: 3, child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal, height: 1.3))),
        // Delete
        GestureDetector(
          onTap: () => _deleteConnection(conn),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cancel_rounded, size: 26, color: LKTheme.textMuted),
            Text('delete', style: TextStyle(fontSize: 9, color: LKTheme.textMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: LKTheme.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.2)),
          child: Center(child: Text((req['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LKTheme.gold)))),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: LKTheme.textPrimary)),
          const Text('Wants to connect', style: TextStyle(fontSize: 11, color: LKTheme.gold)),
        ])),
        IconButton(icon: const Icon(Icons.check_circle_rounded, color: LKTheme.green, size: 30), onPressed: () => _acceptRequest(req), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        const SizedBox(width: 4),
        IconButton(icon: const Icon(Icons.cancel_rounded, color: LKTheme.red, size: 30), onPressed: () => _rejectRequest(req), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    );
  }

  // Add row: [name] [code] [+ CONNECT PEOPLE button]
  Widget _buildAddRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name + Code fields
      Expanded(child: Column(children: [
        SizedBox(height: 42, child: TextField(controller: _nameCtrl, maxLength: 50,
          style: const TextStyle(fontSize: 15, color: LKTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'name ...',
            hintStyle: TextStyle(fontSize: 15, color: LKTheme.textMuted.withValues(alpha: 0.6)),
            counterText: '', isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true, fillColor: LKTheme.bgCardLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.gold, width: 2)),
          ))),
        const SizedBox(height: 4),
        SizedBox(height: 42, child: TextField(controller: _codeCtrl, maxLength: 8, textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: LKTheme.gold, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: 'code',
            hintStyle: TextStyle(fontSize: 15, color: LKTheme.textMuted.withValues(alpha: 0.5)),
            counterText: '', isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true, fillColor: LKTheme.bgCardLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: LKTheme.gold, width: 2)),
          ))),
      ])),
      const SizedBox(width: 8),
      // Button
      SizedBox(height: 88, child: ElevatedButton(
        onPressed: _isAdding ? null : _connectPeople,
        style: ElevatedButton.styleFrom(
          backgroundColor: LKTheme.gold, foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: _isAdding
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF5A3D10), strokeWidth: 2))
          : const Text('+ CONNECT\nPEOPLE', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.3)),
      )),
    ]);
  }
}
