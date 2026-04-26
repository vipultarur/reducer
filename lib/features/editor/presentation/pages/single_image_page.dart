import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reducer/features/gallery/data/models/history_item.dart';
import 'package:reducer/features/gallery/presentation/controllers/history_controller.dart';
import 'package:reducer/features/editor/presentation/controllers/single_image_controller.dart';
import 'package:reducer/features/editor/presentation/widgets/compress_tab_view.dart';
import 'package:reducer/features/editor/presentation/widgets/resize_tab_view.dart';
import 'package:reducer/features/editor/presentation/widgets/format_tab_view.dart';
import 'package:reducer/features/editor/presentation/widgets/export_tab_view.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/core/services/permission_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/services/analytics_service.dart';
import 'package:reducer/features/settings/presentation/controllers/review_controller.dart';
import 'package:reducer/shared/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/shared/presentation/widgets/ads/native_ad_widget.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:reducer/core/utils/file_utils.dart';
import 'package:reducer/core/utils/image_validator.dart';

class SingleImageScreen extends ConsumerStatefulWidget {
  const SingleImageScreen({super.key});

  @override
  ConsumerState<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends ConsumerState<SingleImageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        ref.read(singleImageTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleProcess() async {
    await AdManager().showInterstitialAd(onComplete: () async {
      await ref.read(singleImageControllerProvider.notifier).processFinalImage();
      if (mounted) _tabController.animateTo(3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singleImageControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.originalThumbnail == null) {
      return _buildEmptyState(context);
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const BannerAdWidget(),
            _buildPreviewHeader(state),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Container(
                height: 52.h,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(26.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: isDark ? Colors.white : AppColors.primary,
                  unselectedLabelColor: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: AppTextStyles.labelMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: AppTextStyles.labelMedium(context).copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(text: l10n.compress),
                    Tab(text: l10n.resize),
                    Tab(text: l10n.format),
                    Tab(text: l10n.export),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CompressTabView(
                    settings: state.settings,
                    onSettingsChanged: (s) => ref.read(singleImageControllerProvider.notifier).updateSettings(s),
                  ),
                  ResizeTabView(
                    settings: state.settings,
                    originalWidth: state.originalWidth,
                    originalHeight: state.originalHeight,
                    onSettingsChanged: (s) => ref.read(singleImageControllerProvider.notifier).updateSettings(s),
                  ),
                  FormatTabView(
                    settings: state.settings,
                    onSettingsChanged: (s) => ref.read(singleImageControllerProvider.notifier).updateSettings(s),
                  ),
                  ExportTabView(
                    processedImageBytes: state.processedImageBytes,
                    settings: state.settings,
                    originalSize: state.originalSize,
                    originalWidth: state.originalWidth,
                    originalHeight: state.originalHeight,
                    onSave: () => _saveToGallery(state),
                    onShare: () => _shareImage(state),
                  ),
                ],
              ),
            ),

            Consumer(
              builder: (context, ref, child) {
                final tabIndex = ref.watch(singleImageTabIndexProvider);
                if (tabIndex >= 3) return const SizedBox.shrink();
                
                final isProcessing = ref.watch(singleImageControllerProvider.select((s) => s.isProcessingFinal));
                
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : _handleProcess,
                      icon: const Icon(Iconsax.flash),
                      label: Text(isProcessing ? l10n.processingDot : l10n.processImage),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(SingleImageState state) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayImage = _showOriginal ? state.originalThumbnail! : (state.previewThumbnail ?? state.originalThumbnail!);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.memory(
                  displayImage,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  cacheHeight: 360, 
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => setState(() => _showOriginal = !_showOriginal),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _showOriginal ? AppColors.primary : Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8.r, color: _showOriginal ? AppColors.warning : AppColors.primary),
                        SizedBox(width: 6.w),
                        Text(
                          _showOriginal ? l10n.showAfter : l10n.showBefore, 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${state.originalWidth} × ${state.originalHeight} · ${FileUtils.formatFileSize(state.originalSize)}',
            style: TextStyle(
              color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BannerAdWidget(),
              const SizedBox(height: 40),
              const Icon(Iconsax.image, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                l10n.pickImageToStart,
                style: AppTextStyles.titleLarge(context).copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.pickImageSubtitle, 
                textAlign: TextAlign.center, 
                style: TextStyle(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final l10nCapture = AppLocalizations.of(context)!;
                        try {
                          await ref.read(singleImageControllerProvider.notifier).pickImage(ImageSource.gallery, l10nCapture);
                        } catch (e) {
                          if (e is ValidationResult && context.mounted) {
                            ImageValidator.showValidationDialog(context, e);
                          }
                        }
                      },
                      icon: const Icon(Iconsax.gallery),
                      label: Text(l10n.gallery),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final l10nCapture = AppLocalizations.of(context)!;
                        try {
                          await ref.read(singleImageControllerProvider.notifier).pickImage(ImageSource.camera, l10nCapture);
                        } catch (e) {
                          if (e is ValidationResult && context.mounted) {
                            ImageValidator.showValidationDialog(context, e);
                          }
                        }
                      },
                      icon: const Icon(Iconsax.camera),
                      label: Text(l10n.camera),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),
              const NativeAdWidget(size: NativeAdSize.medium),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToGallery(SingleImageState state) async {
    final processedBytes = state.processedImageBytes;
    final previewBytes = state.previewThumbnail ?? state.originalThumbnail;
    if (processedBytes == null || previewBytes == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    await AdManager().showInterstitialAd(onComplete: () async {
      try {
        if (!mounted) return;
        final ok = await PermissionService.instance.ensurePhotosPermission(context);
        if (!ok) return;

        final timestampMs = DateTime.now().millisecondsSinceEpoch;
        
        final appDir = await getApplicationDocumentsDirectory();
        final thumbRelativePath = 'history/thumb_$timestampMs.jpg';
        final processedRelativePath = 'history/proc_$timestampMs.${state.settings.format.extension}';
        
        final thumbFile = File(p.join(appDir.path, thumbRelativePath));
        final procFile = File(p.join(appDir.path, processedRelativePath));

        await Directory(p.dirname(thumbFile.path)).create(recursive: true);
        await procFile.writeAsBytes(processedBytes);
        await thumbFile.writeAsBytes(previewBytes);

        await Gal.putImage(procFile.path, album: 'Reducer');

        final historyItem = HistoryItem(
          id: const Uuid().v4(),
          thumbnailPath: thumbRelativePath,
          processedPaths: [processedRelativePath],
          originalPath: state.originalFile?.path ?? '',
          settings: state.settings,
          timestamp: DateTime.now(),
          originalSize: state.originalSize,
          processedSize: processedBytes.length,
        );
        
        await ref.read(historyControllerProvider.notifier).addItem(historyItem);

        unawaited(ref.read(analyticsServiceProvider).logCompressionSuccess(
          type: 'single',
          originalSize: state.originalSize,
          compressedSize: processedBytes.length,
          imageCount: 1,
        ));
        unawaited(ref.read(reviewControllerProvider).recordSuccessfulSave());

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.compressionSuccess), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.failedToSave(e.toString())), backgroundColor: AppColors.error),
          );
        }
      }
    });
  }

  Future<void> _shareImage(SingleImageState state) async {
    if (state.processedImageBytes == null || !mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.${state.settings.format.extension}');
      await file.writeAsBytes(state.processedImageBytes!);

      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)], 
            text: l10n.shareWithReducer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToShare(e.toString())), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
