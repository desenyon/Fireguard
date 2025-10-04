import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fireguard/providers/auth_provider.dart';
import 'package:fireguard/utils/constants/palette.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  Future<void> _signInWithGoogle() async {
    final controller = ref.read(googleSignInControllerProvider.notifier);
    try {
      await controller.signIn();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: $e'),
          backgroundColor: AppPalette.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final init = ref.watch(authInitProvider);
    final signInState = ref.watch(googleSignInControllerProvider);
    final isLoading = init.isLoading || signInState.isLoading;

    return Scaffold(
      backgroundColor: AppPalette.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Title
              Icon(
                Icons.local_fire_department,
                size: 80,
                color: AppPalette.orange,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Fireguard',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Your Fire Safety Companion',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppPalette.lightGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Google Sign In Button
              ElevatedButton.icon(
                onPressed: isLoading ? null : _signInWithGoogle,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppPalette.white),
                        ),
                      )
                    : Image.asset(
                        'assets/images/google_logo.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.login,
                            color: AppPalette.white,
                            size: 20,
                          );
                        },
                      ),
                label: Text(
                  isLoading ? 'Signing in...' : 'Continue with Google',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.orange,
                  foregroundColor: AppPalette.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),
              
              // Terms and Privacy
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppPalette.lightGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
