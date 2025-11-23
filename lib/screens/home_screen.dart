import 'package:flutter/material.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/anime.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(
            color: Colors.black.withAlpha(77), // 0.3 * 255 ≈ 77
          ),
          // Icono de perfil arriba a la izquierda
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 25,
                backgroundImage: const AssetImage('assets/defaultpfp.webp'),
                backgroundColor: Colors.grey,
              ),
            ),
          ),
          // Contenido promocional
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', height: 100, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100)),
                  const SizedBox(height: 20),
                  // Título promocional
                  const Text(
                    '¡Bienvenido a Binkscrew!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 8))],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Descripción
                  const Text(
                    'Explora la Pokedex, juega y descubre el mundo Pokemon.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Botón promocional
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 6), blurRadius: 0)],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '¡Comienza tu aventura!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE4000F)),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Usa el navbar inferior para navegar.',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}