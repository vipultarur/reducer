import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_spacing.dart';

class PremiumCloseButton extends StatelessWidget {
  const PremiumCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Image.asset(
        "assets/premium_screen/close_icon.png",
        width: 35,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.close, size: 35),
      ),
    );
  }
}
