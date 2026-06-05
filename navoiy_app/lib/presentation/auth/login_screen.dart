// lib/presentation/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          rememberMe: _rememberMe,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final themeName = ext?.themeName ?? AppConstants.themeClassic;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: _buildBackground(themeName, theme),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(themeName, theme),
                        const SizedBox(height: 16),
                        Text(
                          'Alisher Navoiy',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: _headerColor(themeName, theme),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Asarlarini o\'rganamiz',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _subColor(themeName, theme),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _buildLoginCard(theme, themeName, state),
                        const SizedBox(height: 24),
                        _buildCertBadge(theme, themeName),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildBackground(String themeName, ThemeData theme) {
    switch (themeName) {
      case AppConstants.themeClassic:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5C3D1E), Color(0xFF8B5E3C), Color(0xFFFDF6E3)],
            stops: [0.0, 0.35, 1.0],
          ),
        );
      case AppConstants.themeDark:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF21262D), Color(0xFF0D1117)],
          ),
        );
      default: // modern
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ModernColors.primary.withOpacity(0.12),
              theme.scaffoldBackgroundColor,
            ],
          ),
        );
    }
  }

  Widget _buildLogo(String themeName, ThemeData theme) {
    final Color bgColor;
    final Color iconColor;
    switch (themeName) {
      case AppConstants.themeClassic:
        bgColor = ClassicColors.accent;
        iconColor = ClassicColors.primaryDark;
        break;
      case AppConstants.themeDark:
        bgColor = DarkColors.surface;
        iconColor = DarkColors.primary;
        break;
      default:
        bgColor = ModernColors.primary;
        iconColor = Colors.white;
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.menu_book_rounded, size: 52, color: iconColor),
    );
  }

  Color _headerColor(String themeName, ThemeData theme) {
    switch (themeName) {
      case AppConstants.themeClassic:
        return ClassicColors.accentLight;
      case AppConstants.themeDark:
        return DarkColors.primary;
      default:
        return ModernColors.text;
    }
  }

  Color _subColor(String themeName, ThemeData theme) {
    switch (themeName) {
      case AppConstants.themeClassic:
        return ClassicColors.divider;
      case AppConstants.themeDark:
        return DarkColors.textSecondary;
      default:
        return ModernColors.textSecondary;
    }
  }

  Widget _buildLoginCard(ThemeData theme, String themeName, AuthState state) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tizimga kirish',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Login va parolingizni kiriting',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: 'Login',
                hintText: 'admin yoki user',
                prefixIcon: Icon(Icons.person_outline,
                    color: theme.colorScheme.primary),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Login kiritilmagan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Parol',
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline,
                    color: theme.colorScheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Parol kiritilmagan';
                if (v.length < 6) return 'Parol kamida 6 belgi';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) =>
                      setState(() => _rememberMe = v ?? false),
                  activeColor: theme.colorScheme.primary,
                ),
                Text('Meni eslab qol',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: state is AuthLoading ? null : _onLogin,
                child: state is AuthLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Kirish'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Demo hisoblar:', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('admin / admin123', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('user / user123', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertBadge(ThemeData theme, String themeName) {
    return Opacity(
      opacity: 0.7,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined,
              size: 14, color: theme.colorScheme.onBackground),
          const SizedBox(width: 6),
          Text(
            'Guvohnoma № ${AppConstants.certificateNumber}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
