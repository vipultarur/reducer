import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Last updated: April 05, 2026',
            style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSection(
            context,
            '1. Data Processing',
            'All image processing occurs locally on your device. We do not upload, store, or transmit your photos to any external servers. Your images remain completely private and secure on your device.',
          ),

          _buildSection(
            context,
            '2. Information Collection',
            'We collect minimal anonymous usage data to improve the app experience. This includes crash reports and basic analytics. No personally identifiable information is collected without your explicit consent.',
          ),

          _buildSection(
            context,
            '3. Third-Party Services',
            'We use Google AdMob for displaying advertisements (in the free version) and RevenueCat for managing subscriptions. These services may collect information as outlined in their respective privacy policies.',
          ),

          _buildSection(
            context,
            '4. Device Permissions',
            'We require photo/storage access solely for the purpose of selecting images to edit and saving the processed results. We do not access any other files on your device.',
          ),

          _buildSection(
            context,
            '5. Contact Us',
            'If you have any questions about this Privacy Policy, please contact us at support@tarur.com.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}
