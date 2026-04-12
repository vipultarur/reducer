import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'feature_list_tile.dart';

class ProToolsSection extends StatelessWidget {
  final bool isPro;
  const ProToolsSection({super.key, required this.isPro});

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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
                decoration: BoxDecoration(
                  color: AppColors.premiumContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text('PRO', style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.premium)),
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
          onTap: () => _handleProFeature(context, isPro, '/bulk-editor'),
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

  void _handleProFeature(BuildContext context, bool isPro, String route) {
    if (isPro) {
      context.push(route);
    } else {
      _showPremiumRequiredDialog(context);
    }
  }

  void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Iconsax.crown, color: AppColors.premium, size: 48),
        title: const Text('Premium Feature'),
        content: const Text(
          'Bulk processing requires a ImageMaster Pro subscription. Upgrade now to unlock all features without ads.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.premium),
            onPressed: () {
              Navigator.pop(context);
              context.push('/premium');
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }
}
