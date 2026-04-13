import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/features/premium/presentation/widgets/package_card.dart';
import 'package:reducer/core/theme/app_spacing.dart';

class HorizontalPackageSelector extends ConsumerWidget {
  const HorizontalPackageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final notifier = ref.read(premiumControllerProvider.notifier);

    if (state.availablePackages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'SELECT PLAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: state.availablePackages.map((package) {
            final isPopular = package.isMonthly;
            
            return Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  PackageCard(
                    package: package,
                    isSelected: package == state.selectedPackage,
                    onTap: () => notifier.selectPackage(package),
                  ),
                  if (isPopular)
                    Positioned(
                      top: -12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFFACC15)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Text(
                          'SAVER',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
