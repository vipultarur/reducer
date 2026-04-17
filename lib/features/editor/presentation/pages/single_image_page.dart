import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
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
import 'package:reducer/shared/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/shared/presentation/widgets/ads/native_ad_widget.dart';

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
        // Targeted state update instead of full screen setState
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
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Banner Ad
            const BannerAdWidget(),

            // Header Preview
            _buildPreviewHeader(state),

            // Custom TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isDark ? const Color(0xFF323232) : Colors.white,
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
                  unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: AppTextStyles.labelMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: AppTextStyles.labelMedium(context).copyWith(
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(text: 'Compress'),
                    Tab(text: 'Resize'),
                    Tab(text: 'Format'),
                    Tab(text: 'Export'),
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

            // Process Button (Persistent across first 3 tabs)
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
                      label: Text(isProcessing ? 'Processing...' : 'Process Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayImage = _showOriginal ? state.originalThumbnail! : (state.previewThumbnail ?? state.originalThumbnail!);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  displayImage,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  // Optimization: Downsample to actual display dimensions to save memory
                  cacheHeight: 360, 
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _showOriginal = !_showOriginal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _showOriginal ? AppColors.primary : Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: _showOriginal ? Colors.orange : Colors.indigoAccent),
                        const SizedBox(width: 6),
                        Text(
                          _showOriginal ? 'Show After' : 'Show Before', 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${state.originalWidth} × ${state.originalHeight} · ${_formatFileSize(state.originalSize)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildEmptyState() {
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
                 'Pick an image to start',
                 style: AppTextStyles.titleLarge(context).copyWith(fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               const Text('Choose from your gallery or take a new photo', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 32),
               Row(
                 children: [
                   Expanded(
                     child: ElevatedButton.icon(
                       onPressed: () => ref.read(singleImageControllerProvider.notifier).pickImage(ImageSource.gallery),
                       icon: const Icon(Iconsax.gallery),
                       label: const Text('Gallery'),
                       style: ElevatedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: OutlinedButton.icon(
                       onPressed: () => ref.read(singleImageControllerProvider.notifier).pickImage(ImageSource.camera),
                       icon: const Icon(Iconsax.camera),
                       label: const Text('Camera'),
                       style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 40),
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

    // Trigger Interstitial Ad before save
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Saved to Gallery!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  Future<void> _shareImage(SingleImageState state) async {
    if (state.processedImageBytes == null || !mounted) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.${state.settings.format.extension}');
      await file.writeAsBytes(state.processedImageBytes!);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)], 
          text: 'Processed with Reducer',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
