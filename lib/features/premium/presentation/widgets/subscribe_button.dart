import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';
import 'package:reducer/features/premium/presentation/widgets/premium_login_required_block.dart';

class SubscribeButton extends ConsumerWidget {
  const SubscribeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final authState = ref.watch(authProvider).value;
    final notifier = ref.read(premiumControllerProvider.notifier);

    // Build button text from selected plan
    final selectedPlan = state.selectedPackage;
    final buttonText = selectedPlan != null
        ? 'Subscribe ${selectedPlan.price} / ${selectedPlan.isYearly ? "year" : (selectedPlan.isMonthly ? "month" : selectedPlan.periodName.toLowerCase())}'
        : 'START PRO ACCESS';

    // Trial text if available
    final trialText = selectedPlan?.trialPeriod != null
        ? 'Start with ${selectedPlan!.trialPeriod} free trial'
        : null;

    return Column(
      children: [
        GestureDetector(
          onTap: state.isLoading 
            ? null 
            : () {
                if (authState == null || authState.isAnonymous) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1D27),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumLoginRequiredBlock(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                } else {
                  notifier.purchaseSelectedPackage();
                }
              },
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAB308), Color(0xFFFACC15), Color(0xFFEAB308)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Center(
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      buttonText.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        ),
        const SizedBox(height: 8),
        // Show trial info or fallback text
        Text(
          trialText ?? 'Cancel anytime. Secure checkout.',
          style: TextStyle(
            color: trialText != null ? const Color(0xFF22C55E).withValues(alpha: 0.8) : Colors.white38,
            fontSize: 11,
            fontWeight: trialText != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
