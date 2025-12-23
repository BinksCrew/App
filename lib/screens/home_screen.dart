import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'play_screen.dart';
import 'rewards_screen.dart';

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
    const accent = Color(0xFFFF2E63);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Binkscrew', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _apiService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E1A), Color(0xFF0A0A12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(accent),
                    const SizedBox(height: 18),
                    _buildActionRow(context),
                    const SizedBox(height: 26),
                    _buildSectionTitle('Explora animes'),
                    const SizedBox(height: 12),
                    _animes.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: const Center(
                              child: Text(
                                'No hay animes disponibles por ahora',
                                style: TextStyle(color: Colors.white70),
                              ),
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
                                anime['id'],
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(Color accent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF16162A), Color(0xFF0F0F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.16),
                    border: Border.all(color: accent.withOpacity(0.6)),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $_userName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Prepárate para el siguiente arco',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatPill('${_animes.length}', 'Animes disponibles', accent),
                const SizedBox(width: 10),
                _buildStatPill('Reto rápido', 'Elige un anime y juega', const Color(0xFF08D9D6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Recompensas',
            subtitle: 'Mira tus logros',
            icon: Icons.emoji_events,
            gradient: const [Color(0xFFFF2E63), Color(0xFFB026FF)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RewardsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            title: 'Continuar',
            subtitle: 'Salta a un quiz',
            icon: Icons.play_circle_fill,
            gradient: const [Color(0xFF08D9D6), Color(0xFF11998E)],
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
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFFF2E63)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, int index, String animeId) {
    final gradients = [
      [const Color(0xFF41295a), const Color(0xFF2F0743)],
      [const Color(0xFF0f2027), const Color(0xFF203a43), const Color(0xFF2c5364)],
      [const Color(0xFF141E30), const Color(0xFF243B55)],
      [const Color(0xFF1D976C), const Color(0xFF2DCB73)],
      [const Color(0xFF2b5876), const Color(0xFF4e4376)],
    ];
    final gradient = gradients[index % gradients.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const PlayScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final tween = Tween(begin: const Offset(0.08, 0.0), end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOutCirc),
                );
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(Icons.blur_on, color: Colors.white.withOpacity(0.08), size: 80),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.play_arrow, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Quiz', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 6),
                      Text(
                        'Tap para jugar',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
