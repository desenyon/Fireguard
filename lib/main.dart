import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/constants/palette.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shell/app_shell.dart';
import 'providers/auth_provider.dart';
import 'ui/auth/login_view.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/permission_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
Future<void> _requestPermissions(BuildContext context) async {
    await PermissionService.requestStartupPermissions(context);
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Request permissions after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions(context);
    });
    final ThemeData baseDark = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      splashColor: Colors.transparent,
    );

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
          selectedItemColor: AppPalette.orange,

          unselectedItemColor: AppPalette.lightGray,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user != null) {
          // Kick off background sync of user record (email, location, token)
          UserService.syncSignedInUser();
          return const AppShell();
        } else {
          return const LoginView();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppPalette.screenBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppPalette.orange),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppPalette.screenBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppPalette.red),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 16, color: AppPalette.lightGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app or handle error
                  ref.invalidate(currentUserProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: AppPalette.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
}
