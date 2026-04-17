import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final file = File(image.path);
      try {
        await ref.read(authControllerProvider.notifier).updateProfileImage(file);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final authState = ref.watch(authProvider).value;
    final isLoading = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return _buildLoggedOutState(context);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [


              // 2. Content Body
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Card Container
                    Container(
                      margin: const EdgeInsets.only(top: 60),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 80, AppSpacing.xl, AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        children: [
                          // Name & Bio
                          Text(
                            user.name,
                            style: AppTextStyles.headlineMedium(context).copyWith(
                              color: isDark ? AppColors.onDarkBackground : AppColors.onLightBackground,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                          
                          const SizedBox(height: AppSpacing.xl),

                          // Stats Row
                          _buildStatsRow(context, user).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),

                          const SizedBox(height: AppSpacing.xl3),

                          // Upgrade Card (If not premium)
                          if (user.subscriptionStatus != 'premium')
                            _buildPremiumCard(context).animate().shimmer(delay: 1.seconds, duration: 2.seconds),

                          const SizedBox(height: AppSpacing.xl),

                          // Settings Groups
                          _buildSettingsGroup(
                            context,
                            title: 'Account Settings',
                            items: [
                              _SettingsTile(
                                icon: Iconsax.user_edit,
                                title: 'Display Name',
                                value: user.name,
                                color: Colors.blue,
                              ),
                              _SettingsTile(
                                icon: Iconsax.sms,
                                title: 'Email Address',
                                value: user.email,
                                color: Colors.orange,
                              ),
                              if (user.subscriptionStatus == 'premium' && user.expiryDate != null)
                                _SettingsTile(
                                  icon: Iconsax.calendar_tick,
                                  title: 'Subscription Ends',
                                  value: user.expiryDate!.toLocal().toString().split(' ')[0],
                                  color: Colors.amber,
                                ),
                            ],
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

                          _buildThemeSelector(context, ref).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                          const SizedBox(height: AppSpacing.xl),

                          _buildSettingsGroup(
                            context,
                            title: 'Account Actions',
                            items: [
                              _SettingsTile(
                                icon: Iconsax.logout,
                                title: 'Sign Out',
                                value: 'Disconnect your account',
                                color: Colors.red,
                                onTap: () => _showLogoutDialog(context, ref),
                              ),
                            ],
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                          const SizedBox(height: AppSpacing.xl3),

                          // Delete Account (Optional/Danger Zone)
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Privacy Policy & Terms',
                              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 100), // Extra space for bottom nav
                        ],
                      ),
                    ),

                    // Overlapping Avatar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                shape: BoxShape.circle,
                                boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.primaryContainer,
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                        style: AppTextStyles.displayMedium(context).copyWith(
                                          color: isDark ? AppColors.onDarkSurface : AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: isLoading ? null : () => _pickAndUploadImage(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                      width: 3,
                                    ),
                                    boxShadow: AppColors.buttonShadow,
                                  ),
                                  child: Icon(
                                    isLoading ? Icons.hourglass_empty : Iconsax.camera,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLoggedOutState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.user_minus, size: 80, color: Colors.grey).animate().shake(),
          const SizedBox(height: 24),
          Text(
            'Authentication Required',
            style: AppTextStyles.headlineSmall(context),
          ),
          const SizedBox(height: 12),
          const Text('Sign in to sync your progress across devices'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/login?redirect=${Uri.encodeComponent('/profile')}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Login / Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : AppColors.cardShadowLight,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Images Done',
            value: user.aiImagesGenerated.toString(),
            icon: Iconsax.image,
            color: Colors.blue,
          ),
          Container(height: 30, width: 1, color: isDark ? Colors.white10 : Colors.black12),
          _StatItem(
            label: 'Member Since',
            value: '${user.createdAt.year}',
            icon: Iconsax.calendar_1,
            color: Colors.purple,
          ),
          Container(height: 30, width: 1, color: isDark ? Colors.white10 : Colors.black12),
          _StatItem(
            label: 'Status',
            value: user.subscriptionStatus == 'premium' ? 'Pro' : 'Free',
            icon: user.subscriptionStatus == 'premium' ? Iconsax.crown: Iconsax.user,
            color: user.subscriptionStatus == 'premium' ? Colors.amber : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.premiumGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.premiumButtonShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Reducer Pro',
                  style: AppTextStyles.titleLarge(context).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ad-free experience, unlimited storage & bulk processing.',
                  style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.premium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required String title, required List<_SettingsTile> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: AppTextStyles.titleMedium(context)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text('App Theme', style: AppTextStyles.titleMedium(context)),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Iconsax.sun_1)),
              ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Iconsax.setting)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Iconsax.moon)),
            ],
            selected: {currentTheme},
            onSelectionChanged: (set) => ref.read(themeModeProvider.notifier).setThemeMode(set.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.transparent,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              side: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
        Text(
          label, 
          style: AppTextStyles.labelSmall(context).copyWith(
            color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: AppTextStyles.labelMedium(context)),
      subtitle: Text(
        value, 
        style: AppTextStyles.bodyMedium(context).copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
    );
  }
}
