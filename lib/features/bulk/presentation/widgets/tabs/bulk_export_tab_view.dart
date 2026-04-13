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
}
