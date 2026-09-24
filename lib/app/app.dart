import 'package:flutter/material.dart';

import 'package:can_lua_gia_dinh/screens/history_screen.dart';
import 'package:can_lua_gia_dinh/screens/main_shell.dart';
import 'package:can_lua_gia_dinh/screens/settings_screen.dart';
import 'package:can_lua_gia_dinh/screens/stats_screen.dart';
import 'package:can_lua_gia_dinh/core/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cân Lúa Gia Đình',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainShell(),
        '/history': (context) => const HistoryScreen(),
        '/stats': (context) => const StatsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
