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
              ? const Color(0xFF1E293B) 
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFACC15) 
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFEAB308).withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : [],
        ),
        child: Column(
          children: [
            Text(
              package.isYearly ? 'YEARLY' : (package.isMonthly ? 'MONTHLY' : 'WEEKLY'),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                color: isSelected ? const Color(0xFFFACC15) : Colors.white38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              package.price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.isYearly ? '/Year' : (package.isMonthly ? '/Month' : '/Week'),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFFFACC15) : Colors.white12,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
