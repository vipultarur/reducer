import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

class BulkResizeTabView extends StatelessWidget {
  final ImageSettings settings;
  final ValueChanged<ImageSettings> onSettingsChanged;

  const BulkResizeTabView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildInfoNote(context, 'Percentage scaling is recommended for bulk batches.'),
          const SizedBox(height: AppSpacing.lg),
          
          _buildCard(
            context,
            title: 'SCALE % (RECOMMENDED)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Smaller', style: AppTextStyles.labelSmall(context)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${settings.scalePercent.toInt()}%',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('Original', style: AppTextStyles.labelSmall(context)),
                  ],
                ),
                Slider(
                  value: settings.scalePercent,
                  min: 1,
                  max: 100,
                  activeColor: AppColors.primary,
                  onChanged: (v) => onSettingsChanged(settings.copyWith(
                    scalePercent: v,
                    width: null, // Clear custom size when scaling
                    height: null,
                  )),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildCard(
            context,
            title: 'FIXED DIMENSIONS (EXPERT)',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDimensionField(
                        'Width',
                        settings.width?.toInt().toString() ?? '',
                        (v) => onSettingsChanged(settings.copyWith(width: double.tryParse(v))),
                        isDark,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('×', style: TextStyle(fontSize: 20, color: Colors.grey)),
                    ),
                    Expanded(
                      child: _buildDimensionField(
                        'Height',
                        settings.height?.toInt().toString() ?? '',
                        (v) => onSettingsChanged(settings.copyWith(height: double.tryParse(v))),
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Iconsax.link, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Lock Aspect Ratio', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Switch.adaptive(
                      value: settings.lockAspect,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => onSettingsChanged(settings.copyWith(lockAspect: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context, String text) {
     return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionField(String label, String value, ValueChanged<String> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Colors.black26 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: onChanged,
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
            color: isDark ? const Color(0xFF212121) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: child,
        ),
      ],
    );
  }
}
