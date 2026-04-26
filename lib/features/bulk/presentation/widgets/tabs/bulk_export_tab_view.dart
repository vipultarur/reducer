import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/bulk/presentation/controllers/bulk_image_controller.dart';
import 'package:reducer/features/bulk/presentation/widgets/image_grid_tile.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:reducer/core/utils/file_utils.dart';

class BulkExportTabView extends StatelessWidget {
  final BulkImageState state;
  final VoidCallback onProcess;
  final VoidCallback onSaveAll;
  final VoidCallback onExportZip;

  const BulkExportTabView({
    super.key,
    required this.state,
    required this.onProcess,
    required this.onSaveAll,
    required this.onExportZip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasProcessed = state.processedResults.isNotEmpty;

    return Column(
      children: [
        // Summary Section (Visible after processing)
        if (hasProcessed && !state.isProcessing)
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                   _buildSummaryRow(
                    context, 
                    l10n.totalOriginal, 
                    FileUtils.formatBytesDetailed(state.totalOriginalSize),
                  ),
                  const SizedBox(height: 8),
                   _buildSummaryRow(
                    context, 
                    l10n.totalCompressed, 
                    FileUtils.formatBytesDetailed(state.totalCompressedSize),
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                   _buildSummaryRow(
                    context, 
                    l10n.spaceSaved, 
                    '${state.totalOriginalSize > 0 ? ((state.totalOriginalSize - state.totalCompressedSize) / state.totalOriginalSize * 100).toInt() : 0}%',
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),

        // Progress Overlay (Only visible during processing)
        if (state.isProcessing)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      l10n.processingProgress(state.selectedImages.length), // Reusing processingProgress from arb
                      style: AppTextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(state.progress * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: state.selectedImages.length,
              itemBuilder: (context, index) {
                final xFile = state.selectedImages[index];
                final isProcessed = state.processedResults.containsKey(xFile.name);
                final hasSucceeded = state.processedResults[xFile.name] != null;
                return ImageGridTile(
                  path: xFile.path,
                  isProcessed: isProcessed,
                  hasSucceeded: hasSucceeded,
                );
              },
            ),
          ),
        ),

        // Bottom Actions
        if (hasProcessed && !state.isProcessing)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSaveAll,
                    icon: const Icon(Iconsax.gallery),
                    label: Text(l10n.saveAll),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportZip,
                    icon: const Icon(Iconsax.archive),
                    label: Text(l10n.zip),
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
          ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant)),
        Text(
          value,
          style: AppTextStyles.labelMedium(context).copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? AppColors.onDarkSurface : AppColors.onLightSurface),
          ),
        ),
      ],
    );
  }

  // Replaced by FileUtils.formatBytesDetailed
}

