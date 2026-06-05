// lib/presentation/asarlar/asarlar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'bloc/asarlar_bloc.dart';
import '../../data/models/models.dart';
import '../widgets/category_chip_bar.dart';

class AsarlarScreen extends StatefulWidget {
  const AsarlarScreen({super.key});

  @override
  State<AsarlarScreen> createState() => _AsarlarScreenState();
}

class _AsarlarScreenState extends State<AsarlarScreen> {
  String? _activeCategory;
  String? _search;
  final _categories = ['Barchasi', 'doston', 'devonlar', 'ilmiy', 'boshqa'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<AsarlarBloc>().add(
          AsarlarLoadRequested(category: _activeCategory, search: _search));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asarlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryChipBar(
            categories: _categories,
            activeCategory: _activeCategory ?? 'Barchasi',
            onSelected: (cat) {
              setState(() => _activeCategory = cat == 'Barchasi' ? null : cat);
              _load();
            },
          ),
          if (_search != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.search, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('"$_search"', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () { setState(() => _search = null); _load(); },
                    child: const Text('Tozalash'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<AsarlarBloc, AsarlarState>(
              builder: (context, state) {
                if (state is AsarlarLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AsarlarError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Qayta')),
                      ],
                    ),
                  );
                }
                if (state is AsarlarLoaded) {
                  if (state.asarlar.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.25)),
                          const SizedBox(height: 12),
                          Text('Hech narsa topilmadi', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    );
                  }
                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.asarlar.length,
                      itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 380),
                        child: SlideAnimation(
                          verticalOffset: 36,
                          child: FadeInAnimation(
                            child: _AsarCard(
                              asar: state.asarlar[i],
                              onTap: () => context.push('/asarlar/${state.asarlar[i].id}'),
                              onRead: () => context.push('/asarlar/${state.asarlar[i].id}/read'),
                              onFavorite: (v) => context.read<AsarlarBloc>()
                                  .add(AsarFavoriteToggled(state.asarlar[i].id!, v)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) async {
    final result = await showSearch<String>(
      context: context,
      delegate: _AsarSearchDelegate(),
    );
    if (result != null) {
      setState(() => _search = result.isEmpty ? null : result);
      _load();
    }
  }
}

// ─── Asar Card ────────────────────────────────────────────────────────────────

class _AsarCard extends StatelessWidget {
  final AsarModel asar;
  final VoidCallback onTap;
  final VoidCallback onRead;
  final ValueChanged<bool> onFavorite;

  const _AsarCard({
    required this.asar,
    required this.onTap,
    required this.onRead,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _catColor(asar.category, theme);
    final isDownloaded = asar.isDownloaded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(_catIcon(asar.category), color: catColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(asar.titleUz,
                                  style: theme.textTheme.titleMedium, maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            // Favorite
                            GestureDetector(
                              onTap: () => onFavorite(!asar.isFavorite),
                              child: Icon(
                                asar.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: asar.isFavorite ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.35),
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                        if (asar.description != null) ...[
                          const SizedBox(height: 3),
                          Text(asar.description!, style: theme.textTheme.bodySmall,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom row: tags + download status + read button
              Row(
                children: [
                  // Category tag
                  _Tag(label: _catLabel(asar.category), color: catColor),
                  if (asar.year != null) ...[
                    const SizedBox(width: 6),
                    _Tag(label: '${asar.year}', color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ],
                  const SizedBox(width: 6),
                  // Pages count
                  _Tag(
                    label: '${asar.totalPages} qism',
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                  const Spacer(),
                  // Download indicator
                  Icon(
                    isDownloaded ? Icons.offline_pin : Icons.cloud_outlined,
                    size: 15,
                    color: isDownloaded ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  // O'qish tugmasi
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onRead,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("O'qish"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'doston': return Icons.auto_stories;
      case 'devonlar': return Icons.format_quote;
      case 'ilmiy': return Icons.science_outlined;
      default: return Icons.book;
    }
  }

  Color _catColor(String cat, ThemeData t) {
    switch (cat) {
      case 'doston': return const Color(0xFF8B5E3C);
      case 'devonlar': return const Color(0xFF1A56DB);
      case 'ilmiy': return const Color(0xFF27AE60);
      default: return t.colorScheme.primary;
    }
  }

  String _catLabel(String cat) {
    const m = {'doston': 'Doston', 'devonlar': 'Devon', 'ilmiy': 'Ilmiy'};
    return m[cat] ?? cat;
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}

class _AsarSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Asar qidirish...';

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, query));

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      'Xamsa', 'Farhod va Shirin', 'Layli va Majnun',
      'Hayrat ul-abror', "Sab'ai sayyor", 'Saddi Iskandariy',
      'Badoiy ul-vasat',
    ].where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView(
      children: suggestions
          .map((s) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(s),
                onTap: () => close(context, s),
              ))
          .toList(),
    );
  }
}
