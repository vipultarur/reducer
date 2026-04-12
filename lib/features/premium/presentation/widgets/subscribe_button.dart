import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/features/premium/presentation/widgets/app_button.dart';
import 'package:reducer/features/premium/presentation/widgets/app_status_bar.dart';
import 'package:reducer/features/auth/presentation/providers/auth_providers.dart';

class SubscribeButton extends ConsumerWidget {
  const SubscribeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final authState = ref.watch(authProvider).value;
    
    return AppButton(
      label: "Subscribe Now",
      isLoading: state.isLoading,
      isFullWidth: true,
      onPressed: (state.selectedPackage == null || state.isLoading) 
          ? null 
          : () {
              if (authState == null) {
                AppStatusBar.showError(context, "Please login to unlock Premium");
                context.push('/login');
                return;
              }
              ref.read(premiumControllerProvider.notifier).purchaseSelectedPackage();
            },
      iconWidget: Image.asset(
        "assets/common/king_icon.png",
        color: Colors.white,
        width: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.star, color: Colors.white, size: 20),
      ),
    );
  }
}
