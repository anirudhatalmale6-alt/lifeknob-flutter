import 'package:flutter/material.dart';
import '../models/checkin_model.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CheckIn> _checkIns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getHistory();
      final List data = response['data'] ?? response['check_ins'] ?? response['history'] ?? [];
      if (mounted) {
        setState(() {
          _checkIns = data.map((e) => CheckIn.fromJson(e)).toList();
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
          'History',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)))
          : _error != null
              ? _buildError()
              : _checkIns.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: const Color(0xFF27AE60),
                      onRefresh: _loadHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _checkIns.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final checkIn = _checkIns[index];
                          return _buildCheckInCard(checkIn);
                        },
                      ),
                    ),
    );
  }

  Widget _buildCheckInCard(CheckIn checkIn) {
    final isOk = checkIn.type == 'ok';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFFF0FAF4) : const Color(0xFFFDF0EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOk
              ? const Color(0xFF27AE60).withValues(alpha: 0.3)
              : const Color(0xFFE74C3C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOk ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
            ),
            child: Icon(
              isOk ? Icons.check : Icons.warning,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOk ? 'Pressed OK' : 'SOS Alert',
                  style: TextStyle(
                    fontSize: 14,
                    color: isOk ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Time
          Text(
            checkIn.timeAgo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No check-ins yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'When your connections press OK,\nyou\'ll see it here.',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Could not load history',
            style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
