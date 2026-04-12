import 'package:flutter/material.dart';
import 'premium_info_row.dart';

class BenefitList extends StatelessWidget {
  const BenefitList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PremiumInfoRow(value: "Unlimited access"),
        PremiumInfoRow(value: "Ad-free experience"),
        PremiumInfoRow(value: "Priority support"),
      ],
    );
  }
}
