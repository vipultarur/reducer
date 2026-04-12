import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/premium/presentation/widgets/app_button.dart';

class AlreadyProState extends StatelessWidget {
  const AlreadyProState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                size: 72,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'You\'re a Pro member!',
                style: AppTextStyles.headlineSmall(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Thank you for your support. You have full access to all premium features.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl3),
              AppButton(
                label: 'Manage Subscription',
                icon: Icons.settings,
                style: AppButtonStyle.outline,
                onPressed: () => _openSubscriptionManagement(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
