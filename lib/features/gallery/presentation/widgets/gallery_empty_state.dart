import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class GalleryEmptyState extends StatelessWidget {
  const GalleryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.clock, size: AppSpacing.iconXl4, color: AppColors.primary),
          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.xl2),
          Text(
            'No past edits found',
            style: AppTextStyles.titleLarge(context),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Process and export images\nto see them here',
            style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: AppSpacing.xl3),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.add),
            label: const Text('Start New Edit'),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}
