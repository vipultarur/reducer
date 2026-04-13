import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/shared/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/features/home/presentation/widgets/home_header.dart';
import 'package:reducer/features/home/presentation/widgets/guest_auth_card.dart';
import 'package:reducer/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:reducer/features/home/presentation/widgets/pro_tools_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(premiumControllerProvider.select((s) => s.isPro));
    final authState = ref.watch(authProvider).value;
    final isLoggedIn = authState != null && !authState.isAnonymous;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Banner Ad
            const SliverToBoxAdapter(
              child: BannerAdWidget(),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const HomeHeader(),
                  if (!isLoggedIn) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const GuestAuthCard(),
                  ],
                  const SizedBox(height: AppSpacing.xl2),
                  const QuickActionsSection(),
                  const SizedBox(height: AppSpacing.xl3),
                  ProToolsSection(isPro: isPro, isLoggedIn: isLoggedIn),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
