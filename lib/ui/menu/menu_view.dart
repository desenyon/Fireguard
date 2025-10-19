import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants/palette.dart';
import '../../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';


class MenuView extends ConsumerStatefulWidget {
  const MenuView({super.key});

  @override
  ConsumerState<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends ConsumerState<MenuView> {
  bool _isDarkMode = true;


Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: AppPalette.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Fireguard title and close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppPalette.white,
                      size: 24,
                    ),
                  ),
                  const Text(
                    'Fireguard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.white,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Preparedness Guides Section
                    _buildPreparednessGuides(),
                    
                    const SizedBox(height: 32),
                    
                  
                    
                    const SizedBox(height: 32),
                    
                    // Settings Section
                    _buildSettings(),
                    
                    const SizedBox(height: 32),
                    
                    // Logout Button
                    _buildLogoutButton(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparednessGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preparedness Guides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPalette.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
         height: 270,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () async {
                  _launchURL('https://www.fire.ca.gov/prepare/get-ready');
                },
                child: _buildGuideCard(
                  title: 'Ready',
                  description: 'Prepare your home and family for potential wildfire.',
                  illustration: _buildReadyIllustration(),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  _launchURL('https://www.fire.ca.gov/prepare/get-set');
                },
                child: _buildGuideCard(
                  title: 'Set',
                  description: 'Be aware of conditions and prepare to leave.',
                  illustration: _buildSetIllustration(),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  _launchURL('https://www.fire.ca.gov/prepare/get-ready-to-go');
                },
                child: _buildGuideCard(
                  title: 'Go',
                  description: 'Evacuate if advised or unsafe.',
                  illustration: _buildGoIllustration(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: illustration,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.lightGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.orange, AppPalette.orangeBright],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.home_outlined,
          size: 48,
          color: AppPalette.white,
        ),
      ),
    );
  }

  Widget _buildSetIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.yellow, Color(0xFFFFB800)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.warning_outlined,
          size: 48,
          color: AppPalette.white,
        ),
      ),
    );
  }

  Widget _buildGoIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppPalette.red, Color(0xFFFF6B6B)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_run_outlined,
          size: 48,
          color: AppPalette.white,
        ),
      ),
    );
  }



  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppPalette.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppPalette.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.border),
          ),
          child: Column(
            children: [
              // _buildSettingItem(
              //   title: 'Dark Mode',
              //   trailing: Switch(
              //     value: _isDarkMode,
              //     onChanged: (value) {
              //       setState(() {
              //         _isDarkMode = value;
              //       });
              //     },
              //     activeColor: AppPalette.orange,
              //   ),
              // ),
              // _buildDivider(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppPalette.white,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppPalette.border,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final authService = ref.read(authServiceProvider);
            await authService.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error signing out: $e'),
                  backgroundColor: AppPalette.red,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.red,
          foregroundColor: AppPalette.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}
