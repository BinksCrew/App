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
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _apiService.getUserProfile();
    setState(() {
      _userData = userData;
    });
  }

  Future<void> _redeemProduct(String productId) async {
    try {
      await _apiService.createRedemption(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Producto redimido exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData(); // Refresh user points
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al redimir producto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tienda', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_userData != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFFF2E63), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_userData!['points'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay productos disponibles',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
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
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final userPoints = _userData?['points'] ?? 0;
    final canAfford = userPoints >= (product['pointsCost'] ?? 0);

    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image/Icon
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF2E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Color(0xFFFF2E63),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),

            // Product Name
            Text(
              product['name'] ?? 'Producto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Product Description
            Text(
              product['description'] ?? '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Points Cost
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFF2E63), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${product['pointsCost'] ?? 0}',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFFF2E63) : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Redeem Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? () => _redeemProduct(product['id']) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? const Color(0xFFFF2E63)
                      : Colors.grey.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canAfford ? 'Redimir' : 'Puntos insuficientes',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}