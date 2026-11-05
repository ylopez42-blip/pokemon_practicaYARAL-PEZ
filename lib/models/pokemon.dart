class PokemonEntry {
  const PokemonEntry({
    required this.id,
    required this.name,
    required this.url,
  });

  final int id;
  final String name;
  final String url;

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  factory PokemonEntry.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final idMatch = RegExp(r'/pokemon/(\d+)/').firstMatch(url);
    final id = int.tryParse(idMatch?.group(1) ?? '');
    if (id == null) {
      throw FormatException('No se pudo obtener el ID de ${json['name']}.');
    }
    return PokemonEntry(
      id: id,
      name: json['name'] as String,
      url: url,
    );
  }
}

class PokemonPageResult {
  const PokemonPageResult({
    required this.entries,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<PokemonEntry> entries;
  final int totalCount;
  final bool hasNextPage;

  factory PokemonPageResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>;
    return PokemonPageResult(
      entries: results
          .map((entry) => PokemonEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      totalCount: json['count'] as int,
      hasNextPage: json['next'] != null,
    );
  }
}

class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.imageUrl,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.moves,
  });

  final int id;
  final String name;
  final int height;
  final int weight;
  final String imageUrl;
  final List<String> types;
  final List<PokemonAbility> abilities;
  final List<PokemonStat> stats;
  final List<String> moves;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>;
    final other = sprites['other'] as Map<String, dynamic>;
    final artwork = other['official-artwork'] as Map<String, dynamic>;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int,
      weight: json['weight'] as int,
      imageUrl: (artwork['front_default'] as String?) ??
          PokemonEntry.fromJson({
            'name': json['name'],
            'url': 'https://pokeapi.co/api/v2/pokemon/${json['id']}/',
          }).imageUrl,
      types: (json['types'] as List<dynamic>)
          .map(
            (entry) => ((entry as Map<String, dynamic>)['type']
                as Map<String, dynamic>)['name'] as String,
          )
          .toList(),
      abilities: (json['abilities'] as List<dynamic>)
          .map((entry) {
            final abilityEntry = entry as Map<String, dynamic>;
            final ability = abilityEntry['ability'] as Map<String, dynamic>;
            return PokemonAbility(
              name: ability['name'] as String,
              isHidden: abilityEntry['is_hidden'] as bool,
            );
          })
          .toList(),
      stats: (json['stats'] as List<dynamic>)
          .map((entry) {
            final statEntry = entry as Map<String, dynamic>;
            return PokemonStat(
              name: (statEntry['stat'] as Map<String, dynamic>)['name']
                  as String,
              value: statEntry['base_stat'] as int,
            );
          })
          .toList(),
      moves: (json['moves'] as List<dynamic>)
          .take(8)
          .map(
            (entry) => ((entry as Map<String, dynamic>)['move']
                as Map<String, dynamic>)['name'] as String,
          )
          .toList(),
    );
  }
}

class PokemonAbility {
  const PokemonAbility({required this.name, required this.isHidden});

  final String name;
  final bool isHidden;
}

class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  final String name;
  final int value;
}

class PokemonSpecies {
  const PokemonSpecies({
    required this.category,
    required this.description,
    required this.evolutionChainUrl,
  });

  final String category;
  final String description;
  final String evolutionChainUrl;

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    final genera = json['genera'] as List<dynamic>;
    final spanishGenus = _localizedEntry(genera, 'genus', 'es');
    final englishGenus = _localizedEntry(genera, 'genus', 'en');
    final flavorEntries = json['flavor_text_entries'] as List<dynamic>;
    final spanishFlavor = _localizedEntry(flavorEntries, 'flavor_text', 'es');
    final englishFlavor = _localizedEntry(flavorEntries, 'flavor_text', 'en');
    final evolutionChain =
        json['evolution_chain'] as Map<String, dynamic>;

    return PokemonSpecies(
      category: _cleanText(spanishGenus ?? englishGenus ?? 'Desconocida'),
      description: _cleanText(
        spanishFlavor ??
            englishFlavor ??
            'No hay una descripción disponible para este Pokémon.',
      ),
      evolutionChainUrl: evolutionChain['url'] as String,
    );
  }
}

class PokemonEvolution {
  const PokemonEvolution({required this.id, required this.name});

  final int id;
  final String name;

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}

String? _localizedEntry(
  List<dynamic> entries,
  String valueKey,
  String language,
) {
  for (final entry in entries) {
    final map = entry as Map<String, dynamic>;
    final languageData = map['language'] as Map<String, dynamic>;
    if (languageData['name'] == language) {
      return map[valueKey] as String?;
    }
  }
  return null;
}

String _cleanText(String value) => value.replaceAll(RegExp(r'[\n\f]+'), ' ');
