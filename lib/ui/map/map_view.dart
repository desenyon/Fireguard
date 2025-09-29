import 'package:flutter/material.dart';
import '../../utils/constants/palette.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.screenBackground,
      body: Stack(
        children: [
          // Map placeholder (replace with real map later)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9E4DA),
              child: const Center(
                child: Text('Map Placeholder', style: TextStyle(color: Colors.black54)),
              ),
            ),
          ),
          // Top search pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 40,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search California',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom center rounded action (plus)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: Container(
                  height: 44,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


