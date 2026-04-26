import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reducer/core/localization/locale_provider.dart';
import 'package:reducer/core/theme/app_colors.dart';
import 'package:reducer/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/languages.dart';
import '../../domain/models/app_language.dart';

class LanguageSelectionPage extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const LanguageSelectionPage({
    super.key,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredLanguages = AppLanguages.all.where((lang) {
      final name = lang.name.toLowerCase();
      final sub = lang.sub.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || sub.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Glows for Premium Feel
          _buildBackgroundGlows(isDark),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                // Header
                _buildHeader(context, l10n, isDark),

                SizedBox(height: 24.h),

                // Search Bar
                _buildSearchBar(l10n, isDark),

                SizedBox(height: 24.h),

                // Language List
                Expanded(
                  child: _buildLanguageList(filteredLanguages, currentLocale, isDark),
                ),

                // Continue Button (Only shown during onboarding)
                if (!widget.isFromSettings) _buildContinueButton(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlows(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 5.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                ),
          ),
          Positioned(
            bottom: -50.h,
            left: -50.w,
            child: Container(
              width: 250.r,
              height: 250.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: isDark ? 0.05 : 0.03),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 7.seconds,
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          if (widget.isFromSettings)
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: EdgeInsets.all(8.r),
                margin: EdgeInsets.only(right: 16.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.05) : AppColors.onLightBackground.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.1) : AppColors.onLightBackground.withValues(alpha: 0.05)),
                ),
                child: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.onDarkBackground : AppColors.onLightBackground, size: 18.r),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectLanguage,
                  style: TextStyle(
                    color: isDark ? AppColors.onDarkBackground : AppColors.onLightBackground,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5.w,
                  ),
                ),
                if (!widget.isFromSettings)
                  Text(
                    l10n.setupLanguageSubtitle,
                    style: TextStyle(
                      color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.5) : AppColors.onLightSurfaceVariant,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildSearchBar(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.05) : AppColors.onLightBackground.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _searchQuery.isNotEmpty 
                ? AppColors.primary.withValues(alpha: 0.4) 
                : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.1) : AppColors.onLightBackground.withValues(alpha: 0.05)),
            width: 1.w,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: TextStyle(color: isDark ? AppColors.onDarkBackground : AppColors.onLightBackground, fontSize: 15.sp),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: l10n.searchLanguage,
            hintStyle: TextStyle(
              color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.3) : AppColors.onLightSurfaceVariant,
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              Iconsax.search_normal, 
              color: _searchQuery.isNotEmpty ? AppColors.primary : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.4) : AppColors.onLightSurfaceVariant), 
              size: 20.r
            ),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: Icon(Icons.close, color: isDark ? AppColors.onDarkBackground.withValues(alpha: 0.54) : AppColors.onLightSurfaceVariant, size: 16.r),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    unawaited(HapticFeedback.lightImpact());
                  },
                ) 
              : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildLanguageList(List<AppLanguage> languages, Locale currentLocale, bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.h),
      itemCount: languages.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final lang = languages[index];
        final isSelected = currentLocale.languageCode == lang.code;

        return _LanguageTile(
          lang: lang,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () {
            ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
            unawaited(HapticFeedback.mediumImpact());
          },
        ).animate().fadeIn(delay: (index * 20).ms, duration: 300.ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildContinueButton(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            await HapticFeedback.mediumImpact();
            await ref.read(onboardingProvider.notifier).completeOnboarding();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
          ),
          child: Text(
            l10n.continueLabel,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2);
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage lang;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.lang,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        height: 72.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isSelected 
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.03) : AppColors.onLightBackground.withValues(alpha: 0.03)),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.5)
                : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.08) : AppColors.onLightBackground.withValues(alpha: 0.05)),
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: isSelected && !isDark ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            )
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Flag with animation
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.12) : AppColors.onLightBackground.withValues(alpha: 0.12)),
                        width: 1.5.w,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                        )
                      ] : [],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        lang.flag,
                        fit: BoxFit.cover,
                      ).animate(target: isSelected ? 1 : 0).shimmer(duration: 1.5.seconds, color: Colors.white.withValues(alpha: 0.24)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Name and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.sub,
                          style: TextStyle(
                            color: isSelected 
                                ? (isDark ? AppColors.onDarkBackground : AppColors.primary) 
                                : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.9) : AppColors.onLightBackground),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          lang.name,
                          style: TextStyle(
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.7) 
                                : (isDark ? AppColors.onDarkBackground.withValues(alpha: 0.4) : AppColors.onLightSurfaceVariant),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection Indicator
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.onPrimary,
                        size: 14.r,
                      ),
                    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
