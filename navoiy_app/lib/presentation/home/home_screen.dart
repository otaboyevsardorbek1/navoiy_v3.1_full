// lib/presentation/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../asarlar/asarlar_screen.dart';
import '../sherlar/sherlar_screen.dart';
import '../sync/sync_screen.dart';
import '../settings/settings_screen.dart';
import '../asarlar/bloc/asarlar_bloc.dart';
import '../sherlar/bloc/sherlar_bloc.dart';
import '../sync/bloc/sync_bloc.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../core/network/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AsarlarBloc(DatabaseHelper.instance)),
        BlocProvider(create: (_) => SherlarBloc(DatabaseHelper.instance)),
        BlocProvider(create: (_) => SyncBloc()),
      ],
      child: ConnectivityBanner(
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              AsarlarScreen(),
              SherlarScreen(),
              SyncScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_outlined),
                  activeIcon: Icon(Icons.auto_stories),
                  label: 'Asarlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.format_quote_outlined),
                  activeIcon: Icon(Icons.format_quote),
                  label: 'She\'rlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sync_outlined),
                  activeIcon: Icon(Icons.sync),
                  label: 'Sync',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Sozlamalar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
