import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _gameStats;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final gameStats = await _apiService.getGameStats();
      final userData = await _apiService.getUserProfile();
      
      setState(() {
        _gameStats = gameStats;
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasAchievement(String achievement) {
    if (_gameStats == null) return false;
    
    final totalGames = _gameStats!['totalGames'] ?? 0;
    final totalPoints = _gameStats!['totalPoints'] ?? 0;
    final averageScore = _gameStats!['averageScore'] ?? 0.0;

    switch (achievement) {
      case 'first_quiz':
        return totalGames >= 1;
      case 'five_games':
        return totalGames >= 5;
      case 'perfect_score':
        return averageScore >= 0.9; // 90% or higher
      case 'hundred_points':
        return totalPoints >= 100;
      case 'master':
        return totalPoints >= 500;
      case 'champion':
        return totalPoints >= 1000;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Recompensas', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0C0C16), Color(0xFF0F0F1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF2E63)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Recompensas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Logros desbloqueados'),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.88,
                  children: [
                    _buildDynamicRewardCard('first_quiz', 'Primer Quiz', 'Completaste tu primer juego', Icons.star, Colors.amber),
                    _buildDynamicRewardCard('perfect_score', 'Puntuación Perfecta', 'Promedio del 90% o superior', Icons.emoji_events, Colors.yellow),
                    _buildDynamicRewardCard('five_games', 'Explorador', 'Jugaste 5 juegos o más', Icons.explore, const Color(0xFF08D9D6)),
                    _buildDynamicRewardCard('hundred_points', 'Maestro', 'Alcanzaste 100 puntos', Icons.school, const Color(0xFFB026FF)),
                    _buildDynamicRewardCard('master', 'Leyenda', 'Alcanzaste 500 puntos', Icons.local_fire_department, Colors.red),
                    _buildDynamicRewardCard('champion', 'Campeón', 'Alcanzaste 1000 puntos', Icons.workspace_premium, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final totalPoints = _userData?['points'] ?? 0;
    final unlockedAchievements = [
      'first_quiz',
      'perfect_score', 
      'five_games',
      'hundred_points',
      'master',
      'champion'
    ].where(_hasAchievement).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1B30), Color(0xFF121226)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2E63).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tus recompensas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$unlockedAchievements logros desbloqueados • $totalPoints puntos totales',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2E63).withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.5)),
              ),
              child: Text(
                '$unlockedAchievements',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildRewardCard(String title, String description, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.22), Colors.white.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicRewardCard(String achievementKey, String title, String description, IconData icon, Color color) {
    final isUnlocked = _hasAchievement(achievementKey);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: isUnlocked
            ? LinearGradient(
                colors: [color.withOpacity(0.22), Colors.white.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(color: isUnlocked ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: color.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
              ),
              child: Icon(
                icon, 
                size: 36, 
                color: isUnlocked ? color : Colors.grey.withOpacity(0.6)
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.grey.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isUnlocked ? Colors.white70 : Colors.grey.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.lock,
                color: Colors.grey.withOpacity(0.6),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockedRewardCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(icon, size: 28, color: color.withOpacity(0.6)),
            ),
            const SizedBox(width: 14),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}