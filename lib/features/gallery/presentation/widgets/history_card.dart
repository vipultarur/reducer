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
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reducer/core/services/permission_service.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:reducer/core/utils/file_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              _showActionSheet(context);
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
                          width: 72.r,
                          height: 72.r,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2.r)),
                        )
                      : Builder(builder: (context) {
                          final thumbPath = item.getAbsoluteThumbnailPath(appDocDir!);
                          final file = File(thumbPath);
                          return file.existsSync()
                              ? Image.file(
                                  file,
                                  width: 72.r,
                                  height: 72.r,
                                  fit: BoxFit.cover,
                                  cacheWidth: 144, // 2x for retina displays
                                  cacheHeight: 144,
                                )
                              : Container(
                                  width: 72.r,
                                  height: 72.r,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Icon(Iconsax.image, color: Colors.grey, size: 24.r),
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
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.grid_5, size: 10.r, color: AppColors.secondaryDark),
                                  SizedBox(width: 4.w),
                                  Text(
                                    AppLocalizations.of(context)!.bulkCountLabel(item.itemCount),
                                    style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.secondaryDark),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
                        '${FileUtils.formatBytes(item.originalSize)} → ${FileUtils.formatBytes(item.processedSize)}',
                        style: AppTextStyles.titleSmall(context),
                      ),
                      if (item.compressionPercent > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Iconsax.arrow_down, size: 12.r, color: AppColors.success),
                            SizedBox(width: 4.w),
                            Text(
                              '${item.compressionPercent.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.smaller}',
                              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Iconsax.arrow_right_3, size: 16.r, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.imageActions,
              style: AppTextStyles.titleMedium(context),
            ),
            SizedBox(height: 24.h),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.save_2, color: AppColors.primary, size: 24.r),
              ),
              title: Text(AppLocalizations.of(context)!.saveToGallery),
              onTap: () async {
                Navigator.pop(context);
                final path = item.getAbsoluteProcessedPaths(appDocDir ?? '').firstOrNull;
                if (path != null && File(path).existsSync()) {
                  final ok = await PermissionService.instance.ensurePhotosPermission(context);
                  if (ok) {
                    await Gal.putImage(path, album: 'Reducer');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.savedToGallerySuccess),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.processedFileNotFound),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.share, color: AppColors.secondary, size: 24.r),
              ),
              title: Text(AppLocalizations.of(context)!.shareImage),
              onTap: () async {
                Navigator.pop(context);
                final path = item.getAbsoluteProcessedPaths(appDocDir ?? '').firstOrNull;
                if (path != null && File(path).existsSync()) {
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(path)]),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.processedFileNotFound),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
