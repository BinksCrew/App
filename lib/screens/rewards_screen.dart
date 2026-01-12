import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _Achievement {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const _Achievement({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _gameStats;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  static const List<_Achievement> _achievements = [
    _Achievement(
      key: 'first_quiz',
      title: 'Primer Quiz',
      description: 'Completaste tu primer juego',
      icon: Icons.star,
    ),
    _Achievement(
      key: 'perfect_score',
      title: 'Puntuación perfecta',
      description: 'Promedio del 90% o superior',
      icon: Icons.emoji_events,
    ),
    _Achievement(
      key: 'five_games',
      title: 'Explorador',
      description: 'Jugaste 5 juegos o más',
      icon: Icons.explore,
    ),
    _Achievement(
      key: 'hundred_points',
      title: 'Maestro',
      description: 'Alcanzaste 100 puntos',
      icon: Icons.school,
    ),
    _Achievement(
      key: 'master',
      title: 'Leyenda',
      description: 'Alcanzaste 500 puntos',
      icon: Icons.local_fire_department,
    ),
    _Achievement(
      key: 'champion',
      title: 'Campeón',
      description: 'Alcanzaste 1000 puntos',
      icon: Icons.workspace_premium,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final gameStats = await _apiService.getGameStats();
      final userData = await _apiService.getUserProfile();

      if (!mounted) return;
      setState(() {
        _gameStats = gameStats;
        _userData = userData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasAchievement(String achievement) {
    if (_gameStats == null) return false;

    final totalGamesRaw = _gameStats!['totalGames'];
    final totalPointsRaw = _gameStats!['totalPoints'];
    final averageScoreRaw = _gameStats!['averageScore'];

    final int totalGames = (totalGamesRaw is num) ? totalGamesRaw.toInt() : 0;
    final int totalPoints = (totalPointsRaw is num) ? totalPointsRaw.toInt() : 0;
    final double averageScore = (averageScoreRaw is num) ? averageScoreRaw.toDouble() : 0.0;

    // Some backends return averageScore as a ratio (0..1) and others as a score (0..10).
    final bool isPerfect = averageScore >= 0.9 || averageScore >= 9;

    switch (achievement) {
      case 'first_quiz':
        return totalGames >= 1;
      case 'five_games':
        return totalGames >= 5;
      case 'perfect_score':
        return isPerfect;
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
    final points = (_userData?['points'] ?? 0).toString();
    final unlockedCount = _achievements.where((a) => _hasAchievement(a.key)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events),
                    title: Text('$unlockedCount logros desbloqueados'),
                    subtitle: Text('$points puntos totales'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Logros', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final achievement in _achievements)
                  _buildAchievementTile(achievement),
              ],
            ),
    );
  }

  Widget _buildAchievementTile(_Achievement achievement) {
    final unlocked = _hasAchievement(achievement.key);
    return Card(
      child: ListTile(
        leading: Icon(achievement.icon),
        title: Text(achievement.title),
        subtitle: Text(achievement.description),
        trailing: unlocked ? const Icon(Icons.check_circle) : const Icon(Icons.lock),
      ),
    );
  }
}