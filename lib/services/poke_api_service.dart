import 'package:dio/dio.dart';

import '../models/pokemon.dart';

class PokeApiService {
  PokeApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://pokeapi.co/api/v2/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<PokemonPageResult> getPokemonPage({
    required int offset,
    int limit = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'pokemon/',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('La API no devolvió la lista de Pokémon.');
    }
    return PokemonPageResult.fromJson(data);
  }

  Future<PokemonDetails> getPokemonDetails(int id) async {
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>('pokemon/$id/'),
      _dio.get<Map<String, dynamic>>('pokemon-species/$id/'),
    ]);
    final pokemonData = responses[0].data;
    final speciesData = responses[1].data;
    if (pokemonData == null || speciesData == null) {
      throw const FormatException('La API devolvió detalles incompletos.');
    }

    final pokemon = Pokemon.fromJson(pokemonData);
    final species = PokemonSpecies.fromJson(speciesData);
    final evolutionResponse =
        await _dio.get<Map<String, dynamic>>(species.evolutionChainUrl);
    final evolutionData = evolutionResponse.data;
    if (evolutionData == null) {
      throw const FormatException('No se pudo cargar la cadena evolutiva.');
    }
    return PokemonDetails(
      pokemon: pokemon,
      species: species,
      evolutions: _parseEvolutions(evolutionData['chain']),
    );
  }

  List<PokemonEvolution> _parseEvolutions(dynamic root) {
    final evolutions = <PokemonEvolution>[];
    void visit(Map<String, dynamic> node) {
      final species = node['species'] as Map<String, dynamic>;
      final url = species['url'] as String;
      final idMatch = RegExp(r'/pokemon-species/(\d+)/').firstMatch(url);
      final id = int.tryParse(idMatch?.group(1) ?? '');
      if (id != null) {
        evolutions.add(
          PokemonEvolution(id: id, name: species['name'] as String),
        );
      }
      for (final next in node['evolves_to'] as List<dynamic>) {
        visit(next as Map<String, dynamic>);
      }
    }

    visit(root as Map<String, dynamic>);
    return evolutions;
  }
}

class PokemonDetails {
  const PokemonDetails({
    required this.pokemon,
    required this.species,
    required this.evolutions,
  });

  final Pokemon pokemon;
  final PokemonSpecies species;
  final List<PokemonEvolution> evolutions;
}
