import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/design_tokens.dart';
import 'package:reducer/core/theme/app_theme.dart';
import 'package:reducer/core/utils/target_dimension_calculator.dart';
import 'package:reducer/shared/widgets/app_button.dart';

import 'package:reducer/shared/presentation/widgets/ads/native_ad_widget.dart';

class ExportTabContent extends StatefulWidget {
  final Uint8List? processedImageBytes;
  final Uint8List? originalThumbnail;
  final Uint8List? previewThumbnail;
  final ImageSettings settings;
  final int originalSize;
  final int originalWidth;
  final int originalHeight;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ExportTabContent({
    super.key,
    required this.processedImageBytes,
    required this.originalThumbnail,
    required this.previewThumbnail,
    required this.settings,
    required this.originalSize,
    required this.originalWidth,
    required this.originalHeight,
    required this.onSave,
    required this.onShare,
  });

  @override
  State<ExportTabContent> createState() => _ExportTabContentState();
}

class _ExportTabContentState extends State<ExportTabContent> {
  bool _showBeforeImage = false;

  TargetDimensions get _selectedDimensions => TargetDimensions.fromScale(
    originalWidth: widget.originalWidth,
    originalHeight: widget.originalHeight,
    scalePercent: widget.settings.scalePercent,
  );

  @override
  Widget build(BuildContext context) {
    if (widget.processedImageBytes == null) {
      return const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.info_circle, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No processed image yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Go to Settings tab and click "Process Image"',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
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
                      _showBeforeImage
                          ? 'Before (Original)'
                          : 'After (Processed)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _showBeforeImage = !_showBeforeImage),
                      icon: Icon(
                        _showBeforeImage ? Iconsax.eye : Iconsax.eye_slash,
                        size: 18,
                      ),
                      label: Text(
                        _showBeforeImage ? 'Show After' : 'Show Before',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                      onPanEnd: (_) => setState(() => _showBeforeImage = false),
                      onLongPressStart: (_) =>
                          setState(() => _showBeforeImage = true),
                      onLongPressEnd: (_) =>
                          setState(() => _showBeforeImage = false),
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _showBeforeImage
                                ? (widget.originalThumbnail ??
                                      widget.previewThumbnail ??
                                      widget.processedImageBytes!)
                                : (widget.previewThumbnail ??
                                      widget.processedImageBytes!),
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
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.finger_scan,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hold image to compare',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ready to Export!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _exportInfoRow('Format', widget.settings.format.name),
                      const SizedBox(height: 8),
                      _exportInfoRow(
                        'Quality',
                        '${widget.settings.quality.toInt()}%',
                      ),
                      const SizedBox(height: 8),
                      _exportInfoRow(
                        'Resolution',
                        '${_selectedDimensions.width} x ${_selectedDimensions.height}',
                        valueColor: DesignTokens.primaryBlue,
                      ),
                      const SizedBox(height: 8),
                      _exportInfoRow(
                        'File Size',
                        _formatFileSize(widget.processedImageBytes!.length),
                        valueColor:
                            widget.processedImageBytes!.length <
                                widget.originalSize
                            ? Colors.green
                            : DesignTokens.primaryBlue,
                      ),
                      if (widget.processedImageBytes!.length <
                          widget.originalSize) ...[
                        const SizedBox(height: 8),
                        _exportInfoRow(
                          'Size Reduced',
                          '${((widget.originalSize - widget.processedImageBytes!.length) / widget.originalSize * 100).toStringAsFixed(1)}%',
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
                child: AppButton(
                  label: 'Save to Gallery',
                  icon: Iconsax.save_2,
                  onPressed: widget.onSave,
                  isFullWidth: true,
                ),

              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: 'Share',
                  icon: Iconsax.share,
                  onPressed: widget.onShare,
                  isFullWidth: true,
                ),

              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
