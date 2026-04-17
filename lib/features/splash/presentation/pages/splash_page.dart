import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _controller.forward();
    
    // Remove native splash as soon as first Flutter frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Parallelize branding delay and critical setup
    final minDelay = Future.delayed(const Duration(milliseconds: 800));
    
    try {
      // 1. Resolve Auth first (needed for Premium check)
      await _initializeAuth();

      // 2. Fetch Premium status and sync to AdManager
      // This ensures ads are ONLY initialized if the user is truly non-premium
      await ref.read(premiumControllerProvider.notifier).fetchOffersAndCheckStatus();

      // 3. Concurrent initialization of UI delays and Ads
      await Future.wait([
        minDelay,
        AdManager.initialize(),
      ]);

      if (!mounted) return;

      // 2. Show App Open Ad (Handles timeout internally)
      await AdManager().showSplashAd(onDone: () {
        if (mounted) {
          context.go('/');
        }
      });
    } catch (e) {
      debugPrint('Splash init error: $e');
      if (mounted) context.go('/');
    }
  }

  Future<void> _initializeAuth() async {
    final authService = ref.read(authServiceProvider);
    if (authService.currentUser == null) {
      await authService.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deepest dark blue for premium feel
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Optional: Subtle background pattern or vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.8),
                    const Color(0xFF020617),
                  ],
                ),
              ),
            ),
          ),

          // Central Logo
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/logo/reducer_logo_bg.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      duration: 2000.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.easeInOut,
                    )
                    .shimmer(delay: 3000.ms, duration: 1500.ms, color: Colors.white24),
                
                const SizedBox(height: 48),
                
                // Minimalist App Name (if not in logo)
                Text(
                  'REDUCER',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 12,
                    fontSize: 24,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 1000.ms)
                    .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 1000.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),

          // Bottom Loading / Status
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms)
                    .scaleX(begin: 0, end: 1, delay: 1000.ms, duration: 800.ms),
                const SizedBox(height: 16),
                Text(
                  'POWERED BY AI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
