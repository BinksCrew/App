import 'package:flutter/material.dart';

class PokedexScreen extends StatelessWidget {
  const PokedexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos mock de Pokemon
    final List<String> pokemonList = [
      'Pikachu',
      'Charizard',
      'Bulbasaur',
      'Squirtle',
      'Jigglypuff',
      'Eevee',
      'Snorlax',
      'Mewtwo',
      'Gengar',
      'Dragonite',
    ];

    return Scaffold(
      body: ListView.builder(
        itemCount: pokemonList.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.adjust, color: Color(0xFFE4000F)),
              title: Text(
                pokemonList[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Acción al tocar, por ahora mostrar snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionaste ${pokemonList[index]}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}