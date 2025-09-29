import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/constants/palette.dart';
import 'shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData baseDark = ThemeData(brightness: Brightness.dark, useMaterial3: true,splashColor: Colors.transparent);
    return MaterialApp(
      title: 'Fireguard',
      theme: baseDark.copyWith(
        scaffoldBackgroundColor: AppPalette.screenBackground,
        colorScheme: baseDark.colorScheme.copyWith(
          primary: AppPalette.orange,
          surface: AppPalette.backgroundDarker,
          onSurface: AppPalette.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppPalette.backgroundDarker,
          foregroundColor: AppPalette.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppPalette.navBarBackground,
          selectedItemColor: AppPalette.white,
        
          unselectedItemColor: AppPalette.lightGray,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
