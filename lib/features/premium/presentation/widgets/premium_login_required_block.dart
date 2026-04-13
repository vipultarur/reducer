import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/shared/widgets/app_button.dart';
import 'package:reducer/shared/widgets/app_card.dart';


class PremiumLoginRequiredBlock extends StatelessWidget {
  const PremiumLoginRequiredBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark
          ? AppColors.darkSurface.withValues(alpha: 0.92)
          : AppColors.lightSurface.withValues(alpha: 0.96),
      border: Border.all(
        color: AppColors.warning.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.login, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Login required for Premium',
                  style: AppTextStyles.titleSmall(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You are using guest mode. Login to subscribe, restore purchases, and unlock Pro tools.',
            style: AppTextStyles.bodySmall(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Login',
                  icon: Icons.login,
                  style: AppButtonStyle.primary,
                  isFullWidth: true,
                  onPressed: () => context.push(
                    '/login?redirect=${Uri.encodeComponent('/premium')}',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Register',
                  icon: Icons.person_add_alt_1,
                  style: AppButtonStyle.outline,
                  isFullWidth: true,
                  onPressed: () => context.push(
                    '/register?redirect=${Uri.encodeComponent('/premium')}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
