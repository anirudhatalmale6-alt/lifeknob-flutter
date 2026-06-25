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
        ),
      );
      return;
    }

    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Connection',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the person\'s code to connect with them.',
              style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'CODE',
                hintStyle: TextStyle(
                  fontSize: 24,
                  color: Colors.grey[300],
                  letterSpacing: 4,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 16)),
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
            content: Text('Connected successfully!', style: TextStyle(fontSize: 16)),
            backgroundColor: Color(0xFF27AE60),
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
          ),
        );
      }
    }
  }

  Future<void> _disconnect(Connection conn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to disconnect from ${conn.name}?\n\nYou will no longer see their check-ins.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connections',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addConnection,
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add, size: 24),
        label: const Text('Add Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Plan info bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  _plan == 'free' ? Icons.lock_outline : Icons.star,
                  color: _plan == 'free' ? Colors.grey[500] : const Color(0xFFF39C12),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _plan == 'free' ? 'Free Plan' : 'Paid Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_connections.length}/$_maxConnections used',
                  style: TextStyle(
                    fontSize: 16,
                    color: _connections.length >= _maxConnections ? Colors.red : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Connection list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadConnections,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _connections.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: const Color(0xFF27AE60),
                            onRefresh: _loadConnections,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: _connections.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                return _buildConnectionCard(_connections[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(Connection conn) {
    final isOverdue = conn.isOverdue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFDF0EF) : const Color(0xFFF0FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFE74C3C).withValues(alpha: 0.3)
              : const Color(0xFF27AE60).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
            ),
            child: Center(
              child: Text(
                conn.name.isNotEmpty ? conn.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber : Icons.check_circle,
                      size: 16,
                      color: isOverdue ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue ? 'Overdue - ${conn.lastCheckInText}' : conn.lastCheckInText,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? const Color(0xFFE74C3C) : Colors.grey[500],
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Disconnect button
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF95A5A6), size: 22),
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
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap "Add Connection" and enter\nsomeone\'s code to get started.',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
