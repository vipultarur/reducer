import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'feature_list_tile.dart';
import 'login_required_dialog.dart';

class ProToolsSection extends StatelessWidget {
  final bool isPro;
  final bool isLoggedIn;

  const ProToolsSection({
    super.key,
    required this.isPro,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Advanced Tools', style: AppTextStyles.titleLarge(context)),
            const Spacer(),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.premiumContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'PRO',
                  style: AppTextStyles.badgeLabel(context).copyWith(
                    color: AppColors.premium,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FeatureListTile(
          title: 'Bulk Processing',
          subtitle: 'Process up to 50 images at once',
          icon: Iconsax.layer,
          isPro: true,
          hasAccess: isPro,
          onTap: () =>
              _handleProFeature(context, isPro, isLoggedIn, '/bulk-editor'),
        ),
        const SizedBox(height: AppSpacing.md),
        FeatureListTile(
          title: 'EXIF Eraser',
          subtitle: 'Remove metadata for privacy',
          icon: Iconsax.shield_tick,
          isPro: false,
          hasAccess: true,
          onTap: () => AdManager().showInterstitialAd(
            onComplete: () => context.push('/exif-eraser'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FeatureListTile(
          title: 'Edit History',
          subtitle: 'View and export past edits',
          icon: Iconsax.clock,
          isPro: false,
          hasAccess: true,
          onTap: () => AdManager().showInterstitialAd(
            onComplete: () => context.push('/gallery'),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }


  void _handleProFeature(
    BuildContext context,
    bool isPro,
    bool isLoggedIn,
    String route,
  ) {
    if (isPro) {
      context.push(route);
      return;
    }

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context);
      return;
    }

    _showPremiumRequiredDialog(context);
  }

  void _showPremiumRequiredDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.premium.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.crown, color: AppColors.premium, size: 48),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Unlock Reducer Pro',
                style: AppTextStyles.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Bulk processing and ad-free experience are available for Pro members. Join our community today!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/premium');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.premium,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                  child: const Text('Upgrade to Pro'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginRequiredDialog(),
    );
  }
}

