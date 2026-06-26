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
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Connection> _connections = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;
  int _maxConnections = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = AuthService().currentUser ?? await AuthService().getSavedUser();
      if (user != null) _maxConnections = user.maxConnections;

      final connResp = await ApiService().getConnections();
      final List connData = connResp['data'] ?? [];

      final pendResp = await ApiService().getPendingRequests();
      final List pendData = pendResp['data'] ?? [];

      if (mounted) {
        setState(() {
          _connections = connData.map((e) => Connection.fromJson(e)).toList();
          _pendingRequests = pendData.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _addConnection() async {
    if (_connections.length >= _maxConnections) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SubscriptionScreen(onGoHome: () { Navigator.pop(context); widget.onGoHome?.call(); }),
      ));
      return;
    }

    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: LKTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_add_rounded, size: 44, color: LKTheme.gold),
          const SizedBox(height: 12),
          const Text('Add Person', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Your name and photo will be\nsent as a connection request.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
          const SizedBox(height: 18),
          TextField(controller: nameCtrl, maxLength: 50, style: const TextStyle(fontSize: 18, color: LKTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Their name', counterText: '', prefixIcon: Icon(Icons.person_rounded, color: LKTheme.gold))),
          const SizedBox(height: 10),
          TextField(controller: codeCtrl, maxLength: 8, textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: LKTheme.gold), textAlign: TextAlign.center,
            decoration: InputDecoration(hintText: 'CODE', counterText: '', hintStyle: TextStyle(fontSize: 24, color: LKTheme.textMuted.withValues(alpha: 0.4), letterSpacing: 4))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(context, {'name': nameCtrl.text.trim(), 'code': codeCtrl.text.trim()}),
              style: ElevatedButton.styleFrom(backgroundColor: LKTheme.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Send Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          ]),
        ])),
      ),
    );

    if (result == null || result['code']!.isEmpty) return;

    try {
      await ApiService().connect(result['code']!);
      if (mounted) { _showBigMessage('Request sent!', 'Waiting for them to accept.', LKTheme.gold); _loadData(); }
    } catch (e) {
      final msg = '$e';
      if (msg.contains('404') || msg.contains('not found')) {
        if (mounted) _showBigMessage('Code not found', 'Make sure the person has the app installed and shared the correct code.', LKTheme.gold);
      } else {
        if (mounted) _showBigMessage('Could not connect', msg, LKTheme.red);
      }
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> req) async {
    try {
      await ApiService().acceptRequest(req['connection_id']);
      if (mounted) { _showBigMessage('Accepted!', '${req['name']} is now connected.', LKTheme.green); _loadData(); }
    } catch (e) { if (mounted) _showBigMessage('Error', '$e', LKTheme.red); }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req) async {
    try {
      await ApiService().rejectRequest(req['connection_id']);
      if (mounted) { _loadData(); }
    } catch (e) { if (mounted) _showBigMessage('Error', '$e', LKTheme.red); }
  }

  Future<void> _disconnectPerson(Connection conn) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.link_off_rounded, size: 56, color: LKTheme.gold),
        const SizedBox(height: 16),
        Text('Disconnect ${conn.name}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
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
    } catch (e) { if (mounted) _showBigMessage('Error', '$e', LKTheme.red); }
  }

  void _showBigMessage(String title, String message, Color color) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: LKTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(color == LKTheme.red ? Icons.error_rounded : Icons.check_circle_rounded, size: 56, color: color),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 16, color: LKTheme.textSecondary), textAlign: TextAlign.center)],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: color == LKTheme.gold ? Colors.black : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('OK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        )),
      ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final acceptedConns = _connections.where((c) => c.isAccepted).toList();
    final pendingConns = _connections.where((c) => c.isPending).toList();
    final hasOverdue = acceptedConns.any((c) => c.isOverdue);

    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
              Icon(hasOverdue ? Icons.warning_rounded : Icons.people_rounded, color: hasOverdue ? LKTheme.red : LKTheme.gold, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(hasOverdue ? 'ALERT' : 'People',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: hasOverdue ? LKTheme.red : LKTheme.textPrimary))),
              GestureDetector(onTap: _addConnection, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF5A3D10)),
                  SizedBox(width: 6),
                  Text('Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF5A3D10))),
                ]),
              )),
            ])),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: LKTheme.gold))
                  : _error != null
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.error_rounded, size: 56, color: LKTheme.red),
                          const SizedBox(height: 16),
                          SizedBox(width: 200, height: 48, child: ElevatedButton(onPressed: _loadData, child: const Text('Try Again'))),
                        ]))
                      : RefreshIndicator(color: LKTheme.gold, backgroundColor: LKTheme.bgCard, onRefresh: _loadData,
                          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                            // Pending incoming requests
                            if (_pendingRequests.isNotEmpty) ...[
                              const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Requests for you:', style: TextStyle(fontSize: 15, color: LKTheme.gold, fontWeight: FontWeight.w600))),
                              ..._pendingRequests.map((r) => _buildRequestCard(r)),
                              const SizedBox(height: 12),
                            ],
                            // Connected
                            if (acceptedConns.isNotEmpty) ...[
                              const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Connected:', style: TextStyle(fontSize: 15, color: LKTheme.green, fontWeight: FontWeight.w600))),
                              ...acceptedConns.map((c) => _buildConnectedCard(c)),
                            ],
                            // Pending outgoing
                            if (pendingConns.isNotEmpty) ...[
                              const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Text('Waiting for acceptance:', style: TextStyle(fontSize: 15, color: LKTheme.textMuted, fontWeight: FontWeight.w600))),
                              ...pendingConns.map((c) => _buildPendingCard(c)),
                            ],
                            if (acceptedConns.isEmpty && pendingConns.isEmpty && _pendingRequests.isEmpty)
                              Padding(padding: const EdgeInsets.only(top: 60), child: Column(children: [
                                Icon(Icons.people_outline_rounded, size: 64, color: LKTheme.textMuted.withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                const Text('No connections yet', style: TextStyle(fontSize: 18, color: LKTheme.textMuted)),
                                const SizedBox(height: 8),
                                const Text('Tap "+ Add" to connect with someone', style: TextStyle(fontSize: 14, color: LKTheme.textMuted)),
                              ])),
                          ])),
            ),

            // Home button
            if (widget.onGoHome != null) Padding(padding: const EdgeInsets.fromLTRB(32, 4, 32, 12), child: SizedBox(width: double.infinity, height: 48,
              child: Container(decoration: BoxDecoration(gradient: LKTheme.goldGradient, borderRadius: BorderRadius.circular(24)),
                child: ElevatedButton.icon(onPressed: widget.onGoHome,
                  icon: const Icon(Icons.home_rounded, size: 22, color: Color(0xFF5A3D10)),
                  label: const Text('Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A3D10))),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))))))),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: LKTheme.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: LKTheme.gold.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.gold.withValues(alpha: 0.2)),
          child: Center(child: Text((req['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.gold)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LKTheme.textPrimary)),
          const Text('Wants to connect with you', style: TextStyle(fontSize: 13, color: LKTheme.gold)),
        ])),
        IconButton(icon: const Icon(Icons.check_circle_rounded, color: LKTheme.green, size: 32), onPressed: () => _acceptRequest(req)),
        IconButton(icon: const Icon(Icons.cancel_rounded, color: LKTheme.red, size: 32), onPressed: () => _rejectRequest(req)),
      ]),
    );
  }

  Widget _buildConnectedCard(Connection conn) {
    final isOverdue = conn.isOverdue;
    return GestureDetector(
      onTap: () => _disconnectPerson(conn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isOverdue ? LKTheme.red.withValues(alpha: 0.1) : LKTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: isOverdue ? LKTheme.red.withValues(alpha: 0.3) : LKTheme.border)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isOverdue ? LKTheme.red : LKTheme.green, width: 2), color: (isOverdue ? LKTheme.red : LKTheme.green).withValues(alpha: 0.1)),
            child: Icon(isOverdue ? Icons.warning_rounded : Icons.check_rounded, color: isOverdue ? LKTheme.red : LKTheme.green, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(conn.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LKTheme.textPrimary)),
            Text(isOverdue ? 'NOT checked in!' : 'OK', style: TextStyle(fontSize: 13, color: isOverdue ? LKTheme.red : LKTheme.green)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(conn.lastCheckInText, style: TextStyle(fontSize: 13, color: isOverdue ? LKTheme.red : LKTheme.textMuted, fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal)),
            Text(conn.userCode, style: const TextStyle(fontSize: 11, color: LKTheme.textMuted, letterSpacing: 1)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPendingCard(Connection conn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: LKTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: LKTheme.border)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.textMuted.withValues(alpha: 0.15)),
          child: const Icon(Icons.hourglass_top_rounded, color: LKTheme.textMuted, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(conn.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LKTheme.textPrimary)),
          const Text('Waiting for acceptance', style: TextStyle(fontSize: 13, color: LKTheme.textMuted)),
        ])),
        Text(conn.userCode, style: const TextStyle(fontSize: 11, color: LKTheme.textMuted, letterSpacing: 1)),
      ]),
    );
  }
}
