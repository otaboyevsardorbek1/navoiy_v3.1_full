// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/asarlar/asar_detail_screen.dart';
import '../../presentation/asarlar/asar_reader_screen.dart';
import '../../presentation/sync/content_manager_screen.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/models.dart';
import '../../core/sync/bundled_content_service.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (_, __) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, __) => CustomTransitionPage(
        child: const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    ),

    // Asar detail (meta ma'lumotlar)
    GoRoute(
      path: '/asarlar/:id',
      pageBuilder: (ctx, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return CustomTransitionPage(
          child: BlocProvider.value(
            value: ctx.read<AuthBloc>(),
            child: AsarDetailScreen(id: id),
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    ),

    // Asar reader (sahifalangan matn)
    GoRoute(
      path: '/asarlar/:id/read',
      pageBuilder: (ctx, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return CustomTransitionPage(
          child: _AsyncAsarReader(asarId: id),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    ),

    // Kontent boshqaruvi
    GoRoute(
      path: '/content-manager',
      pageBuilder: (_, __) => CustomTransitionPage(
        child: const ContentManagerScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  ],
);

// ─── Async loader widget (DB dan asar olish) ──────────────────────────────────
class _AsyncAsarReader extends StatefulWidget {
  final int asarId;
  const _AsyncAsarReader({required this.asarId});

  @override
  State<_AsyncAsarReader> createState() => _AsyncAsarReaderState();
}

class _AsyncAsarReaderState extends State<_AsyncAsarReader> {
  AsarModel? _asar;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final asar = await DatabaseHelper.instance.getAsarById(widget.asarId);
    if (mounted) setState(() { _asar = asar; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_asar == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Asar topilmadi')),
      );
    }
    return AsarReaderScreen(asar: _asar!);
  }
}
