import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/core/theme/app_theme.dart';
import 'package:reducer/features/gallery/data/models/history_item.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final String? appDocDir;

  const HistoryCard({
    super.key,
    required this.item,
    required this.appDocDir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppTheme.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () {
            if (item.isBulk) {
              context.push('/bulk-history-detail', extra: item);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-edit feature coming soon!')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: appDocDir == null
                      ? Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Builder(builder: (context) {
                          final thumbPath = item.getAbsoluteThumbnailPath(appDocDir!);
                          final file = File(thumbPath);
                          return file.existsSync()
                              ? Image.file(
                                  file,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Iconsax.image, color: Colors.grey),
                                );
                        }),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isBulk) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.grid_5, size: 10, color: AppColors.secondaryDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BULK (${item.itemCount})',
                                    style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.secondaryDark),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            ),
                            child: Text(
                              item.settings.format.toString().split('.').last.toUpperCase(),
                              style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd').format(item.timestamp),
                            style: AppTextStyles.labelSmall(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_formatSize(item.originalSize)} → ${_formatSize(item.processedSize)}',
                        style: AppTextStyles.titleSmall(context),
                      ),
                      if (item.compressionPercent > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Iconsax.arrow_down, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${item.compressionPercent.toStringAsFixed(1)}% smaller',
                              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
