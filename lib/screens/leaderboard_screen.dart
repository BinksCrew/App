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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (userRank > 0)
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
                  const Icon(Icons.emoji_events, color: Color(0xFFFF2E63), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '#$userRank',
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
              : _leaderboard.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay datos disponibles',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaderboard,
                      color: const Color(0xFFFF2E63),
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
      ),
    );
  }

  Widget _buildLeaderboardItem(dynamic user, int rank, bool isCurrentUser) {
    IconData rankIcon;
    Color rankColor;

    switch (rank) {
      case 1:
        rankIcon = Icons.emoji_events;
        rankColor = Colors.amber;
        break;
      case 2:
        rankIcon = Icons.emoji_events;
        rankColor = Colors.grey;
        break;
      case 3:
        rankIcon = Icons.emoji_events;
        rankColor = Colors.brown;
        break;
      default:
        rankIcon = Icons.person;
        rankColor = const Color(0xFFFF2E63);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isCurrentUser
              ? [const Color(0xFFFF2E63).withOpacity(0.2), const Color(0xFFB026FF).withOpacity(0.2)]
              : [const Color(0xFF1A1A2F), const Color(0xFF121223)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFFF2E63).withOpacity(0.5)
              : const Color(0xFFFF2E63).withOpacity(0.3),
        ),
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: const Color(0xFFFF2E63).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withOpacity(0.1),
                border: Border.all(color: rankColor.withOpacity(0.3)),
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(rankIcon, color: rankColor, size: 20)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user['username'] ?? user['fullName'] ?? 'Usuario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2E63).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.5)),
                          ),
                          child: const Text(
                            'Tú',
                            style: TextStyle(
                              color: Color(0xFFFF2E63),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user['fullName'] != null && user['fullName'] != user['username'])
                    Text(
                      user['fullName'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    '${user['points'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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