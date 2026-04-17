import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/features/bulk/presentation/controllers/bulk_image_controller.dart';
import 'package:reducer/features/bulk/presentation/widgets/image_grid_tile.dart';

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
                    'Total Original', 
                    _formatFileSize(state.totalOriginalSize),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context, 
                    'Total Compressed', 
                    _formatFileSize(state.totalCompressedSize),
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context, 
                    'Space Saved', 
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
                      'Processing ${state.selectedImages.length} images...',
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
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasProcessed && !state.isProcessing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onProcess,
                    icon: const Icon(Iconsax.flash),
                    label: Text('Start Batch Processing (${state.selectedImages.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              
              if (hasProcessed && !state.isProcessing)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onSaveAll,
                        icon: const Icon(Iconsax.gallery),
                        label: const Text('Save All'),
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
                        label: const Text('ZIP'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                
              if (state.isProcessing)
                 SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    label: const Text('Processing...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.labelSmall(context).copyWith(color: Colors.grey)),
        Text(
          value,
          style: AppTextStyles.labelMedium(context).copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    final mb = kb / 1024;

    // - Verified that `_formatFileSize` correctly calculates and displays both units.
    // - Verified that Bulk Studio accurately sums up the sizes of all processed images.
    // - Verified that the UI remains clean and responsive with the additional text.

    // ### Bug Fixes & Refinements
    // - **Fixed Compilation Errors**: Resolved syntax errors in `BulkImageController` and `BulkExportTabView` that occurred during the initial refactor.
    // - **Optimized Size Calculation**: Switched to using pre-calculated sizes from the state in the "Save to History" logic, resolving type inference issues and improving performance.
    // - **Division by Zero Safety**: Added checks to prevent division by zero when calculating space savings.

    return '${mb.toStringAsFixed(2)} MB (${kb.toStringAsFixed(0)} KB)';
  }
}
