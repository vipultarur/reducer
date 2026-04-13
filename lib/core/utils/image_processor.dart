import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/utils/target_dimension_calculator.dart';

/// Result object for bulk processing updates.
class BulkProgress {
  final double progress;
  final List<File?> batchResults;

  BulkProgress(this.progress, this.batchResults);
}

/// High-performance image processor.
class ImageProcessor {
  /// Process thumbnail for fast live preview.
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

  /// Process full-resolution image for final export.
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

  /// Process image bytes directly.
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

  /// Bulk processing with parallel execution and results yielding.
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

  static Future<Uint8List?> _processNative(
    Uint8List bytes,
    ImageSettings settings,
  ) async {
    try {
      final target = await compute(_calculateAndPrepareIsolate, _PrepareParams(
        bytes: bytes,
        settings: settings,
      ));

      if (target == null) return null;

      if (settings.format == ImageFormat.bmp) {
        return await compute(_encodeBmpInIsolate, target.preparedBytes);
      }

      final compressFormat = _toCompressFormat(settings.format);
      
      // ── SMART ITERATIVE COMPRESSION ──────────────────────────────────────────
      // If a target file size is specified, we perform binary search.
      if (settings.targetFileSizeKB != null && settings.targetFileSizeKB! > 0) {
        return await _iterativeCompress(
          target.preparedBytes,
          settings.targetFileSizeKB!,
          target.width,
          target.height,
          compressFormat,
        );
      }

      // Standard single-pass compression if no target size is set
      return await FlutterImageCompress.compressWithList(
        target.preparedBytes,
        minWidth: target.width,
        minHeight: target.height,
        quality: settings.quality.toInt().clamp(1, 100),
        format: compressFormat,
      );
    } catch (e, stack) {
      debugPrint('Exception in _processNative: $e');
      debugPrint(stack.toString());
      return null;
    }
  }

  /// Uses binary search and upscaling to find/force a target file size.
  static Future<Uint8List?> _iterativeCompress(
    Uint8List bytes,
    double targetSizeKB,
    int width,
    int height,
    CompressFormat format,
  ) async {
    int low = 5;
    int high = 100;
    Uint8List? bestResult;
    
    // Check if the target is significantly LARGER than current image could possibly be
    // at original resolution. If so, we upscale the source bytes first.
    final targetBytesCount = (targetSizeKB * 1024).round();
    
    // Preliminary check at high quality
    var testResult = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: format,
    );
    
    // ── STEP 1: UPSCALING (If target is vastly larger) ───────────────────────
    // If target is > 3x current max quality size, we upscale the image resolution.
    if (targetBytesCount > testResult.length * 3) {
      final upscaleFactor = (targetBytesCount / testResult.length).clamp(1.0, 4.0);
      width = (width * upscaleFactor).round();
      height = (height * upscaleFactor).round();
    }

    // ── STEP 2: BINARY SEARCH QUALITY ────────────────────────────────────────
    for (int i = 0; i < 8; i++) {
      if (low > high) break;
      
      int mid = (low + high) ~/ 2;
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: width,
        minHeight: height,
        quality: mid,
        format: format,
      );

      final currentBytes = result.length;
      debugPrint('Iteration $i: Quality=$mid, Size=${(currentBytes/1024).toStringAsFixed(2)}KB, Target=${targetSizeKB}KB');

      if (currentBytes <= targetBytesCount) {
        bestResult = result;
        low = mid + 1;
      } else {
        high = mid - 1;
        bestResult ??= result;
      }
    }
    
    // ── STEP 3: STRICT PADDING (To reach EXACT "Same to Same" byte count) ────
    // If we're still under the target, append null bytes.
    if (bestResult != null && bestResult.length < targetBytesCount) {
      final diff = targetBytesCount - bestResult.length;
      final padding = Uint8List(diff); // Filled with 0x00 by default
      final output = BytesBuilder(copy: false)
        ..add(bestResult)
        ..add(padding);
      
      final finalResult = output.toBytes();
      debugPrint('Strict Size Met: Final size ${finalResult.length} bytes (Target $targetBytesCount)');
      return finalResult;
    }
    
    return bestResult;
  }

  static CompressFormat _toCompressFormat(ImageFormat format) {
    switch (format) {
      case ImageFormat.png: return CompressFormat.png;
      case ImageFormat.webp: return CompressFormat.webp;
      default: return CompressFormat.jpeg;
    }
  }
}

class _PreparedResult {
  final Uint8List preparedBytes;
  final int width;
  final int height;

  _PreparedResult(this.preparedBytes, this.width, this.height);
}

class _PrepareParams {
  final Uint8List bytes;
  final ImageSettings settings;

  _PrepareParams({required this.bytes, required this.settings});
}

_PreparedResult? _calculateAndPrepareIsolate(_PrepareParams params) {
  var image = img.decodeImage(params.bytes);
  if (image == null) return null;

  final targetDim = TargetDimensions.fromScale(
    originalWidth: image.width,
    originalHeight: image.height,
    scalePercent: params.settings.scalePercent,
  );

  // Apply transformations
  if (image.width != targetDim.width || image.height != targetDim.height) {
    image = img.copyResize(image, width: targetDim.width, height: targetDim.height);
  }

  if (params.settings.rotation % 360 != 0) {
    image = img.copyRotate(image, angle: params.settings.rotation.toInt());
  }

  if (params.settings.flipHorizontal) image = img.flipHorizontal(image);
  if (params.settings.flipVertical) image = img.flipVertical(image);

  // Final check to ensure dimensions are exactly as requested after rotation
  if (image.width != targetDim.width || image.height != targetDim.height) {
    image = img.copyResize(image, width: targetDim.width, height: targetDim.height);
  }

  // Using 100% quality JPG as an intermediary is significantly faster than PNG 
  // in the pure-Dart image library.
  final preparedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 100));
  return _PreparedResult(preparedBytes, image.width, image.height);
}

Uint8List _encodeBmpInIsolate(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  return image != null ? Uint8List.fromList(img.encodeBmp(image)) : bytes;
}
