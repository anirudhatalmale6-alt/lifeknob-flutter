import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/connection_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/ad_widgets.dart';
import 'subscription_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  final void Function(int)? onTabChange;
  const HistoryScreen({super.key, this.onGoHome, this.onTabChange});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  List<Connection> _connections = [];
  bool _isLoading = true;
  String? _error;
  int _maxConnections = 1;
  final _codeCtrl = TextEditingController();
  bool _isAdding = false;
  bool _isFreeUser = true;
  bool _showBumperAd = false;

  // Gold accent on all plans per Tom's appfaces sheet (free/paid differ by the ad, not colour).
  Color get _accent => LKTheme.gold;
  LinearGradient get _accentGradient => LKTheme.goldGradient;
  Color get _accentDark => const Color(0xFF5A3D10);
  DateTime? _pageOpenTime;
  String? _bannerAdImage;
  String? _bannerAdUrl;
  String? _bumperAdImage;
  String? _bumperAdUrl;
  int _bumperDelaySeconds = 30;

  int get _activeCount => _connections.where((c) => !c.isInactive).length;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void ensureLoaded() {
    _pageOpenTime = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = AuthService().currentUser ?? await AuthService().getSavedUser();
      if (user != null) {
        _maxConnections = user.maxConnections;
        _isFreeUser = user.isFree;
      }

      try {
        final siteResp = await ApiService().getSiteSettings();
        final data = siteResp['data'] ?? {};
        final days = int.tryParse('${data['alert_threshold_days'] ?? '2'}') ?? 2;
        Connection.alertThresholdDays = days;
        if (mounted) {
          final img = '${data['banner_ad_image'] ?? ''}';
          _bannerAdImage = img.isNotEmpty ? 'https://lifeknob.com$img' : null;
          _bannerAdUrl = data['banner_ad_url'];
          final bImg = '${data['bumper_ad_image'] ?? ''}';
          _bumperAdImage = bImg.isNotEmpty ? 'https://lifeknob.com$bImg' : null;
          _bumperAdUrl = data['bumper_ad_url'];
          _bumperDelaySeconds = int.tryParse('${data['bumper_delay_seconds'] ?? '30'}') ?? 30;
        }
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
    // Code only — the name comes from the database. The person is identified by
    // their 6-letter personal code; we never ask the user to type a name.
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMsg('Please enter their code');
      return;
    }
    setState(() => _isAdding = true);
    try {
      final result = await ApiService().connect(code);
      _codeCtrl.clear();
      if (mounted) {
        setState(() => _isAdding = false);
        final data = result['data'] ?? {};
        final status = data['connection_status'] ?? 'pending';
        // Name resolved from the database for the entered code.
        final theirName = data['connected_to']?['name'] ?? 'them';
        if (status == 'accepted') {
          _showMsg('Connected with $theirName!\nYou can now see each other\'s check-ins.');
        } else {
          _showMsg('Request sent to $theirName.\nYou\'ll connect once they add your code too.');
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
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: LKTheme.dialogFrame(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.red.withValues(alpha: 0.1)),
            child: Icon(Icons.person_remove_rounded, size: 36, color: LKTheme.red),
          ),
          const SizedBox(height: 16),
          Text('Remove ${conn.name}?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('They will see you as disconnected', style: TextStyle(fontSize: 14, color: LKTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(gradient: LKTheme.redGradient, borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Remove', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            )),
          ]),
        ]),
      ),
    ));
    if (confirmed != true) return;
    try {
      await ApiService().disconnect(conn.userId);
      if (mounted) _loadData();
    } catch (e) { _showMsg('Error: $e'); }
  }

  Future<void> _editConnection(Connection conn) async {
    final ctrl = TextEditingController(text: conn.name);
    final accent = _accent;
    final accentGrad = _accentGradient;
    final accentDk = _accentDark;
    final newName = await showDialog<String>(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: LKTheme.dialogFrame(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Edit name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LKTheme.textPrimary)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: LKTheme.bgCardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: LKTheme.border)),
            child: TextField(controller: ctrl, autofocus: true, maxLength: 50,
              style: TextStyle(fontSize: 16, color: LKTheme.textPrimary),
              decoration: const InputDecoration(counterText: '', border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: LKTheme.textSecondary, side: const BorderSide(color: LKTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 12),
            Expanded(child: Container(
              decoration: BoxDecoration(gradient: accentGrad, borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: accentDk, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            )),
          ]),
        ]),
      ),
    ));
    ctrl.dispose();
    if (newName == null || newName.isEmpty || newName == conn.name) return;
    try {
      await ApiService().updateConnectionName(conn.id, newName);
      if (mounted) _loadData();
    } catch (e) { _showMsg('Error: $e'); }
  }

  void _showMsg(String msg) {
    final accent = _accent;
    final accentGrad = _accentGradient;
    final accentDk = _accentDark;
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: LKTheme.dialogFrame(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.1)),
            child: Icon(Icons.info_rounded, size: 36, color: accent),
          ),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(fontSize: 16, color: LKTheme.textPrimary, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48, child: Container(
            decoration: BoxDecoration(gradient: accentGrad, borderRadius: BorderRadius.circular(14)),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: accentDk, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          )),
        ]),
      ),
    ));
  }

  void _checkBumperAdTime() {
    if (!_isFreeUser || _showBumperAd || _pageOpenTime == null) return;
    final elapsed = DateTime.now().difference(_pageOpenTime!).inSeconds;
    if (elapsed >= _bumperDelaySeconds) {
      setState(() => _showBumperAd = true);
      _pageOpenTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFreeUser && _pageOpenTime != null && !_showBumperAd) {
      Future.delayed(const Duration(seconds: 1), () { if (mounted) _checkBumperAdTime(); });
    }
    return Scaffold(
      backgroundColor: LKTheme.bg,
      body: Stack(children: [SafeArea(
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: LKTheme.red.withValues(alpha: 0.1)),
                  child: Icon(Icons.wifi_off_rounded, size: 48, color: LKTheme.red),
                ),
                const SizedBox(height: 16),
                Text('$_error', style: const TextStyle(color: LKTheme.textMuted, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                GestureDetector(onTap: _loadData, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withValues(alpha: 0.5))),
                  child: Text('Try Again', style: TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w600)),
                )),
              ]))
            : RefreshIndicator(color: _accent, backgroundColor: LKTheme.bgCard, onRefresh: _loadData,
                child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [

                  // Page title - matching premium style
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.people_rounded, color: _accent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Text('CONNECT TO PEOPLE', style: LKTheme.h1(size: 22, color: LKTheme.gold, letterSpacing: 1.5))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: _accentGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_activeCount / $_maxConnections',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _accentDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Connection cards
                  ..._connections.map(_buildConnectionCard),

                  // Limit message
                  if (_activeCount >= _maxConnections && _connections.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen(onGoHome: () { Navigator.pop(context); widget.onGoHome?.call(); }))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: LKTheme.gold.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: LKTheme.gold.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, size: 20, color: LKTheme.gold.withValues(alpha: 0.7)),
                              const SizedBox(width: 10),
                              Expanded(child: Text("Upgrade plan for more connections", style: TextStyle(fontSize: 14, color: LKTheme.gold, fontWeight: FontWeight.w500))),
                              Icon(Icons.chevron_right_rounded, size: 20, color: LKTheme.gold),
                            ],
                          ),
                        ),
                      )),

                  // Add new connection
                  if (_activeCount < _maxConnections) ...[
                    const SizedBox(height: 16),
                    _buildAddSection(),
                  ],

                  // Ad banners for free users
                  if (_isFreeUser) ...[
                    const SizedBox(height: 12),
                    AdBannerPair(
                      onRemoveAds: () => widget.onTabChange?.call(2),
                      bannerImageUrl: _bannerAdImage,
                      bannerClickUrl: _bannerAdUrl,
                    ),
                  ],

                  // Empty state
                  if (_connections.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: 48),
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent.withValues(alpha: 0.06),
                          ),
                          child: Icon(Icons.people_outline_rounded, size: 56, color: _accent.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 20),
                        Text('No connections yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: LKTheme.textSecondary)),
                        const SizedBox(height: 8),
                        const Text('Add someone\'s code below\nto connect with them', style: TextStyle(fontSize: 14, color: LKTheme.textMuted, height: 1.4), textAlign: TextAlign.center),
                      ]),
                    ),
                ])))),
      ),
      if (_showBumperAd)
        BumperAdOverlay(onDismiss: () => setState(() => _showBumperAd = false), imageUrl: _bumperAdImage, clickUrl: _bumperAdUrl),
      ]),
    );
  }

  Widget _buildConnectionCard(Connection conn) {
    final isOverdue = conn.isAccepted && conn.isOverdue;
    final isPending = conn.isPending;
    final isInactive = conn.isInactive;

    Color statusColor = LKTheme.green;
    String statusText = 'Connected';
    IconData statusIcon = Icons.check_circle_rounded;

    if (isInactive) {
      statusColor = LKTheme.textMuted;
      statusText = 'Disconnected';
      statusIcon = Icons.link_off_rounded;
    } else if (isPending) {
      // Sheet + connect-state spec: a code entered but not yet reciprocated shows RED.
      statusColor = LKTheme.red;
      statusText = 'Waiting...';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isOverdue) {
      statusColor = LKTheme.red;
      statusText = 'Overdue';
      statusIcon = Icons.warning_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: isInactive ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [LKTheme.surfaceAlt, LKTheme.surface]),
        color: isInactive ? LKTheme.surface.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? LKTheme.red.withValues(alpha: 0.4) : LKTheme.border.withValues(alpha: 0.5),
          width: isOverdue ? 1.5 : 0.5,
        ),
        boxShadow: isInactive ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isInactive ? LKTheme.bgCardLight : statusColor.withValues(alpha: 0.1),
                    border: Border.all(color: statusColor.withValues(alpha: isInactive ? 0.2 : 0.4), width: 2),
                  ),
                  child: Center(child: Text(
                    conn.name.isNotEmpty ? conn.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isInactive ? LKTheme.textMuted : statusColor),
                  )),
                ),
                const SizedBox(width: 14),
                // Name and code
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conn.name, style: LKTheme.h2(size: 17,
                      color: isInactive ? LKTheme.textMuted : LKTheme.contrastText)),
                    const SizedBox(height: 2),
                    Text(conn.userCode, style: TextStyle(fontFamily: 'Dosis', fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w700,
                      color: isInactive ? LKTheme.textMuted.withValues(alpha: 0.6) : _accent.withValues(alpha: 0.7))),
                  ],
                )),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),

            if (!isInactive && !isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isOverdue ? LKTheme.red : LKTheme.teal).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 16, color: isOverdue ? LKTheme.red : LKTheme.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Last verified: ${conn.lastCheckInText}',
                      style: TextStyle(fontSize: 13, color: isOverdue ? LKTheme.red : LKTheme.teal, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            if (isPending) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.hourglass_top_rounded, size: 15, color: LKTheme.red.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Expanded(child: Text('Added — waiting for them to add your code too.',
                  style: TextStyle(fontSize: 13, color: LKTheme.contrastTextSoft, fontStyle: FontStyle.italic))),
              ]),
            ],

            const SizedBox(height: 12),
            Row(children: [
              if (!isInactive) ...[
                GestureDetector(
                  onTap: () => _editConnection(conn),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _accent.withValues(alpha: 0.06),
                      border: Border.all(color: _accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_rounded, size: 14, color: _accent.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text('edit', style: TextStyle(fontSize: 12, color: _accent.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              GestureDetector(
                onTap: () => _deleteConnection(conn),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: LKTheme.red.withValues(alpha: 0.04),
                    border: Border.all(color: LKTheme.red.withValues(alpha: 0.1)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.close_rounded, size: 14, color: LKTheme.textMuted.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text('remove', style: TextStyle(fontSize: 12, color: LKTheme.textMuted.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LKTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.15), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Icon(Icons.person_add_rounded, size: 20, color: _accent.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text("Add a connection", style: LKTheme.h2(size: 17, color: LKTheme.contrastText)),
          ],
        ),
        const SizedBox(height: 6),
        // Code only — the name is pulled from the database automatically.
        Text("Enter their 6-letter code. We'll get their name from the system for you.",
          style: LKTheme.txt(color: LKTheme.contrastTextSoft, height: 1.35)),
        const SizedBox(height: 14),
        TextField(controller: _codeCtrl, maxLength: 6, textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Dosis', fontSize: 26, fontWeight: FontWeight.w700, color: _accent, letterSpacing: 8),
          decoration: InputDecoration(hintText: 'CODE', counterText: '',
            hintStyle: TextStyle(fontFamily: 'Dosis', fontSize: 26, fontWeight: FontWeight.w700, color: LKTheme.contrastTextSoft, letterSpacing: 8),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: LKTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _accent, width: 2)),
            filled: true, fillColor: LKTheme.surfaceAlt)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 52, child: Container(
          decoration: BoxDecoration(gradient: _accentGradient, borderRadius: BorderRadius.circular(14)),
          child: ElevatedButton.icon(
            onPressed: _isAdding ? null : _connectPeople,
            icon: _isAdding ? null : Icon(Icons.add_rounded, size: 22, color: _accentDark),
            label: _isAdding
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _accentDark, strokeWidth: 2))
              : Text('CONNECT', style: LKTheme.h1(size: 18, color: _accentDark)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        )),
      ]),
    );
  }
}
