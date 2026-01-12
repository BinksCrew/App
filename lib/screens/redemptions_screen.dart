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
      appBar: AppBar(
        title: const Text('Mis Redenciones'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _redemptions.isEmpty
                ? const Center(child: Text('No tienes redenciones aún'))
                : RefreshIndicator(
                    onRefresh: _loadRedemptions,
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
    );
  }

  Widget _buildRedemptionCard(dynamic redemption) {
    final product = redemption['product'] ?? {};
    final status = redemption['status'] ?? 'pending';
    final createdAt = DateTime.parse(redemption['createdAt'] ?? DateTime.now().toIso8601String());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard),
        title: Text(product['name'] ?? 'Producto'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((product['description'] ?? '').toString().isNotEmpty)
              Text(
                product['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_getStatusText(status)),
                ),
                Chip(
                  avatar: const Icon(Icons.stars, size: 18),
                  label: Text('${product['pointsCost'] ?? 0}'),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text('${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}