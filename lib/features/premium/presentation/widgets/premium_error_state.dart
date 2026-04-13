import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/shared/widgets/app_button.dart';


class PremiumErrorState extends ConsumerWidget {
  final String error;
  const PremiumErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context),
              ),
              const SizedBox(height: AppSpacing.xl2),
              AppButton(
                label: "Try again",
                icon: Icons.refresh,
                onPressed: () => ref.read(premiumControllerProvider.notifier).fetchOffersAndCheckStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
