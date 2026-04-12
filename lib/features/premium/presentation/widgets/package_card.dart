import 'package:flutter/material.dart';
import 'package:reducer/features/premium/domain/models/premium_plan.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/premium/presentation/widgets/app_card.dart';
import 'trial_badge.dart';
import 'best_value_badge.dart';

class PackageCard extends StatelessWidget {
  final PremiumPlan package;
  final bool isSelected;
  final VoidCallback onTap;

  const PackageCard({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppSpacing.radiusXl,
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.5,
        ),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.primaryContainer.withValues(alpha: 0.1),
                  AppColors.primaryContainer.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Image.asset(
                  isSelected
                      ? "assets/premium_screen/check_icon.png"
                      : "assets/premium_screen/uncheck_icon.png",
                  width: 28,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            package.titleText,
                            style: AppTextStyles.titleMedium(context).copyWith(color: onSurface),
                          ),
                          if (package.trialPeriod != null) ...[
                            const SizedBox(width: 8),
                            TrialBadge(text: '${package.trialPeriod} FREE'),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        package.billingFrequencyText,
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: isSelected ? onSurface : onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  package.periodPriceLabel,
                  style: AppTextStyles.titleMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: isSelected ? onSurface : onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            if (package.isYearly)
              const Positioned(
                top: -30,
                right: -10,
                child: BestValueBadge(),
              ),
          ],
        ),
      ),
    );
  }
}
