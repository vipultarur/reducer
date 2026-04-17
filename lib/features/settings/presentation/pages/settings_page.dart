import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/settings/presentation/widgets/settings_tile.dart';
import 'package:reducer/features/settings/presentation/widgets/settings_section_header.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _shareApp(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out Reducer - The ultimate image compression and processing tool! Download here: https://play.google.com/store/apps/details?id=com.tarurinfotech.reducer',
        subject: 'Reducer',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Premium Section ───────────────────────────────────────────────
          if (!premiumState.isPro) ...[
            const SettingsSectionHeader(title: 'Subscription'),

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
            const SettingsSectionHeader(title: 'Subscription'),

            Card(
              child: ListTile(
                leading: const Icon(Iconsax.verify, color: AppColors.success),
                title: const Text('Reducer Pro Active'),
                subtitle: const Text('Thank you for your support!'),
                onTap: () => context.push('/premium'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Support & Feedback ──────────────────────────────────────────────
          const SettingsSectionHeader(title: 'Support & Feedback'),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SettingsTile(

                  icon: Iconsax.star,
                  title: 'Rate on Play Store',
                  onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.tarurinfotech.reducer'),
                ),
                const Divider(),
                SettingsTile(

                  icon: Iconsax.share,
                  title: 'Share Reducer',
                  onTap: () => _shareApp(context),
                ),
                const Divider(),
                SettingsTile(

                  icon: Iconsax.message_question,
                  title: 'Contact Support',
                  onTap: () => _launchUrl('mailto:support@tarurinfotech.com?subject=Reducer%20Support'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── About ───────────────────────────────────────────────────────────
          const SettingsSectionHeader(title: 'About'),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SettingsTile(

                  icon: Iconsax.shield_tick,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.0.0';
                    final build = snapshot.data?.buildNumber ?? '1';
                    return ListTile(
                      leading: const Icon(Iconsax.info_circle),
                      title: const Text('Version'),
                      trailing: Text('$version ($build)', style: const TextStyle(color: Colors.grey)),
                    );
                  },
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
}

