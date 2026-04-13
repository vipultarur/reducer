import 'package:flutter/material.dart';
import 'package:reducer/core/models/image_settings.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoNote(context, 'Settings will be applied to ALL selected images.'),
          const SizedBox(height: AppSpacing.lg),
          _buildCard(
            context,
            title: 'ENTER TARGET FILE SIZE',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.titleMedium(context),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'e.g. 2.5',
                    ),
                    onChanged: (value) => _updateSettings(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
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
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildCard(
            context,
            title: 'IMAGE QUALITY',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Smaller file', style: AppTextStyles.labelSmall(context)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.settings.quality.toInt()}%',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('Higher quality', style: AppTextStyles.labelSmall(context)),
                  ],
                ),
                Slider(
                  value: widget.settings.quality,
                  min: 1,
                  max: 100,
                  activeColor: AppColors.primary,
                  onChanged: (v) => widget.onSettingsChanged(widget.settings.copyWith(quality: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context, String text) {
     return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.primary),
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
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF212121) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
