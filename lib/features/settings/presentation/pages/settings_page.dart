import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'Check out ImageMaster Pro - The ultimate image redactor and processing tool! Download here: https://play.google.com/store/apps/details?id=com.tarur.imagemetrics',
      subject: 'ImageMaster Pro',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Premium Section ───────────────────────────────────────────────
          if (!premiumState.isPro) ...[
            _buildSectionHeader('Subscription', context),
            Card(
              child: ListTile(
                leading: const Icon(Iconsax.crown, color: AppColors.premium),
                title: const Text('Upgrade to Pro'),
                subtitle: const Text('Unlock all features & remove ads'),
                trailing: const Icon(Iconsax.arrow_right_3, size: 16),
                onTap: () => context.push('/premium'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            _buildSectionHeader('Subscription', context),
            Card(
              child: ListTile(
                leading: const Icon(Iconsax.verify, color: AppColors.success),
                title: const Text('ImageMaster Pro Active'),
                subtitle: const Text('Thank you for your support!'),
                onTap: () => context.push('/premium'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Support & Feedback ──────────────────────────────────────────────
          _buildSectionHeader('Support & Feedback', context),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Iconsax.star,
                  title: 'Rate on Play Store',
                  onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.tarur.imagemetrics'),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Iconsax.share,
                  title: 'Share ImageMaster',
                  onTap: () => _shareApp(context),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Iconsax.message_question,
                  title: 'Contact Support',
                  onTap: () => _launchUrl('mailto:support@tarur.com?subject=ImageMaster%20Support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── About ───────────────────────────────────────────────────────────
          _buildSectionHeader('About', context),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Iconsax.shield_tick,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Iconsax.info_circle),
                  title: Text('Version'),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl2),
          Center(
            child: Text(
              'Made with ♥ by Tarur Infotech',
              style: AppTextStyles.bodySmall(context).copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.labelLarge(context).copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Iconsax.arrow_right_3, size: 16),
      onTap: onTap,
    );
  }
}
