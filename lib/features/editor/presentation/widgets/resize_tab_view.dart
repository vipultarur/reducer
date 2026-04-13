import 'package:flutter/material.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class ResizeTabView extends StatelessWidget {
  final ImageSettings settings;
  final int originalWidth;
  final int originalHeight;
  final ValueChanged<ImageSettings> onSettingsChanged;

  const ResizeTabView({
    super.key,
    required this.settings,
    required this.originalWidth,
    required this.originalHeight,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            context,
            title: 'CUSTOM DIMENSIONS',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDimensionInput(context, 'WIDTH', settings.width?.toInt() ?? originalWidth)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                    Expanded(child: _buildDimensionInput(context, 'HEIGHT', settings.height?.toInt() ?? originalHeight)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lock aspect ratio', style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold)),
                        Text('16:9 maintained', style: AppTextStyles.labelSmall(context).copyWith(color: Colors.grey)),
                      ],
                    ),
                    Switch(
                      value: settings.lockAspect,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => onSettingsChanged(settings.copyWith(lockAspect: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildCard(
            context,
            title: 'TRANSFORM',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Flip horizontal', style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold)),
                Switch(
                  value: settings.flipHorizontal,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => onSettingsChanged(settings.copyWith(flipHorizontal: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionInput(BuildContext context, String label, int value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall(context).copyWith(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value.toString()),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onSubmitted: (val) {
                    final newVal = double.tryParse(val);
                    if (newVal != null) {
                      if (label == 'WIDTH') {
                        onSettingsChanged(settings.copyWith(width: newVal));
                      } else {
                        onSettingsChanged(settings.copyWith(height: newVal));
                      }
                    }
                  },
                ),
              ),
              const Text('px', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelSmall(context).copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: child,
        ),
      ],
    );
  }
}
