import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/poke_api_service.dart';

const _green = Color(0xFF236B45);
const _ink = Color(0xFF183A2A);

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  static const _pageSize = 30;

  final _api = PokeApiService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final List<PokemonEntry> _pokemon = [];
  bool _loading = false;
  bool _hasNextPage = true;
  Object? _loadError;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_loading || !_hasNextPage) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final page = await _api.getPokemonPage(
        offset: _pokemon.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _pokemon.addAll(page.entries);
        _totalCount = page.totalCount;
        _hasNextPage = page.hasNextPage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PokemonEntry> get _visiblePokemon {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _pokemon;
    return _pokemon.where((pokemon) {
      return pokemon.name.contains(query) || pokemon.id.toString() == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePokemon = _visiblePokemon;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.catching_pokemon_rounded,
                                color: Colors.white,
                                size: 31,
                              ),
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'POKÉDEX',
                                    style: TextStyle(
                                      color: _ink,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Explora el mundo Pokémon',
                                    style: TextStyle(
                                      color: Color(0xFF68746A),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_totalCount > 0)
                              Text(
                                '${_pokemon.length} / $_totalCount',
                                style: const TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o número...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFFFFEFA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_pokemon.isEmpty && _loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadingView(),
              )
            else if (_pokemon.isEmpty && _loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadErrorView(onRetry: _loadNextPage),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width > 850
                        ? 5
                        : width > 620
                        ? 4
                        : width > 390
                        ? 3
                        : 2;
                    return SliverGrid.builder(
                      itemCount: visiblePokemon.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.79,
                      ),
                      itemBuilder: (context, index) {
                        final pokemon = visiblePokemon[index];
                        return _PokemonTile(
                          pokemon: pokemon,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PokemonDetailScreen(
                                entry: pokemon,
                                api: _api,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (visiblePokemon.isEmpty && _pokemon.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No hay resultados en los Pokémon cargados. Sigue desplazándote para cargar más.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
                  ),
                )
              else if (_loadError != null)
                SliverToBoxAdapter(
                  child: _PaginationError(onRetry: _loadNextPage),
                )
              else if (_hasNextPage)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: Text(
                        'Desliza hacia abajo para cargar más',
                        style: TextStyle(color: Color(0xFF68746A)),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PokemonTile extends StatelessWidget {
  const _PokemonTile({required this.pokemon, required this.onTap});

  final PokemonEntry pokemon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _cardColorsForId(pokemon.id);
    final accent = colors.first;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.98),
                colors.last.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${pokemon.id.toString().padLeft(3, '0')}',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.08),
                        ),
                      ),
                      Hero(
                        tag: 'pokemon-art-${pokemon.id}',
                        child: Image.network(
                          pokemon.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.catching_pokemon_rounded,
                            size: 60,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _capitalize(pokemon.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    required this.entry,
    required this.api,
    super.key,
  });

  final PokemonEntry entry;
  final PokeApiService api;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late Future<PokemonDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = widget.api.getPokemonDetails(widget.entry.id);
  }

  void _retry() {
    setState(() {
      _details = widget.api.getPokemonDetails(widget.entry.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<PokemonDetails>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }
            if (snapshot.hasError) {
              return _LoadErrorView(onRetry: _retry);
            }
            return _PokemonDetailContent(
              details: snapshot.data!,
              api: widget.api,
            );
          },
        ),
      ),
    );
  }
}

class _PokemonDetailContent extends StatelessWidget {
  const _PokemonDetailContent({required this.details, required this.api});

  final PokemonDetails details;
  final PokeApiService api;

  @override
  Widget build(BuildContext context) {
    final pokemon = details.pokemon;
    final color = _typeColor(pokemon.types.first);
    final secondaryColor = pokemon.types.length > 1
        ? _typeColor(pokemon.types[1])
        : Color.lerp(color, Colors.white, 0.36)!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332C322C),
                        blurRadius: 15,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailHeader(
                        pokemon: pokemon,
                        color: color,
                        secondaryColor: secondaryColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MainArtwork(pokemon: pokemon, color: color),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: pokemon.types
                                  .map(
                                    (type) => _TypeBadge(
                                      label: _translateType(type),
                                      color: _typeColor(type),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'INFORMACIÓN'),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoCard(
                                    label: 'ALTURA',
                                    value:
                                        '${(pokemon.height / 10).toStringAsFixed(1)} m',
                                    icon: Icons.height_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InfoCard(
                                    label: 'PESO',
                                    value:
                                        '${(pokemon.weight / 10).toStringAsFixed(1)} kg',
                                    icon: Icons.monitor_weight_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _InfoCard(
                              label: 'CATEGORÍA',
                              value: details.species.category,
                              icon: Icons.local_florist_outlined,
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'HABILIDADES'),
                            const SizedBox(height: 11),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: pokemon.abilities.map((ability) {
                                final name = _translateAbility(ability.name);
                                return Chip(
                                  avatar: Icon(
                                    ability.isHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.auto_awesome_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    ability.isHidden ? '$name (oculta)' : name,
                                  ),
                                  backgroundColor: const Color(0xFFEAF1E5),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'DESCRIPCIÓN'),
                            const SizedBox(height: 11),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E8F6),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: const Color(0xFFDCCCE9),
                                ),
                              ),
                              child: Text(
                                details.species.description,
                                style: const TextStyle(
                                  color: Color(0xFF49385A),
                                  height: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'ESTADÍSTICAS BASE'),
                            const SizedBox(height: 13),
                            ...pokemon.stats.map(
                              (stat) => _StatRow(stat: stat),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'MOVIMIENTOS'),
                            const SizedBox(height: 11),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: pokemon.moves
                                  .map(
                                    (move) => Chip(
                                      label: Text(_translateMove(move)),
                                      backgroundColor: const Color(0xFFF1F2EC),
                                      side: BorderSide.none,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 22),
                            const _SectionTitle(title: 'LÍNEA EVOLUTIVA'),
                            const SizedBox(height: 10),
                            _EvolutionRow(
                              evolutions: details.evolutions,
                              currentId: pokemon.id,
                              api: api,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        child: const Text(
                          'Información y sprites proporcionados por PokéAPI',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.pokemon,
    required this.color,
    required this.secondaryColor,
  });

  final Pokemon pokemon;
  final Color color;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, secondaryColor],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 15),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver a la Pokédex',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N.º ${pokemon.id.toString().padLeft(3, '0')} · POKÉDEX',
                  style: const TextStyle(
                    color: Color(0xFFE0EBDD),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _capitalize(pokemon.name).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainArtwork extends StatelessWidget {
  const _MainArtwork({required this.pokemon, required this.color});

  final Pokemon pokemon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            Color.lerp(color, Colors.white, 0.78)!,
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.catching_pokemon_rounded,
            size: 190,
            color: color.withValues(alpha: 0.08),
          ),
          Hero(
            tag: 'pokemon-art-${pokemon.id}',
            child: Image.network(
              pokemon.imageUrl,
              height: 235,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator(color: _green);
              },
              errorBuilder: (_, _, _) =>
                  Icon(Icons.catching_pokemon_rounded, size: 110, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.16)!],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(label), size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFD9D8CE))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF365944),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFD9D8CE))),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4D8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF69756B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final PokemonStat stat;

  static const _statNames = {
    'hp': 'PS',
    'attack': 'ATAQUE',
    'defense': 'DEFENSA',
    'special-attack': 'AT. ESP.',
    'special-defense': 'DEF. ESP.',
    'speed': 'VELOCIDAD',
  };

  @override
  Widget build(BuildContext context) {
    final name = _statNames[stat.name] ?? stat.name.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF526357),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${stat.value}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (stat.value / 160).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                final color = stat.value >= 100
                    ? const Color(0xFF54A777)
                    : stat.value >= 60
                    ? const Color(0xFFE1A946)
                    : const Color(0xFFE17A70);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE7E9E0),
                    color: color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionRow extends StatelessWidget {
  const _EvolutionRow({
    required this.evolutions,
    required this.currentId,
    required this.api,
  });

  final List<PokemonEvolution> evolutions;
  final int currentId;
  final PokeApiService api;

  @override
  Widget build(BuildContext context) {
    if (evolutions.isEmpty) {
      return const Text(
        'No hay información de evoluciones disponible.',
        textAlign: TextAlign.center,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < evolutions.length; index++) ...[
            if (index > 0)
              SizedBox(
                width: 34,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_green.withValues(alpha: 0.25), _green],
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _green,
                    ),
                  ],
                ),
              ),
            _EvolutionTile(
              evolution: evolutions[index],
              isCurrent: evolutions[index].id == currentId,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PokemonDetailScreen(
                    entry: PokemonEntry(
                      id: evolutions[index].id,
                      name: evolutions[index].name,
                      url:
                          'https://pokeapi.co/api/v2/pokemon/${evolutions[index].id}/',
                    ),
                    api: api,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvolutionTile extends StatelessWidget {
  const _EvolutionTile({
    required this.evolution,
    required this.isCurrent,
    required this.onTap,
  });

  final PokemonEvolution evolution;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFFE8F1DB)
                  : Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isCurrent
                    ? _green.withValues(alpha: 0.42)
                    : const Color(0xFFE5E6DF),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF1E8),
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      evolution.imageUrl,
                      width: 62,
                      height: 62,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.catching_pokemon_rounded,
                        size: 48,
                        color: _green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _capitalize(evolution.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    '#${evolution.id.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF758176),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _green),
          SizedBox(height: 14),
          Text('Cargando datos desde PokéAPI...'),
        ],
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 14),
            const Text(
              'No fue posible cargar los datos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa tu conexión a internet e inténtalo de nuevo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      child: Column(
        children: [
          const Text('No se pudieron cargar más Pokémon.'),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _translateType(String type) {
  const translations = {
    'bug': 'Bicho',
    'dark': 'Siniestro',
    'dragon': 'Dragón',
    'electric': 'Eléctrico',
    'fairy': 'Hada',
    'fighting': 'Lucha',
    'fire': 'Fuego',
    'flying': 'Volador',
    'ghost': 'Fantasma',
    'grass': 'Planta',
    'ground': 'Tierra',
    'ice': 'Hielo',
    'normal': 'Normal',
    'poison': 'Veneno',
    'psychic': 'Psíquico',
    'rock': 'Roca',
    'steel': 'Acero',
    'water': 'Agua',
  };
  return translations[type] ?? _capitalize(type);
}

Color _typeColor(String type) {
  const colors = {
    'bug': Color(0xFF8A9A25),
    'dark': Color(0xFF51443B),
    'dragon': Color(0xFF6245C5),
    'electric': Color(0xFFC49B00),
    'fairy': Color(0xFFC45E90),
    'fighting': Color(0xFFB74335),
    'fire': Color(0xFFE66D32),
    'flying': Color(0xFF7386C5),
    'ghost': Color(0xFF705A9A),
    'grass': Color(0xFF52984A),
    'ground': Color(0xFFB18D44),
    'ice': Color(0xFF5CABB1),
    'normal': Color(0xFF858578),
    'poison': Color(0xFF9650A0),
    'psychic': Color(0xFFD14C70),
    'rock': Color(0xFF958044),
    'steel': Color(0xFF777F91),
    'water': Color(0xFF4387C5),
  };
  return colors[type] ?? _green;
}

IconData _typeIcon(String type) {
  return switch (type) {
    'Planta' => Icons.eco_rounded,
    'Veneno' => Icons.science_rounded,
    'Fuego' => Icons.local_fire_department_rounded,
    'Agua' => Icons.water_drop_rounded,
    'Eléctrico' => Icons.bolt_rounded,
    'Hielo' => Icons.ac_unit_rounded,
    'Roca' || 'Tierra' => Icons.landscape_rounded,
    'Volador' => Icons.air_rounded,
    'Bicho' => Icons.pest_control_rounded,
    'Fantasma' => Icons.visibility_off_rounded,
    'Hada' || 'Psíquico' => Icons.auto_awesome_rounded,
    'Lucha' => Icons.sports_martial_arts_rounded,
    'Acero' => Icons.shield_rounded,
    'Dragón' => Icons.token_rounded,
    _ => Icons.circle_outlined,
  };
}

List<Color> _cardColorsForId(int id) {
  const palette = [
    Color(0xFF78A875),
    Color(0xFFE59A74),
    Color(0xFF78A9C7),
    Color(0xFFB28AC4),
    Color(0xFFE1B85D),
    Color(0xFF719B91),
  ];
  return [palette[(id - 1) % palette.length], const Color(0xFFFFFEFA)];
}

String _translateAbility(String ability) {
  const translations = {
    'overgrow': 'Espesura',
    'chlorophyll': 'Clorofila',
    'blaze': 'Mar llamas',
    'torrent': 'Torrente',
    'intimidate': 'Intimidación',
    'levitate': 'Levitación',
    'static': 'Elec. estática',
    'pressure': 'Presión',
  };
  return translations[ability] ?? _capitalize(ability.replaceAll('-', ' '));
}

String _translateMove(String move) {
  const translations = {
    'tackle': 'Placaje',
    'growl': 'Gruñido',
    'vine-whip': 'Látigo cepa',
    'razor-leaf': 'Hoja afilada',
    'solar-beam': 'Rayo solar',
    'poison-powder': 'Polvo veneno',
    'sleep-powder': 'Somnífero',
    'seed-bomb': 'Bomba germen',
    'ember': 'Ascuas',
    'water-gun': 'Pistola agua',
  };
  return translations[move] ?? _capitalize(move.replaceAll('-', ' '));
}
