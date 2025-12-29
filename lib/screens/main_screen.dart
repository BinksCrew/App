import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'play_screen.dart';
import 'products_screen.dart';
import 'redemptions_screen.dart';
import 'leaderboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Start at Home by default

  static final List<Widget> _widgetOptions = <Widget>[
    const ProductsScreen(),
    const PlayScreen(),
    const HomeScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F1F), Color(0xFF080810)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage('assets/hero.webp'),
              fit: BoxFit.cover,
              opacity: 0.18,
            ),
          ),
        ),
        // Blur and neon overlay (light blur to keep performance snappy)
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.65),
                  const Color(0xFF0A0A14).withOpacity(0.78),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.black.withOpacity(0.8),
            selectedItemColor: const Color(0xFFFF2E63),
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag),
                label: 'Tienda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle),
                label: 'Jugar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard_outlined),
                activeIcon: Icon(Icons.leaderboard),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
