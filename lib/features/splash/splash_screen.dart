import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_tokens.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/services/purchase_service.dart';
import 'package:reducer/ads/remote_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. Start services initialization immediately and in parallel
    // This allows the heavy lifting to happen while the animation plays
    final servicesFuture = Future.wait([
      // Add a timeout to ensure app doesn't hang if a service fails internally
      RemoteConfigService().initialize().timeout(const Duration(seconds: 5), onTimeout: () {}),
      AdManager().initialize().timeout(const Duration(seconds: 5), onTimeout: () {}),
      PurchaseService.configure().timeout(const Duration(seconds: 5), onTimeout: () {}),
    ]);

    // 2. Enforce minimum splash duration for branding (e.g., 2 seconds)
    final minimumWait = Future.delayed(const Duration(seconds: 2));

    try {
      // Wait for both to complete
      await Future.wait([servicesFuture, minimumWait]);
    } catch (e) {
      debugPrint("⚠️ Initialization error: $e");
    }

    if (!mounted) return;

    // 3. Attempt to show the App Open Ad
    // This method handles its own errors and ensures the callback is called
    await AdManager().showSplashAd(
      onAdClosed: () {
        if (mounted) {
          context.go('/home');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000), // 10% opacity black
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.image_search,
                size: 60,
                color: DesignTokens.primaryBlue,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'ImageMaster Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
            const SizedBox(height: 8),
            const Text(
              'Resize, Compress & Convert Effortlessly',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
