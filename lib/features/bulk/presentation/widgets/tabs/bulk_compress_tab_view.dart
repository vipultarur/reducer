import 'package:flutter/material.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BulkCompressTabView extends StatefulWidget {
  final ImageSettings settings;
  final ValueChanged<ImageSettings> onSettingsChanged;

  const BulkCompressTabView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<BulkCompressTabView> createState() => _BulkCompressTabViewState();
}

class _BulkCompressTabViewState extends State<BulkCompressTabView> {
  late TextEditingController _sizeController;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.settings.targetFileSizeKB != null
        ? (widget.settings.isTargetUnitMb 
            ? widget.settings.targetFileSizeKB! / 1024 
            : widget.settings.targetFileSizeKB!)
        : '';
    _sizeController = TextEditingController(text: initialValue.toString());
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  void _updateSettings({double? size, bool? isMb}) {
    final newIsMb = isMb ?? widget.settings.isTargetUnitMb;
    final rawSize = size ?? double.tryParse(_sizeController.text) ?? 0;
    
    widget.onSettingsChanged(widget.settings.copyWith(
      targetFileSizeKB: newIsMb ? rawSize * 1024 : rawSize,
      isTargetUnitMb: newIsMb,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoNote(context, l10n.bulkSettingsNote),
          const SizedBox(height: AppSpacing.lg),
          _buildCard(
            context,
            title: l10n.targetFileSize.toUpperCase(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.titleMedium(context).copyWith(color: isDark ? AppColors.onDarkSurface : AppColors.onLightSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: isDark ? const BorderSide(color: Colors.white10) : const BorderSide(color: AppColors.lightBorder),
                          ),
                          hintText: l10n.sizeHint,
                          suffixIcon: _sizeController.text.isNotEmpty 
                            ? IconButton(
                                icon: Icon(Icons.close, size: AppSpacing.iconMd, color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant), 
                                onPressed: () {
                                  _sizeController.clear();
                                  _updateSettings(size: 0);
                                },
                              ) 
                            : null,
                        ),
                        onChanged: (value) => _updateSettings(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          _buildUnitButton('MB', widget.settings.isTargetUnitMb, isDark, () => _updateSettings(isMb: true)),
                          _buildUnitButton('KB', !widget.settings.isTargetUnitMb, isDark, () => _updateSettings(isMb: false)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.settings.targetFileSizeKB != null && widget.settings.targetFileSizeKB! > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_fix_high, size: 14.r, color: Colors.orange),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.autoQualityActive,
                            style: TextStyle(fontSize: 11.sp, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Opacity(
            opacity: (widget.settings.targetFileSizeKB != null && widget.settings.targetFileSizeKB! > 0) ? 0.5 : 1.0,
            child: _buildCard(
              context,
              title: l10n.imageQuality.toUpperCase(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.smallerFile, style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          '${widget.settings.quality.toInt()}%',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(l10n.higherQuality, style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant)),
                    ],
                  ),
                  Slider(
                    value: widget.settings.quality,
                    min: 1,
                    max: 100,
                    activeColor: AppColors.primary,
                    inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    onChanged: (widget.settings.targetFileSizeKB != null && widget.settings.targetFileSizeKB! > 0) 
                      ? null 
                      : (v) => widget.onSettingsChanged(widget.settings.copyWith(quality: v)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: AppSpacing.iconSm, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall(context).copyWith(color: isDark ? AppColors.onDarkSurface : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelSmall(context).copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildUnitButton(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? AppColors.darkSurfaceVariant : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.onDarkSurfaceVariant : AppColors.onLightSurfaceVariant),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

