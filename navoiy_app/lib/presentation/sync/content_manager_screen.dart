// lib/presentation/sync/content_manager_screen.dart
import 'package:flutter/material.dart';
import '../../core/sync/bundled_content_service.dart';
import '../../core/sync/sync_manager.dart';
import '../../data/datasources/local/database_helper.dart';

class ContentManagerScreen extends StatefulWidget {
  const ContentManagerScreen({super.key});

  @override
  State<ContentManagerScreen> createState() => _ContentManagerScreenState();
}

class _ContentManagerScreenState extends State<ContentManagerScreen> {
  Map<String, int> _storageUsage = {};
  List<Map<String, dynamic>> _asarlarMeta = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final usage = await BundledContentService.instance.getStorageUsage();
    final meta = await BundledContentService.instance.getDefaultAsarlarMeta();
    // DB versiyalarini ham olish
    final asarlar = await DatabaseHelper.instance.getAsarlar();
    final versionMap = {for (final a in asarlar) a.slug ?? '': a.version ?? 0};

    final enriched = meta.map((m) {
      final slug = m['slug'] as String;
      return {
        ...m,
        'local_version': versionMap[slug] ?? 0,
        'file_size_local': usage['$slug'] ?? usage[slug] ?? 0,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _storageUsage = usage;
        _asarlarMeta = enriched;
        _loading = false;
      });
    }
  }

  Future<void> _deleteContent(String slug, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('"$title" kontentini o\'chirasizmi?\nKeyinroq qayta yuklab olishingiz mumkin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await BundledContentService.instance.deleteAsarContent(slug);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ O\'chirildi' : '❌ Xatolik'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      _loadData();
    }
  }

  Future<void> _downloadContent(String slug, int serverVersion) async {
    final ok = await SyncManager.instance.downloadAsar(
      slug,
      expectedVersion: serverVersion,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Yuklab olindi' : '❌ Yuklab bo\'lmadi'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      _loadData();
    }
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalUsed = _storageUsage.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontent boshqaruvi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Storage summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storage_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Xotira holati', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatTile(label: "Asarlar", value: '${_asarlarMeta.length} ta', theme: theme),
                            _StatTile(label: "Jami hajm", value: _formatSize(totalUsed), theme: theme),
                            _StatTile(
                              label: "Yuklanganlar",
                              value: '${_asarlarMeta.where((m) => (m['local_version'] ?? 0) > 0).length} ta',
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Barcha asarlar ilova ichida mavjud. Online holatda yangi versiyalarni yuklab olishingiz mumkin.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'ASARLAR',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                ..._asarlarMeta.map((meta) => _AsarContentTile(
                      meta: meta,
                      formatSize: _formatSize,
                      onDelete: () => _deleteContent(
                        meta['slug'] as String,
                        meta['title_uz'] as String,
                      ),
                      onDownload: () => _downloadContent(
                        meta['slug'] as String,
                        meta['version'] as int? ?? 1,
                      ),
                    )),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _StatTile({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _AsarContentTile extends StatelessWidget {
  final Map<String, dynamic> meta;
  final String Function(int) formatSize;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _AsarContentTile({
    required this.meta,
    required this.formatSize,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localVersion = meta['local_version'] as int? ?? 0;
    final serverVersion = meta['version'] as int? ?? 1;
    final fileSize = meta['file_size_local'] as int? ?? (meta['file_size_bytes'] as int? ?? 0);
    final totalPages = meta['total_pages'] as int? ?? 0;
    final isDownloaded = localVersion > 0;
    final hasUpdate = serverVersion > localVersion && isDownloaded;
    final isBundled = meta['is_bundled'] == true;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isDownloaded) {
      statusColor = Colors.orange;
      statusIcon = Icons.cloud_download_outlined;
      statusText = 'Yuklanmagan';
    } else if (hasUpdate) {
      statusColor = Colors.blue;
      statusIcon = Icons.update;
      statusText = 'Yangilash bor';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Yangi (v$localVersion)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meta['title_uz'] as String,
                          style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${meta['year']} • ${totalPages} sahifa • ${formatSize(fileSize)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
                if (isBundled)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Built-in',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                const Spacer(),
                // Download/Update button
                if (!isDownloaded || hasUpdate)
                  TextButton.icon(
                    icon: Icon(hasUpdate ? Icons.update : Icons.download, size: 16),
                    label: Text(hasUpdate ? 'Yangilash' : 'Yuklash', style: const TextStyle(fontSize: 13)),
                    onPressed: onDownload,
                  ),
                // Delete button (faqat yuklanganlar uchun)
                if (isDownloaded)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                    tooltip: 'O\'chirish',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
