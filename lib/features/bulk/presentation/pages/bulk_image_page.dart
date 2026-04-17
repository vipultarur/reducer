import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/shared/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/shared/presentation/widgets/ads/native_ad_widget.dart';
import 'package:reducer/features/gallery/presentation/controllers/history_controller.dart';
import 'package:reducer/features/gallery/data/models/history_item.dart';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/core/utils/thumbnail_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:reducer/core/services/permission_service.dart';
import 'package:reducer/features/bulk/presentation/controllers/bulk_image_controller.dart';
import 'package:reducer/features/bulk/presentation/widgets/tabs/bulk_compress_tab_view.dart';
import 'package:reducer/features/bulk/presentation/widgets/tabs/bulk_resize_tab_view.dart';
import 'package:reducer/features/bulk/presentation/widgets/tabs/bulk_format_tab_view.dart';
import 'package:reducer/features/bulk/presentation/widgets/tabs/bulk_export_tab_view.dart';
import 'package:path/path.dart' as p;

class BulkImageScreen extends ConsumerStatefulWidget {
  const BulkImageScreen({super.key});

  @override
  ConsumerState<BulkImageScreen> createState() => _BulkImageScreenState();
}

class _BulkImageScreenState extends ConsumerState<BulkImageScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages() async {
    if (!mounted) return;
    if (!await PermissionService.instance.ensurePhotosPermission(context)) return;

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty && mounted) {
      final isPro = ref.read(premiumControllerProvider).isPro;
      final selected = isPro ? pickedFiles : pickedFiles.take(50).toList();
      ref.read(bulkImageControllerProvider.notifier).selectImages(selected);
      
      if (!isPro && pickedFiles.length > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Free users: limit 50 images. Upgrade for more.')),
        );
      }
    }
  }

  Future<void> _handleProcess() async {
    final isPro = ref.read(premiumControllerProvider).isPro;
    await ref.read(bulkImageControllerProvider.notifier).processAll(isPro);
    
    final state = ref.read(bulkImageControllerProvider);
    final successful = state.processedResults.values.where((f) => f != null).cast<File>().toList();
    if (successful.isNotEmpty) {
      await _saveToHistory(successful, state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkImageControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.selectedImages.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: const Text('Bulk Studio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            onPressed: () => ref.read(bulkImageControllerProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          
          // Custom TabBar (Segmented Style)
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
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? Colors.white : AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                labelStyle: AppTextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.bold),
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
                BulkCompressTabView(
                  settings: state.settings,
                  onSettingsChanged: (s) => ref.read(bulkImageControllerProvider.notifier).updateSettings(s),
                ),
                BulkResizeTabView(
                  settings: state.settings,
                  onSettingsChanged: (s) => ref.read(bulkImageControllerProvider.notifier).updateSettings(s),
                ),
                BulkFormatTabView(
                  settings: state.settings,
                  onSettingsChanged: (s) => ref.read(bulkImageControllerProvider.notifier).updateSettings(s),
                ),
                BulkExportTabView(
                  state: state,
                  onProcess: _handleProcess,
                  onSaveAll: () => AdManager().showInterstitialAd(onComplete: () => _saveAllToGallery(state)),
                  onExportZip: () => AdManager().showInterstitialAd(onComplete: () => _exportAsZip(state)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Scaffold(
       appBar: AppBar(title: const Text('Bulk Studio')),
       body: SafeArea(
         child: SingleChildScrollView(
           padding: const EdgeInsets.all(AppSpacing.xl),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const BannerAdWidget(),
               const SizedBox(height: 40),
               const Icon(Iconsax.grid_5, size: 64, color: AppColors.primary),
               const SizedBox(height: 16),
               Text(
                 'Batch Processing',
                 style: AppTextStyles.titleLarge(context).copyWith(fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               const Text('Optimize hundreds of images in one go', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton.icon(
                   onPressed: () => AdManager().showInterstitialAd(onComplete: _pickMultipleImages),
                   icon: const Icon(Iconsax.add),
                   label: const Text('Select Multiple Images'),
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                 ),
               ),
               const SizedBox(height: 40),
               const NativeAdWidget(size: NativeAdSize.medium),
             ],
           ),
         ),
       ),
     );
  }

  Future<void> _saveToHistory(List<File> results, BulkImageState state) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final sessionId = const Uuid().v4();
      final sessionRelativeDir = 'history/bulk_$sessionId';
      final sessionDir = Directory(p.join(appDir.path, sessionRelativeDir));
      await sessionDir.create(recursive: true);

      final persistentRelativePaths = <String>[];
      for (final file in results) {
        final fileName = p.basename(file.path);
        final relPath = '$sessionRelativeDir/$fileName';
        persistentRelativePaths.add(relPath);
        await file.copy(p.join(appDir.path, relPath));
      }

      final thumbBytes = await ThumbnailGenerator.generateSmallThumbnail(XFile(results.first.path));
      if (thumbBytes == null) return;

      final thumbRelPath = 'history/thumb_bulk_$sessionId.jpg';
      await File(p.join(appDir.path, thumbRelPath)).writeAsBytes(thumbBytes);

      final originalSize = state.totalOriginalSize;
      final processedSize = state.totalCompressedSize;

      final historyItem = HistoryItem(
        id: sessionId,
        thumbnailPath: thumbRelPath,
        originalPath: state.selectedImages.first.path,
        settings: state.settings,
        timestamp: DateTime.now(),
        originalSize: originalSize,
        processedSize: processedSize,
        isBulk: true,
        itemCount: results.length,
        processedPaths: persistentRelativePaths,
      );

      await ref.read(historyControllerProvider.notifier).addItem(historyItem);
    } catch (e) {
      debugPrint('Error saving bulk history: $e');
    }
  }

  Future<void> _saveAllToGallery(BulkImageState state) async {
    final successful = state.processedResults.values.where((f) => f != null).cast<File>().toList();
    if (successful.isEmpty) return;

    try {
      await Future.wait(successful.map((f) => Gal.putImage(f.path, album: 'Reducer')));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Saved ${successful.length} images!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAsZip(BulkImageState state) async {
    final successful = state.processedResults.values.where((f) => f != null).cast<File>().toList();
    if (successful.isEmpty) return;

    try {
      final zipBytes = await compute(_buildZipIsolate, _ZipArgs(
        filePaths: successful.map((f) => f.path).toList(),
        extension: state.settings.format.extension,
      ));

      if (zipBytes == null) throw Exception('ZIP creation failed');

      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/bulk_${DateTime.now().millisecondsSinceEpoch}.zip');
      await zipFile.writeAsBytes(zipBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          subject: 'Processed images',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ZipArgs {
  final List<String> filePaths;
  final String extension;
  const _ZipArgs({required this.filePaths, required this.extension});
}

Future<List<int>?> _buildZipIsolate(_ZipArgs args) async {
  try {
    final archive = Archive();
    for (int i = 0; i < args.filePaths.length; i++) {
      final bytes = await File(args.filePaths[i]).readAsBytes();
      archive.addFile(ArchiveFile('image_${i + 1}.${args.extension}', bytes.length, bytes));
    }
    return ZipEncoder().encode(archive);
  } catch (_) {
    return null;
  }
}
