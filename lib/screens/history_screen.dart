import 'package:flutter/material.dart';
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
      if (user != null) {
        _maxConnections = user.maxConnections;
      }

      final response = await ApiService().getConnections();
      final List data = response['data'] ?? response['connections'] ?? [];
      if (mounted) {
        setState(() {
          _connections = data.map((e) => Connection.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _addConnection() async {
    if (_connections.length >= _maxConnections) {
      _showSubscriptionPrompt();
      return;
    }

    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_rounded, size: 48, color: Color(0xFF27AE60)),
              const SizedBox(height: 12),
              const Text('Add Connection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              const Text('Enter the person\'s code.\nYou will see when they press OK.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D), height: 1.4)),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF27AE60)),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'CODE', counterText: '',
                  hintStyle: TextStyle(fontSize: 32, color: Colors.grey[300], letterSpacing: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, codeController.text.trim()),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Connect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    if (code == null || code.isEmpty) return;

    try {
      await ApiService().connect(code);
      if (mounted) {
        _showBigMessage('Connected!', 'You can now see when they press OK.', const Color(0xFF27AE60));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not connect', '$e', const Color(0xFFE74C3C));
      }
    }
  }

  Future<void> _disconnectPerson(Connection conn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 64, color: Color(0xFFF39C12)),
              const SizedBox(height: 16),
              Text('Disconnect ${conn.name}?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('You will no longer see their check-in status.', style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF39C12), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Disconnect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().disconnect(conn.userId);
      if (mounted) {
        _showBigMessage('Disconnected', '${conn.name} removed.', const Color(0xFF27AE60));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not disconnect', '$e', const Color(0xFFE74C3C));
      }
    }
  }

  void _showSubscriptionPrompt() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SubscriptionScreen(onGoHome: () {
        Navigator.pop(context);
        widget.onGoHome?.call();
      }),
    ));
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
              if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center)],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('OK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOverdue = _connections.any((c) => c.isOverdue);
    final String headerTitle = hasOverdue ? 'ALERT' : 'Check-in History';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(hasOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                    color: hasOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60), size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Text(headerTitle,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: hasOverdue ? const Color(0xFFE74C3C) : const Color(0xFF2C3E50)))),
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
                ],
              ),
            ),

            // Info text
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'People you are watching. Tap a person to disconnect.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ),

            // Connection slots
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          color: const Color(0xFF27AE60),
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              if (index < _connections.length) {
                                return _buildPersonCard(_connections[index]);
                              } else if (index == _connections.length && _connections.length < _maxConnections) {
                                return _buildAddSlot();
                              } else {
                                return _buildLockedSlot();
                              }
                            },
                          ),
                        ),
            ),

            // Big Home button
            if (widget.onGoHome != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 4, 32, 12),
                child: SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton.icon(
                    onPressed: widget.onGoHome,
                    icon: const Icon(Icons.home_rounded, size: 24),
                    label: const Text('Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(Connection conn) {
    final isOverdue = conn.isOverdue;
    final circleColor = isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);

    return GestureDetector(
      onTap: () => _disconnectPerson(conn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isOverdue ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOverdue ? const Color(0xFFE74C3C).withValues(alpha: 0.3) : Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: circleColor, width: 2.5),
                color: circleColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                isOverdue ? Icons.warning_rounded : Icons.check_rounded,
                color: circleColor, size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conn.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 2),
                  Text(
                    isOverdue ? 'NOT checked in!' : 'Checked in OK',
                    style: TextStyle(fontSize: 13, color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              conn.lastCheckInText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF95A5A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSlot() {
    return GestureDetector(
      onTap: _addConnection,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF27AE60), size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Tap to add a connection',
                style: TextStyle(fontSize: 15, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedSlot() {
    return GestureDetector(
      onTap: _showSubscriptionPrompt,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: Icon(Icons.lock_outline_rounded, color: Colors.grey[400], size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Upgrade to connect more people',
                style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_rounded, size: 64, color: Color(0xFFE74C3C)),
          const SizedBox(height: 16),
          Text('Could not load data', style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(width: 200, height: 52, child: ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('OK - Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }
}
