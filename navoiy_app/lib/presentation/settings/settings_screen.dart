// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/settings_service.dart';
import '../../core/network/auth_service.dart';
import '../../core/sync/bundled_content_service.dart';
import '../auth/bloc/auth_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlCtrl;
  bool _testingApi = false;
  String? _apiTestResult;
  Map<String, int> _storageUsage = {};

  @override
  void initState() {
    super.initState();
    _apiUrlCtrl = TextEditingController(text: SettingsService.instance.apiBaseUrl);
    _loadStorage();
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStorage() async {
    final usage = await BundledContentService.instance.getStorageUsage();
    if (mounted) setState(() => _storageUsage = usage);
  }

  int get _totalStorageBytes => _storageUsage.values.fold(0, (a, b) => a + b);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Dizayn uslubi ───────────────────────────────────────────
              _SectionHeader(title: 'Dizayn uslubi', theme: theme),
              const SizedBox(height: 8),
              _ThemeSelector(
                current: settings.themeName,
                onChanged: (t) => settings.setTheme(t),
              ),

              const SizedBox(height: 24),

              // ─── Ishlash rejimi ──────────────────────────────────────────
              _SectionHeader(title: 'Ishlash rejimi', theme: theme),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: AppConstants.modeOffline,
                      groupValue: settings.appMode,
                      title: const Text('Offline rejim'),
                      subtitle: const Text('Mahalliy ma\'lumotlar ishlatiladi'),
                      secondary: const Icon(Icons.wifi_off_outlined),
                      onChanged: (v) async { if (v != null) await settings.setAppMode(v); },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: AppConstants.modeOnline,
                      groupValue: settings.appMode,
                      title: const Text('Online rejim'),
                      subtitle: const Text('API server bilan ishlaydi'),
                      secondary: const Icon(Icons.wifi_outlined),
                      onChanged: (v) async { if (v != null) await settings.setAppMode(v); },
                    ),
                  ],
                ),
              ),

              // ─── API URL (faqat online rejimda) ──────────────────────────
              if (settings.appMode == AppConstants.modeOnline) ...[
                const SizedBox(height: 24),
                _SectionHeader(title: 'API Sozlamalari', theme: theme),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('API Manzili (Base URL)', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiUrlCtrl,
                          decoration: InputDecoration(
                            hintText: AppConstants.defaultApiBaseUrl,
                            helperText: 'Masalan: https://api.myserver.uz/v1',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: 'Standart qiymatga qaytarish',
                              onPressed: () => _apiUrlCtrl.text = AppConstants.defaultApiBaseUrl,
                            ),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: _testingApi
                                    ? const SizedBox(width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.network_check, size: 18),
                                label: Text(_testingApi ? 'Tekshirilmoqda...' : 'Test'),
                                onPressed: _testingApi ? null : _testApiConnection,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text('Saqlash'),
                                onPressed: () async {
                                  await settings.setApiBaseUrl(_apiUrlCtrl.text);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('API manzili saqlandi')));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_apiTestResult != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _apiTestResult!.startsWith('✅')
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_apiTestResult!,
                                style: TextStyle(
                                  color: _apiTestResult!.startsWith('✅') ? Colors.green : Colors.red,
                                  fontSize: 13)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ─── Kontent boshqaruvi ──────────────────────────────────────
              _SectionHeader(title: 'Kontent boshqaruvi', theme: theme),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.folder_outlined, color: theme.colorScheme.primary, size: 22),
                      ),
                      title: const Text('Yuklab olingan asarlar'),
                      subtitle: Text(
                        'Jami hajm: ${_formatSize(_totalStorageBytes)} • ${_storageUsage.length} ta fayl',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/content-manager'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.green, size: 22),
                      ),
                      title: const Text('Bundled asarlar'),
                      subtitle: const Text('6 ta asar ilova ichida mavjud'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Offline ✓',
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Hisob ──────────────────────────────────────────────────
              _SectionHeader(title: 'Hisob', theme: theme),
              const SizedBox(height: 8),
              Card(
                child: FutureBuilder(
                  future: AuthService.instance.getCurrentUser(),
                  builder: (ctx, snap) {
                    final user = snap.data;
                    return Column(
                      children: [
                        if (user != null) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                              child: Text(user.username[0].toUpperCase(),
                                  style: TextStyle(
                                      color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(user.fullName ?? user.username),
                            subtitle: Text(user.email),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: user.role == 'admin'
                                    ? Colors.orange.withOpacity(0.15)
                                    : theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(user.role.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold,
                                      color: user.role == 'admin' ? Colors.orange : theme.colorScheme.primary)),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                        ListTile(
                          leading: Icon(Icons.logout, color: theme.colorScheme.error),
                          title: Text('Chiqish', style: TextStyle(color: theme.colorScheme.error)),
                          onTap: () => _showLogoutConfirm(context),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ─── Dastur haqida ───────────────────────────────────────────
              _SectionHeader(title: 'Dastur haqida', theme: theme),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
                      title: const Text('Guvohnoma raqami'),
                      subtitle: Text(AppConstants.certificateNumber),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      title: const Text('Versiya'),
                      subtitle: Text(AppConstants.appVersion),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.copyright_outlined, color: theme.colorScheme.primary),
                      title: const Text('Mualliflar'),
                      subtitle: const Text('Karimov Nodirbek & Burxonova Madinabonu'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() { _testingApi = true; _apiTestResult = null; });
    await Future.delayed(const Duration(seconds: 1));
    final url = _apiUrlCtrl.text.trim();
    setState(() {
      _apiTestResult = url.startsWith('http')
          ? '✅ API manzili to\'g\'ri ko\'rinadi'
          : '❌ URL http:// yoki https:// bilan boshlanishi kerak';
      _testingApi = false;
    });
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Tizimdan chiqishni xohlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}

// ─── Theme Selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _ThemeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themes = [
      {
        'id': AppConstants.themeClassic, 'name': 'Klassik', 'desc': 'Oltin-jigarrang',
        'icon': Icons.mosque_outlined, 'color': const Color(0xFF8B5E3C), 'bg': const Color(0xFFFDF6E3),
      },
      {
        'id': AppConstants.themeModern, 'name': 'Modern', 'desc': 'Minimalist',
        'icon': Icons.design_services_outlined, 'color': const Color(0xFF1A56DB), 'bg': const Color(0xFFF8F9FA),
      },
      {
        'id': AppConstants.themeDark, 'name': 'Dark', 'desc': "Ko'z uchun qulay",
        'icon': Icons.dark_mode_outlined, 'color': const Color(0xFFD4A843), 'bg': const Color(0xFF0D1117),
      },
    ];
    return Row(
      children: themes.map((t) {
        final isActive = t['id'] == current;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t['bg'] as Color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? (t['color'] as Color) : theme.dividerColor,
                  width: isActive ? 2.5 : 1,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: (t['color'] as Color).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(t['icon'] as IconData, color: t['color'] as Color, size: 26),
                  const SizedBox(height: 5),
                  Text(t['name'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t['color'] as Color),
                      textAlign: TextAlign.center),
                  Text(t['desc'] as String,
                      style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
                  if (isActive) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.check_circle, color: t['color'] as Color, size: 15),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.primary),
      );
}
