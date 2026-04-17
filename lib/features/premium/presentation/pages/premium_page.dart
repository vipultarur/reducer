import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/shared/widgets/app_status_bar.dart';
import 'package:reducer/features/premium/presentation/widgets/already_pro_state.dart';
import 'package:reducer/features/premium/presentation/widgets/premium_error_state.dart';
import 'package:reducer/features/premium/presentation/widgets/no_plans_state.dart';
import 'package:reducer/features/premium/presentation/widgets/premium_feature_item.dart';
import 'package:reducer/features/premium/presentation/widgets/horizontal_package_selector.dart';
import 'package:reducer/features/premium/presentation/widgets/subscribe_button.dart';
import 'package:reducer/features/premium/presentation/widgets/premium_footer_links.dart';
import 'package:reducer/features/premium/presentation/widgets/premium_loading_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);

    // Listen for state changes → show snackbars
    ref.listen<PurchaseState>(premiumControllerProvider, (prev, next) {
      if (next.successMessage.isNotEmpty &&
          (prev == null || prev.successMessage != next.successMessage)) {
        AppStatusBar.showSuccess(context, next.successMessage);
      }

      if (next.errorMessage.isNotEmpty &&
          (prev == null || prev.errorMessage != next.errorMessage)) {
        AppStatusBar.showError(context, next.errorMessage);
      }
    });


    if (state.isPro) {
      return const AlreadyProState();
    }

    if (state.errorMessage.isNotEmpty && state.availablePackages.isEmpty) {
      return PremiumErrorState(error: state.errorMessage);
    }

    if (!state.isLoading && state.availablePackages.isEmpty) {
      return const NoPlansState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Stack(
        children: [
          // Premium Background Gradient & Shapes
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          
          // Decorative Animated Glows
          _buildAnimatedGlow(
            top: -100,
            left: -100,
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            duration: 5.seconds,
          ),
          _buildAnimatedGlow(
            bottom: -50,
            right: -50,
            color: const Color(0xFFEAB308).withValues(alpha: 0.1),
            duration: 7.seconds,
          ),

          // Floating Close Button
          Positioned(
            top: 36, // Moved 20px down from 16
            left: 16,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.close, color: Colors.white70),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white10,
                padding: const EdgeInsets.all(8),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hero Content
                  _buildHeroHeader(context),
                  
                  // Glassmorphism Features Card
                  _buildFeaturesCard(context),

                  // Plan Selection
                  const HorizontalPackageSelector()
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),

                  // Subscribe Button & Trust Subtext
                  const SubscribeButton()
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 500.ms)
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                  // Restores & Legal
                  const PremiumFooterLinks(),
                ],
              ),
            ),
          ),
          if (state.isLoading) const PremiumLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedGlow({double? top, double? left, double? right, double? bottom, required Color color, required Duration duration}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 50,
            )
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: duration,
            curve: Curves.easeInOut,
          ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.2)),
          ),
          child: const Text(
            'PRO ACCESS',
            style: TextStyle(
              color: Color(0xFFFACC15),
              fontSize: 9, // Shrink
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5, end: 0),
        const SizedBox(height: 8),
        const Text(
          'Unlock the Full Studio',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22, // Shrink from 26
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        const Text(
          'Get high-performance tools, AI upscaling,\nand an absolute ad-free experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12, // Shrink from 13
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16), // Shrink from 20
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure it doesn't take extra space
            children: [
              const PremiumFeatureItem(
                icon: Iconsax.maximize_4,
                label: 'Bulk Studio (Batch Resize & Export)',
              ),
              const Divider(height: 8, color: Colors.white10),
              const PremiumFeatureItem(
                icon: Iconsax.cpu,
                label: 'AI Turbo Upscaling & Clean',
              ),
              const Divider(height: 8, color: Colors.white10),
              const PremiumFeatureItem(
                icon: Iconsax.shield_slash,
                label: 'Zero Ads. Absolute Privacy.',
              ),
              const Divider(height: 8, color: Colors.white10),
              const PremiumFeatureItem(
                icon: Iconsax.document_download,
                label: 'Direct ZIP & 4K Collections',
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.1, end: 0);
  }
}
