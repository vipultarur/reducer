import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class PremiumInfoRow extends StatelessWidget {
  final String value;
  const PremiumInfoRow({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            "assets/premium_screen/black_check_icon.png",
            width: 22,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.check_circle,
              size: 22,
              color: onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: onSurface.withValues(alpha: 0.87),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
