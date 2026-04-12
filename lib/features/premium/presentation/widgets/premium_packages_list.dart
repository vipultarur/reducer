import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/features/premium/presentation/widgets/package_card.dart';

class PremiumPackagesList extends ConsumerWidget {
  const PremiumPackagesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final notifier = ref.read(premiumControllerProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.availablePackages.length,
      itemBuilder: (context, index) {
        final package = state.availablePackages[index];
        return PackageCard(
          package: package,
          isSelected: package == state.selectedPackage,
          onTap: () => notifier.selectPackage(package),
        );
      },
    );
  }
}
