import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.advancedTools, style: AppTextStyles.titleLarge(context)),
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
                  l10n.proBadge,
                  style: AppTextStyles.badgeLabel(context).copyWith(
                    color: AppColors.premium,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FeatureListTile(
          title: l10n.bulkProcessing,
          subtitle: l10n.bulkSubtitle,
          icon: Iconsax.layer,
          isPro: true,
          hasAccess: isPro,
          onTap: () =>
              _handleProFeature(context, isPro, isLoggedIn, '/bulk-editor'),
        ),
        const SizedBox(height: AppSpacing.md),
        FeatureListTile(
          title: l10n.exifEraser,
          subtitle: l10n.exifSubtitle,
          icon: Iconsax.shield_tick,
          isPro: false,
          hasAccess: true,
          onTap: () => AdManager().showInterstitialAd(
            onComplete: () => context.push('/exif-eraser'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FeatureListTile(
          title: l10n.viewHistory,
          subtitle: l10n.viewHistorySubtitle,
          icon: Iconsax.clock,
          isPro: false,
          hasAccess: true,
          onTap: () => AdManager().showInterstitialAd(
            onComplete: () => context.go('/gallery'),
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
      if (route == '/bulk-editor') {
        context.go(route);
      } else {
        context.go(route);
      }
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
                AppLocalizations.of(context)!.unlockReducerPro,
                style: AppTextStyles.headlineSmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context)!.proDescription,
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
                  child: Text(AppLocalizations.of(context)!.upgradeToPro),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.maybeLater),
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


