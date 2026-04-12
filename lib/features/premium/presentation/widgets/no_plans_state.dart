import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class NoPlansState extends StatelessWidget {
  const NoPlansState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "No plans available",
          style: AppTextStyles.bodyLarge(context),
        ),
      ),
    );
  }
}
