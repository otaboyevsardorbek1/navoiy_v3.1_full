// lib/presentation/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/sync/bundled_content_service.dart';
import '../auth/bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  String _statusText = "Ma'lumotlar tayyorlanmoqda...";

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    // BundledContentService ni initialize qilish
    if (mounted) setState(() => _statusText = "Asarlar yuklanmoqda...");
    await BundledContentService.instance.initializeIfNeeded();

    if (mounted) setState(() => _statusText = "Tayyor!");
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final themeName = ext?.themeName ?? AppConstants.themeClassic;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/home');
        else if (state is AuthUnauthenticated) context.go('/login');
      },
      child: Scaffold(
        body: Container(
          decoration: _buildBg(themeName),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: _buildLogo(themeName),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text('Alisher Navoiy',
                              style: theme.textTheme.displayMedium?.copyWith(
                                  color: _primaryTextColor(themeName)),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(
                            "Asarlarini integratsion yondashuv\nasosida o'rganamiz",
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: _secondaryTextColor(themeName)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          // Animated status
                          AnimatedBuilder(
                            animation: _textOpacity,
                            builder: (_, __) => Column(
                              children: [
                                SizedBox(
                                  width: 32, height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3, color: _accentColor(themeName)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _secondaryTextColor(themeName).withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLogo(String themeName) {
    final Color bg;
    final Color icon;
    switch (themeName) {
      case AppConstants.themeDark:
        bg = DarkColors.surface; icon = DarkColors.primary; break;
      case AppConstants.themeModern:
        bg = ModernColors.primary; icon = Colors.white; break;
      default:
        bg = ClassicColors.accent; icon = ClassicColors.primaryDark;
    }
    return Container(
      width: 116, height: 116,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Icon(Icons.menu_book_rounded, size: 60, color: icon),
    );
  }

  BoxDecoration _buildBg(String themeName) {
    switch (themeName) {
      case AppConstants.themeDark:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF161B22), Color(0xFF0D1117)]));
      case AppConstants.themeModern:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8F9FA)]));
      default:
        return const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF3D1F0A), Color(0xFF7A4A25), Color(0xFFFDF6E3)],
          stops: [0.0, 0.4, 1.0]));
    }
  }

  Color _primaryTextColor(String t) {
    if (t == AppConstants.themeClassic) return ClassicColors.accentLight;
    if (t == AppConstants.themeDark) return DarkColors.primary;
    return ModernColors.text;
  }

  Color _secondaryTextColor(String t) {
    if (t == AppConstants.themeClassic) return ClassicColors.divider;
    if (t == AppConstants.themeDark) return DarkColors.textSecondary;
    return ModernColors.textSecondary;
  }

  Color _accentColor(String t) {
    if (t == AppConstants.themeClassic) return ClassicColors.accent;
    if (t == AppConstants.themeDark) return DarkColors.primary;
    return ModernColors.primary;
  }
}
