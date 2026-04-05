import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:reducer/core/theme/design_tokens.dart';
import 'package:reducer/core/theme/app_theme.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/features/gallery/gallery.dart';
import 'package:reducer/core/utils/image_processor.dart';
import 'package:reducer/core/widgets/custom_button.dart';
import 'package:reducer/core/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/core/widgets/ads/native_ad_widget.dart';
import 'package:reducer/core/utils/image_validator.dart';
import 'package:reducer/core/utils/thumbnail_generator.dart';
import 'package:reducer/core/utils/debouncer.dart';
import 'package:reducer/features/premium/premium.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/core/services/permission_service.dart';

class SingleImageScreen extends ConsumerStatefulWidget {
  const SingleImageScreen({super.key});

  @override
  ConsumerState<SingleImageScreen> createState() => _SingleImageScreenState();
}

class _SingleImageScreenState extends ConsumerState<SingleImageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  File? _selectedFile;
  Uint8List? _selectedImageBytes;

  Uint8List? _originalThumbnail;
  Uint8List? _previewThumbnail;

  Uint8List? _processedImageBytes;

  ImageSettings _settings = ImageSettings();

  bool _isGeneratingThumbnail = false;
  bool _isProcessingPreview = false;
  bool _isProcessingFinal = false;
  bool _showBeforeImage = false;

  final Debouncer _previewDebouncer =
  Debouncer(delay: const Duration(milliseconds: 250));

  // ── FIX 1: Cancellation flag ─────────────────────────────────────────────
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _cancelled = true;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _previewDebouncer.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage([ImageSource source = ImageSource.gallery]) async {
    final ok = source == ImageSource.camera
        ? await PermissionService.instance.ensureCameraPermission(context)
        : await PermissionService.instance.ensurePhotosPermission(context);
    if (!ok) return;

    final picker = ImagePicker();
    XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open ${source == ImageSource.camera ? "camera" : "photos"}: $e')),
        );
      }
      return;
    }

    // ── FIX 2: mounted check immediately after every await ────────────────
    if (pickedFile == null || !mounted) return;

    setState(() {
      _isGeneratingThumbnail = true;
      _originalThumbnail = null;
      _previewThumbnail = null;
      _processedImageBytes = null;
      _showBeforeImage = false;
    });

    try {
      if (!kIsWeb) {
        _selectedFile = File(pickedFile.path);
        if (!_selectedFile!.existsSync()) {
          throw Exception('Captured file missing');
        }
      }

      final bytes = await pickedFile.readAsBytes();
      if (!mounted || _cancelled) return;

      _selectedImageBytes = bytes;

      final validationResult = ImageValidator.validateImage(_selectedImageBytes!);
      if (!validationResult.isValid) {
        if (mounted) ImageValidator.showValidationDialog(context, validationResult);
        return;
      }
      if (validationResult.hasWarning && mounted) {
        ImageValidator.showValidationDialog(context, validationResult);
      }

      final thumbnail = await ThumbnailGenerator.generateThumbnailFromXFile(
        pickedFile,
        maxWidth: 1000,
        quality: 70,
      );

      // ── FIX 3: mounted check after every async call ───────────────────
      if (!mounted || _cancelled) return;

      if (thumbnail != null) {
        setState(() {
          _originalThumbnail = thumbnail;
          _previewThumbnail = thumbnail;
          _settings = _settings.copyWith(originalFile: _selectedFile);
          _isGeneratingThumbnail = false;
          _tabController.animateTo(1);
        });
        _regeneratePreview();
      } else {
        throw Exception('Failed to generate thumbnail');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingThumbnail = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading image: $e')),
      );
    }
  }

  Future<void> _regeneratePreview() async {
    if (_originalThumbnail == null || !mounted || _cancelled) return;

    setState(() => _isProcessingPreview = true);

    try {
      final isPro = ref.read(premiumControllerProvider).isPro;
      final result = await ImageProcessor.processImageThumbnail(
        _originalThumbnail!,
        _settings,
        isPremium: isPro,
      );

      // ── FIX 4: mounted check after processing completes ───────────────
      if (!mounted || _cancelled) return;

      setState(() {
        _previewThumbnail = result ?? _previewThumbnail;
        _isProcessingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPreview = false);
      debugPrint('Error regenerating preview: $e');
    }
  }

  Future<void> _processFinalImage() async {
    if (_selectedImageBytes == null || !mounted) return;

    setState(() => _isProcessingFinal = true);

    try {
      final isPro = ref.read(premiumControllerProvider).isPro;
      final result = await ImageProcessor.processImageBytes(
        _selectedImageBytes!,
        _settings,
        isPremium: isPro,
      );

      // ── FIX 5: mounted check after heavy async work ───────────────────
      if (!mounted || _cancelled) return;

      if (result != null) {
        setState(() {
          _processedImageBytes = result;
          _isProcessingFinal = false;
          _showBeforeImage = false;
          _tabController.animateTo(2);
        });
      } else {
        setState(() => _isProcessingFinal = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingFinal = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  void _onSettingChanged(ImageSettings newSettings) {
    if (!mounted) return;
    setState(() => _settings = newSettings);
    _previewDebouncer.call(_regeneratePreview);
  }

  Future<void> _saveToGallery() async {
    final processedBytes = _processedImageBytes;
    final previewBytes = _previewThumbnail ?? _originalThumbnail;

    if (processedBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No processed image to save')),
      );
      return;
    }
    if (previewBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available to save in history')),
      );
      return;
    }

    try {
      final ok = await PermissionService.instance.ensurePhotosPermission(context);
      if (!ok) return;

      final timestamp = DateTime.now();
      final timestampMs = timestamp.millisecondsSinceEpoch;
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'imagemaster_$timestampMs.${_settings.format.extension}';
      final file = File('${tempDir.path}/$fileName');

      final appDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory(p.join(appDir.path, 'history'));
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }

      final thumbFileName = 'thumb_$timestampMs.jpg';
      final thumbRelativePath = 'history/$thumbFileName';
      final thumbFile = File(p.join(appDir.path, thumbRelativePath));

      // Fix: Write files concurrently to reduce UI-thread stalls on large images.
      await Future.wait([
        file.writeAsBytes(processedBytes),
        thumbFile.writeAsBytes(previewBytes),
      ]);

      if (!mounted || _cancelled) return;

      await Gal.putImage(file.path, album: 'ImageMaster Pro');

      if (!mounted) return;

      final historyItem = HistoryItem(
        id: const Uuid().v4(),
        thumbnailPath: thumbRelativePath,
        originalPath: _selectedFile?.path ?? '',
        settings: _settings,
        timestamp: timestamp,
        originalSize: _selectedImageBytes?.length ?? 0,
        processedSize: processedBytes.length,
      );
      final historyController = await ref.readHistoryControllerReady();
      await historyController.addItem(historyItem);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('✓ Saved to Gallery!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _shareImage() async {
    if (_processedImageBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No processed image to share')),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'imagemaster_share_${DateTime.now().millisecondsSinceEpoch}.${_settings.format.extension}';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(_processedImageBytes!);

      if (!mounted || _cancelled) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Processed with ImageMaster Pro',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DesignTokens.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: DesignTokens.primaryBlue,
          tabs: const [
            Tab(text: 'Upload', icon: Icon(Iconsax.document_upload)),
            Tab(text: 'Edit & Preview', icon: Icon(Iconsax.setting_2)),
            Tab(text: 'Export', icon: Icon(Iconsax.export)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Fix: Keep only one ad platform view active per tab for smoother frames.
          if (showBanner) const BannerAdWidget(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadTab(),
                _buildSettingsTab(),
                _buildExportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isGeneratingThumbnail)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading image...', style: TextStyle(color: Colors.grey)),
              ],
            )
          else if (_originalThumbnail != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ── FIX 6: RepaintBoundary prevents unnecessary repaints ─
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _originalThumbnail!,
                        height: 300,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                        cacheHeight: 600,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Original Size: ${_formatFileSize(_selectedImageBytes?.length)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          else
            const Icon(Iconsax.image, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isGeneratingThumbnail
                    ? null
                    : () => AdManager().showInterstitialAd(
                    onComplete: () => _pickImage(ImageSource.gallery)),
                icon: const Icon(Iconsax.gallery),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingThumbnail
                    ? null
                    : () => AdManager().showInterstitialAd(
                    onComplete: () => _pickImage(ImageSource.camera)),
                icon: const Icon(Iconsax.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_originalThumbnail == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FIX 7: Show live preview thumbnail while settings change ────
          if (_previewThumbnail != null)
            _buildSettingsSection(
              title: 'Live Preview',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _previewThumbnail!,
                        height: 200,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                        cacheHeight: 600,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  if (_isProcessingPreview)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          _buildSettingsSection(
            title: 'Resize & Scale',
            child: _buildScaleControl(
              value: _settings.scalePercent,
              imageSizeBytes: _selectedImageBytes?.length,
              onChanged: (v) =>
                  _onSettingChanged(_settings.copyWith(scalePercent: v)),
            ),
          ),
          _buildSettingsSection(
            title: 'Adjustments',
            child: Column(
              children: [
                _buildSlider(
                    label: 'Rotation',
                    value: _settings.rotation,
                    min: 0,
                    max: 360,
                    onChanged: (v) =>
                        _onSettingChanged(_settings.copyWith(rotation: v))),
                _buildSlider(
                    label: 'Quality',
                    value: _settings.quality,
                    min: 1,
                    max: 100,
                    onChanged: (v) =>
                        _onSettingChanged(_settings.copyWith(quality: v))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFlipToggle(
                        label: 'Flip H',
                        value: _settings.flipHorizontal,
                        onChanged: (v) => _onSettingChanged(
                            _settings.copyWith(flipHorizontal: v))),
                    _buildFlipToggle(
                        label: 'Flip V',
                        value: _settings.flipVertical,
                        onChanged: (v) => _onSettingChanged(
                            _settings.copyWith(flipVertical: v))),
                  ],
                ),
              ],
            ),
          ),
          _buildSettingsSection(
            title: 'Export Format',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ImageFormat.values.map((f) {
                return ChoiceChip(
                  label: Text(f.name),
                  selected: _settings.format == f,
                  onSelected: (selected) {
                    if (selected) {
                      _onSettingChanged(_settings.copyWith(format: f));
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _isProcessingFinal ? 'Processing...' : 'Process Image',
              icon: Iconsax.cpu,
              onPressed: _processFinalImage,
              isLoading: _isProcessingFinal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    if (_processedImageBytes == null) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.info_circle, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No processed image yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Go to Settings tab and click "Process Image"',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: NativeAdWidget(size: NativeAdSize.medium),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showBeforeImage ? 'Before (Original)' : 'After (Processed)',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _showBeforeImage = !_showBeforeImage),
                      icon: Icon(
                          _showBeforeImage ? Iconsax.eye : Iconsax.eye_slash,
                          size: 18),
                      label: Text(
                          _showBeforeImage ? 'Show After' : 'Show Before'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onPanStart: (_) =>
                          setState(() => _showBeforeImage = true),
                      onPanEnd: (_) =>
                          setState(() => _showBeforeImage = false),
                      onLongPressStart: (_) =>
                          setState(() => _showBeforeImage = true),
                      onLongPressEnd: (_) =>
                          setState(() => _showBeforeImage = false),
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _showBeforeImage
                                ? (_originalThumbnail ??
                                _previewThumbnail ??
                                _processedImageBytes!)
                                : (_previewThumbnail ?? _processedImageBytes!),
                            height: 300,
                            fit: BoxFit.contain,
                            cacheWidth: 800,
                            cacheHeight: 600,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                    if (!_showBeforeImage)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.finger_scan,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 8),
                              Text('Hold image to compare',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text('Ready to Export!',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _exportInfoRow('Format', _settings.format.name),
                      const SizedBox(height: 8),
                      _exportInfoRow(
                          'Quality', '${_settings.quality.toInt()}%'),
                      const SizedBox(height: 8),
                      _exportInfoRow(
                        'File Size',
                        _formatFileSize(_processedImageBytes!.length),
                        valueColor: _processedImageBytes!.length <
                            _selectedImageBytes!.length
                            ? Colors.green
                            : DesignTokens.primaryBlue,
                      ),
                      if (_processedImageBytes!.length <
                          _selectedImageBytes!.length) ...[
                        const SizedBox(height: 8),
                        _exportInfoRow(
                          'Size Reduced',
                          '${_getSizeReductionPercentage().toStringAsFixed(1)}%',
                          valueColor: Colors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Save to Gallery',
                  icon: Iconsax.save_2,
                  onPressed: () => AdManager().showInterstitialAd(
                      onComplete: _saveToGallery),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  label: 'Share',
                  icon: Iconsax.share,
                  onPressed: () => AdManager().showInterstitialAd(
                      onComplete: _shareImage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FIX 8: Extracted repetitive Row widget to reduce duplication ──────────
  Widget _exportInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Please upload an image first',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: NativeAdWidget(size: NativeAdSize.medium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      {required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toInt()}${label.contains('Percent') ? '%' : ''}'),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: DesignTokens.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildFlipToggle(
      {required String label,
        required bool value,
        required Function(bool) onChanged}) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged, activeColor: DesignTokens.primaryBlue),
      ],
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildScaleControl({
    required double value,
    required ValueChanged<double> onChanged,
    int? imageSizeBytes,
  }) {
    const double minScale = 10;
    const double maxScale = 200;
    const double step = 5;

    String estimatedSize = '';
    if (imageSizeBytes != null && imageSizeBytes > 0) {
      final scaleFactor = (value / 100) * (value / 100);
      estimatedSize = _formatFileSize((imageSizeBytes * scaleFactor).round());
    }

    return Column(
      children: [
        Row(
          children: [
            _scaleButton(
                icon: Icons.remove_rounded,
                onTap: value > minScale
                    ? () => onChanged((value - step).clamp(minScale, maxScale))
                    : null),
            const SizedBox(width: 6),
            Text('KB',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.primaryBlue.withValues(alpha: 0.85),
                          DesignTokens.primaryBlue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${value.toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1),
                    ),
                  ),
                  if (estimatedSize.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('≈ $estimatedSize',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            Text('MB',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(width: 6),
            _scaleButton(
                icon: Icons.add_rounded,
                onTap: value < maxScale
                    ? () => onChanged((value + step).clamp(minScale, maxScale))
                    : null),
          ],
        ),
        const SizedBox(height: 14),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape:
            const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: DesignTokens.primaryBlue,
            inactiveTrackColor: DesignTokens.primaryBlue.withValues(alpha: 0.2),
            thumbColor: DesignTokens.primaryBlue,
            overlayColor: DesignTokens.primaryBlue.withValues(alpha: 0.15),
          ),
          child: Slider(value: value, min: minScale, max: maxScale, onChanged: onChanged),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('100%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('200%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scaleButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? DesignTokens.primaryBlue.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap != null
                ? DesignTokens.primaryBlue.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: onTap != null
                ? DesignTokens.primaryBlue
                : Colors.grey.shade400),
      ),
    );
  }

  double _getSizeReductionPercentage() {
    if (_selectedImageBytes == null || _processedImageBytes == null) return 0.0;
    return (_selectedImageBytes!.length - _processedImageBytes!.length) /
        _selectedImageBytes!.length *
        100;
  }
}
