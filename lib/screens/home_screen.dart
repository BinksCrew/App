import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'play_screen.dart';
import 'products_screen.dart';
import 'redemptions_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  String _userName = 'Usuario';
  bool _isLoading = true;
  List<dynamic> _animes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userData = await _apiService.getUserData();
      final animes = await _apiService.getAnimes();
      
      if (mounted) {
        setState(() {
          if (userData != null) {
            _userName = userData['fullName'] ?? userData['username'] ?? 'Usuario';
          }
          _animes = animes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Binkscrew'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _apiService.logout();
              if (!mounted) return;
              navigator.pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(accent),
                  const SizedBox(height: 16),
                  _buildActionRow(context),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Explora animes'),
                  const SizedBox(height: 10),
                  _animes.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No hay animes disponibles por ahora')),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _animes.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder: (context, index) {
                            final anime = _animes[index];
                            return _buildCategoryCard(
                              context,
                              anime['name'] ?? 'Anime',
                              index,
                              (anime['id'] ?? '').toString(),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flash_on),
              title: Text('Hola, $_userName'),
              subtitle: const Text('Prepárate para el siguiente arco'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatPill('${_animes.length}', 'Animes disponibles'),
                const SizedBox(width: 10),
                _buildStatPill('Reto rápido', 'Elige un anime y juega'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          title: 'Jugar',
          subtitle: '¡Pon a prueba tus conocimientos!',
          icon: Icons.play_circle_fill,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const PlayScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final tween = Tween(begin: const Offset(0.0, 0.1), end: Offset.zero).chain(
                    CurveTween(curve: Curves.easeOutCubic),
                  );
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
              ),
            );
          },
        ),
        _buildActionCard(
          title: 'Tienda',
          subtitle: 'Canjea tus puntos por recompensas',
          icon: Icons.shopping_bag,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductsScreen()),
            );
          },
        ),
        _buildActionCard(
          title: 'Mis Redenciones',
          subtitle: 'Ve tus productos canjeados',
          icon: Icons.card_giftcard,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RedemptionsScreen()),
            );
          },
        ),
        _buildActionCard(
          title: 'Leaderboard',
          subtitle: '¿Dónde estás en el ranking?',
          icon: Icons.leaderboard,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, int index, String animeId) {
    return Card(
      child: InkWell(
        onTap: () {
          unawaited(_apiService.getQuestions(animeId: animeId));
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => PlayScreen(
                animeId: animeId,
                animeName: title,
                autoStart: true,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.play_arrow),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text('Tap para jugar', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
