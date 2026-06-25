import 'package:flutter/material.dart';
import '../models/connection_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addConnection() async {
    if (_connections.length >= _maxConnections) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _plan == 'free'
                ? 'Free plan allows 1 connection. Upgrade to add more!'
                : 'You\'ve reached your connection limit ($_maxConnections).',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Add Connection',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the person\'s code to connect.',
              style: TextStyle(fontSize: 15, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
                color: Color(0xFF27AE60),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'CODE',
                hintStyle: TextStyle(
                  fontSize: 28,
                  color: Colors.grey[300],
                  letterSpacing: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) return;

    try {
      await ApiService().connect(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected!', style: TextStyle(fontSize: 16)),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not connect: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disconnect(Connection conn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Disconnect?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(
          'Disconnect from ${conn.name}?\nYou will no longer see their check-ins.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Disconnect', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService().disconnect(conn.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected.', style: TextStyle(fontSize: 16)),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _addConnection,
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add_rounded, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, color: Color(0xFF27AE60), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Connections',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _plan == 'free'
                              ? const Color(0xFFF8F9FA)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _plan == 'free' ? Colors.grey[300]! : const Color(0xFFF39C12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _plan == 'free' ? Icons.lock_outline : Icons.star,
                              size: 14,
                              color: _plan == 'free' ? Colors.grey[500] : const Color(0xFFF39C12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_connections.length}/$_maxConnections',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _connections.length >= _maxConnections
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadConnections,
                                icon: const Icon(Icons.refresh, size: 20),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27AE60),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _connections.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: const Color(0xFF27AE60),
                              onRefresh: _loadConnections,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                itemCount: _connections.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildConnectionCard(_connections[index]),
                                  );
                                },
                              ),
                            ),
            ),
          ],
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
        border: isOverdue
            ? Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverdue
                  ? const Color(0xFFE74C3C).withValues(alpha: 0.15)
                  : const Color(0xFF27AE60).withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                conn.name.isNotEmpty ? conn.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conn.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      size: 15,
                      color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue ? 'Overdue - ${conn.lastCheckInText}' : conn.lastCheckInText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF95A5A6),
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFFBDC3C7), size: 20),
            onPressed: () => _disconnect(conn),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: Icon(Icons.people_outline_rounded, size: 40, color: Colors.grey[350]),
          ),
          const SizedBox(height: 20),
          Text(
            'No connections yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to enter someone\'s code\nand start monitoring.',
            style: TextStyle(fontSize: 15, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
