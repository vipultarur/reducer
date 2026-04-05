import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/core/theme/app_theme.dart';
import 'package:reducer/features/gallery/gallery.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reducer/core/widgets/ads/banner_ad_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String? _appDocDir;

  @override
  void initState() {
    super.initState();
    _initAppDir();
  }

  Future<void> _initAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _appDocDir = dir.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyControllerProvider);
    final items = historyAsync.valueOrNull?.items ?? const <HistoryItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit History'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash),
              onPressed: () => _showClearDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Fix: Delay banner platform view until history is ready.
          if (historyAsync.hasValue) const BannerAdWidget(),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _buildErrorState(error),
              data: (history) {
                if (history.items.isEmpty) return _buildEmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: history.items.length,
                  itemBuilder: (context, index) {
                    final item = history.items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.xl),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child:
                            const Icon(Iconsax.trash, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final notifier =
                            await ref.readHistoryControllerReady();
                        await notifier.removeItem(item.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Item removed from history'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.darkSurface,
                          ),
                        );
                      },
                      child: _buildHistoryCard(item)
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 50 * index),
                          )
                          .slideX(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.error, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unable to load history right now',
              style: AppTextStyles.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$error',
              style: AppTextStyles.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () async {
                final notifier = await ref.readHistoryControllerReady();
                await notifier.loadHistory();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.clock, size: AppSpacing.iconXl4, color: AppColors.primary),
          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.xl2),
          Text(
            'No past edits found',
            style: AppTextStyles.titleLarge(context),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Process and export images\nto see them here',
            style: AppTextStyles.bodyMedium(context).copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: AppSpacing.xl3),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.add),
            label: const Text('Start New Edit'),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppTheme.cardDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () {
            if (item.isBulk) {
              context.push('/bulk-history-detail', extra: item);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-edit feature coming soon!')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: _appDocDir == null
                      ? Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Builder(builder: (context) {
                          final thumbPath = item.getAbsoluteThumbnailPath(_appDocDir!);
                          final file = File(thumbPath);
                          return file.existsSync()
                              ? Image.file(
                                  file,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: const Icon(Iconsax.image, color: Colors.grey),
                                );
                        }),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isBulk) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.grid_5, size: 10, color: AppColors.secondaryDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BULK (${item.itemCount})',
                                    style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.secondaryDark),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            ),
                            child: Text(
                              item.settings.format.toString().split('.').last.toUpperCase(),
                              style: AppTextStyles.badgeLabel(context).copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd').format(item.timestamp),
                            style: AppTextStyles.labelSmall(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_formatSize(item.originalSize)} → ${_formatSize(item.processedSize)}',
                        style: AppTextStyles.titleSmall(context),
                      ),
                      if (item.compressionPercent > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Iconsax.arrow_down, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${item.compressionPercent.toStringAsFixed(1)}% smaller',
                              style: AppTextStyles.labelSmall(context).copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will remove all past edits from history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = await ref.readHistoryControllerReady();
              await notifier.clearAll();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
