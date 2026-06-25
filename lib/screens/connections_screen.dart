import 'package:flutter/material.dart';
import '../models/connection_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ConnectionsScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const ConnectionsScreen({super.key, this.onGoHome});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  List<Connection> _connections = [];
  bool _isLoading = true;
  String? _error;
  int _maxConnections = 1;
  String _plan = 'free';

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _maxConnections = user.maxConnections;
        _plan = user.plan;
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
      if (!mounted) return;
      _showBigMessage(
        'Connection limit',
        _plan == 'free'
            ? 'Free plan allows 1 connection.\nUpgrade to add more!'
            : 'You\'ve reached your limit ($_maxConnections).',
        const Color(0xFFF39C12),
      );
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
              const Text(
                'Ask the person for their code.\nYou will see their check-ins.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D), height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF27AE60)),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'CODE',
                  counterText: '',
                  hintStyle: TextStyle(fontSize: 32, color: Colors.grey[300], letterSpacing: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, codeController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Connect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (code == null || code.isEmpty) return;

    try {
      await ApiService().connect(code);
      if (mounted) {
        _showBigMessage('Connected!', 'You can now see their check-ins.', const Color(0xFF27AE60));
        _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        _showBigMessage('Could not connect', '$e', const Color(0xFFE74C3C));
      }
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
              Icon(
                color == const Color(0xFF27AE60) ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 64, color: color,
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
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

  Future<void> _disconnect(Connection conn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 64, color: Color(0xFFE74C3C)),
              const SizedBox(height: 16),
              const Text('Disconnect?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              Text('You will no longer see\n${conn.name}\'s check-ins.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Disconnect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService().disconnect(conn.id);
      if (mounted) { _loadConnections(); }
    } catch (e) {
      if (mounted) { _showBigMessage('Error', '$e', const Color(0xFFE74C3C)); }
    }
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, color: Color(0xFF27AE60), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Connections', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_connections.length}/$_maxConnections',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _connections.length >= _maxConnections ? const Color(0xFFE74C3C) : const Color(0xFF2C3E50))),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onGoHome != null)
                    GestureDetector(
                      onTap: widget.onGoHome,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
                  : _error != null
                      ? _buildError()
                      : _connections.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: const Color(0xFF27AE60),
                              onRefresh: _loadConnections,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                itemCount: _connections.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _connections.length) return _buildAddButton();
                                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildConnectionCard(_connections[index]));
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: _addConnection,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF27AE60).withValues(alpha: 0.15)),
                child: const Icon(Icons.person_add_rounded, size: 32, color: Color(0xFF27AE60)),
              ),
              const SizedBox(height: 12),
              const Text('Add Connection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF27AE60))),
              const SizedBox(height: 6),
              Text(
                'Enter someone\'s code to see\nwhen they press OK.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard(Connection conn) {
    final isOverdue = conn.isOverdue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue ? Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverdue ? const Color(0xFFE74C3C).withValues(alpha: 0.15) : const Color(0xFF27AE60).withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(conn.name.isNotEmpty ? conn.name[0].toUpperCase() : '?',
                style: TextStyle(color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60), fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conn.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(isOverdue ? Icons.warning_amber_rounded : Icons.check_circle_rounded, size: 15,
                    color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60)),
                  const SizedBox(width: 4),
                  Text(isOverdue ? 'Overdue - ${conn.lastCheckInText}' : conn.lastCheckInText,
                    style: TextStyle(fontSize: 13, color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF95A5A6),
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal)),
                ]),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFFBDC3C7), size: 20), onPressed: () => _disconnect(conn)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: SingleChildScrollView(child: _buildAddButton()));
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_rounded, size: 64, color: Color(0xFFE74C3C)),
          const SizedBox(height: 16),
          Text('Could not load connections', style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(width: 200, height: 52,
            child: ElevatedButton(
              onPressed: _loadConnections,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('OK - Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
