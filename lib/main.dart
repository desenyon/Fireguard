import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/constants/palette.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shell/app_shell.dart';
import 'providers/auth_provider.dart';
import 'ui/auth/login_view.dart';
import 'package:fireguard/services/firms_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Request location permissions
  await _requestLocationPermissions();
  
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // await FIRMSService.fetchFireData();
  }
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestLocationPermissions() async {
  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services are disabled.');
    return;
  }

  // Check location permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permissions are denied');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permissions are permanently denied');
    return;
  }

  print('Location permissions granted');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppPalette.red,
              ),
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
                style: TextStyle(
                  fontSize: 16,
                  color: AppPalette.lightGray,
                ),
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
