import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final StatefulNavigationShell navigationShell;

  const CommonAppBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final isPro = ref.watch(premiumControllerProvider.select((s) => s.isPro));

    String title = 'ImageMaster';
    List<Widget> actions = [];

    switch (index) {
      case 0:
        title = 'ImageMaster';
        actions = [
          if (!isPro)
            _PremiumBadge(onTap: () => navigationShell.goBranch(3)),
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () => context.push('/settings'),
          ),
        ];
        break;
      case 1:
        title = 'Editor';
        break;
      case 2:
        title = 'Edit History';
        break;
      case 3:
        title = 'Premium';
        break;
      case 4:
        title = 'My Profile';
        break;
    }

    return AppBar(
      title: Text(title, style: AppTextStyles.headlineSmall(context).copyWith(fontSize: 20)),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.sm),
      ],
      elevation: 0,
      centerTitle: false,
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.premium,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          onPressed: onTap,
          icon: const Icon(Iconsax.crown, size: 16),
          label: Text('PRO', style: AppTextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
