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
      appBar: AppBar(title: const Text('Pokedex')),
      body: ListView.builder(
        itemCount: pokemonList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: Text(pokemonList[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Seleccionaste ${pokemonList[index]}')),
              );
            },
          );
        },
      ),
    );
  }
}