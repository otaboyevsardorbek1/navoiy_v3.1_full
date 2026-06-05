// lib/presentation/sherlar/sherlar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'bloc/sherlar_bloc.dart';
import '../../data/models/models.dart';
import '../widgets/category_chip_bar.dart';

class SherlarScreen extends StatefulWidget {
  const SherlarScreen({super.key});

  @override
  State<SherlarScreen> createState() => _SherlarScreenState();
}

class _SherlarScreenState extends State<SherlarScreen> {
  String? _activeType;
  final _types = ['Barchasi', 'gazal', 'ruboiy', "qit'a", 'hikmat', 'nazm'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<SherlarBloc>().add(SherlarLoadRequested(type: _activeType));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("She'rlar va G'azallar")),
      body: Column(
        children: [
          CategoryChipBar(
            categories: _types,
            activeCategory: _activeType ?? 'Barchasi',
            onSelected: (t) {
              setState(() => _activeType = t == 'Barchasi' ? null : t);
              _load();
            },
          ),
          Expanded(
            child: BlocBuilder<SherlarBloc, SherlarState>(
              builder: (ctx, state) {
                if (state is SherlarLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SherlarError) {
                  return Center(child: Text(state.message));
                }
                if (state is SherlarLoaded) {
                  if (state.sherlar.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.format_quote, size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.25)),
                          const SizedBox(height: 12),
                          Text("She'rlar topilmadi", style: theme.textTheme.titleMedium),
                        ],
                      ),
                    );
                  }
                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.sherlar.length,
                      itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 380),
                        child: SlideAnimation(
                          verticalOffset: 30,
                          child: FadeInAnimation(
                            child: _SherCard(
                              sher: state.sherlar[i],
                              onFavorite: (v) => ctx.read<SherlarBloc>()
                                  .add(SherFavoriteToggled(state.sherlar[i].id!, v)),
                              onDetail: () => _showSherDetail(context, state.sherlar[i]),
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

  void _showSherDetail(BuildContext context, SherModel sher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SherDetailSheet(sher: sher),
    );
  }
}

// ─── She'r Card ───────────────────────────────────────────────────────────────

class _SherCard extends StatefulWidget {
  final SherModel sher;
  final ValueChanged<bool> onFavorite;
  final VoidCallback onDetail;
  const _SherCard({required this.sher, required this.onFavorite, required this.onDetail});

  @override
  State<_SherCard> createState() => _SherCardState();
}

class _SherCardState extends State<_SherCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(widget.sher.type, theme);
    final lines = widget.sher.content.split('\n');
    final previewLines = lines.take(4).join('\n');
    final hasMore = lines.length > 4;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_typeLabel(widget.sher.type),
                      style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                // To'liq ko'rish
                IconButton(
                  icon: Icon(Icons.open_in_new, size: 17,
                      color: theme.colorScheme.onSurface.withOpacity(0.45)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "To'liq ko'rish",
                  onPressed: widget.onDetail,
                ),
                const SizedBox(width: 10),
                // Copy
                IconButton(
                  icon: Icon(Icons.copy_outlined, size: 17,
                      color: theme.colorScheme.onSurface.withOpacity(0.45)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.sher.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nusxalandi'), duration: Duration(seconds: 1)));
                  },
                ),
                const SizedBox(width: 10),
                // Favorite
                GestureDetector(
                  onTap: () => widget.onFavorite(!widget.sher.isFavorite),
                  child: Icon(
                    widget.sher.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.sher.isFavorite ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.35),
                    size: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(widget.sher.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            // Content with left border
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2.5,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _expanded ? widget.sher.content : previewLines,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic, height: 1.9),
                    ),
                  ),
                ],
              ),
            ),

            // Expand/collapse
            if (hasMore) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Text(
                      _expanded ? "Yig'ish" : "To'liq ko'rish",
                      style: TextStyle(color: typeColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: typeColor, size: 18),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            // Footer
            Row(
              children: [
                Icon(Icons.favorite, size: 13, color: Colors.red.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text('${widget.sher.likeCount}', style: theme.textTheme.bodySmall),
                if (widget.sher.asarTitle != null) ...[
                  const Spacer(),
                  Icon(Icons.auto_stories_outlined, size: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.35)),
                  const SizedBox(width: 4),
                  Text(widget.sher.asarTitle!, style: theme.textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String t, ThemeData theme) {
    switch (t) {
      case 'gazal': return const Color(0xFF1A56DB);
      case 'ruboiy': return const Color(0xFF9B59B6);
      case 'hikmat': return const Color(0xFFD4A843);
      case "qit'a": return const Color(0xFF27AE60);
      default: return theme.colorScheme.primary;
    }
  }

  String _typeLabel(String t) {
    const m = {'gazal': "G'azal", 'ruboiy': 'Ruboiy', 'hikmat': 'Hikmat', "qit'a": "Qit'a", 'nazm': 'Nazm'};
    return m[t] ?? t;
  }
}

// ─── She'r detail bottom sheet ────────────────────────────────────────────────

class _SherDetailSheet extends StatelessWidget {
  final SherModel sher;
  const _SherDetailSheet({required this.sher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color typeColor;
    switch (sher.type) {
      case 'gazal': typeColor = const Color(0xFF1A56DB); break;
      case 'ruboiy': typeColor = const Color(0xFF9B59B6); break;
      case 'hikmat': typeColor = const Color(0xFFD4A843); break;
      default: typeColor = theme.colorScheme.primary;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_typeLabel(sher.type),
                        style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sher.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nusxalandi'), duration: Duration(seconds: 1)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sher.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    if (sher.description != null)
                      Text(sher.description!,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: typeColor, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(sher.content,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic, height: 2.0)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.red.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text('${sher.likeCount} yoqtirish', style: theme.textTheme.bodySmall),
                        if (sher.asarTitle != null) ...[
                          const Spacer(),
                          Icon(Icons.auto_stories_outlined, size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(sher.asarTitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String t) {
    const m = {'gazal': "G'azal", 'ruboiy': 'Ruboiy', 'hikmat': 'Hikmat', "qit'a": "Qit'a"};
    return m[t] ?? t;
  }
}
