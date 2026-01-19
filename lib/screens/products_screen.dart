import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadUserData();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _apiService.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userData = userData;
      });
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _showRedeemConfirmation(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar canje'),
        content: Text('¿Estás seguro de que quieres redimir "$productName"? Se deducirán los puntos de tu cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redimir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _redeemProduct(productId);
    }
  }

  Future<void> _redeemProduct(String productId) async {
    try {
      await _apiService.createRedemption(productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Producto redimido exitosamente!'),
        ),
      );
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al redimir producto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          if (_userData != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.stars, size: 18),
                  label: Text('${_userData!['points'] ?? 0}'),
                ),
              ),
            )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? const Center(child: Text('No hay productos disponibles'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildProductCard(product),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final userPoints = _userData?['points'] ?? 0;
    final productPrice = num.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final canAfford = userPoints >= productPrice;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 210;
        final iconBox = isCompact ? 52.0 : 60.0;
        final titleSize = isCompact ? 14.0 : 16.0;
        final descLines = isCompact ? 1 : 2;
        final buttonVertical = isCompact ? 12.0 : 14.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: iconBox * 0.6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Producto',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['description'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: descLines,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${num.tryParse(product['price']?.toString() ?? '0') ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: FilledButton(
                          onPressed: canAfford ? () => _showRedeemConfirmation(product['id'], product['name'] ?? 'Producto') : null,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: buttonVertical),
                            backgroundColor: canAfford
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: Text(
                            canAfford ? 'Redimir' : 'Insuficiente',
                            style: TextStyle(
                              fontSize: 12,
                              color: canAfford
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}