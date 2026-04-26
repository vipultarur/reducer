import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'tool_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.quickStart, style: AppTextStyles.titleLarge(context)),
            TextButton(
              onPressed: () {}, // Could lead to a guide or "How it works"
              child: Text(
                l10n.howItWorks,
                style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        // Hero Action Card
        _buildHeroCard(context, isDark, l10n),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Secondary Actions Grid
        Row(
          children: [
            Expanded(
              child: ToolCard(
                title: l10n.convert,
                subtitle: l10n.convertSubtitle,
                icon: Iconsax.refresh,
                color: AppColors.secondary,
                onTap: () => AdManager().showInterstitialAd(
                  onComplete: () => context.go('/single-editor'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ToolCard(
                title: l10n.history,
                subtitle: l10n.historySubtitle,
                icon: Iconsax.clock,
                color: AppColors.premium,
                onTap: () => AdManager().showInterstitialAd(
                  onComplete: () => context.go('/gallery'),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeroCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AdManager().showInterstitialAd(
            onComplete: () => context.go('/single-editor'),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.image, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.optimizeImage,
                      style: AppTextStyles.titleLarge(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.optimizeSubtitle,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Iconsax.magicpen,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Iconsax.arrow_right_1, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

