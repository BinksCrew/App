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
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductCard(product);
                    },
                  ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final userPoints = _userData?['points'] ?? 0;
    final canAfford = userPoints >= (product['pointsCost'] ?? 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 210;
        final iconBox = isCompact ? 52.0 : 60.0;
        final titleSize = isCompact ? 14.0 : 16.0;
        final descLines = isCompact ? 1 : 2;
        final buttonVertical = isCompact ? 12.0 : 14.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: iconBox,
                  width: iconBox,
                  child: const Icon(Icons.card_giftcard),
                ),
                SizedBox(height: isCompact ? 10 : 12),
                Text(
                  product['name'] ?? 'Producto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: titleSize),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      product['description'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: descLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.stars, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${product['pointsCost'] ?? 0}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 6 : 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford ? () => _redeemProduct(product['id']) : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: buttonVertical),
                    ),
                    child: Text(canAfford ? 'Redimir' : 'Insuficiente'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}