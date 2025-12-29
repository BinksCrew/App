import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RedemptionsScreen extends StatefulWidget {
  const RedemptionsScreen({super.key});

  @override
  State<RedemptionsScreen> createState() => _RedemptionsScreenState();
}

class _RedemptionsScreenState extends State<RedemptionsScreen> {
  final _apiService = ApiService();
  List<dynamic> _redemptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  Future<void> _loadRedemptions() async {
    try {
      final redemptions = await _apiService.getRedemptions();
      setState(() {
        _redemptions = redemptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar redenciones: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'delivered':
        return 'Entregado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mis Redenciones', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C0C16), Color(0xFF0F0F1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF2E63)))
              : _redemptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.white38,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes redenciones aún',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '¡Juega para ganar puntos y canjear recompensas!',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRedemptions,
                      color: const Color(0xFFFF2E63),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _redemptions.length,
                        itemBuilder: (context, index) {
                          final redemption = _redemptions[index];
                          return _buildRedemptionCard(redemption);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildRedemptionCard(dynamic redemption) {
    final product = redemption['product'] ?? {};
    final status = redemption['status'] ?? 'pending';
    final createdAt = DateTime.parse(redemption['createdAt'] ?? DateTime.now().toIso8601String());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2F), Color(0xFF121223)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: Color(0xFFFF2E63),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Producto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Color(0xFFFF2E63),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product['pointsCost'] ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFFFF2E63),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}