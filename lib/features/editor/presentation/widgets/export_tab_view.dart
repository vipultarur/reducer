import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/shared/widgets/app_button.dart';

class ExportTabView extends StatelessWidget {
  final Uint8List? processedImageBytes;
  final ImageSettings settings;
  final int originalSize;
  final int originalWidth;
  final int originalHeight;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ExportTabView({
    super.key,
    required this.processedImageBytes,
    required this.settings,
    required this.originalSize,
    required this.originalWidth,
    required this.originalHeight,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final processedSize = processedImageBytes?.length ?? 0;
    final savedPercent = originalSize > 0 ? ((originalSize - processedSize) / originalSize * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            context,
            title: 'RESULT SUMMARY',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(context, _formatFileSize(processedSize), 'OUTPUT'),
                _buildSummaryItem(context, '$savedPercent%', 'SAVED', color: AppColors.primary),
                _buildSummaryItem(context, settings.format.name, 'FORMAT'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                _buildStatRow('Original size', _formatFileSize(originalSize)),
                _buildStatRow('Compressed', _formatFileSize(processedSize), valueColor: AppColors.primary),
                _buildStatRow('Dimensions', '${settings.width?.toInt() ?? originalWidth} × ${settings.height?.toInt() ?? originalHeight}'),
                _buildStatRow('Format', settings.format.name, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          
          if (processedImageBytes != null) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Save to Gallery',
                    icon: Iconsax.save_2,
                    onPressed: onSave,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Iconsax.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), style: BorderStyle.none),
              ),
              child: Column(
                children: [
                  const Icon(Iconsax.flash, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Ready to export!',
                    style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apply your changes and click "Process Image" to generate your final result.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall(context).copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            color: color ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(color: Colors.grey, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB (${kb.toStringAsFixed(0)} KB)';
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
