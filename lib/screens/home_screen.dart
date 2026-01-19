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
  Map<String, dynamic>? _userData;

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
            _userData = userData;
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

  void _showStatsModal() {
    if (_userData == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas del usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Nombre'),
              subtitle: Text(_userName),
            ),
            ListTile(
              leading: const Icon(Icons.stars),
              title: const Text('Puntos'),
              subtitle: Text('${_userData!['points'] ?? 0}'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Preguntas respondidas'),
              subtitle: Text('${_userData!['questionsAnswered'] ?? 0}'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Respuestas correctas'),
              subtitle: Text('${_userData!['correctAnswers'] ?? 0}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatsModal,
            tooltip: 'Estadísticas',
          ),
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
                      ? Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No hay animes disponibles por ahora')),
                          ),
                        )
                      : Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: _animes.map((anime) {
                            final index = _animes.indexOf(anime);
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 16 * 2 - 14) / 2,
                              child: _buildCategoryCard(
                                context,
                                anime['name'] ?? 'Anime',
                                index,
                                (anime['id'] ?? '').toString(),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard(Color accent) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $_userName',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prepárate para el siguiente arco',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatPill('${_animes.length}', 'Animes disponibles'),
                  const SizedBox(width: 12),
                  _buildStatPill('Reto rápido', 'Elige un anime y juega'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black, width: 2),
      ),
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
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
                transitionDuration: const Duration(milliseconds: 300),
                reverseTransitionDuration: const Duration(milliseconds: 200),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Jugar Quiz',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
