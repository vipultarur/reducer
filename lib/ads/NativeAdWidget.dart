import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'NativeAdService.dart';
import 'ad_service.dart';

/// Medium-style native ad card with media area.
/// Handles loading shimmer, rendered ad, error + retry, and premium users.
///
/// Usage:
///   const NativeAdWidget()
///
/// The widget self-manages its own [NativeAdService] instance —
/// just drop it in and it loads automatically.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  final NativeAdService _adService = NativeAdService();

  _AdState _adState = _AdState.loading;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Skip entirely for premium users
    if (AdService.isPremium) {
      if (mounted) setState(() => _adState = _AdState.hidden);
      return;
    }

    if (mounted) setState(() => _adState = _AdState.loading);

    _adService.load(
      onLoaded: () {
        if (mounted) setState(() => _adState = _AdState.loaded);
      },
      onFailed: (msg) {
        if (mounted) {
          setState(() {
            _adState = _AdState.failed;
            _errorMessage = msg;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adState == _AdState.hidden) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBadgeBar(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ── "Sponsored" badge row ──────────────────────────────────────────────────

  Widget _buildBadgeBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6200EE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Sponsored',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body switches between shimmer / ad / error ─────────────────────────────

  Widget _buildBody() {
    switch (_adState) {
      case _AdState.loading:
        return const _Shimmer();
      case _AdState.loaded:
        final ad = _adService.nativeAd;
        if (ad == null) return const _Shimmer();
        return SizedBox(
          height: 300,
          child: AdWidget(ad: ad),
        );
      case _AdState.failed:
        return _ErrorView(message: _errorMessage, onRetry: _loadAd);
      case _AdState.hidden:
        return const SizedBox.shrink();
    }
  }
}

// ─── State enum ───────────────────────────────────────────────────────────────

enum _AdState { loading, loaded, failed, hidden }

// ─── Animated shimmer placeholder ─────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + headline + advertiser
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _box(w: 42, h: 42, r: 8),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(w: 140, h: 13),
                      const SizedBox(height: 5),
                      _box(w: 90, h: 11),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Media area
              _box(w: double.infinity, h: 150, r: 8),
              const SizedBox(height: 10),
              // Body text lines
              _box(w: double.infinity, h: 11),
              const SizedBox(height: 5),
              _box(w: 200, h: 11),
              const SizedBox(height: 14),
              // CTA button
              _box(w: 100, h: 36, r: 8),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box({required double w, required double h, double r = 4}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

// ─── Error + retry ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined,
              size: 38, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Ad failed to load',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6200EE),
              side: const BorderSide(color: Color(0xFF6200EE)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}