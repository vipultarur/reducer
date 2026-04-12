import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reducer/core/theme/design_tokens.dart';

class UploadTabContent extends StatelessWidget {
  final bool isGeneratingThumbnail;
  final Uint8List? originalThumbnail;
  final int originalSize;
  final Function(ImageSource) onPickImage;

  const UploadTabContent({
    super.key,
    required this.isGeneratingThumbnail,
    required this.originalThumbnail,
    required this.originalSize,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGeneratingThumbnail)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading image...', style: TextStyle(color: Colors.grey)),
              ],
            )
          else if (originalThumbnail != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        originalThumbnail!,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Original Size: ${_formatSize(originalSize)}',
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
                onPressed: isGeneratingThumbnail
                    ? null
                    : () => onPickImage(ImageSource.gallery),
                icon: const Icon(Iconsax.gallery),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: isGeneratingThumbnail
                    ? null
                    : () => onPickImage(ImageSource.camera),
                icon: const Icon(Iconsax.camera),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
