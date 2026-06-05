// lib/presentation/asarlar/asar_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/asarlar_bloc.dart';
import '../../data/models/models.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/bundled_content_service.dart';
import '../../core/utils/settings_service.dart';

class AsarDetailScreen extends StatefulWidget {
  final int id;
  const AsarDetailScreen({super.key, required this.id});

  @override
  State<AsarDetailScreen> createState() => _AsarDetailScreenState();
}

class _AsarDetailScreenState extends State<AsarDetailScreen> {
  double _fontSize = 16.0;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    context.read<AsarlarBloc>().add(AsarDetailRequested(widget.id));
  }

  Future<void> _downloadAsar(AsarModel asar) async {
    if (asar.slug == null) return;
    setState(() => _downloading = true);
    final ok = await SyncManager.instance.downloadAsar(
      asar.slug!,
      expectedVersion: asar.version,
      expectedChecksum: asar.checksum,
    );
    setState(() => _downloading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Yuklab olindi — offline o\'qish mumkin' : '❌ Yuklab bo\'lmadi'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) context.read<AsarlarBloc>().add(AsarDetailRequested(widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BlocBuilder<AsarlarBloc, AsarlarState>(
        builder: (context, state) {
          if (state is AsarlarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AsarDetailLoaded) {
            return _buildDetail(state.asar, theme);
          }
          return const Center(child: Text('Topilmadi'));
        },
      ),
    );
  }

  Widget _buildDetail(AsarModel asar, ThemeData theme) {
    final isDownloaded = asar.isDownloaded;
    final isOffline = SettingsService.instance.isOfflineMode;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(asar.titleUz, style: const TextStyle(fontSize: 15)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
              ),
              child: Center(
                child: Icon(Icons.auto_stories, size: 80, color: Colors.white.withOpacity(0.25)),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(asar.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: asar.isFavorite ? Colors.red : Colors.white),
              onPressed: () {
                context.read<AsarlarBloc>().add(AsarFavoriteToggled(asar.id!, !asar.isFavorite));
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.text_fields, color: Colors.white),
              onSelected: (v) {
                setState(() {
                  switch (v) {
                    case 'small': _fontSize = 13; break;
                    case 'medium': _fontSize = 16; break;
                    case 'large': _fontSize = 20; break;
                    case 'xlarge': _fontSize = 24; break;
                  }
                });
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'small', child: Text('Kichik (13px)')),
                PopupMenuItem(value: 'medium', child: Text("O'rtacha (16px)")),
                PopupMenuItem(value: 'large', child: Text('Katta (20px)')),
                PopupMenuItem(value: 'xlarge', child: Text('Juda katta (24px)')),
              ],
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Status badges ──────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.category_outlined, label: _catLabel(asar.category), theme: theme),
                    if (asar.year != null)
                      _InfoChip(icon: Icons.calendar_today_outlined, label: '${asar.year}-yil', theme: theme),
                    _InfoChip(icon: Icons.remove_red_eye_outlined, label: '${asar.readCount} o\'qilgan', theme: theme),
                    _InfoChip(
                      icon: Icons.book_outlined,
                      label: '${asar.totalPages} sahifa',
                      theme: theme,
                    ),
                    // Download status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDownloaded
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDownloaded
                              ? Colors.green.withOpacity(0.4)
                              : Colors.orange.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDownloaded ? Icons.offline_pin : Icons.cloud_outlined,
                            size: 13,
                            color: isDownloaded ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDownloaded ? 'Offline mavjud' : 'Faqat online',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDownloaded ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (asar.description != null) ...[
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                            color: theme.colorScheme.primary.withOpacity(0.06),
                            child: Text(
                              asar.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ─── Action buttons ─────────────────────────────────────────
                Row(
                  children: [
                    // O'qish tugmasi
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text("O'qishni boshlash"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => context.push('/asarlar/${asar.id}/read'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Yuklab olish tugmasi (faqat online va yuklanmagan bo'lsa)
                    if (!isDownloaded && !isOffline)
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          icon: _downloading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download_outlined, size: 18),
                          label: Text(_downloading ? 'Yuklanmoqda' : 'Offline saqlash'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _downloading ? null : () => _downloadAsar(asar),
                        ),
                      ),
                    if (isDownloaded)
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.offline_pin, color: Colors.green, size: 18),
                          label: const Text('Saqlangan', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.green),
                          ),
                          onPressed: null,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Versiya info
                if (asar.version > 0)
                  Center(
                    child: Text(
                      'Versiya: ${asar.version} • ${asar.totalPages} qism',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.4),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Tags
                if (asar.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: asar.tags
                        .map((t) => Chip(
                              label: Text('#$t'),
                              labelStyle: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _catLabel(String cat) {
    const map = {
      'doston': 'Doston',
      'gazal': "G'azal",
      'ruboiy': 'Ruboiy',
      'ilmiy': 'Ilmiy',
      'devonlar': 'Devon',
    };
    return map[cat] ?? cat;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _InfoChip({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
