import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PremiumFeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const PremiumFeatureItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.r,
            color: Colors.black87,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

