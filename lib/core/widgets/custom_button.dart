import 'package:flutter/material.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPremium;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isPremium = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: _buildIcon(AppColors.primary),
        label: _buildLabel(AppColors.primary, context),
        style: Theme.of(context).outlinedButtonTheme.style,
      );
    }

    if (isPremium) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.premiumGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppColors.premiumButtonShadow,
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(Colors.white),
          label: _buildLabel(Colors.white, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: _buildIcon(Colors.white),
      label: _buildLabel(Colors.white, context),
    );
  }

  Widget _buildIcon(Color color) {
    if (isLoading) {
      return SizedBox(
        width: AppSpacing.iconMd,
        height: AppSpacing.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    return Icon(icon, size: AppSpacing.iconMd, color: color);
  }

  Widget _buildLabel(Color color, BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.buttonText(context).copyWith(color: color),
    );
  }
}
