import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';

/// One-time initialization: Firebase + GoogleSignIn (new API requires explicit initialize).
final authInitProvider = FutureProvider<void>((ref) async {
  // Ensure Firebase is ready (idempotent if already initialized elsewhere).
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await AuthService.ensureInitialized();
});

// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  // Ensure initialization has run before exposing service (consumer widgets can await authInitProvider if needed)
  ref.watch(authInitProvider);
  return AuthService();
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Sign-in action as an AsyncNotifier for convenient usage in UI (e.g. ref.watch / ref.read(signInWithGoogleProvider.notifier).signIn()).
class GoogleSignInController extends AsyncNotifier<UserCredential?> {
  @override
  Future<UserCredential?> build() async {
    // Not performing an action on build; initial state is AsyncData(null)
    return null;
  }

  Future<UserCredential?> signIn() async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();
      state = AsyncData(credential);
      return credential;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final googleSignInControllerProvider = AsyncNotifierProvider<GoogleSignInController, UserCredential?>(
  GoogleSignInController.new,
);

// Provider for authentication state
final authStateProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider for user display name
final userDisplayNameProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.displayName,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for user email
final userEmailProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.email,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for user photo URL
final userPhotoUrlProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.photoURL,
    loading: () => null,
    error: (_, __) => null,
  );
});
