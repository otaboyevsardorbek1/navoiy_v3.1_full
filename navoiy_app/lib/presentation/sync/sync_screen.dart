// lib/presentation/sync/sync_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/sync_bloc.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/utils/settings_service.dart';
import '../../data/datasources/local/database_helper.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncManifest? _manifest;
  bool _loadingManifest = false;
  Map<String, int> _localVersions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final versions = await _getLocalVersions();
    if (mounted) setState(() => _localVersions = versions);

    if (!SettingsService.instance.isOfflineMode) {
      if (mounted) setState(() => _loadingManifest = true);
      final manifest = await SyncManager.instance.fetchManifest();
      if (mounted) setState(() { _manifest = manifest; _loadingManifest = false; });
    }
  }

  Future<Map<String, int>> _getLocalVersions() async {
    final asarlar = await DatabaseHelper.instance.getAsarlar();
    return {for (final a in asarlar) if (a.slug != null) a.slug!: a.version ?? 0};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = SettingsService.instance.isOfflineMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinxronlash'),
        actions: [
          // Kontent boshqaruvi tugmasi
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Kontent boshqaruvi',
            onPressed: () => context.push('/content-manager'),
          ),
          if (!isOffline)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: BlocConsumer<SyncBloc, SyncState>(
        listener: (ctx, state) {
          if (state is SyncSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('✅ ${state.result.downloaded} ta yangilandi, ${state.result.skipped} ta o\'tkazildi'),
              backgroundColor: Colors.green,
            ));
            _loadData();
          } else if (state is SyncFailure) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: theme.colorScheme.error,
            ));
          }
        },
        builder: (ctx, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusCard(theme, state, isOffline),
              const SizedBox(height: 16),

              if (state is SyncInProgress) ...[
                _buildProgressCard(state, theme),
                const SizedBox(height: 16),
              ],

              // Kontent boshqaruvi kartasi
              Card(
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Kontent boshqaruvi'),
                  subtitle: const Text('Yuklab olingan fayllarni ko\'rish va o\'chirish'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/content-manager'),
                ),
              ),
              const SizedBox(height: 12),

              if (!isOffline) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync_alt, size: 18),
                        label: const Text('Delta sync'),
                        onPressed: (state is SyncInProgress) ? null : () =>
                            ctx.read<SyncBloc>().add(const SyncDeltaRequested()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: const Text("To'liq sync"),
                        onPressed: (state is SyncInProgress) ? null : () =>
                            ctx.read<SyncBloc>().add(const SyncFullRequested()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Asarlar ro'yxati
              if (isOffline)
                _buildOfflineInfo(theme)
              else if (_loadingManifest)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_manifest != null)
                _buildManifestList(theme, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, SyncState state, bool isOffline) {
    Color color; IconData icon; String title; String subtitle;
    if (isOffline) {
      color = Colors.orange; icon = Icons.wifi_off_outlined;
      title = 'Offline rejim'; subtitle = "Mahalliy ma'lumotlar ishlatilmoqda";
    } else if (state is SyncInProgress) {
      color = theme.colorScheme.primary; icon = Icons.sync;
      title = 'Sinxronlanmoqda...'; subtitle = state.progress.phase;
    } else if (state is SyncSuccess) {
      color = Colors.green; icon = Icons.check_circle_outline;
      title = 'Sinxronlash tugadi'; subtitle = '${state.result.downloaded} ta yangilandi';
    } else {
      color = Colors.green; icon = Icons.cloud_done_outlined;
      title = 'Online rejim'; subtitle = 'Server bilan ulangan';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(SyncInProgress state, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(state.progress.currentItem,
                    style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                Text('${state.progress.current}/${state.progress.total}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: state.progress.fraction),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: theme.dividerColor,
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(state.progress.phase, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestList(ThemeData theme, SyncState state) {
    final manifest = _manifest!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('ASARLAR', style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.primary)),
            const Spacer(),
            Text('${manifest.asarlar.length} ta', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ...manifest.asarlar.map((item) {
          final localVer = _localVersions[item.slug] ?? 0;
          final needsUpdate = item.version > localVer;
          final isDownloaded = localVer > 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDownloaded
                      ? (needsUpdate ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.12))
                      : theme.dividerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDownloaded ? (needsUpdate ? Icons.update : Icons.check) : Icons.cloud_download_outlined,
                  size: 18,
                  color: isDownloaded ? (needsUpdate ? Colors.orange : Colors.green)
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              title: Text(item.slug, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                isDownloaded
                    ? (needsUpdate ? 'v$localVer → v${item.version}' : 'Yangi (v${item.version})')
                    : 'Yuklanmagan',
                style: TextStyle(fontSize: 11, color: needsUpdate ? Colors.orange
                    : theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
              trailing: (needsUpdate || !isDownloaded)
                  ? (state is SyncInProgress
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.download, size: 18),
                          onPressed: () => context.read<SyncBloc>().add(SyncAsarRequested(item.slug)),
                        ))
                  : const Icon(Icons.check_circle, color: Colors.green, size: 18),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOfflineInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yuklab olingan asarlar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._localVersions.entries.where((e) => e.value > 0).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(e.key, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text('v${e.value}', style: theme.textTheme.bodySmall),
                ],
              ),
            )),
            if (_localVersions.values.every((v) => v == 0))
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.green.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text('6 ta asar ilova ichida mavjud', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text("Offline rejimda ham to'liq o'qish mumkin",
                        style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
