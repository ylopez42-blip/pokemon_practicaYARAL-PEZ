import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/pokemon.dart';

void main() {
  group('PokemonEntry', () {
    test('reads the id and artwork URL from a paginated API entry', () {
      final entry = PokemonEntry.fromJson({
        'name': 'bulbasaur',
        'url': 'https://pokeapi.co/api/v2/pokemon/1/',
      });

      expect(entry.id, 1);
      expect(entry.name, 'bulbasaur');
      expect(entry.imageUrl, contains('/official-artwork/1.png'));
    });

    test('rejects an entry without a Pokémon id in its URL', () {
      expect(
        () => PokemonEntry.fromJson({
          'name': 'bulbasaur',
          'url': 'https://pokeapi.co/api/v2/pokemon/',
        }),
        throwsFormatException,
      );
    });
  });

  test('parses a paginated response and its continuation state', () {
    final page = PokemonPageResult.fromJson({
      'count': 1302,
      'next': 'https://pokeapi.co/api/v2/pokemon/?offset=1&limit=1',
      'results': [
        {'name': 'bulbasaur', 'url': 'https://pokeapi.co/api/v2/pokemon/1/'},
      ],
    });

    expect(page.totalCount, 1302);
    expect(page.hasNextPage, isTrue);
    expect(page.entries.single.id, 1);
  });

  test('prefers Spanish category and description from species data', () {
    final species = PokemonSpecies.fromJson({
      'genera': [
        {
          'genus': 'Seed Pokémon',
          'language': {'name': 'en'},
        },
        {
          'genus': 'Pokémon Semilla',
          'language': {'name': 'es'},
        },
      ],
      'flavor_text_entries': [
        {
          'flavor_text': 'It is a seed.',
          'language': {'name': 'en'},
        },
        {
          'flavor_text': 'Una semilla.\nCrece.',
          'language': {'name': 'es'},
        },
      ],
      'evolution_chain': {
        'url': 'https://pokeapi.co/api/v2/evolution-chain/1/',
      },
    });

    expect(species.category, 'Pokémon Semilla');
    expect(species.description, 'Una semilla. Crece.');
    expect(
      species.evolutionChainUrl,
      'https://pokeapi.co/api/v2/evolution-chain/1/',
    );
  });
}
