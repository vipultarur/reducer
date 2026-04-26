import 'dart:async';
import 'package:reducer/features/premium/data/datasources/purchase_datasource.dart';
import 'package:reducer/features/exif/presentation/providers/exif_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:reducer/core/services/permission_service.dart';
import 'package:reducer/core/ads/ad_manager.dart';
import 'package:reducer/shared/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:reducer/shared/widgets/app_button.dart';
import 'package:reducer/core/theme/app_theme.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExifEraserScreen extends ConsumerStatefulWidget {
  const ExifEraserScreen({super.key});

  @override
  ConsumerState<ExifEraserScreen> createState() => _ExifEraserScreenState();
}

class _ExifEraserScreenState extends ConsumerState<ExifEraserScreen> {
  XFile? _selectedImages;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    if (!await PermissionService.instance.ensurePhotosPermission(context)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.permissionRequiredToAccessPhotos)),
        );
      }
      return;
    }
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenGallery(e.toString()))),
        );
      }
      return;
    }
    if (image != null) {
      setState(() {
        _selectedImages = image;
      });
    }
  }

  Future<void> _cleanMetadata() async {
    if (_selectedImages == null) return;

    final isPro = ref.read(premiumControllerProvider).isPro;
    final credits = ref.read(exifCreditProvider).availableCredits;

    // Hard Gate Check: Redirect to premium if out of credits
    if (!isPro && credits <= 0) {
      if (mounted) unawaited(context.push('/premium'));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (!await PermissionService.instance.ensurePhotosPermission(context)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.storagePermissionRequiredToSave)),
          );
        }
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/clean_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // flutter_image_compress removes EXIF by default
      final result = await FlutterImageCompress.compressAndGetFile(
        _selectedImages!.path,
        targetPath,
        quality: 95,
        keepExif: false, // This is the key
      );

      if (result != null) {
        // Save to gallery with robust error handling
        try {
          await Gal.putImage(result.path, album: 'Reducer');
        } catch (e) {
          debugPrint('Gal save error: $e');
          throw 'Failed to save to gallery. Please check storage space and permissions.';
        }

        if (mounted) {
          // Consume credit for free users
          if (!isPro) {
            await ref.read(exifCreditProvider.notifier).useCredit();
          }
          if (mounted) {
            _showSuccessDialog(context);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToCleanMetadata)),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorCleaningMetadata(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Iconsax.tick_circle5, color: Colors.green, size: 64.r),
        title: Text(AppLocalizations.of(context)!.success),
        content: Text(
          AppLocalizations.of(context)!.exifSuccessMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedImages = null);
            },
            child: Text(AppLocalizations.of(context)!.done),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedImages = null);
              context.go('/gallery');
            },
            child: Text(AppLocalizations.of(context)!.viewHistory),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(exifCreditProvider);
    final isPro = ref.watch(premiumControllerProvider).isPro;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exifEraser, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.sp)),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!isPro && !creditState.isLoading)
            Center(
              child: Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: creditState.availableCredits > 0 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: creditState.availableCredits > 0 ? Colors.green : Colors.red,
                    width: 0.5.w,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.freeTrialLeft(creditState.availableCredits),
                  style: TextStyle(
                    color: creditState.availableCredits > 0 ? Colors.green : Colors.red,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                   Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: AppTheme.cardDecoration(context),
                    child: Column(
                      children: [
                        Icon(Iconsax.shield_tick, size: 64.r, color: AppColors.primary),
                        SizedBox(height: 16.h),
                        Text(
                          AppLocalizations.of(context)!.privacyFirst,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppLocalizations.of(context)!.privacyFirstDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  if (_selectedImages == null)
                    _buildUploadPlaceholder()
                  else
                    _buildImagePreview(),
                  
                  SizedBox(height: 32.h),
                  
                  if (_selectedImages != null)
                    AppButton(
                      label: _isProcessing 
                          ? AppLocalizations.of(context)!.cleaning 
                          : AppLocalizations.of(context)!.cleanAndSave,
                      icon: Iconsax.shield_tick,
                      onPressed: () => AdManager().showInterstitialAd(
                        onComplete: _cleanMetadata,
                      ),
                      isLoading: _isProcessing,
                      isFullWidth: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add_square, size: 48.r, color: AppColors.primary),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context)!.tapToSelectImage, 
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Image.file(
                File(_selectedImages!.path),
                height: 300.h,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: Icon(Iconsax.close_circle, color: Colors.red, size: 24.r),
              onPressed: () => setState(() => _selectedImages = null),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          _selectedImages!.name,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

