import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/shared/widgets/app_button.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:reducer/core/utils/file_utils.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            title: l10n.resultSummary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(context, FileUtils.formatFileSizeDetailed(processedSize), l10n.output),
                _buildSummaryItem(context, '$savedPercent%', l10n.saved, color: AppColors.primary),
                _buildSummaryItem(context, settings.format.name, l10n.formatLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                _buildStatRow(context, l10n.originalSize, FileUtils.formatFileSize(originalSize)),
                _buildStatRow(context, l10n.compressed, FileUtils.formatFileSize(processedSize), valueColor: AppColors.primary),
                _buildStatRow(context, l10n.dimensions, '${settings.width?.toInt() ?? originalWidth} × ${settings.height?.toInt() ?? originalHeight}'),
                _buildStatRow(context, l10n.format, settings.format.name, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          
          if (processedImageBytes != null) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.saveToGallery,
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
                    label: Text(l10n.share),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
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
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Iconsax.flash, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    l10n.readyToExport,
                    style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.applyChangesMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            color: color ?? (isDark ? AppColors.onDarkSurface : AppColors.onLightSurface),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, {Color? valueColor, bool isLast = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? AppColors.onDarkSurface : AppColors.onLightSurface),
            ),
          ),
        ],
      ),
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
            color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
          ),
          child: child,
        ),
      ],
    );
  }
}

