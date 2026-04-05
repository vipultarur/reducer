import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reducer/core/models/image_settings.dart';

/// Result object for bulk processing updates
class BulkProgress {
  final double progress;
  final List<File?> batchResults;
  BulkProgress(this.progress, this.batchResults);
}

/// High-performance image processor leveraging native compression
class ImageProcessor {
  
  /// Process thumbnail for fast live preview
  static Future<Uint8List?> processImageThumbnail(
    Uint8List inputBytes,
    ImageSettings settings, {
    bool isPremium = false,
  }) async {
    try {
      return await _processNative(inputBytes, settings);
    } catch (e) {
      debugPrint('Error processing thumbnail: $e');
      return null;
    }
  }

  /// Process full-resolution image for final export
  static Future<File?> processImage(
    File input,
    ImageSettings settings, {
    bool isPremium = false,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final processedBytes = await _processNative(bytes, settings);

      if (processedBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(
        '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.${settings.format.extension}',
      );
      await outputFile.writeAsBytes(processedBytes);

      return outputFile;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  /// Process image bytes directly
  static Future<Uint8List?> processImageBytes(
    Uint8List inputBytes,
    ImageSettings settings, {
    bool isPremium = false,
  }) async {
    try {
      return await _processNative(inputBytes, settings);
    } catch (e) {
      debugPrint('Error processing image bytes: $e');
      return null;
    }
  }

  /// Bulk processing with parallel execution and results yielding
  static Stream<BulkProgress> processBulkWithProgress(
    List<File> inputs,
    ImageSettings settings, {
    bool isPremium = false,
    int maxConcurrent = 3,
  }) async* {
    int completed = 0;
    final total = inputs.length;

    for (int i = 0; i < inputs.length; i += maxConcurrent) {
      final batch = inputs.skip(i).take(maxConcurrent).toList();
      
      final results = await Future.wait(
        batch.map((file) => processImage(file, settings, isPremium: isPremium)),
      );

      completed += batch.length;
      yield BulkProgress(completed / total, results);
    }
  }

  /// Native processing core using flutter_image_compress
  static Future<Uint8List?> _processNative(Uint8List bytes, ImageSettings settings) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Failed to decode image for dimensions');

      // Guard extreme dimensions to avoid OOM
      const int maxPixels = 20 * 1000 * 1000; // 20 MP
      if (decoded.width * decoded.height > maxPixels) {
        debugPrint('Image too large (${decoded.width}x${decoded.height}), skipping processing.');
        return null;
      }

      int targetWidth = (decoded.width * (settings.scalePercent / 100.0)).toInt();
      int targetHeight = (decoded.height * (settings.scalePercent / 100.0)).toInt();

      // Ensure dimensions are positive and valid
      if (targetWidth <= 0) targetWidth = 1;
      if (targetHeight <= 0) targetHeight = 1;

      CompressFormat format;
      switch (settings.format) {
        case ImageFormat.png: format = CompressFormat.png; break;
        case ImageFormat.webp: format = CompressFormat.webp; break;
        default: format = CompressFormat.jpeg; break;
      }

      Uint8List? result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: settings.quality.toInt(),
        rotate: settings.rotation.toInt(),
        format: format,
      );

      if (settings.flipHorizontal || settings.flipVertical) {
        result = await compute(_handleFlipInIsolate, _FlipParams(
          bytes: result,
          flipH: settings.flipHorizontal,
          flipV: settings.flipVertical,
        ));
      }

      return result;
    } catch (e, stack) {
      debugPrint('Exception in _processNative: $e');
      debugPrint(stack.toString());
      return null;
    }
  }
}

/// Helper for flipping images in a background isolate.
/// Must be a top-level function for [compute].
Uint8List _handleFlipInIsolate(_FlipParams params) {
  var image = img.decodeImage(params.bytes);
  if (image == null) return params.bytes;

  if (params.flipH) image = img.flipHorizontal(image);
  if (params.flipV) image = img.flipVertical(image);

  // Use a high quality for the intermediate flip step
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

/// Parameters for the flipping isolate.
class _FlipParams {
  final Uint8List bytes;
  final bool flipH;
  final bool flipV;
  _FlipParams({required this.bytes, required this.flipH, required this.flipV});
}
