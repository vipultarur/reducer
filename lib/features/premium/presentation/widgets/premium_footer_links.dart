import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';

class PremiumFooterLinks extends ConsumerWidget {
  const PremiumFooterLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant;
    
    final linkStyle = AppTextStyles.labelMedium(context).copyWith(color: color);
    final divider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text("|", style: linkStyle),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Link(text: "Terms of use", onTap: () => _launch('https://tarur.com/terms')),
        divider,
        _Link(text: "Privacy Policy", onTap: () => _launch('https://tarur.com/privacy')),
        divider,
        _Link(text: "Restore", onTap: () => ref.read(premiumControllerProvider.notifier).restorePurchases()),
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Link extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Link({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: AppTextStyles.labelMedium(context).copyWith(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.onDarkSurfaceVariant 
            : AppColors.onLightSurfaceVariant,
      )),
    );
  }
}
