import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/design_tokens.dart';
import 'package:reducer/shared/presentation/widgets/custom_button.dart';
import 'scale_action_button.dart';

class EditorSettingsPanel extends StatelessWidget {
  final ImageSettings settings;
  final Uint8List? previewThumbnail;
  final bool isProcessingPreview;
  final bool isProcessingFinal;
  final int originalSize;
  final int originalWidth;
  final int originalHeight;
  final bool isPro;
  final ValueChanged<ImageSettings> onSettingChanged;
  final VoidCallback onProcessRequested;

  const EditorSettingsPanel({
    super.key,
    required this.settings,
    required this.previewThumbnail,
    required this.isProcessingPreview,
    required this.isProcessingFinal,
    required this.originalSize,
    required this.originalWidth,
    required this.originalHeight,
    required this.isPro,
    required this.onSettingChanged,
    required this.onProcessRequested,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewThumbnail != null)
            _buildSection(
              title: 'Live Preview',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        previewThumbnail!,
                        height: 200,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                        cacheHeight: 600,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  if (isProcessingPreview)
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
          _buildSection(
            title: 'Resize & Scale',
            child: _buildScaleControl(
              value: settings.scalePercent,
              imageSizeBytes: originalSize,
              originalWidth: originalWidth,
              originalHeight: originalHeight,
              onChanged: (v) =>
                  onSettingChanged(settings.copyWith(scalePercent: v)),
            ),
          ),
          _buildSection(
            title: 'Adjustments',
            child: Column(
              children: [
                _buildSlider(
                    context: context,
                    label: 'Rotation',
                    value: settings.rotation,
                    min: 0,
                    max: 360,
                    onChanged: (v) =>
                        onSettingChanged(settings.copyWith(rotation: v))),
                _buildSlider(
                    context: context,
                    label: 'Quality',
                    value: settings.quality,
                    min: 1,
                    max: 100,
                    onChanged: (v) =>
                        onSettingChanged(settings.copyWith(quality: v))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFlipToggle(
                        label: 'Flip H',
                        value: settings.flipHorizontal,
                        onChanged: (v) => onSettingChanged(
                            settings.copyWith(flipHorizontal: v))),
                    _buildFlipToggle(
                        label: 'Flip V',
                        value: settings.flipVertical,
                        onChanged: (v) =>
                            onSettingChanged(settings.copyWith(flipVertical: v))),
                  ],
                ),
              ],
            ),
          ),
          _buildSection(
            title: 'Export Format',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ImageFormat.values.map((f) {
                return ChoiceChip(
                  label: Text(f.name),
                  selected: settings.format == f,
                  onSelected: (selected) {
                    if (selected) {
                      onSettingChanged(settings.copyWith(format: f));
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
              label: isProcessingFinal ? 'Processing...' : 'Process Image',
              icon: Iconsax.cpu,
              onPressed: isProcessingFinal ? null : onProcessRequested,
              isLoading: isProcessingFinal,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildSlider({
    required BuildContext context,
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
            Text(
                '${value.toInt()}${label.contains('Percent') ? '%' : ''}${label == 'Rotation' ? '°' : ''}'),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: DesignTokens.primaryBlue,
            thumbColor: DesignTokens.primaryBlue,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
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
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: DesignTokens.primaryBlue),
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
    required int originalWidth,
    required int originalHeight,
    int? imageSizeBytes,
  }) {
    const double minScale = 10;
    const double maxScale = 200;
    const double step = 5;

    String estimatedSize = '';
    String resolutionInfo = '';

    if (imageSizeBytes != null && imageSizeBytes > 0) {
      final scaleFactor = (value / 100) * (value / 100);
      estimatedSize = _formatFileSize((imageSizeBytes * scaleFactor).round());

      final targetWidth = (originalWidth * (value / 100)).toInt();
      final targetHeight = (originalHeight * (value / 100)).toInt();
      resolutionInfo =
          '$originalWidth x $originalHeight → $targetWidth x $targetHeight';
    }

    return Column(
      children: [
        Row(
          children: [
            ScaleActionButton(
                icon: Icons.remove_rounded,
                onTap: value > minScale
                    ? () => onChanged((value - step).clamp(minScale, maxScale))
                    : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.primaryBlue,
                          DesignTokens.primaryBlue.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      '${value.toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1),
                    ),
                  ),
                  if (estimatedSize.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(estimatedSize,
                        style: const TextStyle(
                            fontSize: 14,
                            color: DesignTokens.primaryBlue,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(resolutionInfo,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ScaleActionButton(
                icon: Icons.add_rounded,
                onTap: value < maxScale
                    ? () => onChanged((value + step).clamp(minScale, maxScale))
                    : null),
          ],
        ),
      ],
    );
  }
}
