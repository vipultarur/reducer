import 'package:flutter/material.dart';
import 'package:reducer/features/premium/domain/models/premium_plan.dart';
import 'package:reducer/core/theme/app_spacing.dart';

class PackageCard extends StatelessWidget {
  final PremiumPlan package;
  final bool isSelected;
  final VoidCallback onTap;

  const PackageCard({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1E293B).withValues(alpha: 0.8) 
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFACC15) 
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFEAB308).withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 3,
            )
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFACC15).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _planLabel,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? const Color(0xFFFACC15) : Colors.white38,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _currencySymbol,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? const Color(0xFFFACC15) : Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _numericPrice,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _periodSuffix,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            // Show trial badge if available
            if (package.trialPeriod != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${package.trialPeriod} FREE',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFACC15) : Colors.white12,
                  width: 1.5,
                ),
                color: isSelected ? const Color(0xFFFACC15) : Colors.transparent,
              ),
              child: Icon(
                Icons.check,
                color: isSelected ? Colors.black : Colors.transparent,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The label displayed at the top of the card, derived from the plan type.
  String get _planLabel {
    if (package.isTestPlan) return 'TRIAL';
    if (package.isYearly) return 'YEARLY';
    if (package.isMonthly) return 'MONTHLY';
    return package.periodName.toUpperCase();
  }

  /// Extract the currency symbol from the formatted price (e.g., "₹" from "₹99.00").
  String get _currencySymbol {
    return RegExp(r'^[^\d]+').stringMatch(package.price) ?? '';
  }

  /// Extract the numeric portion from the formatted price (e.g., "99.00" from "₹99.00").
  String get _numericPrice {
    return RegExp(r'[\d,.]+').stringMatch(package.price) ?? '0';
  }

  /// The period suffix displayed below the price.
  String get _periodSuffix {
    if (package.isTestPlan) return 'Full Access';
    if (package.isYearly) return '/year';
    if (package.isMonthly) return '/month';
    return '/${package.periodName.toLowerCase()}';
  }
}
