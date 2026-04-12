import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_theme.dart';

class FeatureListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPro;
  final bool hasAccess;
  final VoidCallback onTap;

  const FeatureListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPro,
    required this.hasAccess,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: isPro && !hasAccess ? Colors.grey : AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Text(title),
            if (isPro && !hasAccess) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Iconsax.lock, size: 14, color: Colors.grey),
            ],
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Iconsax.arrow_right_3, size: 16),
      ),
    );
  }
}
