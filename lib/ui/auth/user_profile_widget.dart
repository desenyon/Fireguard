import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants/palette.dart';

class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final authService = ref.read(authServiceProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.border),
          ),
          child: Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: user.photoURL != null 
                    ? NetworkImage(user.photoURL!)
                    : null,
                backgroundColor: AppPalette.orange,
                child: user.photoURL == null
                    ? Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName![0].toUpperCase()
                            : user.email![0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPalette.lightGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sign Out Button
              IconButton(
                onPressed: () async {
                  try {
                    await authService.signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sign out failed: ${e.toString()}'),
                          backgroundColor: AppPalette.red,
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  Icons.logout,
                  color: AppPalette.lightGray,
                ),
                tooltip: 'Sign Out',
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppPalette.mediumGray,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.orange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppPalette.mediumGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 180,
                    decoration: BoxDecoration(
                      color: AppPalette.mediumGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.red),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppPalette.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading user data',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppPalette.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
