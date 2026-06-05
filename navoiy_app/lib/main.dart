// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/utils/settings_service.dart';
import 'core/network/auth_service.dart';
import 'presentation/auth/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Faqat sozlamalarni yuklash — kontent splash da yuklanadi
  await SettingsService.instance.init();

  runApp(const NavoiyApp());
}

class NavoiyApp extends StatelessWidget {
  const NavoiyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        authService: AuthService.instance,
        settings: SettingsService.instance,
      ),
      child: ListenableBuilder(
        listenable: SettingsService.instance,
        builder: (context, _) {
          final theme = SettingsService.instance.currentTheme;
          final themeName = SettingsService.instance.themeName;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                themeName == 'dark' ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                theme.bottomNavigationBarTheme.backgroundColor,
            systemNavigationBarIconBrightness:
                themeName == 'dark' ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp.router(
            title: 'Navoiy Asarlari',
            debugShowCheckedModeBanner: false,
            theme: theme,
            routerConfig: appRouter,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
