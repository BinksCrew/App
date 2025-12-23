import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Start at Home by default

  static final List<Widget> _widgetOptions = <Widget>[
    const RewardsScreen(),
    const HomeScreen(),
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
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.black.withOpacity(0.65),
            indicatorColor: const Color(0xFFFF2E63).withOpacity(0.4),
            onDestinationSelected: _onItemTapped,
            selectedIndex: _selectedIndex,
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined, color: Colors.white),
                selectedIcon: Icon(Icons.emoji_events, color: Colors.white),
                label: 'Rewards',
              ),
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.white),
                selectedIcon: Icon(Icons.home, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: Colors.white),
                selectedIcon: Icon(Icons.person, color: Colors.white),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
