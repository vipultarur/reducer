import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'tool_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Essential Tools', style: AppTextStyles.titleLarge(context)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ToolCard(
                title: 'Compress',
                subtitle: 'Reduce size',
                icon: Iconsax.document_download,
                color: AppColors.primary,
                onTap: () => AdManager().showInterstitialAd(
                  onComplete: () => context.push('/single-editor'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ToolCard(
                title: 'Convert',
                subtitle: 'Change format',
                icon: Iconsax.refresh,
                color: AppColors.secondary,
                onTap: () => AdManager().showInterstitialAd(
                  onComplete: () => context.push('/single-editor'),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
