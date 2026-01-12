import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _loadUserData();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await _apiService.getLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar leaderboard: $e')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _apiService.getUserData();
    setState(() {
      _userData = userData;
    });
  }

  int _getUserRank() {
    if (_userData == null) return -1;
    final userId = _userData!['id'];
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i]['id'] == userId) {
        return i + 1;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final userRank = _getUserRank();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          if (userRank > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.emoji_events, size: 18),
                  label: Text('#$userRank'),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _leaderboard.isEmpty
                ? const Center(child: Text('No hay datos disponibles'))
                : RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaderboard.length,
                      itemBuilder: (context, index) {
                        final user = _leaderboard[index];
                        final isCurrentUser = _userData != null && user['id'] == _userData!['id'];
                        return _buildLeaderboardItem(user, index + 1, isCurrentUser);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildLeaderboardItem(dynamic user, int rank, bool isCurrentUser) {
    final username = user['username'] ?? user['fullName'] ?? 'Usuario';
    final fullName = user['fullName'];
    final points = user['points'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: rank <= 3 ? const Icon(Icons.emoji_events) : Text('$rank'),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) const SizedBox(width: 8),
            if (isCurrentUser) const Chip(label: Text('Tú')),
          ],
        ),
        subtitle: (fullName != null && fullName != username) ? Text('$fullName') : null,
        trailing: Chip(
          avatar: const Icon(Icons.stars, size: 18),
          label: Text('$points'),
        ),
      ),
    );
  }
}