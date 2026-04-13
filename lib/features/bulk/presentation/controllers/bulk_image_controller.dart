import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/utils/image_processor.dart';
import 'package:image_picker/image_picker.dart';

part 'bulk_image_controller.g.dart';

class BulkImageState {
  final List<XFile> selectedImages;
  final Map<String, File?> processedResults;
  final bool isProcessing;
  final double progress;
  final ImageSettings settings;

  BulkImageState({
    this.selectedImages = const [],
    this.processedResults = const {},
    this.isProcessing = false,
    this.progress = 0.0,
    ImageSettings? settings,
  }) : settings = settings ?? ImageSettings();

  BulkImageState copyWith({
    List<XFile>? selectedImages,
    Map<String, File?>? processedResults,
    bool? isProcessing,
    double? progress,
    ImageSettings? settings,
  }) {
    return BulkImageState(
      selectedImages: selectedImages ?? this.selectedImages,
      processedResults: processedResults ?? this.processedResults,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      settings: settings ?? this.settings,
    );
  }
}

@riverpod
class BulkImageController extends _$BulkImageController {
  @override
  BulkImageState build() {
    return BulkImageState();
  }

  void selectImages(List<XFile> images) {
    state = state.copyWith(selectedImages: images, processedResults: {});
  }

  Future<void> processAll(bool isPro) async {
    if (state.selectedImages.isEmpty) return;

    state = state.copyWith(isProcessing: true, progress: 0.0, processedResults: {});

    final inputFiles = state.selectedImages.map((x) => File(x.path)).toList();
    final progressStream = ImageProcessor.processBulkWithProgress(
      inputFiles,
      state.settings,
      isPremium: isPro,
    );

    int currentIndex = 0;
    await for (final update in progressStream) {
      if (!state.isProcessing) break; // Safety check

      final newBatch = state.selectedImages
          .skip(currentIndex)
          .take(update.batchResults.length)
          .toList();

      state = state.copyWith(
        progress: update.progress,
        processedResults: {
          ...state.processedResults,
          for (int i = 0; i < newBatch.length; i++)
            newBatch[i].name: update.batchResults[i],
        },
      );
      
      currentIndex += update.batchResults.length;
    }

    state = state.copyWith(isProcessing: false);
  }

  void updateSettings(ImageSettings settings) {
    state = state.copyWith(settings: settings);
  }

  void clear() {
    state = BulkImageState();
  }
}
