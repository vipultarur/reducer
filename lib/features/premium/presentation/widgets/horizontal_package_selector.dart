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
            const Expanded(child: Divider(height: 1, color: Colors.white10)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'SELECT PLAN',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const Expanded(child: Divider(height: 1, color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: state.availablePackages.map((package) {
            // Show dynamic savings badge for yearly plan
            final savingsText = _calculateSavings(state, package);
            
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
                  if (savingsText != null)
                    Positioned(
                      top: -12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEAB308), Color(0xFFFACC15)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Text(
                          savingsText,
                          style: const TextStyle(
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

  /// Calculate savings for a plan compared to the monthly plan.
  /// Returns null if no savings badge should be shown.
  String? _calculateSavings(PurchaseState state, package) {
    if (!package.isYearly) return null;

    // Find the monthly plan to compare against
    final monthlyPlan = state.availablePackages
        .where((p) => p.isMonthly)
        .firstOrNull;

    if (monthlyPlan == null) return 'BEST VALUE';

    final monthlyMicros = monthlyPlan.priceAmountMicros;
    final yearlyMonthlyEquiv = package.monthlyEquivalentMicros;

    if (monthlyMicros <= 0) return 'BEST VALUE';

    final savingsPercent = ((monthlyMicros - yearlyMonthlyEquiv) / monthlyMicros * 100).round();

    if (savingsPercent > 0) {
      return 'SAVES $savingsPercent%';
    }
    return 'BEST VALUE';
  }
}
