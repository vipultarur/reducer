import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscribeButton extends ConsumerWidget {
  const SubscribeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final notifier = ref.read(premiumControllerProvider.notifier);

    return Column(
      children: [
        GestureDetector(
          onTap: state.isLoading ? null : () => notifier.purchaseSelectedPackage(),
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
                  : const Text(
                      'START PRO ACCESS',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
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
        const SizedBox(height: 16),
        const Text(
          'Cancel anytime. Secure checkout.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
